#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

my $action = "c";
my @cust_class_name = ();
my @cust_pattern_format = ();

my $cust_pattern_prefix = "cust";

# Parsing the command line arguments
GetOptions("action|a=s" => \$action);

# Loading the configurations from file
execute(load_config("eagle"));

my %class_configs = do "other_config/$cfg{'class_config'}.cfg";
%cfg = (%cfg, %class_configs);

@cust_class_name = @{$cfg{"tcp_class_names"}};
@cust_pattern_format = @{$cfg{"tcp_class_port"}};

@cust_class_name = @cust_class_name[4..$#cust_class_name];
@cust_pattern_format = @cust_pattern_format[4..$#cust_pattern_format];

# Login to Appliance
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

if ($action eq "c" || $action eq "create")
{
	# Creating custom class with pattern 
	for(my $i = 0; $i <= $#cust_class_name; $i++)
	{
		my $cust_pattern_name = $cust_pattern_prefix . "_" . @cust_class_name[$i];
		execute(create_pattern($appliance, $cust_pattern_name, "port: @cust_pattern_format[$i]"));
		execute(create_class($appliance, @cust_class_name[$i], $LINK0, $cust_pattern_name));
	}

	# sync after create class 
	print $appliance "app\nsync\n\r";
	unless($appliance->expect(30, "Activated new patterns and classes successfully"))
	{
		execute("Failed to sync.\n");
	}
}
else
{
	# Deleting class
	delete_classes($appliance, @cust_class_name);
}
