# NAME

DBD::Unify - DBI driver for Unify database systems

# SYNOPSIS

    # Examples marked NYT are Not Yet Tested, they might work
    #  all others have been tested.
    # man DBI for explanation of each method (there's more than listed here)

    $dbh = DBI->connect ("DBI:Unify:[\$dbname]", "", $schema, {
                            AutoCommit    => 0,
                            ChopBlanks    => 1,
                            uni_unicode   => 0,
                            uni_verbose   => 0,
                            uni_scanlevel => 2,
                            });
    $dbh = DBI->connect_cached (...);                   # NYT
    $dbh->do ($statement);
    $dbh->do ($statement, \%attr);
    $dbh->do ($statement, \%attr, @bind);
    $dbh->commit;
    $dbh->rollback;
    $dbh->disconnect;

    $all = $dbh->selectall_arrayref ($statement);
    @row = $dbh->selectrow_array ($statement);
    $col = $dbh->selectcol_arrayref ($statement);

    $sth = $dbh->prepare ($statement);
    $sth = $dbh->prepare ($statement, \%attr);
    $sth = $dbh->prepare_cached ($statement);           # NYT
    $sth->execute;
    @row = $sth->fetchrow_array;
    $row = $sth->fetchrow_arrayref;
    $row = $sth->fetchrow_hashref;
    $all = $sth->fetchall_arrayref;
    $sth->finish;

    # Statement has placeholders like where field = ?
    $sth = $dbh->prepare ($statement);
    $sth->bind_param ($p_num, $bind_value);             # NYT
    $sth->bind_param ($p_num, $bind_value, $bind_type); # NYT
    $sth->bind_param ($p_num, $bind_value, \%attr);     # NYT
    $sth->bind_col ($col_num, \$col_variable);          # NYT
    $sth->bind_columns (@list_of_refs_to_vars_to_bind);
    $sth->execute (@bind_values);

    $cnt = $sth->rows;

    $sql = $dbh->quote ($string);

    $err = $dbh->err;
    $err = $sth->err;
    $str = $dbh->errstr;
    $str = $sth->errstr;
    $stt = $dbh->state;
    $stt = $sth->state;

    For large DB fetches the combination $sth->bind_columns ()
    with $sth->fetchrow_arrayref is the fastest (DBI
    documentation).

# DESCRIPTION

DBD::Unify is an extension to Perl which allows access to Unify
databases. It is built on top of the standard DBI extension and
implements the methods that DBI requires.

This document describes the differences between the "generic" DBD
and DBD::Unify.

## Extensions/Changes

- returned types

    The DBI docs state that:

        Most data is returned to the perl script as strings (null values
        are returned as undef).  This allows arbitrary precision numeric
        data to be handled without loss of accuracy.  Be aware that perl
        may  not preserve the same accuracy when the string is used as a
        number.

    Integers are returned as integer values (perl's IV's).

    (Huge) amounts, floats, reals and doubles are returned as strings for which
    numeric context (perl's NV's) has been invoked already, so adding zero to
    force convert to numeric context is not needed.

    Chars are returned as strings (perl's PV's).

    Chars, Dates, Huge Dates and Times are returned as strings (perl's PV's).
    Unify represents midnight with 00:00, not 24:00.

- connect

        connect ("DBI:Unify:dbname[;options]" [, user [, auth [, attr]]]);

    Options to the connection are passed in the data-source
    argument. This argument should contain the database
    name possibly followed by a semicolon and the database options
    which are ignored.

    Since Unify database authorization is done using grant's using the
    user name, the _user_ argument may be empty or undef. The _auth_
    field will be used as a default schema. If the _auth_ field is empty
    or undefined connect will check for the environment variable $USCHEMA
    to use as a default schema. If neither exists, you will end up in your
    default schema, or if none is assigned, in the schema PUBLIC.

    At the moment none of the attributes documented in DBI's "ATTRIBUTES
    COMMON TO ALL HANDLES" are implemented specifically for the Unify
    DBD driver, but they might have been inherited from DBI. The _ChopBlanks_
    attribute is implemented, but defaults to 1 for DBD::Unify.
    The Unify driver supports "uni\_scanlevel" to set the transaction scan
    level to a value between 1 and 16 and "uni\_verbose" to set DBD specific
    debugging, allowing to show only massages from DBD-Unify without using
    the default DBI->trace () call.

    The connect call will result in statements like:

        CONNECT;
        SET CURRENT SCHEMA TO PUBLIC;  -- if auth = "PUBLIC"
        SET TRANSACTION SCAN LEVEL 7;  -- if attr has { uni_scanlevel => 7 }

    local database

        connect ("/data/db/unify/v63AB", "", "SYS")

