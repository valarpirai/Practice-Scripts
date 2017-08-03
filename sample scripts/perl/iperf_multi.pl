#!/usr/bin/perl

=This script will read the input from the other_config/traffic_with_pipe_flowrate.csv file

Traffic with pipe , flowrate and priority.

Script Input Line:  1000,1000 ,256,0,3, 0,0,3, 1,500, 1,200, 50, 32,0, 64,0,

WAN speed  IN - 1000 Kbps
WAN speed  OUT - 1000 Kbps

SLA for class (pipe min) - 256 Kbps
SLA for class (pipe max) - 0 Kbps
My_class priority - 3

SLA for Other Traffic (pipe min) - 0 Kbps
SLA for Other Traffic (pipe max) - 0 Kbps
Other Traffic priority - 3

My_Class Traffic - no_of_flows: 1, flow_rate :500 Kbps
Other Traffic - no_of_flows: 1, flow_rate :200 Kbps

Test total Duration: 50

flowrate guranteed - 32 Kbps
flowrate burstmax - 0 Kbps

Other Traffic flowrate guranteed - 64 Kbps
Other Traffic flowrate burstmax - 0 Kbps

Here I print the flow count, bandwidth used, data tranfered for both the interface level and class level.

=cut
=Things should taken care

=cut

use perl_modules::common;
use strict;
use Getopt::Long;

my $traffic_type = "tcp";
my @all_test_inputs = (); # All test configurations loaded from the input file

# Other variables
my $appl_name = "eagle"; # Default config file
my $test_interval = 100; # Default 100 secs
my $wan_speed = 10; 				# Default WAN speed 10 Mbps
my $num_flows = 50;     			# Default 200 flows

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
my @pipemin_percentage = ();		# values in Kbps
my @pipemax_percentage = ();		# values in Kbps
my @flowrate_min_percentage = ();	# values in Kbps
my @flowrate_max_percentage = ();	# values in Kbps

my @min_bw = ();					# values in Kbps
my @burstmax = ();					# values in Kbps

my @iperf_server_pid = (0, 0, 0, 0, 0, 0, 0, 0);
my @iperf_client_pid = (0, 0, 0, 0, 0, 0, 0, 0);

my $server_traffic_options;
my $sleep_after_test = 100;
my $i;
my $delim = ",";
my $traffic_duration = 100;

# Parsing the command line arguments
my $appl_name;
my $input_file;

GetOptions("appl_name|a=s" => \$appl_name, "input-file|i=s" => \$input_file, "usage|u=s" => \$traffic_type);

# Validating the inputs
unless ($appl_name)
{
	print "\nPlease provide the appliance name.. Which appliance?\n";
	exit;
}
unless ($input_file)
{
	print "\nPlease provide the input file name(Traffic cofigurations file name)\n";
	exit;
}
if($test_interval < 80)
{
	print "Please enter the value greater than 80 seconds.\n";
	exit;
}



# Loading the configurations from file
execute(load_config($appl_name));

if ($traffic_type eq "tcp")
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
	for(my $j=0; $j <= $#udp_traffic_bandwidth_percentage; $j++)
	{
		if(@udp_class_packet_size[$j] < 22)
		{
			@udp_class_packet_size[$j] = 0;
			print "UDP packet size should not be less than 63 bytes. Packet size set to Default value for @class_names[$j].\n";
		}
	}
}

# Load test parameters from the local file given by user input
execute(parse_input("$input_file.csv", \@all_test_inputs));


# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));


# Check shaping is on, unless turn on shaping
execute(set_shaping_on($appliance));

