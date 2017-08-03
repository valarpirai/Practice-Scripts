#!/usr/bin/perl

use perl_modules::common;
use perl_modules::regression;
use strict;
use Getopt::Long;

my %license = ();
my %version = ();
my $timeout = 3;
my $local_session;
my $appl_name;
my $regress;
my $result = "";
my $ftp_path = "ftp://valar:testpass\@192.168.1.26/tmp/config";

# Parsing the command line arguments
GetOptions("appl_name|a=s" => \$appl_name, "regression|r" => \$regress);
unless ($appl_name)
{
	print " 
	        Please provide the appliance name.. Which appliance?
	        ex. perl valar_test.pl -a <appliance_config_file> 
";
	exit;
}

# Loading the config
execute(load_config($appl_name));

my %class_configs = do "other_config/$cfg{'class_config'}.cfg";
%cfg = (%cfg, %class_configs);

my @class_names = @{$cfg{"udp_class_names"}};
my @cust_class_name = @class_names;
my @initial_class_port = @{$cfg{"udp_class_ports"}};
my @cust_pattern_format = @{$cfg{"udp_class_ports"}};


print_log($ALL, "Ping tests before starting Test");

$local_session = Expect->new();
# Adding the log file name
$local_session->log_file($global_cfg{"log_file"});
if ($global_cfg{"print_in_screen"} eq $YES) 
{
	$local_session->log_stdout(1);
}else 
{
	$local_session->log_stdout(0);
}

my $check = "PASS";

# pinging the Test bed machines

$result = execute(ping($local_session, $cfg{"appliance_ip"}));
if($result ne $SUCCESS)
{
	$check = $result;
}
$result = execute(ping($local_session, $cfg{"server_ip"}));
if($result ne $SUCCESS)
{
	$check = $result;
}
$result = execute(ping($local_session, $cfg{"client_ip"}));
if($result ne $SUCCESS)
{
	$check = $result;
}

if($check eq "PASS")
{
	print_log($ALL, $result);
}else
{
	print_log($ALL, "FAIL");
}


# Login to appliance with default user and password. Login as root to get the dp_console output
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
my $root_appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_root_username"}, $cfg{"appliance_root_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));


# Check license 
print_log($ALL, "Show license");
$result = execute(get_license($appliance, \%license));
print_log($ALL, $result);

print_log($ALL, "Show health");
$result = execute(show_health($appliance, $root_appliance));
print_log($ALL, $result);

# Upgrade to the latest build
print_log($ALL, "Upgrade to latest Build");
$result = execute(upgrade_to_latest_build(\$appliance));
print_log($ALL, $result);

print_log($ALL, "Show health");
$result = execute(show_health($appliance, $root_appliance));
print_log($ALL, $result);

# Check bypass status
print_log($ALL, "Checking bypass is OFF");
$result = is_bypass_on($appliance);
if(not defined $result)
{
	$result = $SUCCESS;
}
print_log($ALL, $result);

print_log($ALL, "Config Backup");
$result = config_backup($appliance, $ftp_path);
print_log($ALL, $result);

print_log($ALL, "Show img");
$result = execute(get_software_version($appliance, \%version));
print_log($ALL, $result);

my @comm = ("pmdump", "pmdebug", "hmon", "classdump active", "classdump nzask", "classdump nzqueue",
		"classdump nzdrop", "flowdump ipv4 all", "pmdebug", "classdump all", "memusage", "cfr status", "hmon");

collect_dpconsole_output($root_appliance, @comm);

# Check shaping is on, unless turn on shaping
print_log($ALL, "Check shaping is off, unless turn off shaping");
$result = execute(set_shaping_off($appliance));
print_log($ALL, $result);

print_log($ALL, "Shaping OFF: Ping from client to server");
$result = execute(ping_test_from_client($client));
print_log($ALL, $result);

# Check shaping is on, unless turn on shaping
print_log($ALL, "Check shaping is on, unless turn on shaping");
$result = execute(set_shaping_on($appliance));
print_log($ALL, $result);

