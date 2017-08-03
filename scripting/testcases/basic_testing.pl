#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;
my %license = ();


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



# Resetting the appliance to factory image and rebooting
print $appliance "system\nimg factory-reset\n";
if ($appliance->expect(15, "Are you sure you want to proceed? Yes/No"))
{
	$appliance->send("yes\r");
	$appliance->expect(100, "Image reset to factory version");
}
if($appliance->expect(1,"Connection to $cfg{\"appliance_ip\"} closed"))
{
	execute(wait_till_up($cfg{"appliance_ip"}, 100));
	$appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
}
execute(wait_till_up($cfg{"appliance_ip"}, 100));


# Check license 
#execute_not(get_license($appliance, \%license));
execute(get_license($appliance, \%license));



# Check bypass status
#execute(is_bypass_on($appliance));
execute_not(is_bypass_on($appliance));



# Check the class count
my $ret = get_class_count($appliance);
if (int($ret) > 0)
{
	print_log($ANY, "There are $ret classes in the $cfg{'appliance_ip'}");
#	execute("There shouldn't be any class now");
}
elsif (length($ret) > 5) # Assuming the ret may be an error instead of zero
{
	execute($ret);
}



# Check the policies count
my $ret = get_policy_count($appliance);
if (int($ret) > 0)
{
	print_log($ANY, "There are $ret policies in the $cfg{'appliance_ip'}");
#	execute("There shouldn't be any policy now");
}
elsif (length($ret) > 5) # Assuming the ret may be an error instead of zero
{
	execute($ret);
}



# Check the filter count
my $ret = get_filter_count($appliance);
if (int($ret) > 0)
{
	print_log($ANY, "There are $ret filters in the $cfg{'appliance_ip'}");
#	execute("There shouldn't be any filters now");
}
elsif (length($ret) > 5) # Assuming the ret may be an error instead of zero
{
#	execute($ret);
}


# Create a pattern
my $new_pattname = "pattern_iperf";
my $new_patt_format = "port: 5001";
#execute_not(create_pattern($appliance, $new_pattname, $new_patt_format));
execute(create_pattern($appliance, $new_pattname, $new_patt_format));



# Create a class
my $predef_pattname = "ftp_rule";
my $new_classname = "my_class";
#execute_not(create_class($appliance, $new_classname, $LINK0, $predef_pattname));
execute(create_class($appliance, $new_classname, $LINK0, $predef_pattname));



# Modifying the WAN speed
my $wan_speed_in  = "5000";
my $wan_speed_out = "5000";
#execute_not(set_wan_speed($appliance, $LINK0, $wan_speed_in, $wan_speed_out));
execute(set_wan_speed($appliance, $LINK0, $wan_speed_in, $wan_speed_out));


# Setting max limits 
my $new_class_limit = 1000;
my $new_flow_limit = 1000;
my $new_flow_threshold = 95;
my $new_flow_limit_action = "reject";
my $new_pattern_limit = 1000;
my $new_policy_limit = 1000;
#execute_not(set_class_limit($appliance, $new_class_limit));
execute(set_class_limit($appliance, $new_class_limit));
#execute_not(set_flow_limit($appliance, $new_flow_limit, $new_flow_threshold, $new_flow_limit_action));
execute(set_flow_limit($appliance, $new_flow_limit, $new_flow_threshold, $new_flow_limit_action));
#execute_not(set_pattern_limit($appliance, $new_pattern_limit));
execute(set_pattern_limit($appliance, $new_pattern_limit));
#execute_not(set_policy_limit($appliance, $new_policy_limit));
execute(set_policy_limit($appliance, $new_policy_limit));


# Closing the session
$appliance->soft_close();
