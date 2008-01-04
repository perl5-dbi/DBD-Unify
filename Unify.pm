#   Copyright (c) 1999-2008 H.Merijn Brand
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

require 5.006;

use strict;
use warnings;

package DBD::Unify;

our $VERSION = "0.70";

=head1 NAME

DBD::Unify - DBI driver for Unify database systems

=head1 SYNOPSIS

 # Examples marked NYT are Not Yet Tested, they might work
 #  all others have been tested.
 # man DBI for explanation of each method (there's more than listed here)

 $dbh = DBI->connect ("DBI:Unify:[\$dbname]", "", $schema, {
			 AutoCommit    => 0,
			 ChopBlanks    => 1,
			 uni_verbose   => 0,
			 uni_scanlevel => 2,
			 });
 $dbh = DBI->connect_cached (...);                   # NYT
 $dbh->do ($statement);
 $dbh->do ($statement, \%attr);                      # NYI
 $dbh->do ($statement, \%attr, @bind);               # NYI
 $dbh->commit;
 $dbh->rollback;
 $dbh->disconnect;

 $all = $dbh->selectall_arrayref ($statement);
 @row = $dbh->selectrow_array ($statement);
 $col = $dbh->selectcol_arrayref ($statement);

 $sth = $dbh->prepare ($statement);
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

=cut

# The POD text continues at the end of the file.

###############################################################################

use Carp;
use DBI 1.42;

use DynaLoader ();
use vars qw(@ISA);
@ISA = qw(DynaLoader);
bootstrap DBD::Unify $VERSION;

use vars qw($err $errstr $state $drh);
$err    = 0;		# holds error code   for DBI::err
$errstr = "";		# holds error string for DBI::errstr
$state  = "";		# holds SQL state    for DBI::state
$drh    = undef;	# holds driver handle once initialised

sub driver
{
    return $drh if $drh;
    my ($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh ($class, {
	Name         => "Unify",
	Version      => $VERSION,
	Err          => \$DBD::Unify::err,
	Errstr       => \$DBD::Unify::errstr,
	State        => \$DBD::Unify::state,
	Attribution  => "DBD::Unify by H.Merijn Brand",
	});

    $drh;
    } # driver

1;

####### Driver ################################################################

package DBD::Unify::dr;

$DBD::Unify::dr::imp_data_size = 0;

sub connect
{
    my ($drh, $dbname, $user, $auth) = @_;

    unless ($ENV{UNIFY} && -d $ENV{UNIFY} && -x _) {
	$drh->{Warn} and
	    Carp::croak "\$UNIFY not set or invalid. UNIFY may fail\n";
	}
    # More checks here if wanted ...

    $user = "" unless defined $user;
    $auth = "" unless defined $auth;
    
    # create a 'blank' dbh
    my $dbh = DBI::_new_dbh ($drh, {
	Name          => $dbname,
	USER          => $user,
	CURRENT_USER  => $user,
	});

    # Connect to the database..
    DBD::Unify::db::_login ($dbh, $dbname, $user, $auth) or return;

    $dbh;
    } # connect

sub data_sources
{
    my ($drh) = @_;
    $drh->{Warn} and
	Carp::carp "\$drh->data_sources () not defined for Unify\n";
    "";
    } # data_sources

####### Database ##############################################################

package DBD::Unify::db;

$DBD::Unify::db::imp_data_size = 0;

sub ping
{
    my $dbh = shift;
    $dbh->prepare ("select ORD from SYS.ORD") or return 0;
    return 1;
    } # ping

sub do
{
    my ($dbh, $statement, $attribs, @params) = @_;
    # Next two might use base class: DBD::_::do (@_);
    Carp::carp "DBD::Unify::\$dbh->do () attribs unused\n" if $attribs;
    Carp::carp "DBD::Unify::\$dbh->do () params unused\n"  if @params;
    DBD::Unify::db::_do ($dbh, $statement);
    } # do

sub prepare
{
    my ($dbh, $statement, @attribs) = @_;

    # Strip comments
    $statement = join "" => map {
	my $s = $_;
	$s =~ m/^'.*'$/ or $s =~ s/(--.*)$//m;
	$s;
	} split m/('[^']*')/ => $statement;
    # create a 'blank' sth
    my $sth = DBI::_new_sth ($dbh, {
	Statement => $statement,
	});

    # Setup module specific data
#   $sth->STORE ("driver_params" => []);
#   $sth->STORE ("NUM_OF_PARAMS" => ($statement =~ tr/?//));

    DBD::Unify::st::_prepare ($sth, $statement, @attribs) or return;

    $sth;
    } # prepare

sub table_info
{
    my $dbh = shift;
    my ($catalog, $schema, $table, $type, $attr);
    ref $_[0] or ($catalog, $schema, $table, $type) = splice @_, 0, 4;
    if ($attr = shift) {
	ref ($attr) eq "HASH" or
	    Carp::croak qq{usage: table_info ({ TABLE_NAME => "foo", ... })};
	exists $attr->{TABLE_SCHEM} and $schema = $attr->{TABLE_SCHEM};
	exists $attr->{TABLE_NAME}  and $table  = $attr->{TABLE_NAME};
	exists $attr->{TABLE_TYPE}  and $type   = $attr->{TABLE_TYPE};
	}
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in table_info\n";
	return;
	}
    my @where;
    $schema and push @where, "OWNR       like '$schema'";
    $table  and push @where, "TABLE_NAME like '$table'";
    $type   and $type = uc substr $type, 0, 1;
    $type   and push @where, "TABLE_TYPE like '$type'";
    local $" = " and ";
    my $where = @where ? " where @where" : "";
    my $sth = $dbh->prepare (
	"select '', OWNR, TABLE_NAME, TABLE_TYPE, RDWRITE ".
	"from   SYS.ACCESSIBLE_TABLES ".
	$where);
    $sth or return;
    $sth->execute;
    $sth;
    } # table_info