- AutoCommit

    It is recommended that the `connect` call ends with the attributes
    { AutoCommit = 0 }>, although it is not implemented (yet).

    If you don't want to check for errors after **every** call use
    { AutoCommit = 0, RaiseError => 1 }> instead. This will `die` with
    an error message if any DBI call fails.

- Unicode

    By default, this driver is completely Unicode unaware: what you put into
    the database will be returned to you without the encoding applied.

    To enable automatic decoding of UTF-8 when fetching from the database,
    set the `uni_unicode` attribute to a true value for the database handle
    (statement handles will inherit) or to the statement handle.

        $dbh->{uni_unicode} = 1;

    When CHAR or TEXT fields are retrieved and the content fetched is valid
    UTF-8, the value will be marked as such.

- re-connect

    Though both the syntax and the module support connecting to different
    databases, even at the same time, the Unify libraries seem to quit
    connecting to a new database, even if the old one is closed following
    every rule of precaution.

    To be safe in closing a handle of all sorts, undef it after it is done with,
    it will than be destroyed. (As of 0.12 this is tried internally for handles
    that proved to be finished)

    explicit:

        my $dbh = DBI->connect (...);
        my $sth = $dbh->prepare (...);
        :
        $sth->finish;     undef $sth;
        $dbh->disconnect; undef $dbh;

    or implicit:

        {   my $dbh = DBI->connect (...);
            {   my $sth = $dbh->prepare (...);
                while (my @data = $sth->fetchrow_array) {
                    :
                    }
                }  # $sth implicitly destroyed by end-of-scope
            $dbh->disconnect;
            }  # $dbh implicitly destroyed by end-of-scope

- do

        $dbh->do ($statement)

    This is implemented as a call to 'EXECUTE IMMEDIATE' with all the
    limitations that this implies.

- commit and rollback invalidates open cursors

    DBD::Unify does warn when a commit or rollback is issued on a $dbh
    with open cursors.

    Possibly a commit/rollback/disconnect should also undef the $sth's.
    (This should probably be done in the DBI-layer as other drivers will
    have the same problems).

    After a commit or rollback the cursors are all ->finish'ed, i.e. they
    are closed and the DBI/DBD will warn if an attempt is made to fetch
    from them.

    A future version of DBD::Unify might re-prepare the statement.

## Stuff implemented in perl

- driver

    Just here for DBI. No use in telling the end-user what to do with it :)

- connect
- data\_sources

    There is no way for Unify to tell what data sources might be available.
    There is no central files (like `/etc/oratab` for Oracle) that lists all
    available sources, so this method will always return an empty list.

- quote\_identifier

    As DBI's `quote_identifier ()` gladly accepts the empty string as a
    valid identifier, I have to override this method to translate empty
    strings to undef, so the method behaves properly. Unify does not allow
    to select `NULL` as a constant as in:

        select NULL, foo from bar;

- prepare ($statement \[, \\%attr\])

    The only attribute currently supported is the `dbd_verbose` (or its
    alias `uni_verbose`) level. See "trace" below.

