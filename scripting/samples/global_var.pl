#!/usr/bin/perl

use perl_modules::common;
use strict;

# Getting value for cfg from the common.pm
load_config("210");
for (keys %cfg)
{
	print $_ . " => " . $cfg{$_} . "\n";
}