# $sth = $dbh->foreign_key_info (
#            $pk_catalog, $pk_schema, $pk_table,
#            $fk_catalog, $fk_schema, $fk_table,
#            \%attr);
sub foreign_key_info
{
    my $dbh = shift;
    my ($Pcatalog, $Pschema, $Ptable,
	$Fcatalog, $Fschema, $Ftable, $attr) = (@_, {});

    my @where;
    $Pschema and push @where, "REFERENCED_OWNER  = '$Pschema'";
    $Ptable  and push @where, "REFERENCED_TABLE  = '$Ptable'";
    $Fschema and push @where, "REFERENCING_OWNER = '$Fschema'";
    $Ftable  and push @where, "REFERENCING_TABLE = '$Ftable'";

    my $where = @where ? "where " . join " and " => @where : "";
    my $sth = $dbh->prepare (join "\n",
	"select INDEX_NAME, ",
	"       REFERENCED_OWNER,  REFERENCED_TABLE,  REFERENCED_COLUMN,",
	"       REFERENCING_OWNER, REFERENCING_TABLE, REFERENCING_COLUMN,",
	"       REFERENCING_COLUMN_ORD",
	"from   SYS.LINK_INDEXES",
	$where);
    $sth or return;
    $sth->execute;
    my @fki;
    while (my @sli = $sth->fetchrow_array) {
	push @fki, [
	    undef, @sli[1..3],
	    undef, @sli[4..6], $sli[7] + 1,
	    undef, undef,
	    $sli[0], undef,
	    undef, undef
	    ];
	}
    $sth->finish;
    $sth = undef;
    
    DBI->connect ("dbi:Sponge:", "", "", { RaiseError => 1 })->prepare (
	"select link_info $where", {
	    rows => \@fki,
	    NAME => [qw(
		uk_table_cat uk_table_schem uk_table_name uk_column_name
		fk_table_cat fk_table_schem fk_table_name fk_column_name
		ordinal_position

		update_rule delete_rule
		fk_name uk_name
		deferability unique_or_primary
		)],
	    });
    } # foreign_key_info

