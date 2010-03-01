#!/pro/bin/perl

use strict;
use warnings;

use PROCURA::DBD;
use Data::Peek;
my $dbh = DBDlogon (1, { RaiseError => 0, PrintError => 1 });

eval {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 0;
    $dbh->do ("drop table xbb");
    };

chomp (my @DATA = <DATA>);

for (@DATA) {
    my $sql = "create table xbb (xbb $_)";
    print "$sql\n";
    $dbh->do ($sql) or next;
    $dbh->commit;

    my $info = (describe ("xbb"))[0];
    my $s = join "," => grep { $info->{$_} } qw( PRECISION SCALE );
    $s = $s ? qq{"$s"} : "undef";
    my $ti = $dbh->type_info ($info->{TYPE}) // {};
    printf "\t%-20s %-20s %-20s\n", $ti->{TYPE_NAME}//"?", $info->{TYPE}, $s;

    my $hr = $dbh->column_info (undef, undef, "xbb", "xbb")->fetchrow_hashref;
    $hr and printf "\t%-20s %-20s\n", $hr->{type_name}, $hr->{data_type};

    $dbh->do ("drop table xbb");
    $dbh->commit;
    }

for (@DATA) {
    my $sql = "create table xbb (xbb $_)";
    $dbh->do ($sql) or next;
    $dbh->commit;

    my $info = (describe ("xbb"))[0];
    my $s = join "," => grep { $info->{$_} } qw( PRECISION SCALE );
    $s = $s ? qq{"$s"} : "undef";
    my $ti = $dbh->type_info ($info->{TYPE}) // {};

    my $hr = $dbh->column_info (undef, undef, "xbb", "xbb")->fetchrow_hashref;
    printf "  %-19s  %-16s %2s  %-16s %4s\n",
	$_,
	$ti->{TYPE_NAME}//"?", $info->{TYPE},
	$hr ? ($hr->{type_name}, $hr->{data_type}) : ("-", "");

    $dbh->do ("drop table xbb");
    $dbh->commit;
    }
__END__
amount
amount (5, 2)
huge amount
huge amount (5, 2)
huge amount (15, 2)
byte
byte (512)
char
char (12)
currency
currency (9)
currency (7,2)
date
huge date
decimal
decimal (2)
decimal (8)
double precision
float
huge integer
integer
numeric
numeric (2)
numeric (6)
real
smallint
text
time
