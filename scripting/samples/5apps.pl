#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

my $appl_name;
my $test_duration = 500;
my $i = 1;
my $start = 5;
my $test_interval = 100;
my @class_port = (80, 443, 21, 445, 5001);

# Parsing the command line arguments
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

my @class_names = ("HTTP", "SSL", "FTP", "SMB", "iperf");  # Class Names
my @pattern_names = ("patt_1", "patt_2", "patt_3", "patt_4", "patt_5"); # pattern names
my @pattern_formats = ("port: 5001", "port: 5002", "port: 5003", "port: 5004", "port: 5005"); # pattern format

my @min_bw = (); # values in Kbps
my @burstmax = (); # values in Kbps
my @generate_traffic_at = (); # values in Kbps

my @priority_policies = ("pl1", "pl2", "pl3", "pl4", "pl5"); # priority policy names
my @priorities = (3, 3, 3, 3, 6); # priority values



for($i = 5 ; $i < 5 ; $i++)
{
	execute(create_pattern($appliance, @pattern_names[$i], @pattern_formats[$i]));
	execute(create_class($appliance, @class_names[$i], $LINK0, @pattern_names[$i]));
}

# sync after create class
print $appliance "app\nsync\n\r";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync.\n");
}

# Policy Creation
print $appliance "policy\n\r";
for($i = 0 ; $i < 5 ; $i++)
{
	execute(create_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	execute(assign_policy($appliance, @priority_policies[$i], @class_names[$i]));
}

my @iperf_server_pid = (0, 0, 0, 0, 0);
my @iperf_client_pid = (0, 0, 0, 0, 0);
#Stop other servers like httpd, ftp , smb before starting iperf servers
stop_other_service($server);
# Start iperf server listening on 5001 and 5005 ports
foreach($i = 0; $i < 5 ;$i++)
{
	execute(start_iperf_server($server, \@iperf_server_pid[$i], " -p @class_port[$i]"));
}

# Changing WAN speeds
foreach(my $w = 0 ; $w < 2 ; $w++ )
{
	my $wan_idx = ($w % 2);
	execute(set_wan_speed($appliance, $LINK0, @wan_speed_in[$wan_idx], @wan_speed_out[$wan_idx]));
	execute(set_wan_speed($appliance, $LINK1, @wan_speed_in[$wan_idx], @wan_speed_out[$wan_idx]));
	
	print_log($ANY, "set wan speed IN: @wan_speed_in[$wan_idx], OUT: @wan_speed_out[$wan_idx]");
	my $WAN = @wan_speed_in[$wan_idx];
	
	@min_bw = (to_percentage($WAN, 20), to_percentage($WAN, 30), to_percentage($WAN, 50), 0 , 0); # values in Kbps
	@burstmax = (0, 0 , 0, 0, 0); # values in Kbps
	
	#@generate_traffic_at = (to_percentage($WAN, 20), to_percentage($WAN, 30), to_percentage($WAN, 50), to_percentage($WAN, 100), to_percentage($WAN, 100)); # values in Kbps
	
	show_config_verbose($appliance, @class_names);
	
	my $outstr = "";
	print $appliance "policy\n\r";
	# pipe creation
	for($i = 0; $i < 5 ; $i++)
	{
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));
		$outstr = $outstr. "Set pipe min @min_bw[$i], max @burstmax[$i] to class @class_names[$i].\n";
	}
	print_log($ANY, $outstr."\n Starting all traffic:");
	start_iperf($appliance, $client, @class_port);
	
	#stop c1 traffic
	print_log($ANY, "Stop HTTP traffic.");
	@class_port = (443, 21, 445, 5001);
	start_iperf($appliance, $client, @class_port);
	

	#stop c4 and c5 traffic
	print_log($ANY, "Stop SMB and iperf traffic");
	@class_port = (443, 21);
	start_iperf($appliance, $client, @class_port);
	
	
	#give priority 4 to c2
	execute(change_policy($appliance, @priority_policies[1], "priority 4"));
	print_log($ANY, "Set priority 4 to SSL and Start SSL, FTP traffic");
	
	@class_port = (80, 443, 21, 5001);
	start_iperf($appliance, $client, @class_port);
	
	
	#set pipe max to c4 as 256Kbps. Start c4 and c5 traffic
	execute(set_pipe($appliance, 0, 256, @class_names[3]));
	show_config_verbose($appliance, (@class_names[3]));
	print_log($ANY, "Set Pipe Max 256 to class SMB and Start SMB, iperf");
	
	@class_port = (445, 5001);
	start_iperf($appliance, $client, @class_port);
	
	#set pipe max to c1 as 60%WAN and start c1 traffic
	execute(set_pipe($appliance, @min_bw[0], to_percentage($WAN, 60), @class_names[0]));
	show_config_verbose($appliance, (@class_names[0]));
	print_log($ANY, "Set pipe min @min_bw[0] and burst max ". to_percentage($WAN, 60)." to class @class_names[0].\n Start HTTP , SMB and iperf");
	@class_port = (80, 445, 5001);
	start_iperf($appliance, $client, @class_port);
	
	#stop c5 traffic
	print_log($ANY, "Stop iperf traffic");
	@class_port = (80, 445);
	start_iperf($appliance, $client, @class_port);
	
	#stop c4 traffic and start c5 traffic
	print_log($ANY, "Stop SMB traffic and start iperf traffic");
	@class_port = (80, 5001);
	start_iperf($appliance, $client, @class_port);

	
	@min_bw = (0, 0, 0, 0 , 0); # values in Kbps
	@burstmax = (0, 0 , 0, 0, 0); # values in Kbps
		
	print $appliance "policy\n\r";
	for($i = 0; $i < 5 ; $i++)
	{
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));
	}
	print_log($ANY, "Reset pipe for all class and assign priority HTTP- 3, FTP- 5, SMB- 7");
	
	#remove all pipe min and max then set priorities as, HTTP- 3, FTP- 5, SMB- 7

	execute(change_policy($appliance, @priority_policies[0], "priority 3"));
	execute(change_policy($appliance, @priority_policies[2], "priority 5"));
	execute(change_policy($appliance, @priority_policies[3], "priority 7"));
	
	show_config_verbose($appliance, @class_names);
	
	@class_port = (80, 443, 21, 445, 5001);
	start_iperf($appliance, $client, @class_port);
	
}

