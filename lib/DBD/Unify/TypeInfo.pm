package DBD::Unify::TypeInfo;

# The %type_info_all hash was automatically generated by
# DBI::DBD::Metadata::write_typeinfo_pm v2.008696.
# And manually reformatted into readable style

our $VERSION = 0.10;

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
#   [ "GIANT AMOUNT",                      undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "HUGE AMOUNT",      -207,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "AMOUNT",           -206,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    undef,undef,undef,2,    2,    undef,undef,undef,undef, ],
    [ "BINARY",           SQL_VARBINARY,   undef,"'", ,"'",  undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
    [ "BYTE",             SQL_BINARY,      undef,undef,undef,undef,            1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "CHAR",             SQL_CHAR,        undef,undef,undef,"PRECISION",      1,0,3,0,    undef,undef,undef,0,    undef,undef,undef,undef,undef, ],
    [ "CURRENCY",         -218,            undef,undef,undef,"PRECISION,SCALE",1,0,3,0,    2,    undef,undef,0,    8,    undef,undef,undef,undef, ],
    [ "HUGE DATE",        SQL_TIMESTAMP,   undef,undef,undef,undef,            1,0,3,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef, ],
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
    ];

my %_data_type = map {
    $type_info_all->[$_][0] => $type_info_all->[$_][1];
    } 1 .. $#$type_info_all;
$_data_type{CHARACTER} = $_data_type{CHAR};

sub type_name2data_type
{
    my $type = shift or return undef;
    return $_data_type{uc $type} || undef;
    } # data_type_code

1;

__END__
Interactive SQL/A supports the following column data types:

    - [HUGE] AMOUNT [(integer[,2])]
    - BINARY
    - BYTE [integer]
    - CHAR[ACTER] [(integer)]
    - CURRENCY [(integer[,integer])]
    - [HUGE] DATE
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