print_log($ALL, "Shaping ON: Ping from server to client");
$result = execute(ping_test_from_server($server));
print_log($ALL, $result);

print_log($ALL, "Creating classes");
$result = execute(create_classes($appliance));
print_log($ALL, $result);

my %flow_summary = ();
my @priority_policies = ();
my @flowrate_policies = ();
my @priorities = (4,5,6,2,1,0,7,5,6,7);
my @policies = ();

my $wan_speed  = $license{'lic_link_speed_kbps'};

print_log($ALL, "Configure WAN speed of $LINK0 - $wan_speed Kbps");
$result = execute(set_wan_speed($appliance, $LINK0, $wan_speed, $wan_speed));
print_log($ALL, $result);

if($license{'lic_dual_link'} eq $YES)
{
	print_log($ALL, "Configure WAN speed of $LINK1 - $wan_speed Kbps");
	$result = execute(set_wan_speed($appliance, $LINK1, $wan_speed, $wan_speed));
	print_log($ALL, $result);
}

my $ADAgent = "192.168.1.223";
my $ADUser = "Administrator";
my $AD_pattern_name = "cust_ad_patt_1";
my $AD_class_name = "cust_ad_class";

print_log($ALL, "Create ADAgent");
$result = execute(create_adagent($appliance, "$ADAgent"));
print_log($ALL, $result);
sleep(120); # To ensure ADAgent is created successfully and synced

print_log($ALL, "Create Class for checking ADIntegration");
$result = execute(create_pattern($appliance, $AD_pattern_name, "user: $ADUser"));
$result = execute(create_class($appliance, $AD_class_name, $LINK0, $AD_pattern_name));
print_log($ALL, $result);

print_log($ALL, "Delete ADAgent");
$result = execute(delete_classes($appliance, $AD_class_name));
$result = execute(delete_adagent($appliance, "$ADAgent"));
print_log($ALL, $result);


my $iperf_pattern_name = "cust_iperf_patt";
my $iperf_class_name = "cust_iperf_class";
my $iperf_port = 10001;

print_log($ALL, "Create iperf class");
$result = execute(create_pattern($appliance, $iperf_pattern_name, "port: $iperf_port"));
$result = execute(create_class($appliance, $iperf_class_name, $LINK0, $iperf_pattern_name));
execute(app_sync($appliance));
print_log($ALL, $result);

print_log($ALL, "Starting iperf test");
$result = execute(simple_iperf_test($appliance, $server, $client));
print_log($ALL, $result);

print_log($ALL, "Delete iperf class");
$result = execute(delete_classes($appliance, "$iperf_class_name"));
print_log($ALL, $result);


