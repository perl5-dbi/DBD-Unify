#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN { use_ok ("DBI") };

my ($schema, $dbh) = ("DBUTIL");

ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "Connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

my $sth = $dbh->prepare ("select * from DIRS");
ok ($sth->execute,	"execute");
ok ($sth->{Active},	"sth attr Active");
$sth->finish;
ok (!$sth->{Active},	"sth attr not Active");
$dbh->disconnect;	# Should auto-destroy $sth;
ok (!$dbh->ping,	"disconnected");

{   local $SIG{__WARN__} = sub {};
    $ENV{UNIFY} = undef;
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY undef");
    $ENV{UNIFY} = "";
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY ''");
    $ENV{UNIFY} = "/dev/null";
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY '/dev/null'");
    }

exit 0;
