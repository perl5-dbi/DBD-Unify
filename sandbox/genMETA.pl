#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
my $check = 0;
my $opt_v = 0;
GetOptions (
    "c|check"		=> \$check,
    "v|verbose:1"	=> \$opt_v,
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "lib/DBD/Unify.pm",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    $meta->check_minimum ([ "lib", "t", "Makefile.PL" ]);
    $meta->check_minimum ("5.010", [ "examples" ]);
    }
elsif ($opt_v) {
    $meta->print_yaml ();
    }
else {
    $meta->fix_meta ();
    }

__END__
--- #YAML:1.0
name:                    DBD-Unify
version:                 VERSION
abstract:                DBI driver for Unify database systems
license:                 perl
author:              
    - H.Merijn Brand <h.m.brand@xs4all.nl>
generated_by:            Author
distribution_type:       module
provides:
    DBD::Unify:
        file:            lib/DBD/Unify.pm
        version:         VERSION
    DBD::Unify::GetInfo:
        file:            lib/DBD/Unify/GetInfo.pm
        version:         0.10
    DBD::Unify::TypeInfo:
        file:            lib/DBD/Unify/TypeInfo.pm
        version:         0.10
requires:     
    perl:                5.008004
    Carp:                0
    DBI:                 1.42
    DynaLoader:          0
configure_requires:
    ExtUtils::MakeMaker: 0
    Config:              0
    Cwd:                 0
    DBI::DBD:            0
build_requires:
    Config:              0
    File::Copy:          0
    File::Find:          0
test_requires:
    Test::Harness:       0
    Test::More:          0.90
recommends:
    perl:                5.014002
    DBI:                 1.618
test_recommends:
    Test::More:          0.98
resources:
    license:             http://dev.perl.org/licenses/
    repository:          http://repo.or.cz/w/DBD-Unify.git
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
