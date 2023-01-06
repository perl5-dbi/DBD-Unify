#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use PROCURA::DBD;

my $dbh = DBDlogon;

my $dd = $dbh->func ("db_dict");

my $c = $dd->{COLUMN}[shift] or exit 1;
DDumper $dd->{TABLE}[$c->{TID}];
DDumper $c;

#DDumper $dd->{COLGRP};
