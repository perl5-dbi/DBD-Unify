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
    print STDERR "Check required and recommended module versions ...\n";
    BEGIN { $V::NO_EXIT = $V::NO_EXIT = 1 } require V;
    my %vsn = map { m/^\s*([\w:]+):\s+([0-9.]+)$/ ? ($1, $2) : () } @yml;
    delete @vsn{qw( perl version )};
    for (sort keys %vsn) {
	$vsn{$_} eq "0" and next;
	my $v = V::get_version ($_);
	$v eq $vsn{$_} and next;
	printf STDERR "%-35s %-6s => %s\n", $_, $vsn{$_}, $v;
	}

    print STDERR "Checking generated YAML ...\n";
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
    @my == 1 && open my $my, ">", $my[0] or die "Cannot update META.yml\n";
    print $my @yml;
    close $my;
    chmod 0644, $my[0];
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
    perl:                5.006
    Carp:                0
    Cwd:                 0
    DBI:                 1.42
    DynaLoader:          0
configure_requires:
    ExtUtils::MakeMaker: 0
    Config:              0
    Cwd:                 0
    DBI:                 1.42
    DBI::DBD:            0
build_requires:
    Config:              0
    File::Copy:          0
    File::Find:          0
    Test::Harness:       0
    Test::More:          0
recommends:
    perl:                5.012001
    DBI:                 1.613
resources:
    license:             http://dev.perl.org/licenses/
    repository:          http://repo.or.cz/w/DBD-Unify.git
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
