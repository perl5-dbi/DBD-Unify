#!/usr/bin/perl

use strict;
use warnings;

my ($pid, $p_in, $p_out);
BEGIN {
    delete @ENV{qw( LC_ALL LANG BOOLFMT DATEFMT )};
    $ENV{DATEFMT} = "MM/DD/YY";

    pipe ($p_in, $p_out);
    unless ($pid = fork ()) {
	close $p_out;
	scalar <$p_in>;
	close $p_in;
	qx{echo "xlock xx; !sleep 5;" | env UNIFY=$ENV{UNIFY} DBPATH=$ENV{DBPATH} SQL -q >/dev/null 2>&1};
	exit;
	}
    }

use Test::More;
use DBI qw(:sql_types);

my $UNIFY  = $ENV{UNIFY};

exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db" or
    BAIL_OUT ("\$DBPATH not set\n");
my $dbname = "DBI:Unify:$ENV{DBPATH}";

my $dbh;
ok ($dbh = DBI->connect ($dbname, undef, "", {
	RaiseError    => 1,
	PrintError    => 1,
	AutoCommit    => 0,
	ChopBlanks    => 1,
	uni_verbose   => 0,
	uni_scanlevel => 6,
	}), "connect with attributes");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }
is ($dbh->state, "", "state method");
is ($DBI::state, "", "state method");

like (qx{env DBPATH=$ENV{DBPATH} lmshow -Oprocess=$$},
      qr{20-uni-basic.t}i, "message log init");

ok (1, "-- CREATE THE TABLE");
ok ($dbh->do (join " " =>
    qq{create table xx (},
    qq{    xs  numeric       (4) not null,},
    qq{    xl  numeric       (9),},
    qq{    xc  char          (5),},
    qq{    xf  float            ,},
    qq{    xr  real             ,},
    qq{    xa  amount      (5,2),},
    qq{    xh  huge amount (9,2),},
    qq{   "xT" time             ,},
    qq{    xd  date             ,},
    qq{    xe  huge date         },
    qq{)}), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
is ($dbh->state, "", "state method");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0,1000,'   ',0.1,0.25,0.50,1000.4,12:40,11/11/89,7/21/00)"), "insert 0");
is ($dbh->state, "", "state method");
foreach my $v ( 1 .. 9 ) {
    ok ($dbh->do ("insert into xx values ($v,100$v,'$v',$v.1,$v.25,$v.50,100$v.4,"
	."12:40,5/20/06,7/21/00)"), "insert $v");
    is ($dbh->state, "", "state method");
    }
ok (1, "-- FILL THE TABLE, POSITIONAL");
my $sth;
ok ($sth = $dbh->prepare ("insert into xx values (?,?,?,?,?,?,?,?,05/29/07,02/06/07)"), "ins prepare");
is ($sth->state, "", "state method");
foreach my $v ( 10 .. 18 ) {
    ok ($sth->execute ($v, 1000 + $v, "$v", $v + .1, $v + .25, $v + .50, 1000.4 + $v,
	'11:31'), "insert $v");
    is ($sth->state, "", "state method");
    }
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

$" = ", ";
ok (1, "-- SELECT FROM THE TABLE");
my %result_ok = (
    0 => "0, 1000, '', 0.100000, 0.250000, 0.50, 1000.40, 12:40, 11/11/89, 07/21/00",

    4 => "4, 1004, '4', 4.10000, 4.25000, 4.50, 1004.40, 12:40, 05/20/06, 07/21/00",
    5 => "5, 1005, '5', 5.10000, 5.25000, 5.50, 1005.40, 12:40, 05/20/06, 07/21/00",
    6 => "6, 1006, '6', 6.10000, 6.25000, 6.50, 1006.40, 12:40, 05/20/06, 07/21/00",
    7 => "7, 1007, '7', 7.10000, 7.25000, 7.50, 1007.40, 12:40, 05/20/06, 07/21/00",
    );
