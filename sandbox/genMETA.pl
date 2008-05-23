#!/pro/bin/perl

use strict;
use warnings;

my $version;
open my $pm, "<", "Unify.pm" or die "Cannot read Unify.pm";
while (<$pm>) {
    m/^our .VERSION\s*=\s*"?([-0-9._]+)"?\s*;\s*$/ or next;
    $version = $1;
    last;
    }
close $pm;
$version or die "Could not extract VERSION from Unify.pm\n";

my @my = glob <*/META.yml>;
@my == 1 && open my $my, ">", $my[0] or die "Cannot update META.yml|n";
while (<DATA>) {
    s/VERSION/$version/o;
    print $my $_;
    }
close $my;

__END__
--- #YAML:1.0
name:              DBD-Unify
version:           VERSION
abstract:          DBI driver for Unify database systems
license:           perl
author:              
    - H.Merijn Brand <h.merijn@xs4all.nl>
generated_by:      Author
distribution_type: module
provides:
    DBD::Unify:
        file:      Unify.pm
        version:   VERSION
requires:     
    perl:          5.006
    Carp:          0
    Config:        0
    Cwd:           0
    DBI:           1.42
    DynaLoader:    0
    File::Copy:    0
    File::Find:    0
build_requires:
    Test::Harness: 0
    Test::More:    0
resources:
    license:       http://dev.perl.org/licenses/
meta-spec:
    url:           http://module-build.sourceforge.net/META-spec-v1.3.html
    version:       1.3
