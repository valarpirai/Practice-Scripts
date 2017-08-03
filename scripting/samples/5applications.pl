#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

# Parsing the command line arguments
my $appl_name;
my $test_duration = 120;
my $httperf_timeout = 10;
my $iperf_duration = 100;
my $i = 1;
my $start = 5;
my $test_interval = 100;
my $wait = 3;

GetOptions("appl_name|a=s" => \$appl_name);
unless ($appl_name)
{
	print "Please provide the appliance name.. Which appliance?\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));

# Check bypass is off
execute_not(is_bypass_on($appliance));
execute(set_shaping_on($appliance));


my @wan_speed_in  = (10000, 45000);
my @wan_speed_out = (10000, 45000);

my @class_names = ("HTTP", "SSH", "iperf");  # Class Names

my @min_bw = (); # values in Kbps
my @burstmax = (); # values in Kbps
my @generate_traffic_at = (); # values in Kbps

my @priority_policies = ("pl1", "pl2", "pl3"); # priority policy names
my @priorities = (3, 3, 5); # priority values

execute(create_pattern($appliance, "iperf_patt", "port: 5001"));
execute(create_class($appliance, @class_names[2], $LINK0, "iperf_patt"));

# sync after create class
print $appliance "app\nsync\n\r";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync.\n");
	exit;
}


# Policy Creation
print $appliance "policy\n\r";
for($i = 0; $i < 3 ; $i++)
{
	execute(create_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	execute(assign_policy($appliance, @priority_policies[$i], @class_names[$i]));
}

my $iperf_server_pid = 0;

execute(start_iperf_server($client, \$iperf_server_pid, " -p 5001"));

# Changing WAN speeds
foreach(my $w = 0 ; $w < 2 ; $w++ )
{
	execute(set_wan_speed($appliance, $LINK0, @wan_speed_in[$w], @wan_speed_out[$w]));
	execute(set_wan_speed($appliance, $LINK1, @wan_speed_in[$w], @wan_speed_out[$w]));
	
	my $outstr = "Set wan speed IN: @wan_speed_in[$w], OUT: @wan_speed_out[$w]\n";
	my $WAN = @wan_speed_in[$w];
	
	@min_bw = (to_percentage($WAN, 40), to_percentage($WAN, 50), 0); # values in Kbps
	@burstmax = (0, 0, 0); # values in Kbps
	
	#@generate_traffic_at = (to_percentage($WAN, 20), to_percentage($WAN, 30), to_percentage($WAN, 50), to_percentage($WAN, 100), to_percentage($WAN, 100)); # values in Kbps
		
	print $appliance "policy\n\r";
	# pipe creation
	for($i = 0; $i < 3 ; $i++)
	{
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));
		$outstr = $outstr. "Set pipe min @min_bw[$i], max @burstmax[$i] to class @class_names[$i].\n";
	}
	
	show_config_verbose($appliance, @class_names);
	$httperf_timeout = 10;
	print_log($ANY, $outstr."Starting all traffic: HTTP, SSH, iperf");
	start_all_traffic($client, $server);
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);

	print_log($ANY, "Stopping iperf traffic. Running HTTP, SSH traffic");
	start_scp($client);
	start_http($client);
	unless(stop_iperf($server) eq $SUCCESS)
	{
		print_log($ANY, "Failed to stop iperf traffic.");
	}
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);
	
	print_log($ANY, "Stopping HTTP traffic. Running SSH traffic");
	start_scp($client);
	unless(stop_http($client) eq $SUCCESS)
	{
		print_log($ANY, "Failed to stop HTTP traffic.");
	}
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);

	stop_scp($client);
	#stop_all_traffic($server, $client);
	print_log($ANY, "Stopping all the traffic.");
	
	#set pipe max to c3 as 256Kbps. Start  traffic
	execute(set_pipe($appliance, 0, 1000, @class_names[2]));
	show_config_verbose($appliance, @class_names);
	
	start_all_traffic($client, $server);
	print_log($ANY, "Set pipe max 1000 to @class_names[2]. Starting all the traffic.");
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);
	
	stop_scp($client);
	print_log($ANY, "Stopping SCP traffic. Running HTTP and iperf traffic.");
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);
	
	stop_all_traffic($server, $client);
	sleep($test_interval);
	print_log($ANY, "Stopping all the traffic.");
	
	@min_bw = (0, 0, 0,); # values in Kbps
	@burstmax = (0, 0 , 0); # values in Kbps
	
	print $appliance "policy\n\r";
	for($i = 0; $i < 3 ; $i++)
	{
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));
	}
	print_log($ANY, "Reset pipe for all class and assign priority HTTP- 3, SCP- 5, iperf- 7");
	
	execute(change_policy($appliance, @priority_policies[0], "priority 3"));
	execute(change_policy($appliance, @priority_policies[1], "priority 5"));
	execute(change_policy($appliance, @priority_policies[2], "priority 7"));
	
	show_config_verbose($appliance, @class_names);
	
	start_all_traffic($client, $server);
	print_log($ANY, "Starting all traffic: HTTP, SSH, iperf");
	
	collect_stats_all_classes($appliance, @class_names);
	collect_other_info($appliance, $client, @class_names);

	stop_all_traffic($server, $client);
}