- table\_info ($;$$$$)
- columne\_info ($$$$)
- foreign\_key\_info ($$$$$$;$)
- link\_info ($;$$$$)
- primary\_key ($$$)
- uni\_clear\_cache ()

    Note that these five get their info by accessing the `SYS` schema which
    is relatively extremely slow. e.g. Getting all the primary keys might well
    run into seconds, rather than milliseconds.

    This is work-in-progress, and we hope to find faster ways to get to this
    information. Also note that in order to keep it fast across multiple calls,
    some information is cached, so when you alter the data dictionary after a
    call to one of these, that cached information is not updated.

    For `column_info ()`, the returned `DATA_TYPE` is deduced from the
    `TYPE_NAME` returned from `SYS.ACCESSIBLE_COLUMNS`. The type is in
    the ODBC range and the original Unify type and type\_name are returned
    in the additional fields `uni_type` and `uni_type_name`. Somehow
    selecting from that table does not return valid statement handles for
    types `currency` and `huge integer`.

        Create as           sth attributes       uni_type/uni_type_name
        ------------------- -------------------  -------------------------
        amount              FLOAT             6   -4 AMOUNT (9, 2)
        amount (5, 2)       FLOAT             6   -4 AMOUNT (5, 2)
        huge amount         REAL              7   -6 HUGE AMOUNT (15, 2)
        huge amount (5, 2)  REAL              7   -6 HUGE AMOUNT (5, 2)
        huge amount (15, 2) REAL              7   -6 HUGE AMOUNT (15, 2)
        byte                BINARY           -2  -12 BYTE (1)
        byte (512)          BINARY           -2  -12 BYTE (512)
        char                CHAR              1    1 CHAR (1)
        char (12)           CHAR              1    1 CHAR (12)
        currency            DECIMAL           3    - ?
        currency (9)        DECIMAL           3    - ?
        currency (7,2)      DECIMAL           3    - ?
        date                DATE              9   -3 DATE
        huge date           TIMESTAMP        11  -11 HUGE DATE
        decimal             NUMERIC           2    2 NUMERIC (9)
        decimal (2)         NUMERIC           2    2 NUMERIC (2)
        decimal (8)         NUMERIC           2    2 NUMERIC (8)
        double precision    DOUBLE PRECISION  8    8 DOUBLE PRECISION (64)
        float               DOUBLE PRECISION  8    6 FLOAT (64)
        huge integer        HUGE INTEGER     -5    - ?
        integer             NUMERIC           2    2 NUMERIC (9)
        numeric             NUMERIC           2    2 NUMERIC (9)
        numeric (2)         SMALLINT          5    2 NUMERIC (2)
        numeric (6)         NUMERIC           2    2 NUMERIC (6)
        real                REAL              7    7 REAL (32)
        smallint            SMALLINT          5    2 NUMERIC (4)
        text                TEXT             -1   -9 TEXT
        time                TIME             10   -7 TIME

    Currently the driver tries to cache information about the schema as it
    is required. When there are fields added, removed, or altered, references
    are added or removed or primary keys or unique hashes are added or removed
    it is wise to call `$dbh->uni_clear_cache` to ensure that the info
    on next inquiries will be up to date.

- ping

## Stuff implemented in C (XS)

- trace

    The `DBI->trace (level)` call will promote the level to DBD::Unify,
    showing both the DBI layer debugging messages as well as the DBD::Unify
    specific driver-side debug messages.

    It is however also possible to trace **only** the DBD-Unify without the
    `DBI->trace ()` call by using the `uni_verbose` attribute on `connect ()`
    or by setting it later to the database handle, the default level is set from
    the environment variable `$DBD_TRACE` if defined:

        $dbh = DBI->connect ("DBI::Unify", "", "", { uni_verbose => 3 });
        $dbh->{uni_verbose} = 3;

    As DBD::Oracle also supports this scheme since version 1.22, `dbd_verbose`
    is a portable alias for `uni_verbose`, which is also supported in DBD::Oracle.

    DBD::Unify now also allows an even finer grained debugging, by allowing
    `dbd_verbose` on statement handles too. The default `dbd_verbose` for
    statement handles is the global `dbd_verbose` at creation time of the
    statement handle.

    The environment variable `DBD_VERBOSE` is used if defined and overrules
    `$DBD_TRACE`.

        $dbh->{dbd_verbose} = 4;
        $sth = $dbh->prepare ("select * from foo");  # sth's dbd_verbose = 4
        $dbh->{dbd_verbose} = 3;                     # sth's dbd_verbose = 4
        $sth->{dbd_verbose} = 5;                     # now 5

    Currently, the following levels are defined:

    - 1 & 2

        No DBD messages implemented at level 1 and 2, as they are reserved for DBI

    - 3

            DBD::Unify::dbd_db_STORE (ScanLevel = 7)
            DBD::Unify::st_prepare u_sql_00_000000 ("select * from foo")
            DBD::Unify::st_prepare u_sql_00_000000 (<= 4, => 0)
            DBD::Unify::st_execute u_sql_00_000000
            DBD::Unify::st_destroy 'select * from parm'
            DBD::Unify::st_free u_sql_00_000000
            DBD::Unify::st 0x7F7F25CC 0x0000 0x0000 0x00000000 0x00000000 0x00000000
            DBD::Unify::st destroyed
            DBD::Unify::db_disconnect
            DBD::Unify::db_destroy

    - 4

        Level 3 plus errors and additional return codes and field types and values:

            DBD::Unify::st_prepare u_sql_00_000000 ("select c_bar from foo where c_foo = 1")
                After allocate, sqlcode = 0
                After prepare,  sqlcode = 0
                After allocate, sqlcode = 0
                After describe, sqlcode = 0
                After count,    sqlcode = 0, count = 1
            DBD::Unify::fld_describe o_sql_00_000000 (1 fields)
                After get,      sqlcode = 0
            DBD::Unify::st_prepare u_sql_00_000000 (<= 1, => 0)
            DBD::Unify::st_execute u_sql_00_000000
                After open,     sqlcode = 0 (=> 0)
            DBD::Unify::st_fetch u_sql_00_000000
                Fetched         sqlcode = 0, fields = 1
                After get,      sqlcode = 0
                 Field   1: c_bar: NUMERIC  4: (6030) 6030 ==
                 Fetch done
            DBD::Unify::st_finish u_sql_00_000000
                After close,    sqlcode = 0
            DBD::Unify::st_destroy 'select c_bar from foo where c_foo = 1'
            DBD::Unify::st_free u_sql_00_000000
                After deallocO, sqlcode = 0
                After deallocU, sqlcode = 0

    - 5

        Level 4 plus some content info:

            DBD::Unify::st_fetch u_sql_00_000000
                Fetched         sqlcode = 0, fields = 1
                After get,      sqlcode = 0
                 Field   1: [05 00 04 00 00] c_bar: NUMERIC  4: (6030) 6030 ==
                 Fetch done

    - 6

        Level 5 plus internal coding for exchanges and low(er) level return codes:

            DBD::Unify::fld_describe o_sql_00_000000 (1 fields)
                After get,      sqlcode = 0
                 Field   1: [05 00 04 00 FFFFFFFF] c_bar
            DBD::Unify::st_prepare u_sql_00_000000 (<= 1, => 0)

    - 7

        Level 6 plus destroy/cleanup states:

            DBD::Unify::st_free u_sql_00_000000
             destroy allocc destroy alloco    After deallocO, sqlcode = 0
             destroy alloci destroy allocp    After deallocU, sqlcode = 0
             destroy stat destroy growup destroy impset

    - 8

        No messages (yet) set to level 8 and up.