# type = "R" ? references me : references
# This is to be converted to foreign_key_info
sub link_info
{
    my $dbh = shift;
    my ($catalog, $schema, $table, $type, $attr);
    ref $_[0] or ($catalog, $schema, $table, $type) = splice @_, 0, 4;
    if ($attr = shift) {
	ref ($attr) eq "HASH" or
	    Carp::croak qq{usage: link_info ({ TABLE_NAME => "foo", ... })};
	exists $attr->{TABLE_SCHEM} and $schema = $attr->{TABLE_SCHEM};
	exists $attr->{TABLE_NAME}  and $table  = $attr->{TABLE_NAME};
	exists $attr->{TABLE_TYPE}  and $type   = $attr->{TABLE_TYPE};
	}
    my @where;
    unless ($type and $type =~ m/^[Rr]/) {
	$schema and push @where, "REFERENCING_OWNER = '$schema'";
	$table  and push @where, "REFERENCING_TABLE = '$table'";
	}
    else {
	$schema and push @where, "REFERENCED_OWNER  = '$schema'";
	$table  and push @where, "REFERENCED_TABLE  = '$table'";
	}
    local $" = " and ";
    my $where = @where ? " where @where" : "";
    my $sth = $dbh->prepare (join "\n",
	"select '', REFERENCED_OWNER, INDEX_NAME, REFERENCED_TABLE,",
	"       REFERENCED_COLUMN, REFERENCED_COLUMN_ORD,",
	"       REFERENCING_OWNER, REFERENCING_TABLE, REFERENCING_COLUMN,",
	"       REFERENCING_COLUMN_ORD ",
	"from   SYS.LINK_INDEXES",
	$where);
    $sth or return;
    $sth->execute;
    $sth;
    } # link_info

*DBI::db::link_info = \&link_info;

1;

####### Statement #############################################################

package DBD::Unify::st;

1;

####### End ###################################################################

=head1 DESCRIPTION

DBD::Unify is an extension to Perl which allows access to Unify
databases. It is built on top of the standard DBI extension an
implements the methods that DBI require.

This document describes the differences between the "generic" DBD
and DBD::Unify.

=head2 Extensions/Changes

=over 2

=item returned types

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

=item connect

    connect ("DBI:Unify:dbname[;options]" [, user [, auth [, attr]]]);

Options to the connection are passed in the datasource
argument. This argument should contain the database
name possibly followed by a semicolon and the database options
which are ignored.

Since Unify database authorization is done using grant's using the
user name, the I<user> argument me be empty or undef. The auth
field will be used as a default schema. If the auth field is empty
or undefined connect will check for the environment variable $USCHEMA
to use as a default schema. If neither exists, you will end up in your
default schema, or if none is assigned, in the schema PUBLIC.

At the moment none of the attributes documented in DBI's "ATTRIBUTES
COMMON TO ALL HANDLES" are implemented specifically for the Unify
DBD driver, but they might have been inherited from DBI. The I<ChopBlanks>
attribute is implemented, but defaults to 1 for DBD::Unify.
The Unify driver supports "uni_scanlevel" to set the transaction scan
level to a value between 1 and 16 and "uni_verbose" to set DBD specific
debugging, allowing to show only massages from DBD-Unify without using
the default DBI->trace () call.

The connect call will result in statements like:

    CONNECT;
    SET CURRENT SCHEMA TO PUBLIC;  -- if auth = "PUBLIC"
    SET TRANSACTION SCAN LEVEL 7;  -- if attr has { uni_scanlevel => 7 }

local database

    connect ("/data/db/unify/v63AB", "", "SYS")

=item AutoCommit

It is recommended that the C<connect> call ends with the attributes
S<{ AutoCommit => 0 }>, although it is not implemented (yet).

If you dont want to check for errors after B<every> call use 
S<{ AutoCommit => 0, RaiseError => 1 }> instead. This will C<die> with
an error message if any DBI call fails.

=item re-connect

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
     {   my $sth = $dbh->prepare ("...");
         while (my @data = $sth->fetchrow_array) {
             :
             }
         }  # $sth implicitly destroyed by end-of-scope
     $dbh->disconnect;
     }  # $dbh implicitly destroyed by end-of-scope

=item do

 $dbh->do ($statement)

This is implemented as a call to 'EXECUTE IMMEDIATE' with all the
limitations that this implies.

=item commit and rollback invalidates open cursors

DBD::Unify does warn when a commit or rollback is issued on a $dbh
with open cursors.

Possibly a commit/rollback/disconnect should also undef the $sth's.
(This should probably be done in the DBI-layer as other drivers will
have the same problems).

