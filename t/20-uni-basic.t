#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 145;

use DBI qw(:sql_types);

my $UNIFY  = $ENV{UNIFY};
local $ENV{DATEFMT} = 'MM/DD/YY';

unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

my $dbh;
ok ($dbh = DBI->connect ($dbname, undef, "", {
	RaiseError    => 1,
	PrintError    => 1,
	AutoCommit    => 0,
	ChopBlanks    => 1,
	uni_verbose   => 0,
	uni_scanlevel => 7,
	}), "connect with attributes");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

ok (1, "-- CREATE THE TABLE");
ok ($dbh->do (join " " =>
    "create table xx (",
    "    xs numeric       (4) not null,",
    "    xl numeric       (9),",
    "    xc char          (5),",
    "    xf float            ,",
    "    xr real             ,",
    "    xa amount      (5,2),",
    "    xh huge amount (9,2),",
    "    xt time             ,",
    "    xd date             ,",
    "    xe huge date         ",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0,1000,'   ',0.1,0.2,0.3,1000.4,12:40,11/11/89,7/21/00)"), "insert 0");
foreach my $v ( 1 .. 9 ) {
    ok ($dbh->do ("insert into xx values ($v,100$v,'$v',$v.1,$v.2,$v.3,100$v.4,"
	."12:40,5/20/06,7/21/00)"), "insert $v");
    }
ok (1, "-- FILL THE TABLE, POSITIONAL");
my $sth;
ok ($sth = $dbh->prepare ("insert into xx values (?,?,?,?,?,?,?,?,?,?)"), "ins prepare");
foreach my $v ( 10 .. 18 ) {
    ok ($sth->execute ($v, 1000 + $v, "$v", $v + .1, $v + .2, $v + .3, 1000.4 + $v,
	'11:31', '2/28/93', '11/21/89'), "insert $v");
    }
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

$" = ", ";
ok (1, "-- SELECT FROM THE TABLE");
my %result_ok = (
    0 => "0, 1000, '', 0.100000, 0.200000, 0.30, 1000.40, 12:40, 11/11/89, 07/21/00",

    4 => "4, 1004, '4', 4.100000, 4.200000, 4.30, 1004.40, 12:40, 05/20/06, 07/21/00",
    5 => "5, 1005, '5', 5.100000, 5.200000, 5.30, 1005.40, 12:40, 05/20/06, 07/21/00",
    6 => "6, 1006, '6', 6.100000, 6.200000, 6.30, 1006.40, 12:40, 05/20/06, 07/21/00",
    7 => "7, 1007, '7', 7.100000, 7.200000, 7.30, 1007.40, 12:40, 05/20/06, 07/21/00",
    );
ok ($sth = $dbh->prepare ("select * from xx where xs between 4 and 7 or xs = 0"), "sel prepare");
ok (1, "-- Check the internals");
{   local $" = ":";
    my %attr = (
	NAME      => "xs:xl:xc:xf:xr:xa:xh:xt:xd:xe",
	uni_types => "5:2:1:8:7:-4:-6:-7:-3:-11",
	TYPE      => "5:2:1:8:7:6:7:10:9:11",
	PRECISION => "4:9:5:64:32:9:15:0:0:0",
	SCALE     => "0:0:0:0:0:2:2:0:0:0",
	NULLABLE  => "0:1:1:1:1:1:1:1:1:1",	# Does not work in Unify (yet)
	);
    foreach my $attr (qw(NAME uni_types TYPE PRECISION SCALE)) {
	#printf STDERR "\n%-20s %s\n", $attr, "@{$sth->{$attr}}";
	is ("@{$sth->{$attr}}", $attr{$attr}, "attr $attr");
	}
    }
ok ($sth->execute, "execute");
while (my ($xs, $xl, $xc, $xf, $xr, $xa, $xh, $xt, $xd, $xe) = $sth->fetchrow_array ()) {
    is ($result_ok{$xs}, "$xs, $xl, '$xc', $xf, $xr, $xa, $xh, $xt, $xd, $xe",
	"fetchrow_array $xs");
    }
ok ($sth->finish, "finish");

ok ($sth = $dbh->prepare ("select xl, xc from xx where xs = 8"), "sel prepare");
ok ($sth->execute, "execute");
my $ref;
ok ($ref = $sth->fetchrow_arrayref, "fetchrow_arrayref");
is ("@$ref", "1008, 8", "fr_ar values");
ok ($sth->finish, "finish");
ok (1, "-- test the reexec");
ok ($sth->execute, "execute");
ok ($ref = $sth->fetchrow_arrayref);
is ("@$ref", "1008, 8", "fr_ar values 2nd");
ok ($sth->finish, "finish");

ok ($sth = $dbh->prepare ("select xl from xx where xs = 9"), "sel prepare");
ok ($sth->execute, "execute");
ok ($ref = $sth->fetchrow_hashref, "fetchrow_hashref");
ok (keys %$ref == 1 && exists $ref->{xl} && $ref->{xl} == 1009, "fr_hr values");
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, NESTED");
ok ($sth = $dbh->prepare ("select xs from xx where xs in (3, 5)"), "sel prepare");
ok ($sth->execute, "execute");
while (my ($xs) = $sth->fetchrow_array ()) {
    my $sth2;
    ok ($sth2 = $dbh->prepare ("select xl from xx where xs = @{[$xs - 1]}"), "sel prepare sth2");
    if ($sth2) {
	ok ($sth2->execute, "execute");
	while (my ($xl) = $sth2->fetchrow_array ()) {
	    ok (($xs == 3 || $xs == 5) && $xl == $xs + 999, "nested fetch $xs");
	    }
	}
    ok ($sth2->finish, "finish");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("select xs from xx where xs = ?"), "sel prepare");
foreach my $xs (3 .. 5) {
    ok ($sth->execute ($xs), "execute $xs");
    my ($xc) = $sth->fetchrow_array;
    is ($xs, $xc, "fetch positional $xs");
    }
ok (1, "-- Check the bind_columns");
{   my $xs = 0;
    ok ($sth->bind_columns (\$xs), "bind \$xs");
    ok ($sth->execute (3), "execute 3");
    ok ($sth->fetchrow_arrayref, "fetchrow_arrayref");
    is ($xs, 3, "fetched");
    }
ok ($sth->finish, "finish");

ok (1, "-- UPDATE THE TABLE");
ok ($dbh->do ("update xx set xf = xf + .05 where xs = 5"), "do update");
ok ($dbh->commit, "commit");

ok (1, "-- UPDATE THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("update xx set xa = xa + .05 where xs = ?"), "do update positional");
ok ($sth->execute (4), "execute");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

ok (1, "-- UPDATE THE TABLE, MULTIPLE RECORDS, and COUNT");
ok ($sth = $dbh->prepare ("update xx set xa = xa + .05 where xs = 5 or xs = 6"), "upd prepare");
ok ($sth->execute, "execute");
is ($sth->rows, 2, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");

ok (1, "-- UPDATE THE TABLE, POSITIONAL TWICE");
ok ($sth = $dbh->prepare ("update xx set xc = ? where xs = ?"), "upd prepare");
ok ($sth->execute ("33", 3), "execute");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

ok (1, "-- UPDATE THE TABLE, POSITIONAL TWICE, NON-KEY");
ok ($sth = $dbh->prepare ("update xx set xc = ? where xf = 10.1 and xl = ?"), "upd prepare");
ok ($sth->execute ("12345", 1010), "execute");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

ok ($sth = $dbh->prepare ("select * from xx where xs = ?"), "sel prepare");
ok ($sth->execute (1), "execute 1");
ok ($sth->execute (-1), "execute -1");
ok ($sth->execute ("1"), "execute '1'");
ok ($sth->execute ("-1"), "execute '-1'");
ok ($sth->execute ("  1"), "execute '  1'");
ok ($sth->execute (" -1"), "execute ' -1'");
#$sth->execute ("x");	# Should warn, which it does.
ok ($sth->finish, "finish");

ok (1, "-- Check final state");
my @rec = (
    "0, 1000, , 0.100000, 0.200000, 0.30, 1000.40, 12:40, 11/11/89, 07/21/00",
    "1, 1001, 1, 1.100000, 1.200000, 1.30, 1001.40, 12:40, 05/20/06, 07/21/00",
    "2, 1002, 2, 2.100000, 2.200000, 2.30, 1002.40, 12:40, 05/20/06, 07/21/00",
    "3, 1003, 33, 3.100000, 3.200000, 3.30, 1003.40, 12:40, 05/20/06, 07/21/00",
    "4, 1004, 4, 4.100000, 4.200000, 4.35, 1004.40, 12:40, 05/20/06, 07/21/00",
    "5, 1005, 5, 5.150000, 5.200000, 5.30, 1005.40, 12:40, 05/20/06, 07/21/00",
    "6, 1006, 6, 6.100000, 6.200000, 6.30, 1006.40, 12:40, 05/20/06, 07/21/00",
    "7, 1007, 7, 7.100000, 7.200000, 7.30, 1007.40, 12:40, 05/20/06, 07/21/00",
    "8, 1008, 8, 8.100000, 8.200000, 8.30, 1008.40, 12:40, 05/20/06, 07/21/00",
    "9, 1009, 9, 9.100000, 9.200000, 9.30, 1009.40, 12:40, 05/20/06, 07/21/00",
    "10, 1010, 12345, 10.100000, 10.200000, 10.30, 1010.40, 11:31, 02/28/93, 11/21/89",
    "11, 1011, 11, 11.100000, 11.200000, 11.30, 1011.40, 11:31, 02/28/93, 11/21/89",
    "12, 1012, 12, 12.100000, 12.200000, 12.30, 1012.40, 11:31, 02/28/93, 11/21/89",
    "13, 1013, 13, 13.100000, 13.200000, 13.30, 1013.40, 11:31, 02/28/93, 11/21/89",
    "14, 1014, 14, 14.100000, 14.200000, 14.30, 1014.40, 11:31, 02/28/93, 11/21/89",
    "15, 1015, 15, 15.100000, 15.200000, 15.30, 1015.40, 11:31, 02/28/93, 11/21/89",
    "16, 1016, 16, 16.100000, 16.200001, 16.30, 1016.40, 11:31, 02/28/93, 11/21/89",
    "17, 1017, 17, 17.100000, 17.200001, 17.30, 1017.40, 11:31, 02/28/93, 11/21/89",
    "18, 1018, 18, 18.100000, 18.200001, 18.30, 1018.40, 11:31, 02/28/93, 11/21/89",
    );
ok ($sth = $dbh->prepare ("select * from xx order by xs"), "sel prepare final state");
ok ($sth->execute, "execute");
while (my @f = $sth->fetchrow_array ()) {
    my $exp = shift @rec;
    is ("@f", $exp, "final $f[0]");
    }
ok ($sth->finish, "finish");

ok ($dbh->do ("delete xx"), "do delete");
ok ($dbh->commit, "commit");

ok (1, "-- DROP THE TABLE");
ok ($dbh->do ("drop table xx"), "do drop");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

exit 0;
