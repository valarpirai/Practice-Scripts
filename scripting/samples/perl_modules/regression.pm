package perl_modules::regression;

use perl_modules::common;
use strict;
use base 'Exporter';


# Add the function names in the following to make the function accessible from the .pl files
our @EXPORT = qw(
show_health
config_backup
config_restore
set_pagination_off
set_pagination_on
show_class_all
show_pattern_all
show_list_all
show_config
show_interface
show_limit
show_status
show_bandwidth_allocation
show_policy_all
show_filter_all
show_config_AD
show_config_users
show_config_syslog
show_config_hostmapping
show_config_ssh
show_config_time
show_all
config_user_tests
config_mgmt_port
config_ntp
config_syslog
syslog_backup
global_set_limit
set_discovery_on
set_discovery_off
app_context
change_class_name
change_class_type
create_list
delete_list
create_filter
delete_filter
assign_pattern
set_admission_control
show_policy
create_all_type_of_policy
policy_context
global_context
system_context
add_hostname_map_range
del_hostname_map_range
);

my $timeout = 3;
my $sleeptime = 3;
my $shorttimeout = 1;
my $longtimeout = 30;
#-------------------------------------------------------------------------------

sub show_health
{
	my ($session, $root_session) = @_;
	my @com = ("hmon", "pmdump", "pmdebug", "flowdump", "memusage", "hmon", "dprx");
	
	collect_dpconsole_output($root_session, @com);
	show_status($session);
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

#Do backup first and do all the tests
sub config_backup
{
	my ($session, $path) = @_;
	my $localtimeout = $longtimeout;
	
	my $cmd = "system\nconfig backup $path\n";

	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";

	my $match = "Configuration saved to $path successfully";
	unless($session->expect($localtimeout, "$match"))
	{
		return "Failed to backup the system configurations to $path.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

# After all tests finished restore the config
sub config_restore
{
	my ($session, $path) = @_;
	my $localtimeout = $longtimeout;
	
	my $cmd = "system\nconfig restore $path\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";

	my $match = "Are you sure you want to overwrite running configuration with the one from $path? Yes/No";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to restore the system configurations.\n";
	}
	
	$cmd = "yes\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configuration restored from $path successfully";
	unless($session->expect($localtimeout, "$match"))
	{
		return "Failed to restore the system configurations from $path.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_pagination_off
{
	my ($session) = @_;
	my $cmd = "global\nset pagination off\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	my $match = "Global >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to turn off pagination.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_pagination_on
{
	my ($session) = @_;
	my $cmd = "global\nset pagination on\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	my $match = "Global >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to turn on pagination.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_class_all
{
	my ($session) = @_;
	my $cmd = "app\nshow class all verbose\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd\n";
	# Expecting the starting header
	unless($session->expect($timeout, "-re", "show class all verbose\n-+\n\|Name.*\n[-]+.*"))
	{
		return "Not able to get the show class all output.\n";
	}
	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show class all output.\n";
	}
	
	my $match = "App >";
	unless($session->expect($timeout, "$match"))
	{
		return "Command 'show class all verbose' failed.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_pattern_all
{
	my ($session) = @_;
	my $cmd = "app\nshow pattern all\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	unless($session->expect($timeout, "-re", "show pattern all\nDisplaying.*\n-+\n\|Name.*\n-.*"))
	{
		return "Not able to get the show pattern all output.\n";
	}
	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show pattern all output.\n";
	}
	
	my $match = "App >";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show pattern all failed.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_list_all
{
	my ($session) = @_;
	my $cmd = "app\nshow list all\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	unless($session->expect($timeout, "-re", "show list all\n-+\n\|Name.*\n-.*"))
	{
		return "Not able to get the show list all output.\n";
	}
	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show list all output.\n";
	}
	
	my $match = "App >";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show list all failed.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config
{
	my ($session) = @_;
	my $cmd = "system\nshow config\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Displaying system configurations";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show config failed.\n";
	}
	
	$match = "Bypass";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show config failed.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_interface
{
	my ($session) = @_;
	my $cmd = "system\nshow interface\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "MGMT";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show interface failed.\n";
	}
	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show interface output.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_limit
{
	my ($session) = @_;
	my $cmd = "global\nshow limit\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Pattern";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show limit failed\n";
	}
	
	$match = "Global >";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show limit failed\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_status
{
	my ($session) = @_;
	my $cmd = "system\nshow status\nshow status cpu\nshow status disk\nshow status memory\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Log Disk:";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show status failed.\n";
	}
	
	$match = "Memory:";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show status disk failed\n";
	}
	
	$match = "System >";
	unless($session->expect($timeout, "$match"))
	{
		return "Command show status memory failed\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_bandwidth_allocation
{
	my ($session) = @_;
	my $cmd = "policy\nshow bandwidth allocation\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "WAN Speed";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get bandwidth allocation.\n";
	}
	
	$match = "Policy >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get end of bandwidth allocation.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_policy_all
{
	my ($session) = @_;
	my $cmd = "policy\nshow policy all\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	unless($session->expect($timeout, -re,"show policy all\n-+\n\|Name.*\n-.*"))
	{
		return "Failed to get policy list.\n";
	}	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show policy all output.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_filter_all
{
	my ($session) = @_;
	my $cmd = "policy\nshow filter all\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Policy >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get filter list.\n";
	}
	$match = "Policy >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get end of filter list.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_AD
{
	my ($session) = @_;
	my $cmd = "system\nshow config ADintegration\nshow ADAgents\nshow ADUsers\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Displaying ADAgent(s) information";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get ADintegration config.\n";
	}
	
	$match = "System >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get ADAgents list.\n";
	}
	
	$match = "System >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get ADUsers list.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_users
{
	my ($session) = @_;
	my $cmd = "system\nshow config users\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Displaying information for";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get Users list.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_syslog
{
	my ($session) = @_;
	my $cmd = "system\nshow config syslog\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Flow Threshold";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get config syslog.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_hostmapping
{
	my ($session) = @_;
	my $cmd = "system\nshow config HostMapping\nshow HostNameMapping\nshow HostMapRange\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Hostname Table Status";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get config HostMapping.\n";
	}
	
	$match = "Start IP address";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get HostNames Map.\n";
	}

	$match = "System >";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get HostMap Ranges.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_ssh
{
	my ($session) = @_;
	my $cmd = "system\nshow config ssh\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Portnumber";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get config SSH.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_time
{
	my ($session) = @_;
	my $cmd = "system\nshow config time\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "NTP Server";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to get config TIME.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_all
{
	my ($session) = @_;
	
	print_log($ALL, "Show Class All");
	my $result = execute(show_class_all($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show Pattern All");
	$result = execute(show_pattern_all($session));
	print_log($ALL, $result);

	print_log($ALL, "Show list all");
	$result = execute(show_list_all($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config");
	$result = execute(show_config($session));
	print_log($ALL, $result);

	print_log($ALL, "Show interface");
	$result = execute(show_interface($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show limit");
	$result = execute(show_limit($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show status");
	$result = execute(show_status($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show Bandwidth allocation");
	$result = execute(show_bandwidth_allocation($session));
	print_log($ALL, $result);

	print_log($ALL, "Show Policy all");
	$result = execute(show_policy_all($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show filter all");
	$result = execute(show_filter_all($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config SSH");
	$result = execute(show_config_ssh($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config time");
	$result = execute(show_config_time($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config AD");
	$result = execute(show_config_AD($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config users");
	$result = execute(show_config_users($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config syslog");
	$result = execute(show_config_syslog($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config HostnameMapping");
	$result = execute(show_config_hostmapping($session));
	print_log($ALL, $result);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub config_user_tests
{
	my ($session) = @_;
	my $user = "sanity_user";
	my $pass = "sanity123";
	my $puser = "sanity_pri_user";
	my $ppass = "sanitypri123";
	my $result;
	
	print_log($ALL, "Add normal user");
	$result = execute(add_user($session, $user, "normal", $pass));
	print_log($ALL, $result);
	
	print_log($ALL, "Add privileged user");
	$result = execute(add_user($session, $puser, "privileged", $ppass));
	print_log($ALL, $result);
	
	print_log($ALL, "Config password");
	$result = execute(change_password($session, $user, $ppass));
	print_log($ALL, $result);
	
	print_log($ALL, "Show config users");
	$result = execute(show_config_users($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Login using the newly created privileged user");
	$result = login($cfg{"appliance_ip"}, $puser, $ppass);
	
	if(not defined $result)
	{
		$result = $SUCCESS;
	}else
	{
		$result = $FAIL;
	}
	print_log($ALL, $result);
	
	print_log($ALL, "Login using the newly created normal user");
	$result = login($cfg{"appliance_ip"}, $user, $pass);
	if(not defined $result)
	{
		$result = $SUCCESS;
	}else
	{
		$result = $FAIL;
	}
	print_log($ALL, $result);
	
	print_log($ALL, "Delete normal user");
	$result = execute(delete_user($session, $user));
	print_log($ALL, $result);

	print_log($ALL, "Delete privileged user");
	$result = execute(delete_user($session, $puser));
	print_log($ALL, $result);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub config_mgmt_port
{
	my ($session) = @_;
	my $localtimeout = $longtimeout;
	my $cmd = "system\nconfig mgtport speed 10\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Configured management port speed to 10M successfully";
	unless($session->expect($localtimeout, "$match"))
	{
		return "Failed to configure Management port to 10M.\n";
	}
	
	$cmd = "config mgtport speed 100\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configured management port speed to 100M successfully";
	unless($session->expect($localtimeout, "$match"))
	{
		return "Failed to configure Management port to 100M.\n";
	}

	$cmd = "config mgtport speed auto\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configured management port speed successfully";
	unless($session->expect($localtimeout, "$match"))
	{
		return "Failed to configure Management port to auto.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub config_ntp
{
	my ($session) = @_;
	my $ntpserver = "time-c.nist.gov";
	
	my $cmd = "system\nshow config time\nconfig ntp on\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Configured ntp successfully";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to configure NTP.\n";
	}
	
	$cmd = "config ntp server $ntpserver\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configured ntp server ip to $ntpserver successfully";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to add NTP server ($ntpserver).\n";
	}

	$cmd = "show config time\n";
		
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "$ntpserver";
	unless($session->expect($timeout, "$match"))
	{
		return "NTP server ($ntpserver) is not added in the list.\n";
	}

	$cmd = "config ntp delete $ntpserver\n";
		
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Removed ntp server ip $ntpserver successfully";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to delete NTP server ($ntpserver).\n";
	}
	
	$cmd = "show config time\n";
		
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "$ntpserver";
	if($session->expect($timeout, "$match"))
	{
		return "NTP server ($ntpserver) is not deleted from the list.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub config_syslog
{
	my ($session) = @_;
	my $email_id = "test\@gmail.com";
	my $remote_server = "192.168.1.204";
	my $log_level = "notice";
	my $threshold = 75;
	
	show_config_syslog($session);
	
	my $cmd = "system\nsyslog email add $email_id\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Configured $email_id target for syslog successfully.";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to add Email-id for syslog.\n";
	}
	
	$cmd = "syslog email level $log_level\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configured email target for syslog successfully. Messages at higher level than $log_level will be sent to the configured email address.";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to change log level for Email.\n";
	}
	
	$cmd = "syslog remote ip $remote_server\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Added syslog server $remote_server successfully";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to add remote syslog server ($remote_server).\n";
	}
	
	$cmd = "syslog remote level $log_level\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Configured remote server target for syslog successfully. Messages at higher level than $log_level will be sent to the configured remote server.";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to change log level for remote.\n";
	}

	$cmd = "syslog threshold cpu $threshold\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "CPU utilization threshold set to $threshold successfully for syslog";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to set cpu threshold to $threshold.\n";
	}
	
	$cmd = "syslog threshold disk $threshold\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Disk utilization threshold set to $threshold successfully for syslog";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to set disk utilization threshold to $threshold.\n";
	}
	
	$cmd = "syslog threshold flows $threshold\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Threshold for flow count set to $threshold successfully for syslog";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to set flows count threshold to $threshold.\n";
	}
	
	$cmd = "syslog threshold mem $threshold\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Memory utilization threshold set to $threshold successfully for syslog";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to set Memory utilization threshold to $threshold.\n";
	}
	
	show_config_syslog($session);
	
	$cmd = "syslog email delete $email_id\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Deleted $email_id target for syslog successfully.";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to delete syslog Email id ($email_id).\n";
	}
	
	$cmd = "system\nsyslog remote delete $remote_server\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	$session->expect($timeout, "System >");
	
	$match = "Deleted syslog server $remote_server successfully";
	$session->expect($timeout, $match);
	unless($session->expect($timeout, "System >"))
	{
		return "Failed to delete syslog server ($remote_server).\n";
	}

	show_config_syslog($session);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub syslog_backup
{
	my ($session, $destination) = @_;
	
	my $cmd = "system\nsyslog backup $destination\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Syslog files saved to $destination successfully";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to backup syslog file to $destination.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub global_set_limit
{
	my ($session) = @_;
	my %license = ();
	
	my $threshold = 95;
	my $limit_action = "passthrough";
	my $result = "";
	
	show_limit($session);
	get_license($session, \%license);
	
	print_log($ALL, "Set Class limit");
	$result = execute(set_class_limit($session, $license{'lic_max_classes'}));
	print_log($ALL, $result);
	
	print_log($ALL, "set Flow limit");
	$result = execute(set_flow_limit($session, $license{'lic_max_flows'}, $threshold , $limit_action));
	print_log($ALL, $result);
	
	print_log($ALL, "Set policy limit");
	$result = execute(set_policy_limit($session, $license{'lic_max_policies'}));
	print_log($ALL, $result);
	
	print_log($ALL, "Show limit");
	$result = execute(show_limit($session));
	print_log($ALL, $result);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_discovery_on
{
	my ($session) = @_;
	my $localtimeout = $longtimeout;
	# Check shaping is on, unless turn on it
	my $cmd = "app\nset discovery on\n";
	print_log($LOG, "CMD : $cmd");
	unless(is_discovery_on($session) eq $SUCCESS)
	{
		print $session "$cmd";
		my $match = "Discovery set to on successfully";
		unless($session->expect($localtimeout, "$match"))
		{
			return "Failed to turn on Discovery.\n";
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_discovery_off
{
	my ($session) = @_;
	# Check shaping is off, unless turn off it
	my $cmd = "app\nset discovery off\n";
	print_log($LOG, "CMD : $cmd");
	unless(is_discovery_on($session) ne $SUCCESS)
	{
		print $session "$cmd";
		my $match = "Discovery set to off successfully";
		unless($session->expect($timeout, "$match"))
		{
			return "Failed to turn off Discovery.\n";
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub app_context
{
	my ($session) = @_;
	
	# TODO : refclass: $ref_class_name
	
	my $url_name = "www.tester.com";
	my $port = 10000;
	my $srcport = 34240;
	my $dstport = 45000;
	my $ip_addr = $cfg{"server_loc_eth_ip"};
	my $srcip_addr = $cfg{"client_loc_eth_ip"};
	my $dstip_addr = $cfg{"server_loc_eth_ip"};
	my $protocol = "udp";
	my $vlan_id = 4095;
	my $mpls_label = 1048575;
	my $dscp_value = 50;
	my $ref_class_name = "Google";
	
	my $i = 0;
	my $check = "PASS";
	my $link = $LINK0;
	my $result = "";
	
	my @src_ip_list = ();
	my @dst_ip_list = ();
	my @ip_list = ();
	my @list_names = ("ll_1", "ll_2", "ll_3", "ll_4");
	
	print_log($ALL, "Set Discovery off");
	$result = execute(set_discovery_off($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Set Discovery on");
	$result = execute(set_discovery_on($session));
	print_log($ALL, $result);
	
	
	#Creating ip lists
	for(my $j = 101 ; $j <= 110; $j++)
	{
		push @src_ip_list, int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255));
		push @dst_ip_list, int(rand(255)) . "." . int(rand(255)) . ".$j." . int(rand(255));
		push @ip_list, int(rand(255)) . "." . int(rand(255)) . "." . int(rand(255)). ".$j";
	}
	
	print_log($ALL, "Create Lists");
	$result = execute(create_list($session, @list_names[0], "ip", @src_ip_list));
	if($result ne $SUCCESS)
	{
		print_log($ALL, $result);
	}
	$result = execute(create_list($session, @list_names[1], "ip", @dst_ip_list));
	if($result ne $SUCCESS)
	{
		print_log($ALL, $result);
	}
	$result = execute(create_list($session, @list_names[2], "ip", @ip_list));
	print_log($ALL, $result);
	
	print_log($ALL, "Show list all");
	$result = execute(show_list_all($session));
	print_log($ALL, $result);
	
	my @custom_classes = ();
	my @custom_patterns = ();
	my @pattern_format = ("url: $url_name", "port: $port", "ip: $ip_addr", "srcport: $srcport",
	"srcip: $srcip_addr", "dstport: $dstport", "dstip: $dstip_addr","ipproto: $protocol",
	"vlanid: $vlan_id", "mpls: $mpls_label", "dscp: $dscp_value", "srciplist: $list_names[0]",
	"dstiplist: $list_names[1]", "iplist: $list_names[2]");
	
	print_log($ALL, "Creating classes with different type of patterns");
	foreach(@pattern_format)
	{
		my $pattern_type = $_;
		$custom_patterns[$i] = "patt_custom_" . $i;
		$custom_classes[$i] = $custom_patterns[$i] . "_class"; 
		
		$result = execute(create_pattern($session, $custom_patterns[$i], $pattern_type));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
		$result = execute(create_class($session, $custom_classes[$i], $link, $custom_patterns[$i]));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
		$i++;
	}
	
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}
	
	my $choose = int(rand($#custom_patterns - 3)) + 1;
	
	print_log($ALL, "Creating patterns list");
	$result = create_list($session, @list_names[3], "pattern", @custom_patterns[0..$choose]);
	print_log($ALL, $result);
	
	my $custom_class_name = "Test_list_pattern_class";
	$custom_classes[$i] = $custom_class_name;
	
	print_log($ALL, "Creating class using Pattern list");
	$result = execute(create_class($session, $custom_class_name, $link, $list_names[3], undef, "list"));
	print_log($ALL, $result);

	$choose = int(rand($#custom_classes));
	my $choose_1 = int(rand($#custom_classes));

	print_log($ALL, "Assigning pattern $custom_patterns[$choose] to class $custom_classes[$choose_1]");
	$result = execute(assign_pattern($session, $custom_classes[$choose] , $custom_patterns[$choose_1]));
	print_log($ALL, $result);
	
	print_log($ALL, "Sync after creating the classes");
	$result = execute(app_sync($session));
	print_log($ALL, $result);
	
	$choose = int(rand($#custom_classes));
	
	$custom_class_name = "class_with_pattern_list";
	
	print_log($ALL, "Changing class name $custom_classes[$choose] to $custom_class_name");
	$result = execute(change_class_name($session, $custom_classes[$choose], $custom_class_name));
	$custom_classes[$choose] = $custom_class_name;
	print_log($ALL, $result);
	
	print_log($ALL, "Changing the classtype of class $custom_classes[$choose] to ContentDelivery");
	$result = execute(change_class_type($session, $custom_classes[$choose], "ContentDelivery"));
	print_log($ALL, $result);



	print_log($ALL, "Deleting the created classes");
	$result = execute(delete_classes($session, @custom_classes));
	print_log($ALL, $result);
		
	$check = "PASS";
	print_log($ALL, "Deleting the created lists");
	foreach(@list_names)
	{
		$result = execute(delete_list($session, $_));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
	}
	
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub change_class_name
{
	my ($session, $src_name, $dst_name) = @_;
	
	my $cmd = "app\nset name $src_name $dst_name\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Updated class name for class $src_name successfully to $dst_name";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to rename class $src_name to $dst_name.\n";
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub change_class_type
{
	my ($session, $class_name, $type) = @_;
	
	my $cmd = "app\nset type $class_name $type\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	my $match = "Updated class type to $type for class $class_name successfully.";
	unless($session->expect($timeout, "$match"))
	{
		return "Failed to change type of the class $class_name to $type.\n";
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub create_list
{
	my($session, $list_name, $list_type, @list_items) = @_;
	
	unless($list_type)
	{
		return "List type is a mandatory param. Specify the list type.(ip or pattern list)\n";
	}
	if(lc($list_type) eq "ip")
	{
		$list_type = "iplist";
	}else
	{
		$list_type = "patternlist";
	}
	
	my $cmd = "app\nnew list $list_name $list_type " . join(" ", @list_items) . "\napp\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	sleep(1);
	my $match = "New list $list_name created successfully";
	unless ($session->expect($timeout, "$match"))
	{
		return "Not able to create list $list_name\n";
	}
	$session->expect($timeout, "App >");
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub delete_list
{
	my($session, $list_name) = @_;
	
	my $cmd = "app\ndelete list $list_name\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Deleted list $list_name successfully";
	unless ($session->expect($timeout, "$match"))
	{
		return "Not able to delete list $list_name\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub create_filter
{
	my($session, $filter_name, $filter_format, $filter_action) = @_;
	my $localtimeout = $longtimeout;
	my $cmd = "policy\nnew filter $filter_name $filter_format $filter_action\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Created new filter $filter_name successfully.";
	unless ($session->expect($localtimeout, "$match"))
	{
		return "Failed to create filter $filter_name\n";
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub delete_filter
{
	my($session, $filter_name) = @_;
	my $localtimeout = $longtimeout;
	my $cmd = "policy\ndelete filter $filter_name\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Filter $filter_name deleted successfully.";
	
	if(lc($filter_name) eq "all")
	{
		$match = "All Filters deleted successfully.";
	}
	
	unless ($session->expect($localtimeout, "$match"))
	{
		return "Failed to delete filter $filter_name\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub assign_pattern
{
	my($session, $class_name, $pattern_name) = @_;
	
	my $cmd = "app\nassign pattern $pattern_name $class_name\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Assigned pattern $pattern_name to $class_name successfully. Please use sync command to activate new pattern";
	
	unless ($session->expect($timeout, "$match"))
	{
		return "Failed to assign pattern $pattern_name to class $class_name.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub set_admission_control
{
	my($session, $class_name, $control_type) = @_;
	
	my $cmd = "policy\nadmission-control $class_name $control_type\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Added admission control for $class_name successfully.";
	
	unless ($session->expect($timeout, "$match"))
	{
		return "Failed to set admission control \"$control_type\" to class $class_name.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_policy
{
	my ($session, $policy_name) = @_;
	my $cmd = "policy\nshow policy $policy_name\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	unless($session->expect($timeout, -re,"show policy.*\n-+\n\|Name.*\n-.*"))
	{
		return "Failed to show policy.\n";
	}	
	# Expecting the ending header
	unless($session->expect($timeout, "-re", "^[-]+"))
	{
		return "Not able to get end of show policy $policy_name output.\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub create_all_type_of_policy
{
	my ($session) = @_;
	
	my @policies = ();
	
	my @policy_type = ("passthrough", "drop", "priority 5", "flowrate guaranteed 1000", 
	"flowrate guaranteed 100 burst: 1000 priority: 4", "mpls 1000", "dscp 10", "tos 20", 
	"vlan-prio 7", "vlan-switch swap: 2000", "flowrate inbound guaranteed 1000", 
	"flowrate inbound guaranteed 300 burst: 1000 priority: 5", "flowrate outbound guaranteed 500", 
	"flowrate outbound guaranteed 600 burst: 3000 priority: 4");
	
	my $result;
	my $check = "PASS";
	
	print_log($ALL, "Creating all type of policies");
	for(my $j = 0; $j <= $#policy_type; $j++)
	{
		@policies[$j] = "all_type_policy_" . $j;
		$result = execute(create_policy($session, $policies[$j], $policy_type[$j]));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
	}
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}	
	
	print_log($ALL, "Show Policy all");
	$result = execute(show_policy_all($session));
	print_log($ALL, $result);
	
	@policy_type = ("passthrough", "drop", "priority 7", "flowrate guaranteed 2000", 
	"flowrate guaranteed 500 burst: 1500 priority: 6", "mpls 2000", "dscp 40", "tos 60", 
	"vlan-prio 1", "vlan-switch swap: 4000", "flowrate inbound guaranteed 2000", 
	"flowrate inbound guaranteed 500 burst: 1500 priority: 6", "flowrate outbound guaranteed 1500", 
	"flowrate outbound guaranteed 700 burst: 3500 priority: 2");
	
	$check = "PASS";
	
	print_log($ALL, "Changing the created policies");
	for(my $j = 2; $j <= $#policy_type; $j++)
	{
		$result = execute(change_policy($session, $policies[$j], $policy_type[$j]));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
	}
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}
	
	my @classes = ("HTTP", "SSL", "Google", "Apple", "Akamai");
	my $choose = int(rand($#classes - 1)) + 1;
	
	$check = "PASS";
	print_log($ALL, "Assigning policies");
	for(my $j = 0; $j <= $choose; $j++)
	{
		$result = execute(assign_policy($session, $policies[$j], $classes[$j]));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
	}
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}
	
	
	$check = "PASS";
	print_log($ALL, "Unassigning policies");
	for(my $j = 0; $j <= $choose; $j++)
	{
		$result = execute(unassign_policy($session, $policies[$j], "all"));
		if($result ne $SUCCESS)
		{
			$check = $result;
		}
	}
	if($check eq "PASS")
	{
		print_log($ALL, $result);
	}else
	{
		print_log($ALL, "FAIL");
	}
	
	$choose = int(rand($#policies));
	
	print_log($ALL, "Show policy $policies[$choose]");
	$result = execute(show_policy($session, $policies[$choose]));
	print_log($ALL, $result);
	
	print_log($ALL, "Deleting created policies");
	$result = execute(delete_policies($session, @policies));
	print_log($ALL, $result);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub policy_context
{
	my ($session) = @_;
	my $result = "";
	# Check shaping is on, unless turn on shaping
	print_log($ALL, "Set shaping off");
	$result = execute(set_shaping_off($session));
	print_log($ALL, $result);

	print_log($ALL, "Set shaping on");
	$result = execute(set_shaping_on($session));
	print_log($ALL, $result);
	
	create_all_type_of_policy($session);
	
	print_log($ALL, "Admission control");
	$result = execute(set_admission_control($session, "HTTP", "reject"));
	print_log($ALL, $result);
	
	my @filters = ("test_filter_1", "test_filter_2", "test_filter_3");
	
	my $filter_url = "www.google.com";
	my $filter_ipv4 = $cfg{'server_loc_eth_ip'};
	my $filter_ipv6 = $cfg{'server_loc_eth_ipv6'};
	
	print_log($ALL, "Create filter URL");
	$result = execute(create_filter($session, @filters[0], "url: $filter_url" , "deny"));
	print_log($ALL, $result);
	
	print_log($ALL, "Create filter IPv4");
	$result = execute(create_filter($session, @filters[1], "ip: $filter_ipv4" , "deny"));
	print_log($ALL, $result);
	
	print_log($ALL, "Create filter IPv6");
	$result = execute(create_filter($session, @filters[2], "ip: $filter_ipv6" , "deny"));
	print_log($ALL, $result);
	
	print_log($ALL, "Show filter all");
	$result = execute(show_filter_all($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Delete filter URL");
	$result = execute(delete_filter($session, @filters[0]));
	print_log($ALL, $result);
	
	print_log($ALL, "Delete filter IPv4");
	$result = execute(delete_filter($session, @filters[1]));
	print_log($ALL, $result);
	
	print_log($ALL, "Delete filter IPv6");
	$result = execute(delete_filter($session, @filters[2]));
	print_log($ALL, $result);
	
	my $pipe_min = 1000;
	my $pipe_max = 2000;
	my $pipe_class = "FTP";
	my $pipe_in_class = "SIP";
	my $pipe_out_class = "SMTP";
	
	my $check = "PASS";
	print_log($ALL, "Set pipe");
	$result = execute(set_pipe($session, $pipe_min, $pipe_max, $pipe_class));
	print_log($ALL, $result);
	
	print_log($ALL, "Set pipe inbound");
	$result = execute(set_pipe($session, $pipe_min, $pipe_max, $pipe_in_class, " inbound "));
	print_log($ALL, $result);
	
	print_log($ALL, "Set pipe outbound");
	$result = execute(set_pipe($session, $pipe_min, $pipe_max, $pipe_out_class, " outbound "));
	print_log($ALL, $result);
	
	print_log($ALL, "Show bandwidth allocation");
	$result = execute(show_bandwidth_allocation($session));
	print_log($ALL, $result);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub global_context
{
	my ($session) = @_;
	my %if_stats = ();
	
	print_log($ALL, "Set pagination on");
	my $result = execute(set_pagination_on($session));
	print_log($ALL, $result);

	print_log($ALL, "set pagination off");
	$result = execute(set_pagination_off($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Show interface stats link0");
	$result = execute(get_link_stats($session, \%if_stats, $LINK0, "last_min"));
	print_log($ALL, $result);

	print_log($ALL, "Show interface stats link1");
	$result = execute(get_link_stats($session, \%if_stats, $LINK1, "last_min"));
	print_log($ALL, $result);
	
	global_set_limit($session);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub system_context
{
	my ($session) = @_;
	my %license = ();
	my $ADAgent = "192.168.1.223";
	my $HostName_start = "192.168.1.1";
	my $HostName_end = "192.168.1.254";
	my $wan_speed  = "10000";
	my $ftp_path = "ftp://valar:testpass\@192.168.1.26/tmp/syslogs";
	
	get_license($session, \%license);
	
	$wan_speed = $license{'lic_link_speed_kbps'};
	print_log($ALL, "Configure WAN speed of $LINK0 - $wan_speed Kbps");
	my $result = execute(set_wan_speed($session, $LINK0, $wan_speed, $wan_speed));
	print_log($ALL, $result);

	if($license{'lic_dual_link'} eq $YES)
	{
		print_log($ALL, "Configure WAN speed of $LINK1 - $wan_speed Kbps");
		$result = execute(set_wan_speed($session, $LINK1, $wan_speed, $wan_speed));
		print_log($ALL, $result);
	}
	
	config_user_tests($session);

	print_log($ALL, "Create ADAgent");
	$result = execute(create_adagent($session, "$ADAgent"));
	print_log($ALL, $result);

	sleep(120); # To ensure ADAgent is created successfully and synced

	print_log($ALL, "Show config AD integration");
	$result = execute(show_config_AD($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Delete ADAgent");
	$result = execute(delete_adagent($session, "$ADAgent"));
	print_log($ALL, $result);

	print_log($ALL, "Add HostnameMap range");
	$result = execute(add_hostname_map_range($session, $HostName_start, $HostName_end));
	print_log($ALL, $result);

	print_log($ALL, "Show config HostnameMapping");
	$result = execute(show_config_hostmapping($session));
	print_log($ALL, $result);
	
	print_log($ALL, "Delete HostnameMap range");
	$result = execute(del_hostname_map_range($session, $HostName_start, $HostName_end));
	print_log($ALL, $result);
	
	print_log($ALL, "Configure Management port");
	$result = execute(config_mgmt_port($session));
	print_log($ALL, $result);

	print_log($ALL, "Configure ntp");
	$result = execute(config_ntp($session));
	print_log($ALL, $result);

	print_log($ALL, "Backup syslog");
	$result = execute(syslog_backup($session, $ftp_path));
	print_log($ALL, $result);
	
	print_log($ALL, "Configure syslog");
	$result = execute(config_syslog($session));
	print_log($ALL, $result);

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub add_hostname_map_range
{
	my ($session, $start_ip, $end_ip) = @_;
	
	my $cmd = "system\nshow HostMapRange\n";
	my $match = "";
	if($session->expect($timeout, "-re", "\|$start_ip.*\|$end_ip.*"))
	{
		del_hostname_map_range($session, $start_ip, $end_ip);
	}
	
	$cmd = "config HostMapping status: on\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	$match = "Hostname mapping configured successfully.";
	$session->expect($timeout, "$match");
	
	$cmd = "add HostMapRange start: $start_ip end: $end_ip\n";
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	$match = "Hostname Mapping IP address Range $start_ip-$end_ip added successfully.";
	unless ($session->expect($timeout, "$match"))
	{
		return "Failed to add HostMapRange $start_ip-$end_ip\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub del_hostname_map_range
{
	my ($session, $start_ip, $end_ip) = @_;
	
	my $cmd = "system\ndelete HostMapRange start: $start_ip end: $end_ip\n";
	
	print_log($LOG, "CMD : $cmd");
	print $session "$cmd";
	
	my $match = "Hostname Mapping IP address Range $start_ip-$end_ip deleted successfully.";
	
	unless ($session->expect($timeout, "$match"))
	{
		return "Failed to delete HostMapRange $start_ip-$end_ip\n";
	}
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

=app_show_flow ................. PASS
app_show_flow_summary ................. PASS
app_show_flow_summary active ................. PASS
app_show_stats_class FTP ................. PASS

sys_config_restore ................. PASS

=cut
#-------------------------------------------------------------------------------

1;
