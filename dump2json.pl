#!/usr/bin/perl

#use strict;
use warnings;
use JSON;

$ifile = $ARGV[0] or die 'No file name given.';
$ofile = $ifile.'.json';

require $ifile;

$json = JSON->new->utf8->encode($main::VAR1);
open(my $fh, '>', $ofile) or die "Can't open ".$ofile;
print $fh $json;

close $fh;
