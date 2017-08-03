#!/usr/bin/perl

use perl_modules::common;
use Expect;

# Loading the config
 execute(load_config("228"));
#
#
# # Login to appliance with default user and password
my $session = execute_ssh(login("192.168.1.210","admin","admin"));

print get_filter_count($session);
print " Class count ";