- int  dbd\_bind\_ph (SV \*sth, imp\_sth\_t \*imp\_sth, SV \*param, SV \*value, IV sql\_type, SV \*attribs, int is\_inout, IV maxlen)
- SV  \*dbd\_db\_FETCH\_attrib (SV \*dbh, imp\_dbh\_t \*imp\_dbh, SV \*keysv)
- int  dbd\_db\_STORE\_attrib (SV \*dbh, imp\_dbh\_t \*imp\_dbh, SV \*keysv, SV \*valuesv)
- int  dbd\_db\_commit (SV \*dbh, imp\_dbh\_t \*imp\_dbh)
- void dbd\_db\_destroy (SV \*dbh, imp\_dbh\_t \*imp\_dbh)
- int  dbd\_db\_disconnect (SV \*dbh, imp\_dbh\_t \*imp\_dbh)
- int  dbd\_db\_do (SV \*dbh, char \*statement)
- int  dbd\_db\_login (SV \*dbh, imp\_dbh\_t \*imp\_dbh, char \*dbname, char \*user, char \*pwd)
- int  dbd\_db\_rollback (SV \*dbh, imp\_dbh\_t \*imp\_dbh)
- int  dbd\_discon\_all (SV \*drh, imp\_drh\_t \*imp\_drh)
- int  dbd\_fld\_describe (SV \*dbh, imp\_sth\_t \*imp\_sth, int num\_fields)
- void dbd\_init (dbistate\_t \*dbistate)
- int  dbd\_prm\_describe (SV \*dbh, imp\_sth\_t \*imp\_sth, int num\_params)
- SV  \*dbd\_st\_FETCH\_attrib (SV \*sth, imp\_sth\_t \*imp\_sth, SV \*keysv)
- int  dbd\_st\_STORE\_attrib (SV \*sth, imp\_sth\_t \*imp\_sth, SV \*keysv, SV \*valuesv)
- int  dbd\_st\_blob\_read (SV \*sth, imp\_sth\_t \*imp\_sth, int field, long offset, long len, SV \*destrv, long destoffset)
- void dbd\_st\_destroy (SV \*sth, imp\_sth\_t \*imp\_sth)
- int  dbd\_st\_execute (SV \*sth, imp\_sth\_t \*imp\_sth)
- AV  \*dbd\_st\_fetch (SV \*sth, imp\_sth\_t \*imp\_sth)
- int  dbd\_st\_finish (SV \*sth, imp\_sth\_t \*imp\_sth)
- int  dbd\_st\_prepare (SV \*sth, imp\_sth\_t \*imp\_sth, char \*statement, SV \*attribs)
- int  dbd\_st\_rows (SV \*sth, imp\_sth\_t \*imp\_sth)