print "\nTest Finished\n";

#delete_classes($appliance, @class_names);
delete_policies($appliance, @priority_policies);
start_other_service($server);
# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();

print "\nLog file : " . $global_cfg{"log_file"};
print "\nOutput file : " . $global_cfg{"output_file"}."\n";

#-------------------------------------------------------------------------------

sub to_percentage
{
	my ($total, $percent) = @_;
	
	return (($total * $percent)  / 100);
}
#-------------------------------------------------------------------------------

sub killall_iperf
{
	my ($session) = @_;
	for(my $i = 0 ; $i < 5 ; $i++)
	{
		print $session "killall -9 iperf\n";
		if($session->expect(1, "iperf: no process found"))
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
	
	execute(get_link_stats($session, \%if_stats, $LINK0, "last_min"));
	
	my $report = "\nInterface Flow count - external = $if_stats{\"ls_ext_flow_count\"}, ";
	$report = $report . "Bandwidth - internal = $if_stats{\"ls_int_tx_kbps\"} Kbps, ";
	my $data_transmitted_int = $if_stats{"ls_int_tx_bytes"} / 1000;
	$report = $report . "Bytes transferred - internal =  $data_transmitted_int KB.\n";
	
	$report = $report . "-----------------------------------------------------\n";
	$report = $report . "Classname\t|Rate\t|Flows\t|Bytes\t\n";
		
	foreach(@classes)
	{
		execute(get_class_stats($session, \%stats, $_, "last_min", $LINK0));
		my $data_transmitted_in = $stats{"cs_in_tx_bytes"} / 1000;
		$report = $report . "$_\t\t|$stats{\"cs_in_tx_kbps\"}\t|$stats{\"cs_out_flow_count\"}\t|$data_transmitted_in\n";
	}
	$report = $report . "-----------------------------------------------------\n";

	print_log($ANY, $report);
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub collect_other_info
{
	sleep($test_interval);
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
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub ping_test_from_server
{
	my ($ser_session) = @_;
	my $cmd = "ping -c 10 ".$cfg{"client_loc_eth_ip"};
	print $ser_session "$cmd\n";
	my $match = "ping statistics";
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
	my $match = "ping statistics";
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
#-------------------------------------------------------------------------------
sub start_iperf
{
	my ($app_session, $cli_session, @ports) = @_;
	my $pid = 0;
	# start iperf client
	for(@ports)
	{
		my $options = " -c $cfg{\"server_loc_eth_ip\"} -t $test_duration -P 200 -p $_";
		execute(start_iperf_client($cli_session, \$pid, $options));
	}
	
	collect_stats_all_classes($app_session, @class_names);
	collect_other_info($app_session, $cli_session, @class_names);
	
	execute(killall_iperf($cli_session));
}
#-------------------------------------------------------------------------------
sub stop_other_service
{
	my ($ser_session) = @_;
	my $cmd = "service httpd stop";
	print $ser_session "$cmd\n";
	my $match = "Stopping httpd (via systemctl):                            [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Stopping httpd service failed.\n");
	}
	$cmd = "service vsftpd stop";
	print $ser_session "$cmd\n";
	$match = "Stopping vsftpd (via systemctl):                           [  OK";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Stopping vsftpd service failed.\n");
	}
	$cmd = "service smb stop";
	print $ser_session "$cmd\n";
	$match = "Stopping smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Stopping smb service failed.\n");
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub start_other_service
{
	my ($ser_session) = @_;
	my $cmd = "service httpd start";
	print $ser_session "$cmd\n";
	my $match = "Starting httpd (via systemctl):                            [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Starting httpd service failed.\n");
	}
	$cmd = "service vsftpd start";
	print $ser_session "$cmd\n";
	$match = "Starting vsftpd (via systemctl):                           [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Starting vsftpd service failed.\n");
	}
	$cmd = "service smb start";
	print $ser_session "$cmd\n";
	$match = "Starting smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($ANY,"Starting smb service failed.\n");
	}
	return $SUCCESS;
}
