#!/usr/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.02 - 20170901";
my $cmd = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $cmd tablename | tale-pattern";
    exit $err;
    } # usage

use DBI;
use Data::Peek;
use Getopt::Long qw(:config bundling);
my $opt_v = 0;
GetOptions (
    "help|?"	=> sub { usage (0); },
    "V|version"	=> sub { say "$cmd [$VERSION]"; exit 0; },

    "c|compact!"	=> \my $opt_c,

    "v|verbose:1"	=> \   $opt_v,
    ) or usage (1);

my $table = shift or usage (1);

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
    $opt_v > 8 and DDumper $t;
    print "$t->{TID}: " if $opt_v;
    print "$aid{$t->{AID}}.$t->{NAME}";
    print " DIRECT KEYED" if $t->{DIRECTKEY};
    print " FIXED SIZE"   if $t->{FIXEDSIZE};
    print " SCATTERED"    if $t->{SCATTERED};
    print "\n";

    foreach my $cid (@{$t->{COLUMNS}}) {
	my $c = $dd->{COLUMN}[$cid];
	$opt_v > 8 and DDumper $c;
	my $L = "";
	my $l = $c->{LINK};
	if ($l >= 0) {
	    $L = sprintf "%s.%s",
		$dd->{COLUMN}[$l]{TNAME},
		$dd->{COLUMN}[$l]{NAME};
	    my $ts = $dd->{AUTH}[$dd->{TABLE}[$dd->{COLUMN}[$l]{TID}]{AID}]{NAME};
	    substr $L, 0, 0, "$ts."              if $ts ne $ENV{USCHEMA} // "";
	    substr $L, 0, 0, sprintf "%3d: ", $l if $opt_v;
	    }

	my $cn = $c->{NAME};
	substr $cn, 0, 0, sprintf "%3d:", $cid if $opt_v;

	my $cl = $c->{LENGTH} ? sprintf " (%d%s)",
		$c->{LENGTH}, $c->{SCALE}    ? ".$c->{SCALE}" : "" : "";

	if ($opt_c) {
	    printf "  %-17s %-20s %1s%1s %2d:%s%s\n", $cn, $L,
		$c->{PKEY}     ? "*" : " ",
		$c->{NULLABLE} ? " " : "N",
		$c->{TYPE}, $dd->{TYPE}[$c->{TYPE}], $cl;
	    }
	else {
	    printf "   %-23s %-20s%s\t%s%s\n", $cn,
		$dd->{TYPE}[$c->{TYPE}], $cl,
		$c->{NULLABLE} ? "" : " NOT NULL",
		$c->{PKEY}     ? " PRIMARY KEY" : "";
	    $L and printf "%12s %s\n", "-->", $L;
	    }
	}
    }