delete_classes($appliance, (@class_names[2]));
delete_policies($appliance, @priority_policies);

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();
print "Test finished.\n";
print "\nLog file : " . $global_cfg{"log_file"};
print "\nOutput file : " . $global_cfg{"output_file"}."\n";

#-------------------------------------------------------------------------------

sub start_all_traffic
{
	my ($cli_session, $ser_session) = @_;
	my $pid = 0;
	
	my $options = " -c $cfg{'client_loc_eth_ip'} -t $iperf_duration -p 5001";
	execute(start_iperf_client($ser_session, \$pid, $options));
	
	start_http($cli_session);
	
	start_scp($cli_session);
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub start_http
{
	my ($cli_session) = @_;
	my $cmd = "httperf --server $cfg{'server_loc_eth_ip'} --uri /payload.tar --rate 10 --num-conn 1000 --timeout $httperf_timeout &";
	print $cli_session "$cmd\n";
	my $match = "$cmd";
	unless($cli_session->expect(1, $match))
	{
		return $FAIL;
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub start_scp
{
	my ($cli_session) = @_;
	
	for(my $j=0; $j < 1 ; $j++)
	{
		execute(scp_file($cli_session, "$cfg{'server_username'}\@$cfg{'server_loc_eth_ip'}:$cfg{'scp_file_location'}", "/tmp/test.tar", "$cfg{'server_password'}"));
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub to_percentage
{
	my ($total, $percent) = @_;
	
	return (($total * $percent)  / 100);
}
#-------------------------------------------------------------------------------

sub stop_all_traffic
{
	my ($ser_session, $cli_session) = @_;
	
	stop_iperf($ser_session);
	stop_http($cli_session);
	stop_scp($cli_session);
	
	return $SUCCESS;
}

#-------------------------------------------------------------------------------

sub stop_iperf
{
	my ($session) = @_;
	my $cmd = "killall -9 iperf";
	for(my $i = 0 ; $i < 5 ; $i++)
	{
		print $session "$cmd\n";
		$cmd = "ps -eaf | grep iperf";
		print $session "$cmd\n";
		$session->expect($wait,"$cmd");
		unless($session->expect($wait, "grep --color=auto"))
		{
			print "Failed to get the process id.\n";
		}
		my $str = $session->before();
		my @lines = split("\n", $str);
		$cmd = "kill -9";
		foreach(@lines)
		{
			my @str1 = split(" ", $_);
			$cmd = $cmd." ".@str1[1];
		}
		print $session "$cmd\n";
		print_log($LOG, "Kill command $cmd\n");
		unless($session->expect($wait, "root"))
		{
			print " Failed to get the process id.\n";
		}
		if($session->expect($wait, "No such process"))
		{
			$i = 5;
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub stop_http
{
	my ($session) = @_;
	my $cmd = "killall -9 httperf";
	for(my $i = 0 ; $i < 5 ; $i++)
	{
		print $session "$cmd\n";
		$cmd = "ps -eaf | grep httperf";
		print $session "$cmd\n";
		$session->expect($wait,"$cmd");
		unless($session->expect($wait, "grep --color=auto"))
		{
			print "Failed to get the process id.\n";
		}
		my $str = $session->before();
		my @lines = split("\n", $str);
		$cmd = "kill -9";
		foreach(@lines)
		{
			my @str1 = split(" ", $_);
			$cmd = $cmd." ".@str1[1];
		}
		print $session "$cmd\n";
		print_log($LOG, "Kill command $cmd\n");
		unless($session->expect($wait, "root"))
		{
			print " Failed to get the process id .\n";
		}
		if($session->expect($wait, "No such process"))
		{
			$i = 5;
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub stop_scp
{
	my ($session) = @_;
	my $cmd = "killall -9 scp";
	for(my $i = 0 ; $i < 5 ; $i++)
	{
		print $session "$cmd\n";
		$cmd = "ps -eaf | grep scp";
		print $session "$cmd\n";
		$session->expect($wait,"$cmd");
		unless($session->expect($wait, "grep --color=auto"))
		{
			print "Failed to get the process id.\n";
		}
		my $str = $session->before();
		my @lines = split("\n", $str);
		$cmd = "kill -9";
		foreach(@lines)
		{
			my @str1 = split(" ", $_);
			$cmd = $cmd." ".@str1[1];
		}
		print $session "$cmd\n";
		print_log($LOG, "Kill command $cmd\n");
		unless($session->expect($wait, "root"))
		{
			print " Failed to get the process id.\n";
		}
		if($session->expect($wait, "No such process"))
		{
			$i = 5;
		}
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------


sub collect_stats_all_classes
{
	my ($session, @classes) = @_;
	my %stats = ();
	my %if_stats = ();
	sleep($test_interval);
	execute(get_link_stats($session, \%if_stats, $LINK0, "last_min"));
	
	my $report = "\nInterface Flow count - IN = $if_stats{\"ls_int_flow_count\"}, OUT = $if_stats{\"ls_ext_flow_count\"},";
	$report = $report . "Bandwidth - int = $if_stats{\"ls_int_tx_kbps\"} Kbps, ext = $if_stats{\"ls_ext_tx_kbps\"} Kbps,";
	my $data_transmitted_int = $if_stats{"ls_int_tx_bytes"} / 1000;
	my $data_transmitted_ext = $if_stats{"ls_ext_tx_bytes"} / 1000;
	$report = $report . "Bytes transferred - int = $data_transmitted_int, ext =  $data_transmitted_ext KB.\n";
	
	$report = $report . "-----------------------------------------------------\n";
	$report = $report . "Classname\t|Rate\t|Flows\t|Bytes\t\n";
	$report = $report . "-----------------------------------------------------\n";	
	foreach(@classes)
	{
		execute(get_class_stats($session, \%stats, $_, "last_min", $LINK0));
		my $data_transmitted_in = $stats{"cs_out_tx_bytes"} / 1000;
		$report = $report . "$_\t\t|$stats{\"cs_out_tx_kbps\"}\t|$stats{\"cs_out_flow_count\"}\t|$data_transmitted_in\n";
	}
	$report = $report . "-----------------------------------------------------\n";

	print_log($ANY, $report);
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub collect_other_info
{
	return $SUCCESS;
	my ($app_session, $cli_session, @classes) = @_;
	
	execute(set_shaping_off($app_session));
	print_log($ANY, "Shaping OFF:\n");
	execute(ping_test_from_client($cli_session));
	
	sleep($test_interval);
	execute(collect_stats_all_classes($app_session, @classes));
	
	execute(set_shaping_on($app_session));
	print_log($ANY, "Shaping ON:\n");
	sleep($test_interval);
	execute(ping_test_from_client($cli_session));
	
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub show_config_verbose
{
	my ($session, @classes) = @_;
	my $cmd = "app";
	print $session "$cmd\n";
	foreach(@classes)
	{
		$cmd = "show class $_ verbose link: $LINK0";
		print $session "$cmd\n";
		unless($session->expect(1, "Displaying class information"))
		{
			return "Unable to get class info.\n";
		}
	}
	$cmd = "policy";
	print $session "$cmd\n";
	$cmd = "show policy all";
	print $session "$cmd\n";
	unless($session->expect(1, "Policy >"))
	{
		return "Unable to get policy list.\n";
	}
	$cmd = "show bandwidth allocation";
	print $session "$cmd\n";
	unless($session->expect(1, "LINK -    link0"))
	{
		return "Unable to get bandwidth alloacation info.\n";
	}
	$cmd = "system\nshow interface";
	print $session "$cmd\n";
	unless($session->expect(1, "Displaying interface information"))
	{
		return "Unable to get interface info.\n";
	}

	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub ping_test_from_server
{
	my ($ser_session) = @_;
	my $cmd = "ping -c 10 ".$cfg{"client_loc_eth_ip"};
	print $ser_session "$cmd\n";
	my $match = "10 packets transmitted,";
	unless($ser_session->expect(15, $match))
	{
		return "Ping command failed.\n";
	}
	$match = "10 packets transmitted, 10 received, 0% packet loss";
	unless($ser_session->expect(1, $match))
	{
		return "Ping connection failed.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub ping_test_from_client
{
	my ($cli_session) = @_;
	my $cmd = "ping -c 10 ".$cfg{"client_loc_eth_ip"};
	print $cli_session "$cmd\n";
	my $match = "10 packets transmitted,";
	unless($cli_session->expect(15, $match))
	{
		return "Ping command failed.\n";
	}
	$match = "10 packets transmitted, 10 received, 0% packet loss";
	unless($cli_session->expect(1, $match))
	{
		return "Ping connection failed.\n";
	}
	return $SUCCESS;
}
