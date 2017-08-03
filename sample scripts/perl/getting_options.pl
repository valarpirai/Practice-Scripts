#!/usr/bin/perl

use Getopt::Long;
use strict;


my $verbose = '';	# option variable with default value (false)
my $all = '';	# option variable with default value (false)


GetOptions ('verbose|v=s' => \$verbose, 'all|a=s' => \$all);


print $verbose.' next: '.$all."\n";
