#!/usr/bin/perl

use perl_modules::common;

load_config();
print wait_till_up("192.168.1.26", 100);
print "Next";
print wait_till_up("192.168.1.2", 100);
print "Next";