ok ($sth = $dbh->prepare ("select * from xx where xs between ? and ? or xc = ?"), "sel prepare");
is ($sth->state, "", "state method");
ok ($sth->execute (4, 7, "0"), "execute");
is ($sth->state, "", "state method");
ok (1, "-- Check the internals");
{   my %attr = (	# $sth attributes as documented in DBI-1.607
	NAME          => [qw( xs xl xc xf xr xa xh xT xd xe )],
	NAME_lc       => [qw( xs xl xc xf xr xa xh xt xd xe )],
	NAME_uc       => [qw( XS XL XC XF XR XA XH XT XD XE )],
	NAME_hash     => {qw( xs 0 xl 1 xc 2 xf 3 xr 4 xa 5 xh 6 xT 7 xd 8 xe 9 )},
	NAME_lc_hash  => {qw( xs 0 xl 1 xc 2 xf 3 xr 4 xa 5 xh 6 xt 7 xd 8 xe 9 )},
	NAME_uc_hash  => {qw( XS 0 XL 1 XC 2 XF 3 XR 4 XA 5 XH 6 XT 7 XD 8 XE 9 )},
	uni_type      => [ 5, 2, 1, 8, 7, -4, -6, -7, -3, -11],
	TYPE          => [ 5, 2, 1, 8, 7, 6, 7, 10, 9, 9],
	PRECISION     => [ 4, 9, 5, 64, 32, 9, 15, 0, 0, 0],
	SCALE         => [ 0, 0, 0, 0, 0, 2, 2, 0, 0, 0],
#	NULLABLE      => [ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1], # Does not work in Unify (yet)
	NULLABLE      => [ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
	CursorName    => "c_sql_00_000001",
	NUM_OF_FIELDS => 10,
	NUM_OF_PARAMS =>  3,
	Database      => $dbh,
	ParamValues   => { 1 => 4, 2 => 7, 3 => "0" },
	ParamTypes    => { 1 => 5, 2 => 5, 3 => 1   },
	ParamArrays   => undef, # NYI
	RowsInCache   => 0,
	);
    foreach my $attr (sort keys %attr) {
	#printf STDERR "\n%-20s %s\n", $attr, "@{$sth->{$attr}}";
	my $av = exists $sth->{$attr} ? $sth->{$attr} : undef;
	is_deeply ($av, $attr{$attr}, "attr $attr");
	}
    }
while (my ($xs, $xl, $xc, $xf, $xr, $xa, $xh, $xt, $xd, $xe) = $sth->fetchrow_array ()) {
    is ($sth->state, "", "state method");
    is ($result_ok{$xs}, "$xs, $xl, '$xc', $xf, $xr, $xa, $xh, $xt, $xd, $xe",
	"fetchrow_array $xs");
    }
ok ($sth->finish, "finish");

ok ($sth = $dbh->prepare ("select xl, xc from xx where xs = 8"), "sel prepare");
is ($sth->state, "", "state method");
ok ($sth->execute, "execute");
is ($sth->state, "", "state method");
my $ref;
ok ($ref = $sth->fetchrow_arrayref, "fetchrow_arrayref");
is ($sth->state, "", "state method");
is ("@$ref", "1008, 8", "fr_ar values");
ok ($sth->finish, "finish");
ok (1, "-- test the reexec");
ok ($sth->execute, "execute");
is ($sth->state, "", "state method");
ok ($ref = $sth->fetchrow_arrayref);
is ($sth->state, "", "state method");
is ("@$ref", "1008, 8", "fr_ar values 2nd");
ok ($sth->finish, "finish");

ok ($sth = $dbh->prepare ("select xl from xx where xs = 9"), "sel prepare");
is ($sth->state, "", "state method");
ok ($sth->execute, "execute");
is ($sth->state, "", "state method");
ok ($ref = $sth->fetchrow_hashref, "fetchrow_hashref");
is ($sth->state, "", "state method");
ok (keys %$ref == 1 && exists $ref->{xl} && $ref->{xl} == 1009, "fr_hr values");
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, NESTED");
ok ($sth = $dbh->prepare ("select xs from xx where xs in (3, 5)"), "sel prepare");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($DBI::state, "", "state method");
ok ($sth->execute, "execute");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($DBI::state, "", "state method");
while (my ($xs) = $sth->fetchrow_array ()) {
    my $sth2;
    ok ($sth2 = $dbh->prepare ("select xl from xx where xs = @{[$xs - 1]}"), "sel prepare sth2");
    if ($sth2) {
	is ($sth2->state, "", "state method");
	is ($dbh->state, "", "state method");
	is ($DBI::state, "", "state method");
	ok ($sth2->execute, "execute");
	is ($sth2->state, "", "state method");
	is ($dbh->state, "", "state method");
	is ($DBI::state, "", "state method");
	while (my ($xl) = $sth2->fetchrow_array ()) {
	    is ($sth2->state, "", "state method");
	    is ($dbh->state, "", "state method");
	    is ($DBI::state, "", "state method");
	    ok (($xs == 3 || $xs == 5) && $xl == $xs + 999, "nested fetch $xs");
	    }
	}
    ok ($sth2->finish, "finish");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("select xs from xx where xs = ?"), "sel prepare");
is ($sth->state, "", "state method");
foreach my $xs (3 .. 5) {
    ok ($sth->execute ($xs), "execute $xs");
    is ($sth->state, "", "state method");
    my ($xc) = $sth->fetchrow_array;
    is ($sth->state, "", "state method");
    is ($xs, $xc, "fetch positional $xs");
    }
ok (1, "-- Check the bind_columns");
{   my $xs = 0;
    ok ($sth->bind_columns (\$xs), "bind \$xs");
    is ($sth->state, "", "state method");
    ok ($sth->execute (3), "execute 3");
    is ($sth->state, "", "state method");
    ok ($sth->fetchrow_arrayref, "fetchrow_arrayref");
    is ($sth->state, "", "state method");
    is ($xs, 3, "fetched");
    }
ok ($sth->finish, "finish");

ok (1, "-- UPDATE THE TABLE");
is ($dbh->do ("update xx set xf = xf + .0625 where xs = 5"), 1, "do update");
is ($dbh->state, "", "state method");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("update xx set xa = xa + .0625 where xs = ?"), "do update positional");
is ($sth->state, "", "state method");
is ($sth->execute (4), 1, "execute");
is ($sth->state, "", "state method");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, MULTIPLE RECORDS, and COUNT");
ok ($sth = $dbh->prepare ("update xx set xa = xa + .0625 where xs = 5 or xs = 6"), "upd prepare");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($sth->execute, 2, "execute");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($sth->rows, 2, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, NO RECORDS, and COUNT");
ok ($sth = $dbh->prepare ("update xx set xa = xa + .125 where xs = 95 or xs = 96"), "upd prepare");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($sth->execute, "0E0", "execute");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($sth->rows, 0, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, POSITIONAL TWICE");
ok ($sth = $dbh->prepare ("update xx set xc = ? where xs = ?"), "upd prepare");
is ($sth->state, "", "state method");
is ($sth->execute ("33", 3), 1, "execute");
is ($sth->state, "", "state method");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, POSITIONAL TWICE, NON-KEY");
ok ($sth = $dbh->prepare ("update xx set xc = ? where xf = 10.1 and xl = ?"), "upd prepare");
is ($sth->state, "", "state method");
is ($sth->execute ("12345", 1010), 1, "execute");
is ($sth->state, "", "state method");
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- UPDATE THE TABLE, ERROR RETURN");
ok ($sth = $dbh->prepare ("update xx set xs = null"), "upd prepare");
is ($sth->state, "", "state method");
is ($dbh->state, "", "state method");
is ($DBI::state, "", "state method");
{ local ( $sth->{RaiseError}, $sth->{PrintError} );
  is ($sth->execute, undef, "execute");
  is ($sth->state, "35000", "state method");
  is ($dbh->state, "35000", "state method");
  is ($DBI::state, "35000", "state method"); }
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");
is ($DBI::state, "", "state method");

ok (1, "-- UPDATE THE TABLE, ERROR RETURN");
{ local ( $dbh->{RaiseError}, $dbh->{PrintError} );
  is ($dbh->do ("update xx set xs = null" ), undef, "do update");
  is ($dbh->state, "35000", "state method"); }
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DELETE FROM TABLE, ONE RECORD");
ok ($sth = $dbh->prepare ("delete xx where xs = 2"), "del prepare");
is ($sth->state, "", "state method");
is ($sth->execute, 1, "execute");
is ($sth->state, "", "state method");
is ($sth->rows, 1, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DELETE FROM TABLE, NO RECORDS");
ok ($sth = $dbh->prepare ("delete xx where xs = 98"), "del prepare");
is ($sth->state, "", "state method");
is ($sth->execute, "0E0", "execute");
is ($sth->state, "", "state method");
is ($sth->rows, 0, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DELETE FROM TABLE");
ok ($sth = $dbh->prepare ("delete xx"), "del prepare");
is ($sth->state, "", "state method");
is ($sth->execute, 19, "execute");
is ($sth->state, "", "state method");
is ($sth->rows, 19, "rows method");
ok ($sth->finish, "finish");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DO DELETE FROM TABLE, NO ROWS");
is ($dbh->do ("delete xx where xs = -1"), "0E0", "do delete");
is ($dbh->state, "", "state method");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DO DELETE FROM TABLE, ONE ROW");
is ($dbh->do ("delete xx where xs = 1"), 1, "do delete");
is ($dbh->state, "", "state method");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DO DELETE FROM TABLE, TWO ROWS");
is ($dbh->do ("delete xx where xs = 1 or xs = 0"), 2, "do delete");
is ($dbh->state, "", "state method");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok (1, "-- DO DELETE FROM TABLE, ALL ROWS");
is ($dbh->do ("delete xx"), 19, "do delete");
is ($dbh->state, "", "state method");
ok ($dbh->rollback, "rollback");
is ($dbh->state, "", "state method");

ok ($sth = $dbh->prepare ("select * from xx where xs = ?"), "sel prepare");
is ($sth->state, "", "state method");
ok ($sth->execute (1), "execute 1");
is ($sth->state, "", "state method");
ok ($sth->execute (-1), "execute -1");
is ($sth->state, "", "state method");
ok ($sth->execute ("1"), "execute '1'");
is ($sth->state, "", "state method");
ok ($sth->execute ("-1"), "execute '-1'");
is ($sth->state, "", "state method");
ok ($sth->execute ("  1"), "execute '  1'");
is ($sth->state, "", "state method");
ok ($sth->execute (" -1"), "execute ' -1'");
is ($sth->state, "", "state method");
#$sth->execute ("x");	# Should warn, which it does.
ok ($sth->finish, "finish");

ok (1, "-- Check final state");
my @rec = (
    "0, 1000, , 0.100000, 0.250000, 0.50, 1000.40, 12:40, 11/11/89, 07/21/00",
    "1, 1001, 1, 1.10000, 1.25000, 1.50, 1001.40, 12:40, 05/20/06, 07/21/00",
    "2, 1002, 2, 2.10000, 2.25000, 2.50, 1002.40, 12:40, 05/20/06, 07/21/00",
    "3, 1003, 33, 3.10000, 3.25000, 3.50, 1003.40, 12:40, 05/20/06, 07/21/00",
    "4, 1004, 4, 4.10000, 4.25000, 4.56, 1004.40, 12:40, 05/20/06, 07/21/00",
    "5, 1005, 5, 5.16250, 5.25000, 5.50, 1005.40, 12:40, 05/20/06, 07/21/00",
    "6, 1006, 6, 6.10000, 6.25000, 6.50, 1006.40, 12:40, 05/20/06, 07/21/00",
    "7, 1007, 7, 7.10000, 7.25000, 7.50, 1007.40, 12:40, 05/20/06, 07/21/00",
    "8, 1008, 8, 8.10000, 8.25000, 8.50, 1008.40, 12:40, 05/20/06, 07/21/00",
    "9, 1009, 9, 9.10000, 9.25000, 9.50, 1009.40, 12:40, 05/20/06, 07/21/00",
    "10, 1010, 12345, 10.1000, 10.2500, 10.50, 1010.40, 11:31, 05/29/07, 02/06/07",
    "11, 1011, 11, 11.1000, 11.2500, 11.50, 1011.40, 11:31, 05/29/07, 02/06/07",
    "12, 1012, 12, 12.1000, 12.2500, 12.50, 1012.40, 11:31, 05/29/07, 02/06/07",
    "13, 1013, 13, 13.1000, 13.2500, 13.50, 1013.40, 11:31, 05/29/07, 02/06/07",
    "14, 1014, 14, 14.1000, 14.2500, 14.50, 1014.40, 11:31, 05/29/07, 02/06/07",
    "15, 1015, 15, 15.1000, 15.2500, 15.50, 1015.40, 11:31, 05/29/07, 02/06/07",
    "16, 1016, 16, 16.1000, 16.2500, 16.50, 1016.40, 11:31, 05/29/07, 02/06/07",
    "17, 1017, 17, 17.1000, 17.2500, 17.50, 1017.40, 11:31, 05/29/07, 02/06/07",
    "18, 1018, 18, 18.1000, 18.2500, 18.50, 1018.40, 11:31, 05/29/07, 02/06/07",
    );
ok ($sth = $dbh->prepare ("select * from xx order by xs"), "sel prepare final state");
is ($sth->state, "", "state method");
ok ($sth->execute, "execute");
is ($sth->state, "", "state method");
while (my @f = $sth->fetchrow_array ()) {
    is ($sth->state, "", "state method");
    my $exp = shift @rec;
    is ("@f", $exp, "final $f[0]");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT WITH WARNINGS");
ok ($dbh->disconnect, "disconnect");
print $p_out "LOCK!\n";
close $p_out;
sleep 2;
ok ($dbh = DBI->connect ($dbname, undef, "", {
	RaiseError    => 1,
	PrintError    => 1,
	PrintWarn     => 0,
	AutoCommit    => 0,
	ChopBlanks    => 1,
	uni_verbose   => 0,
	uni_scanlevel => 6,
	}), "connect with attributes");
ok ($sth = $dbh->prepare ("select xl, xc from xx where xs = ?"), "sel prepare");
ok ($sth->execute (1), "execute 1");
is ($sth->state, "", "state method");
ok ($ref = $sth->fetchrow_arrayref, "fetchrow_arrayref");
is ($sth->state, "01U00", "state method");
is ("@$ref", "1001, 1", "fr_ar values");
ok ($sth->finish, "finish");
waitpid $pid, 0;

is ($dbh->do ("delete xx"), 19, "do delete");
is ($dbh->state, "", "state method");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok (1, "-- DROP THE TABLE");
ok ($dbh->do ("drop table xx"), "do drop");
is ($dbh->state, "", "state method");
ok ($dbh->commit, "commit");
is ($dbh->state, "", "state method");

ok ($dbh->disconnect, "disconnect");

done_testing;