After a commit or rollback the cursors are all ->finish'ed, i.e. they
are closed and the DBI/DBD will warn if an attempt is made to fetch
from them.

A future version of DBD::Unify might re-prepare the statement.

=back

=head2 Stuff implemented in perl

=over 2

=item driver

Just here for DBI. No use in telling the end-user what to do with it :)

=item connect

=item data_sources

There is no way for Unify to tell what data sources might be available.
There is no central files (like /etc/oratab for Oracle) that lists all
available sources, so this method will always return an empty list.

=item do

=item prepare

=item table_info ($;$$$$)

=item foreign_key_info ($$$$$$;$)

=item link_info ($;$$$$)

=item ping

=back

=head2 Stuff implemented in C (XS)

=over 2

=item trace

The C<DBI-E<gt>trace (level)> call will promote the level to DBD-Unify, showing
both the DBI layer debugging messages as well as the DBD-Unify debug messages.
It is however also possible to trace B<only> the DBD-Unify without the
C<DBI-E<gt>trace ()> call by using the C<uni_verbose> attribute on C<connect ()>.
Currently, the following levels are defined:

=over 2

=item 1

No messages implemented (yet) at level 1

=item 2

Level 1 plus main method entry and exit points:

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

=item 3

Level 2 plus errors and additional return codes and field types and values:

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

=item 4

Level 3 plus some content info:

  DBD::Unify::st_fetch u_sql_00_000000
      Fetched         sqlcode = 0, fields = 1
      After get,      sqlcode = 0
       Field   1: [05 00 04 00 00] c_bar: NUMERIC  4: (6030) 6030 ==
       Fetch done

=item 5

Level 4 plus internal coding for exchanges and low(er) level return codes:

  DBD::Unify::fld_describe o_sql_00_000000 (1 fields)
      After get,      sqlcode = 0
       Field   1: [05 00 04 00 FFFFFFFF] c_bar
  DBD::Unify::st_prepare u_sql_00_000000 (<= 1, => 0)

=item 6

Level 5 plus destroy/cleanup states:

  DBD::Unify::st_free u_sql_00_000000
   destroy allocc destroy alloco    After deallocO, sqlcode = 0
   destroy alloci destroy allocp    After deallocU, sqlcode = 0
   destroy stat destroy growup destroy impset

=item 7

No messages (yet) set to level 7 and up.

=back

=item int  dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,

=item SV  *dbd_db_FETCH_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)

=item int  dbd_db_STORE_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)

=item int  dbd_db_commit (SV *dbh, imp_dbh_t *imp_dbh)

=item void dbd_db_destroy (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_disconnect (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_do (SV *dbh, char *statement)

=item int  dbd_db_login (SV *dbh, imp_dbh_t *imp_dbh,

=item int  dbd_db_rollback (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_discon_all (SV *drh, imp_drh_t *imp_drh)

=item int  dbd_fld_describe (SV *dbh, imp_sth_t *imp_sth, int num_fields)

=item void dbd_init (dbistate_t *dbistate)

=item int  dbd_prm_describe (SV *dbh, imp_sth_t *imp_sth, int num_params)

=item SV  *dbd_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv)

=item int  dbd_st_STORE_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)

=item int  dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field,

=item void dbd_st_destroy (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_execute (SV *sth, imp_sth_t *imp_sth)

=item AV  *dbd_st_fetch (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_finish (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_prepare (SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs)

=item int  dbd_st_rows (SV *sth, imp_sth_t *imp_sth)

=back

=head1 NOTES

Far from complete ...

=head1 SEE ALSO

The DBI documentation in L<DBI>, a lot of web pages, some very good, the
Perl 5 DBI Home page (http://dbi.perl.org/), other DBD modules'
documentation (DBD-Oracle is probably the most complete), the
comp.lang.perl.modules newsgroup and the dbi-users mailing list
(mailto:dbi-users-help@perl.org)

=head1 AUTHORS

DBI/DBD was developed by Tim Bunce, <Tim.Bunce@ig.co.uk>, who also
developed the DBD::Oracle.

H.Merijn Brand, <h.m.brand@xs4all.nl> developed the DBD::Unify extension.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999-2008 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
