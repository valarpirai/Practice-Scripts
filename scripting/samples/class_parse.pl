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


# Loading the config
execute(load_config($appl_name));


# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

$appliance->log_stdout(1);

my %config = ();

execute(get_class_stats($appliance,%config,"iperf_class","last_day"));

foreach (sort keys %config)
{
        print $_ ," : " ,$config{$_}, "\n";
}

print "\n\nLicense config:\n";

my %license = ();
execute(get_license($appliance, \%license));

foreach (keys %license)
{
        print $_ ," : " ,$license{$_}, "\n";
}

print "\nDiscovery ".is_discovery_on($appliance);
print "\nShaping ".is_shaping_on($appliance);
print "\nBypass ".is_bypass_on($appliance)."\n";



$appliance->soft_close();
