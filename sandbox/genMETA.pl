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

my $version;
open my $pm, "<", "Unify.pm" or die "Cannot read Unify.pm";
while (<$pm>) {
    m/^our .VERSION\s*=\s*"?([-0-9._]+)"?\s*;\s*$/ or next;
    $version = $1;
    last;
    }
close $pm;
$version or die "Could not extract VERSION from Unify.pm\n";

my @yml;
while (<DATA>) {
    s/VERSION/$version/o;
    push @yml, $_;
    }

if ($check) {
    use YAML::Syck;
    use Test::YAML::Meta::Version;
    my $h;
    eval { $h = Load (join "", @yml) };
    $@ and die "$@\n";
    $opt_v and print Dump $h;
    my $t = Test::YAML::Meta::Version->new (yaml => $h);
    $t->parse () and die join "\n", $t->errors, "";

    my $req_vsn = $h->{requires}{perl};
    print "Checking if $req_vsn is still OK as minimal version\n";
    use Test::MinimumVersion;
    all_minimum_version_ok ($req_vsn, { paths =>
	[ "lib", "t", "examples", "Makefile.PL" ]});
    }
elsif ($opt_v) {
    print @yml;
    }
else {
    my @my = glob <*/META.yml>;
    @my == 1 && open my $my, ">", $my[0] or die "Cannot update META.yml|n";
    print $my @yml;
    close $my;
    chmod 0644, $my[0];
    }

__END__
--- #YAML:1.4
name:              DBD-Unify
version:           VERSION
abstract:          DBI driver for Unify database systems
license:           perl
author:              
    - H.Merijn Brand <h.m.brand@xs4all.nl>
generated_by:      Author
distribution_type: module
provides:
    DBD::Unify:
        file:      lib/DBD/Unify.pm
        version:   VERSION
requires:     
    perl:          5.006
    Carp:          0
    Cwd:           0
    DBI:           1.42
    DynaLoader:    0
build_requires:
    Config:        0
    File::Copy:    0
    File::Find:    0
    Test::Harness: 0
    Test::More:    0
recommends:
    perl:          5.8.8
    DBI:           1.607
resources:
    license:       http://dev.perl.org/licenses/
meta-spec:
    version:       1.4
    url:           http://module-build.sourceforge.net/META-spec-v1.4.html
