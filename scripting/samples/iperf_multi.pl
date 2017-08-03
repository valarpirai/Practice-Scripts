#!/usr/bin/perl

=This script will read the input from the other_config/<test_spec_file_name>.csv file

Traffic with pipe , flowrate and priority.

Script Input Line:  #1, 10000,120, 20,0,0,0,5,100,20

Test Id - #1
WAN speed - 10000 Kbps
Test total Duration: 120 seconds

SLA for class_1 (pipe min) 		- 20 % of WAN
SLA for class_1 (pipe max)		- 0 % of WAN
flowrate guranteed for class_1 	- 0 % of Pipe min BW
flowrate burstmax for class_1	- 0 % of Pipe min BW
priority for class_1 			- 3
Traffic rate for class_1 		- 100 % of WAN (Only for UDP traffic)
no_of_flows for class_1  		- 20 flows

Here I print the flow count, bandwidth used for both the interface level and class level.

=cut
=Things should taken care

Client machine of the appliance should conneted at the WAN interface of appliance.
Server machine of the appliance should conneted at the LAN interface of appliance.

Usage:

 -a			=> Appliance, Client and Server configurations and UDP, TCP class names and port numbers. <config_file_name> *
 -i			=> Test configurations .csv file with above reported format. <test_spec_file_name> *
 -test-type	=> Traffic type must be TCP or UDP. Default tcp. (UDP or TCP) 
 -d			=> Test with Shaping off state also. Default "no". (yes or no)
 
=cut

use perl_modules::common;
use strict;
use Getopt::Long;

my $ttype_1 = "tcp";
my $ttype_2 = "udp";
my $ip_ver_4 = "ipv4";
my $ip_ver_6 = "ipv6";


my $traffic_type = $ttype_1; # Default tcp test
my $test_times = "one";
my @all_test_inputs = (); # All test configurations loaded from the input file

# Other variables
my $appl_name = "eagle"; # Default config file
my $test_interval = 100; # Default 100 secs
my $wan_speed = 10; 				# Default WAN speed 10 Mbps

my @initial_class_port = ();
my @udp_traffic_bandwidth_per_flow = ();
my @udp_traffic_bandwidth_percentage = ();
my @udp_class_packet_size = ();			# Packet size of UDP classes in bytes

my @class_names = ("HTTP", "SSL", "LDAP", "SMB", "iperf_tcp_1", "iperf_tcp_2", "iperf_tcp_3", "iperf_tcp_4");	# Class Names
my @class_port = ();			# Port number for classes
my @initial_priorities = (3, 3, 3, 3, 6, 3, 3, 3); 			# initial priority

my @priorities = ();				# priority values
my @no_of_flows = ();				# priority values
my @priority_policies = (); 		# priority policy names
my @flowrate_policies = (); 		# flowrate policy names
my @pipemin_percentage = ();		# values in Kbps
my @pipemax_percentage = ();		# values in Kbps
my @flowrate_min_percentage = ();	# values in Kbps
my @flowrate_max_percentage = ();	# values in Kbps

my @min_bw = ();					# values in Kbps
my @burstmax = ();					# values in Kbps
my @flowrate_min_bw = ();					# values in Kbps
my @flowrate_burstmax = ();					# values in Kbps
my %version = ();

my @flowrate_policy_assigned = (0, 0, 0, 0, 0, 0, 0, 0);
my @iperf_server_pid = (0, 0, 0, 0, 0, 0, 0, 0);
my @iperf_client_pid = (0, 0, 0, 0, 0, 0, 0, 0);

my $server_traffic_options = "";
my $sleep_after_test = 100;
my $i;
my $delim = ",";
my $traffic_duration = 100;
my $ip_protocol = $ip_ver_4;

# Parsing the command line arguments
my $appl_name;
my $input_file;

GetOptions("appl_name|app|a=s" => \$appl_name, "input-file|test-list|i=s" => \$input_file, "usage|test-type|u=s" => \$traffic_type,
			"shaping_off|both|d=s" => \$test_times, "protocol|ip=s" => \$ip_protocol);