## DBD specific functions

### db\_dict

Query the data dictionary through HLI calls:

    my $dd = $dbh->func (   "db_dict");
    my $dd = $dbh->func (0, "db_dict"); # same
    my $dd = $dbh->func (1, "db_dict"); # force reload

This function returns the data dictionary of the database in a hashref. The
dictionary contains all information accessible to the current user and will
likely contain all accessible schema's, tables, columns, and simple links
(referential integrity).

The force\_reload argument is useful if the data dictionary might have changed:
adding/removing tables/links/primary keys, altering tables etc.

The dictionary will have 4 entries

- TYPE


        my $types = $dd->{TYPE};

    This holds a list with the native type descriptions of the `TYPE` entries
    in the `COLUMN` hashes.

        say $dd->{TYPE}[3]; # DATE

- AUTH


        my $schemas = $dd->{AUTH};

    This will return a reference to a list of accessible schema's. The schema's
    that are not accessible or do not exist (anymore) have an `undef` entry.

    Each auth entry is `undef` or a hashref with these entries:

    - AID


        Holds the AUTH ID of the schema (INTEGER). In the current implementation,
        the `AID` entry is identical to the index in the list

            say $schemas->[3]{AID};
            # 3

    - NAME


        Holds the name of the schema (STRING)

            say $schemas->[3]{NAME};
            # DBUTIL

    - TABLES


        Holds the list of accessible table ID's in this schema (ARRAY of INTEGER's)

            say join ", " => $schemas->[3]{TABLES};
            # 43, 45, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 61

