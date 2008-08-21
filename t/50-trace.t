#!/usr/bin/perl

use strict;
use warnings;

 use Test::More tests => 383;
#use Test::More "no_plan";

BEGIN { use_ok ("DBI") }

my $dbh;
ok ($dbh = DBI->connect ("dbi:Unify:", "", ""), "connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

# Hmm with perlIO I can use
# open my $trace_handle, ">", \$trace;
# $dbh->trace (1, $trace_handle);
# $dbh->trace (0);
# and have the complete trace in $trace
my $tracefile = "trace.log";
my $trace;

sub stoptrace
{
    ok (1, "Stop trace");
    $dbh->trace (0);

    $trace = "";
    open my $tf, "<", $tracefile or return;
    {   local $/;
	$trace = <$tf>;
	}
    close $tf;

    unlink $tracefile;
    } # stoptrace

END {
    stoptrace (0);
    }

my ($catalog, $schema, $table, $type, $rw);

my %pat = (
    dbi => [	qr{^}s,
		qr{trace level set to 0x0/1}s,
		qr{trace level set to 0x0/2}s,
		qr{trace level set to 0x0/3}s,
		qr{trace level set to 0x0/4}s,
		qr{trace level set to 0x0/5}s,
		],
    dbd => [	undef,
		qr{^}s,
		qr{DBD::Unify::st_fetch u_sql_00_000000}s,
		qr{DBD::Unify::st_finish u_sql_00_000000}s,
		qr{Field   2: \[01 12 00 00 12\]}s,
		qr{Field   2: \[01 12 00 00 FFFFFFFF\] OWNR}s,
		qr{LEVEL 6 HAS NOT YET BEEN IMPLEMENTED}s,
		],
    );

sub testtrace
{
    my $dbdv = shift;
    ok (1, "-- $dbdv: table_info ()");

    ok (my $sth = $dbh->table_info (), "table_info ()");
    ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
    my $n = 0;
    ok ($sth->fetch,  "fetch");
    ok ($sth->finish, "finish");

    stoptrace ();

    ok (1, "$dbdv - trace = " . length $trace);
    } # testtrace

foreach     my $v_dbi (0 .. 4) {
    foreach my $v_dbd (0 .. 5) {
	my $dbdv = "$v_dbi.$v_dbd";
	is ($dbh->trace ($v_dbi, $tracefile),  0, "Set DBI trace level $v_dbi");
	is ($dbh->{dbd_verbose} = $v_dbd, $v_dbd, "Set DBD trace level $v_dbd");
	testtrace ($dbdv);

	my $v_nxt = $v_dbi + 1;
	like   ($trace, $pat{dbi}[$v_dbi],	"DBI trace matches level $v_dbi");
	unlike ($trace, $pat{dbi}[$v_nxt],	"DBI trace doesn't match $v_nxt");

	$v_dbd or next;
	my $v_trc = $v_dbi > $v_dbd ? $v_dbi : $v_dbd; # DBD trace uses the highest
	   $v_nxt = $v_trc + 1;
	like   ($trace, $pat{dbd}[$v_trc],	"DBD trace matches level $v_trc");
	unlike ($trace, $pat{dbd}[$v_nxt],	"DBD trace doesn't match $v_nxt");
	}
    }
