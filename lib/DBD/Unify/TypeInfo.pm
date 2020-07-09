package DBD::Unify::TypeInfo;

# The %type_info_all hash was automatically generated by
# DBI::DBD::Metadata::write_typeinfo_pm v2.008696.
# And manually reformatted into readable style

our $VERSION = "0.91";

use strict;
use warnings;

require Exporter;
require DynaLoader;

use vars  qw(@ISA @EXPORT $type_info_all);
@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw($type_info_all);
use DBI   qw(:sql_types);

$type_info_all = [
    {	TYPE_NAME          =>  0,
	DATA_TYPE          =>  1,
	COLUMN_SIZE        =>  2,
	LITERAL_PREFIX     =>  3,
	LITERAL_SUFFIX     =>  4,
	CREATE_PARAMS      =>  5,
	NULLABLE           =>  6,
	CASE_SENSITIVE     =>  7,
	SEARCHABLE         =>  8,
	UNSIGNED_ATTRIBUTE =>  9,
	FIXED_PREC_SCALE   => 10,
	AUTO_UNIQUE_VALUE  => 11,
	LOCAL_TYPE_NAME    => 12,
	MINIMUM_SCALE      => 13,
	MAXIMUM_SCALE      => 14,
	SQL_DATA_TYPE      => 15,
	SQL_DATETIME_SUB   => 16,
	NUM_PREC_RADIX     => 17,
	INTERVAL_PRECISION => 18,
	},

#     TYPE_NAME           DATA_TYPE        SIZE  PFX   SFX   PARAMS            N C S UNSIG FPS   AUTO  LOCAL MINSC MAXSC SDT   SDS   RADIX PREC
    [ "UNKNOWN",          0,               undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
#   [ "GIANT AMOUNT",                      undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "HUGE AMOUNT",      -207,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "AMOUNT",           -206,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "VARBINARY",        SQL_VARBINARY,   undef,"'", ,"'",  undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "BINARY",           SQL_BINARY,      undef,undef,undef,undef,            1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "CHAR",             SQL_CHAR,        undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "CURRENCY",         -218,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    2,    undef,undef,0,    8,    undef,undef,undef,undef, ],
    [ "TIMESTAMP",        SQL_TIMESTAMP,   undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "DATE",             SQL_DATE,        undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "DECIMAL",          SQL_DECIMAL,     undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "DOUBLE PRECISION", SQL_DOUBLE,      undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "FLOAT",            SQL_FLOAT,       undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "HUGE INTEGER",     SQL_BIGINT,      undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    0,    undef,undef,undef,undef, ],
    [ "INTEGER",          SQL_INTEGER,     undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "NUMERIC",          SQL_NUMERIC,     undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    0,    undef,undef,undef,undef, ],
    [ "REAL",             SQL_REAL,        undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "SMALLINT",         SQL_SMALLINT,    undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    0,    undef,undef,undef,undef, ],
    [ "TEXT",             SQL_LONGVARCHAR, undef,"'", ,"'",  undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "TIME",             SQL_TIME,        undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "TIMESTAMP",        SQL_TIMESTAMP,   undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    ];
# Copy DATA_TYPE to SQL_DATA_TYPE
$type_info_all->[$_][15] = $type_info_all->[$_][1] for 1 .. $#$type_info_all;

my %odbc_types = map { ( $_->[0] => $_->[1], $_->[1] => $_->[0] ) }
    [  -5  => "BIGINT"		], # SQL_BIGINT
    [  -3  => "VARBINARY"	], # SQL_VARBINARY
    [  -2  => "BINARY"		], # SQL_BINARY
    [  -1  => "TEXT"		], # SQL_LONGVARCHAR
    [   0  => "UNKNOWN_TYPE"	], # SQL_UNKNOWN_TYPE
    [   1  => "CHAR"		], # SQL_CHAR
    [   2  => "NUMERIC"		], # SQL_NUMERIC
    [   3  => "DECIMAL"		], # SQL_DECIMAL
    [   4  => "INTEGER"		], # SQL_INTEGER
    [   5  => "SMALLINT"	], # SQL_SMALLINT
    [   6  => "FLOAT"		], # SQL_FLOAT
    [   7  => "REAL"		], # SQL_REAL
    [   8  => "DOUBLE PRECISION"], # SQL_DOUBLE
    [   9  => "DATE"		], # SQL_DATE
    [  10  => "TIME"		], # SQL_TIME
    [  11  => "TIMESTAMP"	], # SQL_TIMESTAMP
    [  12  => "VARCHAR"		], # SQL_VARCHAR
    [  16  => "BOOLEAN"		], # SQL_BOOLEAN
    [  19  => "ROW"		], # SQL_ROW
    [  20  => "REF"		], # SQL_REF
    [  30  => "BLOB"		], # SQL_BLOB
    [  40  => "CLOB"		], # SQL_CLOB
    ;
$odbc_types{DOUBLE}  = $odbc_types{"DOUBLE PRECISION"};

# see include/sqle_usr.h
my %uni_types = map { ( $_->[0] => $_->[1], $_->[1] => $_->[0] ) }
    [ -19  => "DATETIME"	], # SQLDATETIME
    [ -18  => "CURRENCY"	], # SQLAMT64
    [ -17  => "HUGE INTEGER"	], # SQLINT64
    [ -12  => "BYTE"		], # SQLBYTE
    [ -11  => "HUGE DATE"	], # SQLHDATE
    [ -10  => "BINARY"		], # SQLBINARY
    [  -9  => "TEXT"		], # SQLTEXT
    [  -7  => "TIME"		], # SQLSMTIME
    [  -6  => "HUGE AMOUNT"	], # SQLHUGEAMT
    [  -4  => "AMOUNT"		], # SQLAMOUNT
    [  -3  => "DATE"		], # SQLDATE
    [   0  => "NOTYPE"		], # SQLNOTYPE
    [   1  => "CHAR"		], # SQLCHAR
    [   2  => "NUMERIC"		], # SQLNUMERIC
    [   3  => "DECIMAL"		], # SQLDECIMAL
    [   4  => "INTEGER"		], # SQLINTEGER
    [   5  => "SMALLINT"	], # SQLSMINT
    [   6  => "FLOAT"		], # SQLFLOAT
    [   7  => "REAL"		], # SQLREAL
    [   8  => "DOUBLE PRECISION"], # SQLDBLPREC
    ;
$uni_types{CHARACTER} = $uni_types{CHAR};
$uni_types{DOUBLE}    = $uni_types{"DOUBLE PRECISION"};

# see include/rhli.h
my %hli_types = map { ( $_->[0] => $_->[1], $_->[1] => $_->[0] ) }
    [   1  => "INTEGER"		], # U_INT	"small" numerics
    [   2  => "NUMERIC"		], # U_HINT	"huge" numerics
    [   3  => "DATE"		], # U_DATE	"small" dates
    [   4  => "AMOUNT"		], # U_AMT	"small" amounts
    [   5  => "CHAR"		], # U_STR	strings (terminated)
    [   6  => "HUGE AMOUNT"	], # U_HAMT	"huge" amounts
    [   7  => "TIME"		], # U_TIME	times
    [   8  => "FLOAT"		], # U_FLT	floating numerics
    [   9  => "TEXT"		], # U_VTXT	variable length text
    [  10  => "BINARY"		], # U_VBIN	variable length binary
    [  11  => "HUGE DATE"	], # U_HDATE	"huge" (long) dates
    [  12  => "BYTE"		], # U_BYT	byte strings (non-terminated)
    [  13  => "BOOL"		], # U_BOOL	boolean type
    [  14  => "REAL"		], # U_REAL	real type
    [  15  => "DOUBLE"		], # U_DBL	double type
    [  16  => "DECIMAL"		], # U_DEC	packed decimal type
    [  17  => "GIANT NUMERIC"	], # U_GINT	"giant" numerics
    [  18  => "GIANT AMOUNT"	], # U_GAMT	"giant" amounts
    [  19  => "DATETIME"	], # U_DATETIME	date and time
#   [ 100  => "COL_GROUP"	], # U_CGP	column group type
    ;
$hli_types{CHARACTER}          = $hli_types{CHAR};
$hli_types{"DOUBLE PRECISION"} = $hli_types{DOUBLE};

sub odbc_type {
    my $t = shift;
    defined $t or return 0;
    $t = $odbc_types{uc $t} || $t;
    return $t;
    } # uni_type

sub uni_type {
    my $t = shift;
    defined $t or return 0;
    $t = $uni_types{uc $t} || $t;
    return $t;
    } # uni_type

sub hli_type {
    my $t = shift;
    defined $t or return 0;
    $t = $hli_types{uc $t} || $t;
    return $t;
    } # hli_type

1;

__END__
Interactive SQL/A supports the following column data types:

    - [HUGE] AMOUNT [(integer[,2])]
    - BINARY
    - BYTE [integer]
    - CHAR[ACTER] [(integer)]
    - CURRENCY [(integer[,integer])]
    - [HUGE] DATE
    - DATETIME
    - DEC[IMAL] [(integer)]
    - DOUBLE PRECISION
    - FLOAT
    - HUGE INTEGER
    - INT[EGER]
    - NUMERIC [(integer)]
    - REAL
    - SMALLINT
    - TEXT
    - TIME

#   define SQLNOTYPE	((SQLCOLTYPE)0)
#   define SQLCHAR	((SQLCOLTYPE)1)
#   define SQLNUMERIC	((SQLCOLTYPE)2)
#   define SQLDECIMAL	((SQLCOLTYPE)3)
#   define SQLINTEGER	((SQLCOLTYPE)4)
#   define SQLSMINT	((SQLCOLTYPE)5)
#   define SQLFLOAT	((SQLCOLTYPE)6)
#   define SQLREAL	((SQLCOLTYPE)7)
#   define SQLDBLPREC	((SQLCOLTYPE)8)
#   define SQLDATE	((SQLCOLTYPE)(-(U_DATE)))
#   define SQLAMOUNT	((SQLCOLTYPE)(-(U_AMT)))
#   define SQLHUGEAMT	((SQLCOLTYPE)(-(U_HAMT)))
#   define SQLSMTIME	((SQLCOLTYPE)(-(U_TIME)))
#   define SQLTEXT	((SQLCOLTYPE)(-(U_VTXT)))
#   define SQLBINARY	((SQLCOLTYPE)(-(U_VBIN)))
#   define SQLHDATE	((SQLCOLTYPE)(-(U_HDATE)))
#   define SQLBYTE	((SQLCOLTYPE)(-(U_BYT)))
#   define SQLINT64	((SQLCOLTYPE)(-(U_GINT)))
#   define SQLAMT64	((SQLCOLTYPE)(-(U_GAMT)))
#   define SQLDATETIME	((SQLCOLTYPE)(-(U_DATETIME)))

