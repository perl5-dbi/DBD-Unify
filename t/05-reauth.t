#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => "No tests here yet. Please investigate";

__END__

BEGIN { use_ok ("DBI") };

my $dbuser   = $ENV{ORACLE_USERID}   || "scott/tiger";
my $dbuser_2 = $ENV{ORACLE_USERID_2} || "";

sub give_up { warn @_ if @_; print "1..0\n"; exit 0; }

if ($dbuser_2 eq "") {
    print "ORACLE_USERID_2 not defined.\nTests skiped.\n";
    give_up ();
    }
(my $uid1 = uc $dbuser)   =~ s:/.*::;
(my $uid2 = uc $dbuser_2) =~ s:/.*::;
if ($uid1 eq $uid2) {
    give_up ("ORACLE_USERID_2 not unique.\nTests skiped.\n")
    }

my $dbh = DBI->connect ("dbi:Unify:", $dbuser, "");

unless($dbh) {
    give_up("Unable to connect to Oracle ($DBI::errstr)\nTests skiped.\n");
    }

print "1..3\n";

ok (0, ($dbh->selectrow_array ("SELECT USER FROM DUAL"))[0] eq $uid1);
ok (0, $dbh->func ($dbuser_2, "", "reauthenticate"));
ok (0, ($dbh->selectrow_array ("SELECT USER FROM DUAL"))[0] eq $uid2);

$dbh->disconnect;
