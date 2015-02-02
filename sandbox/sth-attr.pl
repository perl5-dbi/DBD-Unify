#!/pro/bin/perl

use strict;
use warnings;

use PROCURA::DBD;

my $dbh = DBDlogon (0);

my $sth = prepex ("select * from usr");

use DDumper;
#print DDumper $sth;

# Test DBI-1.607 11570 statement handle attributes
foreach my $attr (qw(
	NUM_OF_FIELDS NUM_OF_PARAMS
	NAME NAME_lc NAME_uc NAME_hash NAME_lc_hash NAME_uc_hash
	TYPE PRECISION SCALE NULLABLE
	CursorName Database
	ParamValues ParamArrays ParamTypes 
	Statement
	RowsInCache
	)) {
    printf "%-16s: ", $attr;
    unless (exists $sth->{$attr}) {
	print "-- not yet implemented --\n";
	next;
	}
    my $a = $sth->{$attr};
    unless (defined $a) {
	print "<undef>\n";
	next;
	}
    $_ = DDumper $a;
    s/\n\s*/ /g;
    s/\s+=>/ =>/g;
    s/bless\(\s*/bless (/g && s/ \)/)/g;
    s/^\$VAR1 = //;
    s/[\n\s]*(?:;[\n\s]*)?\Z/\n/;
    print;
    }