- TABLE


        my $tables = $dd->{TABLE};

    This will return a reference to a list of accessible tables. The tables
    that are not accessible or do not exist (anymore) have an `undef` entry.

    Each table entry is `undef` or a hashref with these entries:

    - AID


        Holds the AUTH ID (INTEGER) of the schema this table belongs to.

            say $tables->[43]{AID};
            # 3

    - ANAME


        Holds the name of the schema this table belongs too.

            say $tables->[43]{NAME};
            # UTLATH

    - TID


        Holds the TABLE ID of the table (INTEGER). In the current implementation,
        the `TID` entry is identical to the index in the list

            say $tables->[43]{TID};
            # 43

    - NAME


        Holds the name of the table

            say $tables->[43]{NAME};
            # UTLATH

    - KEY


        Holds a list of column indices (`CID`'s) of the columns that are the
        primary key of this table. The list can be empty if the table has no
        primary key.

            say for @{$tables->[43]{KEY}};
            # 186

    - CGRP


        Holds a list of column groups for this table (if any).

            my $cgrp = $dd->{TABLE}[59];

        Each entry in the list holds a has with the following entries

        - CID


            Holds the column ID of this column group

                say $cgrp->[0]{CID}
                # 260

        - TYPE


            Holds the type of this group. This will always be `100`.

                say $cgrp->[0]{TYPE}
                # 100

        - COLUMNS


            Holds the list of `CID`s this group consists of

                say for @{$cgrp->[0]{COLUMNS}}
                # 255
                # 256

    - DIRECTKEY


        Holds a true/false indication of the table being `DIRECT-KEYED`.

            say $tables->[43]{DIRECTKEY}
            # 1

    - FIXEDSIZE


        Holds a true/false indication of the table being of fixed size.
        See also [EXPNUM](https://metacpan.org/pod/EXPNUM)

    - EXPNUM


        If [FIXEDNUM](https://metacpan.org/pod/FIXEDNUM) is true, this entry holds the number of records of the table

    - OPTIONS

    - PKEYED


        Holds a true/false indication of the table being primary keyed

    - SCATTERED


        Holds a true/false indication if the table has data scattered across volumes

    - COLUMNS


        Holds a list of column indices (`CID`'s) of the columns of this table.

            say for @{$tables->[43]{COLUMNS}};
            # 186
            # 187
            # 188

- COLUMN


        my $columns = $dd->{COLUMN};

    This will return a reference to a list of accessible columns. The columns
    that are not accessible or do not exist (anymore) have an `undef` entry.

    Each columns entry is `undef` or a hashref with these entries:

    - CID


        Holds the COLUMN ID of the column (INTEGER). In the current implementation,
        the `CID` entry is identical to the index in the list

            say $columns->[186]{CID};
            # 186

    - NAME


        Holds the name of the column

            say $columns->[186]{NAME};
            # ATHID

    - TID


        Holds the TABLE ID (INTEGER) of the table this column belongs to.

            say $columns->[186]{TID};
            # 43

    - TNAME


        Holds the name of the table this column belongs to.

            say $columns->[186]{TNAME};
            # DBUTIL

    - TYPE


        Holds the type (INTEGER) of the column

            say $columns->[186]{TYPE};
            # 2

        The description of the type can be found in the `TYPE` entry in `$dd-`{TYPE}>.

    - LENGTH


        Holds the length of the column or `0` if not appropriate.

            say $columns->[186]{LENGTH};
            # 9

    - SCALE


        Holds the scale of the column or `0` if not appropriate.

            say $columns->[186]{SCALE};
            # 0

    - NULLABLE


        Holds the true/false indication of this column allowing `NULL` as value

            say $columns->[186]{NULLABLE};
            # 0

        Primary keys implicitly do not allow `NULL` values

    - DSP\_LEN


        Holds, if appropriate, the display length of the column

            say $columns->[186]{DSP_LEN};
            # 10

    - DSP\_SCL


        Holds, if appropriate, the display scale of the column

            say $columns->[186]{DSP_SCL};
            # 0

    - DSP\_PICT


        Holds, if appropriate, the display format of the column

            say $columns->[186]{DSP_PICT};
            #

    - OPTIONS


        Holds the internal (bitmap) representation of the options for this column.
        Most, if not all, of these options have been translated to the other entries
        in this hash.

            say $columns->[186]{OPTIONS};
            # 16412

    - PKEY


        Holds a true/false indication of the column is a (single) primary key.

            say $columns->[186]{PKEY};
            # 1

    - RDONLY


        Holds a true/false indication of the column is read-only.

            say $columns->[186]{RDONLY};
            # 0

    - UNIQUE


        Holds a true/false indication of the column is unique.

            say $columns->[186]{UNIQUE};
            # 1

    - LINK


        Holds the `CID` of the column this column links to through referential
        integrity. This value is `-1` if there is no link.

            say $columns->[186]{LINK};
            # -1

    - REFS


        Holds a list of column indices (`CID`'s) of the columns referencing
        this column in a link.

            say for @{$columns->[186]{REFS}};
            # 191
            # 202

    - NBTREE


        Holds the number of B-tree indices the column participates in

            say $columns->[186]{NBTREE};
            # 0

    - NHASH


        Holds the number of hash-tables the column belongs to

            say $columns->[186]{NHASH};
            # 0

    - NPLINK


        Holds the number of links the column is parent of

            say $columns->[186]{NPLINK};
            # 2

    - NCLINK


        Holds the number of links the column is child of (<C0> or `1`)

            say $columns->[186]{NCLINK};
            # 0

        If this entry holds `1`, the `LINK` entry holds the `CID` of the
        parent column.

Combining all of these into describing a table, might look like done in
`examples/describe.pl`

# TODO

As this module is probably far from complete, so will the TODO list most
likely will be far from complete. More generic (test) items are mentioned
in the README in the module distribution.

- Handle attributes

    Check if all documented handle (database- and statement-) attributes are
    supported and work as expected.

        local $dbh->{RaiseError}       = 0;
        local $sth->{FetchHashKeyName} = "NAME";

- Statement attributes

    Allow setting and getting statement attributes. A specific example might be

        $sth->{PrintError}       = 0;
        $sth->{FetchHashKeyName} = "NAME_uc";

- 3-argument bind\_param ()

    Investigate and implement 3-argument versions of $sth->bind\_param ()

- looks\_as\_number ()

    Investigate if looks\_as\_number () should be used in st\_bind ().
    Comments are in where it should.

- Multiple open databases

    Try finding a way to open several different Unify databases at the
    same time for parallel (or at least sequential) processing.

# SEE ALSO

The DBI documentation in [DBI](https://metacpan.org/pod/DBI), a lot of web pages, some very good, the
Perl 5 DBI Home page (http://dbi.perl.org/), other DBD modules'
documentation (DBD-Oracle is probably the most complete), the
comp.lang.perl.modules newsgroup and the dbi-users mailing list
(mailto:dbi-users-help@perl.org)

# AUTHOR

DBI/DBD was developed by Tim Bunce, who also developed the DBD::Oracle.

H.Merijn Brand developed the DBD::Unify extension.

Todd Zervas has given a lot of feedback and patches.

# COPYRIGHT AND LICENSE

Copyright (C) 1999-2021 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