# Validating the inputs
unless ($appl_name)
{
	print "\nPlease provide the appliance name.. Which appliance?\n";
	exit;
}
unless ($input_file)
{
	print "\nPlease provide the input file name (Traffic cofigurations file name)\n";
	exit;
}
unless(lc($traffic_type) eq $ttype_1 || lc($traffic_type) eq $ttype_2)
{
	print "\nTraffic type must be TCP or UDP. This test will use the default traffic type(TCP).\n";
	$traffic_type = $ttype_1;
}

unless(lc($ip_protocol) eq $ip_ver_4 || lc($ip_protocol) eq $ip_ver_6)
{
	$ip_protocol = $ip_ver_4;
}

# Loading the configurations from file
execute(load_config($appl_name));

my %class_configs = do "other_config/$cfg{'class_config'}.cfg";
%cfg = (%cfg, %class_configs);

if ($traffic_type eq $ttype_1)
{
	@class_names = @{$cfg{"tcp_class_names"}}; # tcp classnames
	@initial_class_port = @{$cfg{"tcp_class_port"}};
	@initial_priorities = @{$cfg{"tcp_class_priorities"}}; 
}else
{
	@class_names = @{$cfg{"udp_class_names"}};
	@initial_class_port = @{$cfg{"udp_class_ports"}};
   	@udp_traffic_bandwidth_percentage = @{$cfg{"udp_class_traffic_WAN_percentage"}};
	@udp_class_packet_size = @{$cfg{"udp_class_packet_size"}};			# UDP payload size in bytes
	@initial_priorities = @{$cfg{"udp_class_priorities"}}; 
	for(my $j=0; $j <= $#udp_class_packet_size; $j++)
	{
		if(@udp_class_packet_size[$j] < 22)
		{
			@udp_class_packet_size[$j] = 0;
			print "UDP packet size should not be less than 63 bytes. Packet size set to Default value for @class_names[$j].\n";
		}
	}
}

# Load test parameters from the local file given by user input
execute(parse_input("other_config/$input_file.csv", \@all_test_inputs));


my $subject = "Script Tests Started on appliance $cfg{'appliance_ip'} from " . get_local_ip_address() . " ";
my $body_text = "Please don't use the system until the test finished.";
# send email before sanity test
send_mail("$subject", "$body_text");

# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));


# Check shaping is on, unless turn on shaping
execute(set_shaping_on($appliance));

if ($traffic_type eq $ttype_1)
{
	# Stop other servers like httpd, ftp , smb before starting iperf servers
	stop_other_service($server);

	# TCP is the default server option
	$server_traffic_options = "";
}
else
{
	# UDP needs -u server option
	$server_traffic_options = " -u ";
}

if ($ip_protocol eq $ip_ver_6)
{
	$server_traffic_options = $server_traffic_options . " -V ";
	execute(add_ipv6($server, $cfg{'server_loc_ethname'}, $cfg{'server_loc_eth_ipv6'} . "/64", "add"));
	execute(add_ipv6($client, $cfg{'client_loc_ethname'}, $cfg{'client_loc_eth_ipv6'} . "/64", "add"));
}

#Loading the initial port numbers
@class_port = @initial_class_port;

# Start iperf server listening on 5001 and 5005 ports
foreach($i = 0; $i <= $#class_port ;$i++)
{
	execute(start_iperf_server($server, \@iperf_server_pid[$i], " -p @class_port[$i] $server_traffic_options"));
}

# Loading the inital priorities
@priorities = @initial_priorities;
	
# Policy Creation
for($i = 0 ; $i <= $#class_names ; $i++)
{
	my $policy_name = "cust_policy_".($i +1)."";
	my $fl_policy_name = "cust_fl_policy_".($i +1)."";
	@priority_policies[$i] = $policy_name;
	@flowrate_policies[$i] = $fl_policy_name;
	
	# Create Priority policy and flowrate policy with default values
	execute(create_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	execute(create_policy($appliance, @flowrate_policies[$i], "flowrate guaranteed 10"));
	
	# Assign only the priority policy to the classes
	execute(assign_policy($appliance, @priority_policies[$i], @class_names[$i]));
}

print_log($ANY, "Test traffic type is \"$traffic_type\"");

# This loop will run all tests
for my $hash (@all_test_inputs) 
{
	# Resetting values in the arrays for next test
	@pipemin_percentage = ();		# values in Kbps
	@pipemax_percentage = ();		# values in Kbps
	@flowrate_min_percentage = ();	# values in Kbps
	@flowrate_max_percentage = ();	# values in Kbps
	@priorities = ();				# priority values
	@udp_traffic_bandwidth_percentage = ();	# values in Kbps
	@no_of_flows = ();				# number of flows
	@min_bw = ();					# values in Kbps
	@burstmax = ();					# values in Kbps
	@flowrate_min_bw = ();			# values in Kbps
	@flowrate_burstmax = ();		# values in Kbps
	@class_port = ();
	
	# The hash reference variable "$hash" contains values for all the tests
	# Load pipe, priority and flowrate of a class for test
	foreach (sort keys %{$hash})
	{
		if($_ ne "wan_speed" && $_ ne "test_duration" && $_ ne "test_id")
		{
			my $inline = "Class :  $_\tPipe min % :  @{$hash->{$_}}[0] \tPipe max % : @{$hash->{$_}}[1]\tFlowrate min % : @{$hash->{$_}}[2]\tFlowrate max % : @{$hash->{$_}}[3]";
			$inline = $inline . "\tPriority : @{$hash->{$_}}[4]\tTraffic rate % : @{$hash->{$_}}[5] (Only for UDP test)\tNo. of flows : @{$hash->{$_}}[6]";
			#print $inline."\n";
			print_log($LOG, $inline);
			
			push @pipemin_percentage, @{$hash->{$_}}[0];
			push @pipemax_percentage, @{$hash->{$_}}[1];
			push @flowrate_min_percentage, @{$hash->{$_}}[2];
			push @flowrate_max_percentage, @{$hash->{$_}}[3];
			push @priorities, @{$hash->{$_}}[4];
			push @udp_traffic_bandwidth_percentage, @{$hash->{$_}}[5];	# only for UDP traffic
			push @no_of_flows, int(@{$hash->{$_}}[6]);
		}
		print "\n";
	}
	
	$wan_speed = $hash->{'wan_speed'};
	$test_interval = $hash->{'test_duration'};
	$traffic_duration = $test_interval + 200;	
	
	# changing the WAN speed of both link0 and link1
	execute(set_wan_speed($appliance, $LINK0, $wan_speed, $wan_speed));
	execute(set_wan_speed($appliance, $LINK1, $wan_speed, $wan_speed));
	
	for($i = 0 ; $i <= $#no_of_flows ; $i++)
	{
		# If we give number of flows to '0' that traffic won't run
		if(@no_of_flows[$i] > 0)
		{
			# Calculating the initial pipe min, burst-max and flowrate min, burst-max
			@min_bw[$i] = to_percentage($wan_speed, @pipemin_percentage[$i]);
			@burstmax[$i] = to_percentage($wan_speed, @pipemax_percentage[$i]);
			@flowrate_min_bw[$i] = to_percentage(@min_bw[$i], @flowrate_min_percentage[$i]);
			@flowrate_burstmax[$i] = to_percentage(@min_bw[$i], @flowrate_max_percentage[$i]);
			
			# Reseting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Trying to unassign the flowrate policy from the class, if the class has no flowrate in this test. Otherwise assign the flowrate policy to the class
			if(@flowrate_min_bw[$i] <= 0 && @flowrate_burstmax[$i] <= 0)
			{
				# Unassign the flowrate policy from a class, if flowrate min and burst max are not given from the input file.
				if(@flowrate_policy_assigned[$i] == 1)
				{
					execute(unassign_policy($appliance, @flowrate_policies[$i], @class_names[$i]));
					@flowrate_policy_assigned[$i] = 0;
				}
			}elsif(@flowrate_min_bw[$i] > 0 && @flowrate_burstmax[$i] == 0)
			{
				# This will create a non-burstable flowrate policy with guranteed bandwidth and assign policy to the class
				execute(change_policy($appliance, @flowrate_policies[$i], "flowrate guaranteed @flowrate_min_bw[$i]"));
				if(@flowrate_policy_assigned[$i] == 0)
				{
					execute(assign_policy($appliance, @flowrate_policies[$i], @class_names[$i]));
					@flowrate_policy_assigned[$i] = 1;
				}
			}else
			{
				# This will create a burstable flowrate policy with guranteed and burst max bandwidth values and assign policy to the class
				my $option = "flowrate guaranteed @flowrate_min_bw[$i] burst: @flowrate_burstmax[$i] priority: @priorities[$i]";
				execute(change_policy($appliance, @flowrate_policies[$i], $option));
				if(@flowrate_policy_assigned[$i] == 0)
				{
					execute(assign_policy($appliance, @flowrate_policies[$i], @class_names[$i]));
					@flowrate_policy_assigned[$i] = 1;
				}
			}

			# Modifying the priority of a class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
			
			# Add the port in which we are going to send traffic
			push @class_port, @initial_class_port[$i];

			if ($traffic_type ne $ttype_1)
			{
				# Calculating the UDP traffic bandwidth
				@udp_traffic_bandwidth_per_flow[$i] = to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / @no_of_flows[$i];
				if((to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / @no_of_flows[$i]) < 20)
				{
					print "Cannot create the flows in this rate ". to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / @no_of_flows[$i] . "K. Set to default 20K.\n";
					@udp_traffic_bandwidth_per_flow[$i] = 20;
				}
			}
		}
	}
		
	print_log($ANY, "Test $hash->{'test_id'} (WAN - " . ($wan_speed / 1000) ."Mbps)");
	print_info(@class_port);
	if($test_times eq "yes")
	{
		execute(set_shaping_off($appliance));
		print_log($ANY, "Shaping turned OFF");
		start_iperf($appliance, $client, @class_port);
		execute(set_shaping_on($appliance));
		print_log($ANY, "Shaping turned ON");
	}
	start_iperf($appliance, $client, @class_port);
	
	# End of a test from the configurations file
}


# Deleting classes, policies
delete_policies($appliance, @priority_policies);
delete_policies($appliance, @flowrate_policies);

if ($traffic_type eq $ttype_1)
{
	execute(killall_iperf($server));
	# Starting other services
	start_other_service($server);
}

get_software_version($appliance, \%version);

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();

print_log($ANY, "Tests Completed\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}");

my $subject = "Script Tests Finished for build # " . $version{"ver_current"};
my $body_text = "Please find attached output and log files for the build sanity test results.";
# send email after sanity test
send_mail("$subject", "$body_text", "attach logs");

print "\nLog file :  $global_cfg{'log_file'}\nOutput file : $global_cfg{'output_file'}\n";

#-------------------------------------------------------------------------------

sub parse_input
{
	my ($input_file, $alltest) = @_;
	
	my $file = "$input_file";
	open my $in, $file or die "Could not open $file: $!";

	while(my $line = <$in>)  
	{
		my @str = split($delim, $line);
		my %test = ();
		
		print_log($LOG, "Input Line : " .join(", ", @str));
		
		$test{'test_id'} = @str[0];
		$test{'wan_speed'} = @str[1];
		$test{'test_duration'} = @str[2];
		
		my @str1 = @str[3..$#str];
		my $loop_count = ($#str1 / 7);
		my $i = 0;
		for(my $j = 0 ; $j < $loop_count; $j++)
		{
			my @class = (@str1[0+$i], @str1[1+$i], @str1[2+$i], @str1[3+$i], @str1[4+$i], @str1[5+$i], int(@str1[6+$i]));
			$i += 7;
			$test{"class_$j"} = [@class];
		}
		push @{$alltest} , \%test;
	}

	close $in;
	return $SUCCESS;
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
		print_log($LOG, "Stopping httpd service failed.\n");
	}
	$cmd = "service smb stop";
	print $ser_session "$cmd\n";
	$match = "Stopping smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($LOG, "Stopping smb service failed.\n");
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
		print_log($LOG, "Starting httpd service failed.\n");
	}
	$cmd = "service smb start";
	print $ser_session "$cmd\n";
	$match = "Starting smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print_log($LOG, "Starting smb service failed.\n");
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------

sub start_iperf
{
	my ($app_session, $cli_session, @ports) = @_;
	my $pid = 0;
	# start iperf client
	$i = 0;
	
	show_config_verbose($app_session, @class_names);
	
	foreach(@ports)
	{
		my $idx;
		my $port_num = $_;
		
		my $l = 0;
		foreach(@initial_class_port)
		{
			if ($_ == $port_num)
			{
				$idx = $l;
			}
			$l++;
		}
		# To change the no. of connections in iperf, change value for -P option. The value should be less than 350, iperf doesn't allow you to create more threads in single process
		my $options = "-p $_";

		if ($traffic_type ne $ttype_1)
		{
			$options = $options . " -u -b @udp_traffic_bandwidth_per_flow[$idx]" . "K";
			if(@udp_class_packet_size[$idx] != 0)
			{
				$options = $options . " -l @udp_class_packet_size[$idx]";
			}
		}
		if ($ip_protocol eq $ip_ver_6)
		{
			$options = $options . " -V ";
			execute(start_iperf_clients($cli_session, \$pid, $cfg{"server_loc_eth_ipv6"}, @no_of_flows[$idx], $traffic_duration, 0, 0, $options));
		}else
		{
			execute(start_iperf_clients($cli_session, \$pid, $cfg{"server_loc_eth_ip"}, @no_of_flows[$idx], $traffic_duration, 0, 0, $options));
		}
	}
	
	collect_stats_all_classes($app_session, @class_names);

	execute(killall_iperf($cli_session));
	print_log($ANY, "Waiting for $sleep_after_test secs.... (before starting the next test)");
	sleep($sleep_after_test);
}
#-------------------------------------------------------------------------------

sub fs
{
	my ($string) = @_;
	
	if(length($string) <= 8)
	{
		$string .= "\t\t";
	}else
	{
		$string .= "\t";
	}
	return $string;
}
#-------------------------------------------------------------------------------

sub print_info
{
	my (@class_portlist) = @_;

	foreach(@class_portlist)
	{
		my $idx;
		my $port_num = $_;
		
		my $l = 0;
		foreach(@initial_class_port)
		{
			if ($_ == $port_num)
			{
				$idx = $l;
			}
			$l++;
		}

		my $input_bw = "";
		my $flow_rate = "";
		if ($traffic_type ne $ttype_1)
		{
			my $total_bw = @udp_traffic_bandwidth_per_flow[$idx] * @no_of_flows[$idx];
			$input_bw = "\tInput_BW: $total_bw"; 
		}
		if(@flowrate_policy_assigned[$idx] == 1)
		{
			$flow_rate = "\tFlowrate min: @flowrate_min_bw[$idx]  \tburst-max : @flowrate_burstmax[$idx]";
		}
		print_log($ANY, fs(@class_names[$idx]) . "- Pipemin: @min_bw[$idx]\tPipemax: @burstmax[$idx]  Priority: @priorities[$idx]  Flows: @no_of_flows[$idx] $input_bw $flow_rate");
	}
}
#-------------------------------------------------------------------------------

sub collect_stats_all_classes
{
	my ($session, @classes) = @_;
	my %stats = ();
	my %if_stats = ();
	

	# Waiting for collecting stats
	print_log($ANY, "Started traffic for $test_interval secs....");
	sleep($test_interval);

	execute(get_link_stats($session, \%if_stats, $LINK0, "last_min"));
	

	my $report =     "\n----------- Test Output Summary -----------\n";
	$report = $report . "Classname\t|Rate\t|Flows\n";
	$report = $report . "-------------------------------------------\n";
	
	foreach(@classes)
	{
		%stats = ();
		execute(get_class_stats($session, \%stats, $_, "last_min", $LINK0));
		$report = $report . fs($_)."|$stats{\"cs_in_tx_kbps\"}\t|$stats{\"cs_out_flow_count\"}\n";
	}
	$report = $report . "-------------------------------------------\n";
	$report = $report . "Interface\t|Rate\t|Flows\n";
	$report = $report . fs($if_stats{'ls_link'}). "|$if_stats{'ls_int_tx_kbps'}\t|$if_stats{'ls_ext_flow_count'}\n";
	$report = $report . "-------------------------------------------\n\n\n";

	print_log($ANY, $report);
	return $SUCCESS;
}
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

sub add_ipv6
{
	my ($session, $interface, $ip, $action) = @_;
	unless(defined $action)
	{
		$action = "add";
	}
	my $cmd = "ifconfig $interface inet6 $action $ip \n";
	print $session "$cmd";
	print $session "$cmd";
	my $match = "SIOCSIFADDR: File exists";
	unless($session->expect(1, "$match"))
	{
		return "Failed to add this $ip ipv6 address\n";
	}
	$cmd = "ifconfig $interface \n";
	print $session "$cmd";
	$match = "root\@";
	unless($session->expect(1, "$match"))
	{
		return "Failed to execute \"ifconfig $interface\"\n";
	}
	return $SUCCESS;
}
