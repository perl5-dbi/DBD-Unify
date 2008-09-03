#!/usr/bin/perl

use strict;
use warnings;

#use Test::More tests => 145;
use Test::More "no_plan";

my $UNIFY  = $ENV{UNIFY};

unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

use DBI;

my $dbh;
ok ($dbh = DBI->connect ($dbname, undef, "", {
	RaiseError    => 1,
	PrintError    => 1,
	AutoCommit    => 0,
	ChopBlanks    => 1,
	dbd_verbose   => 0,
	uni_scanlevel => 7,
	}), "connect with attributes");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

ok (1, "-- CREATE A TABLE");
ok ($dbh->do (join " " =>
    "create table xx (",
    "    xs numeric (4) not null,",
    "    xl numeric (9),",
    "    xc char    (5),",
    "    xf float",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0, 123456789, 'abcde', 1.23)"), "insert 1234");
foreach my $v ( 1 .. 9 ) {
    ok ($dbh->do ("insert into xx values (?, ?, ?, ?)", undef,
	$v, $v * 100000, "$v", .99/$v), "insert $v with 3-arg do ()");
    }

ok ($dbh->commit, "commit");

ok ($dbh->do ("drop table xx"), "Drop table");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

exit 0;
