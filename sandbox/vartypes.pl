#!/pro/bin/perl

use strict;
use warnings;

use PROCURA::DBD;
use Data::Peek;
my $dbh = DBDlogon (1, { RaiseError => 0, PrintError => 1, AutoCommit => 1 });

eval {
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 0;
    $dbh->do ("drop table xbb");
    };

my %DATA;
my $dbt;
while (<DATA>) {
    m/^(?:#|\s*$)/ and next;
    chomp;
    m/^\[(\w+)\]/ and $dbt = $1, next;
    push @{$DATA{$dbt}}, $_;
    }
$dbt = (DB_Type ())[1];
print "$dbt\n";
my @DATA = @{$DATA{$dbt}};

print <<EOH;
  Create as               sth attributes                   column_info ()                       uni_type/uni_type_name
  ----------------------- -------------------------------  -----------------------------------  -------------------------
EOH

for (@DATA) {
    my $sql = "create table xbb (xbb $_)";
    $dbh->do ($sql) or next;
    #$dbh->commit;

    my $info = (describe ("xbb"))[0];
    my $s = join "," => grep { $info->{$_} } qw( PRECISION SCALE );
    $s = $s ? qq{"$s"} : "undef";
    my $ti = $dbh->type_info ($info->{TYPE}) // {};

    my $hr = $dbh->column_info (undef, undef, "xbb", "xbb")->fetchrow_hashref;
    if ($hr) {
	#$a++ or DDumper $hr;
	$hr->{lc $_} = $hr->{$_} for grep m/[A-Z]/ => keys %$hr;
	}
    my $tp = sprintf "%5s %s", $hr->{uni_type} // "-", $hr->{uni_type_name} // "?";
    if ($hr && $hr->{column_size}) {
	$tp .= " ($hr->{column_size}";
	$hr->{decimal_digits} and $tp .= ", $hr->{decimal_digits}";
	$tp .= ")";
	}
    printf "  %-22s  %-20s %5s %4s  %-29s %5s  %s\n",
	$_,
	$ti->{TYPE_NAME}//"?", $info->{TYPE},$info->{uni_types},
	($hr ? ($hr->{type_name} // "?", $hr->{data_type} // "") : ("-", "")),
	$tp;

    $dbh->do ("drop table xbb");
    #$dbh->commit;
    }
__END__

[Unify]
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

[PostgreSQL]
bigint
bigserial
bit
bit (9)
bit varying
bit varying (35)
bool
boolean
box
bytea
character
character (5)
character varying
character varying (21)
cidr
circle
date
decimal
decimal (15, 2)
decimal (8)
double precision
float4
float8
inet
int
int2
int4
int8
integer
interval
interval (3)
line
lseg
macaddr
money
numeric
numeric (15, 2)
numeric (8)
path
point
polygon
real
serial
serial4
smallint
text
time
time (3)
timestamp
timestamp (3)
timestamptz
timestamptz (3)
timetz
timetz (3)
tsquery
tsvector
txid_snapshot
uuid
varchar
varchar (21)
xml

[Oracle]
bfile
blob
char
char (19)
clob
date
float
float (12)
integer
interval day to second
interval day (3) to second (2)
long
long raw
mlslabel
nchar
nchar (13)
nclob
number
number (8)
number (15, 2)
number (9, -2)
nvarchar2 (3)
raw (58)
rowid
timestamp
timestamp (3)
urowid
varchar (46)
varchar2 (46)
xmltype
