#!/usr/bin/perl

use strict;
use warnings;

use DBI;

my $table = shift or die "usage: $0 tablename | table-pattern\n";

my $dbh = DBI->connect ("dbi:Unify:");

my $dd = $dbh->func ("db_dict");

my ($sch, $tbl) = split m/\./ => $table;
$tbl or ($tbl, $sch) = ($sch, $ENV{USCHEMA} || die "No (explicit) schema\n");

my       @a = grep { $_ and    $_->{NAME} eq     $sch    } @{$dd->{AUTH}};
   @a or @a = grep { $_ and lc $_->{NAME} eq  lc $sch    } @{$dd->{AUTH}};
   @a or @a = grep { $_ and    $_->{NAME} =~  m/^$sch$/  } @{$dd->{AUTH}};
   @a or @a = grep { $_ and    $_->{NAME} =~   m/$sch/   } @{$dd->{AUTH}};
   @a or @a = grep { $_ and    $_->{NAME} =~  m/^$sch$/i } @{$dd->{AUTH}};
   @a or @a = grep { $_ and    $_->{NAME} =~   m/$sch/i  } @{$dd->{AUTH}};
   @a or die "Cannot find an accessible schema matchin $sch\n";

my %aid = map { $_->{AID} => $_->{NAME} } @a;

my @tbl = grep { $_ and exists $aid{$_->{AID}} } @{$dd->{TABLE}} or
    die "Cannot find any accessible tables in accessible schemas\n";

my       @t = grep {    $_->{NAME} eq     $tbl    } @tbl;
   @t or @t = grep { lc $_->{NAME} eq  lc $tbl    } @tbl;
   @t or @t = grep {    $_->{NAME} =~  m/^$tbl$/  } @tbl;
   @t or @t = grep {    $_->{NAME} =~   m/$tbl/   } @tbl;
   @t or @t = grep {    $_->{NAME} =~  m/^$tbl$/i } @tbl;
   @t or @t = grep {    $_->{NAME} =~   m/$tbl/i  } @tbl;
   @t or die "Cannot find an accessible table matching $table\n";

foreach my $t (@t) {
    print "$t->{TID}: $aid{$t->{AID}}.$t->{NAME}";
    print " DIRECT KEYED" if $t->{DIRECTKEY};
    print " FIXED SIZE"   if $t->{FIXEDSIZE};
    print " SCATTERED"    if $t->{SCATTERED};
    print "\n";

    foreach my $cid (@{$t->{COLUMNS}}) {
	my $c = $dd->{COLUMN}[$cid];
	printf "%6d: %-20s %-20s (%3d%s)\t%s%s\n",
	    $cid, $c->{NAME},
	    $dd->{TYPE}[$c->{TYPE}], $c->{LENGTH},
	    $c->{SCALE}    ? ".$c->{SCALE}" : "",
	    $c->{NULLABLE} ? "" : " NOT NULL",
	    $c->{PKEY}     ? " PRIMARY KEY" : "",
	    ;
	my $lnk = $c->{LINK};
	$lnk >= 0 or next;
	printf "%12s %3d: %s.%s.%s\n", "-->", $lnk,
	    $dd->{AUTH}[$dd->{TABLE}[$dd->{COLUMN}[$lnk]{TID}]{AID}]{NAME},
	    $dd->{COLUMN}[$lnk]{TNAME},
	    $dd->{COLUMN}[$lnk]{NAME};
	}
    }