if ($traffic_type eq "tcp")
{
	# Stop other servers like httpd, ftp , smb before starting iperf servers
	stop_other_service($server);

	# TCP is the default server option
	$server_traffic_options = "";
}
else
{
	# UDP needs -u server option
	$server_traffic_options = "-u";
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
for($i = 0 ; $i <= $#priorities ; $i++)
{
	my $policy_name = "cust_policy_$i";
	@priority_policies[$i] = $policy_name;

	execute(create_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	execute(assign_policy($appliance, @priority_policies[$i], @class_names[$i]));
}

# This will run each test
for my $hash (@all_test_inputs) {
	
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
	@class_port = ();
	
	# Load configurations for test
	foreach (sort keys %{$hash})
	{
		if($_ ne "wan_speed" && $_ ne "test_duration")
		{
			print "\nClass : " . $_;
			print "\nPipe min % : " . @{$hash->{$_}}[0];
			print "\nPipe max % : ".@{$hash->{$_}}[1];
			print "\nFlowrate min % : ".@{$hash->{$_}}[2];
			print "\nFlowrate max % : ".@{$hash->{$_}}[3];
			print "\nPriority : ".@{$hash->{$_}}[4];
			print "\nTraffic rate % : ".@{$hash->{$_}}[5];	# only for UDP traffic
			print "\nNo. of flows : ".@{$hash->{$_}}[6];
			
			push @pipemin_percentage, @{$hash->{$_}}[0];
			push @pipemax_percentage, @{$hash->{$_}}[1];
			push @flowrate_min_percentage, @{$hash->{$_}}[2];
			push @flowrate_max_percentage, @{$hash->{$_}}[3];
			push @priorities, @{$hash->{$_}}[4];
			push @udp_traffic_bandwidth_percentage, @{$hash->{$_}}[5];	# only for UDP traffic
			push @no_of_flows, @{$hash->{$_}}[6];
		}
		
		print "\n";
	}
	
	$wan_speed = $hash->{'wan_speed'};
	$test_interval = $hash->{'test_duration'};
	
	$traffic_duration = $test_interval + 200;
	
	execute(set_wan_speed($appliance, $LINK0, $wan_speed, $wan_speed));
	execute(set_wan_speed($appliance, $LINK1, $wan_speed, $wan_speed));
	
	for($i = 0 ; $i <= $#no_of_flows ; $i++)
	{
		if(@no_of_flows[$i] > 0)
		{
			# Calculating the initial pipe min and max
			@min_bw[$i] = to_percentage($wan_speed, @pipemin_percentage[$i]);
			@burstmax[$i] = to_percentage($wan_speed, @pipemax_percentage[$i]);
			
			# Reseting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Modifying the priorities of the class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
			push @class_port, @initial_class_port[$i];
			if ($traffic_type ne "tcp")
			{
				# Calculating the UDP traffic bandwidth
				@udp_traffic_bandwidth_per_flow[$i] = to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / $num_flows;
				if((to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / $num_flows) < 20)
				{
					print "Cannot create the flows in this rate ". to_percentage($wan_speed, @udp_traffic_bandwidth_percentage[$i]) / $num_flows . "K. Set to default 20K.\n";
					@udp_traffic_bandwidth_per_flow[$i] = 20;
				}
			}
		}
	}	
	print_log($ANY, "WAN - " . ($wan_speed / 1000) ."Mbps");
	print_info(@class_port);
	start_iperf($appliance, $client, @class_port);
	
	# End of a test from the configurations file
}

# Deleting classes, policies
delete_policies($appliance, @priority_policies);

if ($traffic_type eq "tcp")
{
	execute(killall_iperf($server));
	# Starting other services
	start_other_service($server);
}

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();

print "\nLog file : " . $global_cfg{"log_file"};
print "\nOutput file : " . $global_cfg{"output_file"}."\n";

#-------------------------------------------------------------------------------

sub parse_input
{
	my ($input_file, $alltest) = @_;

	my $local_session=Expect->new();
	$local_session->log_stdout(0);
	$local_session->send(`cat other_config/$input_file\n`);
	$local_session->expect(1,"cat");
	my $after = $local_session->before();

	# Split each line of the input file
	my @cat_output = split("\n",$after);

	foreach (@cat_output) 
	{
		# Split the line by using comma, then take the config and store them in hash (7 values for each class)
		my ($conf_string) = $_;
		my @str = split($delim, $conf_string);
		my %test = ();
		#print join(", ", @str);
		#print "\n";
		$test{'wan_speed'} = @str[0];
		$test{'test_duration'} = @str[1];
		
		my @str1 = @str[2..$#str];
		my $loop_count = ($#str1 / 7);
		my $i = 0;
		# Load the each class config in an array and add it to a test hash
		for(my $j = 0 ; $j < $loop_count; $j++)
		{
			# A class config array
			my @class = (@str1[0+$i], @str1[1+$i], @str1[2+$i], @str1[3+$i], @str1[4+$i], @str1[5+$i], @str1[6+$i]);
			$i += 7;
			$test{"class_$j"} = [@class];
		}
		# Add the each test hash to a array containing all tests
		push @{$alltest} , \%test;
	}
	
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

		if ($traffic_type ne "tcp")
		{
			$options = $options . " -u -b @udp_traffic_bandwidth_per_flow[$idx]" . "K";
			if(@udp_class_packet_size[$idx] != 0)
			{
				$options = $options . " -l @udp_class_packet_size[$idx]";
			}
		}
		execute(start_iperf_clients($cli_session, \$pid, $cfg{"server_loc_eth_ip"}, $num_flows, $traffic_duration, 0, 0, $options));
		
	}
	
	#collect_other_info($app_session, $cli_session, @class_names);
	collect_stats_all_classes($app_session, @class_names);

	execute(killall_iperf($cli_session));
	print_log($ANY, "Waiting for $sleep_after_test secs.... (before starting the next test)");
	sleep($sleep_after_test);
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
		if ($traffic_type ne "tcp")
		{
			my $total_bw = @udp_traffic_bandwidth_per_flow[$idx] * $num_flows;
			$input_bw = "\tInput_BW: $total_bw"; 
		}
		print_log($ANY, "@class_names[$idx]\t - Pipemin: @min_bw[$idx]\tPipemax: @burstmax[$idx]\tPriority: @priorities[$idx] $input_bw");
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
	$report = $report . "Classname\t\t|Rate\t|Flows\n";
	$report = $report . "-------------------------------------------\n";
	
	foreach(@classes)
	{
		%stats = ();
		execute(get_class_stats($session, \%stats, $_, "last_min", $LINK0));
		$report = $report . "$_ \t\t|$stats{\"cs_in_tx_kbps\"}\t|$stats{\"cs_out_flow_count\"}\n";
	}
	$report = $report . "-------------------------------------------\n";
	$report = $report . "Interface\t|Rate\t|Flows\n";
	$report = $report . "$LINK0\t\t|$if_stats{'ls_int_tx_kbps'}\t|$if_stats{'ls_ext_flow_count'}\n";
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
