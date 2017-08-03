#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

# Parsing the command line arguments
my $appl_name;
GetOptions("appl_name|a=s" => \$appl_name);
unless ($appl_name)
{
	print "\nPlease provide the appliance name.. Which appliance?\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Login to appliance with default user and password
my $root_appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_root_username"}, $cfg{"appliance_root_password"}));

my $start_time = "";
get_date($root_appliance, \$start_time, " +\"%T\"");
print "\nDATE: ".$start_time." te";
my $op = ' +"%T"';
get_date($root_appliance, \$start_time, $op); 
print "\nDATE: ".$start_time." te";
collect_dpconsole_output($root_appliance, ("dprx","classdump bw"));
get_date($root_appliance, \$start_time, " +\"%F %T\""); 
print "\nDATE: ".$start_time." te";
$root_appliance->soft_close();