# Policy creation and assign to the classes
for(my $i = 0 ; $i <= $#class_names ; $i++)
{
	my $policy_name = "cust_prio_policy_".($i +1)."";
	my $fl_policy_name = "cust_flr_policy_".($i +1)."";
	@priority_policies[$i] = $policy_name;
	@flowrate_policies[$i] = $fl_policy_name;
	
	# Create Priority policy and flowrate policy with default values
	execute(create_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	execute(create_policy($appliance, @flowrate_policies[$i], "flowrate guaranteed 100"));
	
	# Assign only the priority policy to the classes
	execute(assign_policy($appliance, @priority_policies[$i], @class_names[$i]));
	execute(assign_policy($appliance, @flowrate_policies[$i], @class_names[$i]));
}

# Unassign Policies from classes
for(my $i = 0 ; $i <= $#flowrate_policies ; $i++)
{
	execute(unassign_policy($appliance, @priority_policies[$i], @class_names[$i]));
	execute(unassign_policy($appliance, @flowrate_policies[$i], @class_names[$i]));
}

delete_policies($appliance, @priority_policies);
delete_policies($appliance, @flowrate_policies);


# Setting max limits 
my $new_class_limit = $license{'lic_max_classes'};
my $new_flow_limit = $license{'lic_max_flows'};
my $new_flow_threshold = 95;
my $new_flow_limit_action = "reject";
my $new_pattern_limit = $license{'lic_max_policies'};
my $new_policy_limit = 1000;

execute(set_class_limit($appliance, $new_class_limit));
execute(set_flow_limit($appliance, $new_flow_limit, $new_flow_threshold, $new_flow_limit_action));
execute(set_pattern_limit($appliance, $new_pattern_limit));
execute(set_policy_limit($appliance, $new_policy_limit));

if(defined $regress)
{
	regression_tests($appliance, $root_appliance);
}

print_log($ALL, "Restore System Configurations");
$result = execute(config_restore($appliance, $ftp_path));
print_log($ALL, $result);

@comm = ("pmdump", "pmdebug", "hmon", "classdump active", "classdump nzask", "classdump nzqueue",
		"classdump nzdrop", "flowdump ipv4 all", "pmdebug", "classdump all", "memusage", "cfr status", "hmon");

collect_dpconsole_output($root_appliance, @comm);

print_log($ALL, "Show health");
$result = execute(show_health($appliance, $root_appliance));
print_log($ALL, $result);

# Closing the sessions after all the tests finished
$appliance->soft_close();
$root_appliance->soft_close();
$server->soft_close();
$client->soft_close();

my $subject = "Sanity Tests Finished for build # $version{'ver_current'}";
my $body_text = "Please find attached output and log files for the build sanity test results.";

#Removing JUNK characters from the log file
`cp $global_cfg{'log_file'} $global_cfg{'log_file'}test`;
`strings $global_cfg{'log_file'}test > $global_cfg{'log_file'}`;
`rm -f $global_cfg{'log_file'}test`;

# send email after sanity test
send_mail("$subject", "$body_text", "attach logs");

print_log($ANY, "Tests Completed\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}");
print "\nTests Completed\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}\n";

#-------------------------------------------------------------------------------

sub create_classes
{
	my ($session) = @_;
	# Creating custom class with pattern 
	for(my $i = 0; $i <= $#class_names; $i++)
	{
		my $cust_pattern_name = "cust_pattern_" . @cust_class_name[$i];
		execute(create_pattern($session, $cust_pattern_name, "port: @cust_pattern_format[$i]"));
		execute(create_class($session, @cust_class_name[$i], $LINK0, $cust_pattern_name));
	}

	execute(app_sync($session));
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub simple_iperf_test
{
	my ($app, $ser, $cli) = @_;
	my $iperf_flows = 20;
	my $traffic_duration = 100;
	my $iperf_port = 10001;
	my $pid;
	
	start_iperf_server($ser, \$pid, " -p $iperf_port ");

	my $options = "-p $iperf_port";
	start_iperf_clients($cli, \$pid, $cfg{"server_loc_eth_ip"}, $iperf_flows, $traffic_duration + 20 , 0, 0, $options);

	sleep($traffic_duration);

	get_flow_summary($app, \%flow_summary, "last_min");
	execute(collect_class_stats($app, ("$iperf_class_name")));
	
	killall($cli, "iperf");
	killall($ser, "iperf");
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub regression_tests
{
	my ($session, $root_session) = @_;
	# Turning off the print on screen of test result for regression test.
	$global_cfg{'print_output_in_screen'} = $NO;
	my $result = "";
	my $ftp_config_path = "ftp://valar:testpass\@192.168.1.26/tmp/configs";
	
	print_log($ANY, "====================== Regression Tests ======================");
	print "====================== Regression Tests ======================\n";

	print_log($ALL, "Show health");
	$result = execute(show_health($session, $root_session));
	print_log($ALL, $result);
	
	execute(show_all($appliance));
	
	print_log($ALL, "Config Backup");
	$result = config_backup($session, $ftp_config_path);
	print_log($ALL, $result);

	app_context($session);
	policy_context($session);
	global_context($session);
	system_context($session);

	show_all($session);

	print_log($ALL, "Restore System Configurations");
	$result = execute(config_restore($session, $ftp_config_path));
	print_log($ALL, $result);

	print_log($ALL, "Show health");
	$result = execute(show_health($session, $root_session));
	print_log($ALL, $result);

	return $SUCCESS;
}
#-------------------------------------------------------------------------------
