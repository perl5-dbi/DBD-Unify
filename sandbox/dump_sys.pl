#!/pro/bin/perl

use 5.18.2;
use warnings;

use CSV;
use PROCURA::DBD;

my $dbh = DBDlogon;

foreach my $t (sort grep m/\b(SYS|DBUTIL)\b/ => $dbh->tables (undef, undef, undef, undef)) {
    $t =~ s/"//g;
    my $sth = prepex ("select * from $t");
    csv (in => sub { $sth->fetchrow_hashref }, out => "dta/$t");
    }
