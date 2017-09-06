#!/pro/bin/perl

use 5.18.2;
use warnings;

use PROCURA::DBD;

my $dbh = DBDlogon;

my $dd = $dbh->func ("db_dict");

foreach my $t (grep { defined } @{$dd->{TABLE}}) {
    my @k = @{$t->{KEY}};
    @k < 2 and next;
    say "$t->{ANAME}.$t->{NAME} (@k)";
    }
