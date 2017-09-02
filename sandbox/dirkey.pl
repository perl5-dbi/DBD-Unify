#!/pro/bin/perl -w

use 5.18.2;
use warnings;
use integer;

use DBI;

my $dsn     = "dbi:Unify:$ENV{DBPATH}";
my @options = {
    uni_scanlevel      => 2,
    uni_unicode        => 1,
    AutoCommit         => 0,
    PrintError         => 0,
    RaiseError         => 1,
    ShowErrorStatement => 0
    };
my $dbh = DBI->connect ($dsn, undef, undef, @options);
for my $table ("a1", "a2") {
    my $sth = $dbh->column_info (undef, undef, $table, undef);
    my $column_info = $sth->fetchall_hashref ("COLUMN_NAME");
    print "$table.$_\n" for sort keys %$column_info;
    }
$dbh->disconnect;
