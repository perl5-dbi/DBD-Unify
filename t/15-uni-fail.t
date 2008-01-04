#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use Cwd qw( getcwd );
use DBI qw(:sql_types);

unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

{   no warnings 'uninitialized';
    local $ENV{UNIFY} = undef;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "Undefined \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "Undef \$Unify error message");
    }

{   local $ENV{UNIFY} = "";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "Empty \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "Empty \$Unify error message");
    }

{   local $ENV{UNIFY} = "/dev/null";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = /dev/null");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = getcwd;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = __FILE__;
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   local $ENV{UNIFY} = getcwd;
    mkdir "bogus-dir", 0666;
    $ENV{UNIFY} .= "/bogus-dir";
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    rmdir $ENV{UNIFY};
    is ($dbh, undef, "\$UNIFY = $ENV{UNIFY}");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "\$Unify error message");
    }

{   delete $ENV{UNIFY};
    my $dbh = DBI->connect ($dbname, undef, "", { RaiseError => 0, PrintError => 0 });
    is ($dbh, undef, "No \$UNIFY");
    like ($DBI::errstr, qr{'\$UNIFY' directory does not exist or}, "No \$Unify error message");
    }

1;
