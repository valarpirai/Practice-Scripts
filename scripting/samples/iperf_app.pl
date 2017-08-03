#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

my $traffic_type = "tcp";

my @class_names = ();
my @class_port = ();
my $test_pipemin_percentage = "20,30,50,0,0,0,0,0";	# Default pipemin percentages
my $test_pipemax_percentage = "0,0,0,0,0,0,0,0"; 	# Default pipemax percentages
my $test_priorities         = "3,3,3,3,6,3,3,3"; 	# Default priorities
my $num_flows = 200;     			# Default 200 flows

# Other variables
my $test_wan_speed = "10"; # Default 10Mbps
my $appl_name = "eagle"; # Default config file
my $test_interval = 100; # Default 100 secs
my @tcp_class_names = ("HTTP", "SSL", "LDAP", "SMB", "iperf_tcp_1", "iperf_tcp_2", "iperf_tcp_3", "iperf_tcp_4");	# Class Names
my @tcp_class_port = (80, 443, 389, 445, 6001, 6002, 6003, 6004);			# Port number for classes

my $i;
my @priorities = ();
my @pipemin_percentage = ();
my @pipemax_percentage = ();
my @generate_traffic_at = (); # values in Kbps
my @min_bw = (); # values in Kbps
my @burstmax = (); # values in Kbps
my @priority_policies = (); 					# priority policy names
my $server_traffic_options;
my @udp_traffic_bandwidth_per_flow = ();
my @udp_traffic_bandwidth_percentage = ();
my @udp_class_packet_size = ();			# Packet size of UDP classes in bytes

my @initial_priorities = (3, 3, 3, 3, 6, 3, 3, 3); 			# initial priority
my @initial_pipemin_percentage = (0, 0, 0, 0, 0, 0, 0, 0);		# Pipemin percentages
my @initial_pipemax_percentage = (0, 0, 0, 0, 0, 0, 0, 0);		# Pipemax percentages
my @initial_class_port = ();
my @iperf_server_pid = (0, 0, 0, 0, 0, 0, 0, 0);
my @iperf_client_pid = (0, 0, 0, 0, 0, 0, 0, 0);

my @cust_class_names = (@tcp_class_names[4]); # pattern names
my @cust_pattern_names = ("cust_iperf_pattern"); # pattern names
my @cust_pattern_formats = ("port: 5001"); # pattern format
my $sleep_after_test = 100;


# Parsing the command line arguments
GetOptions("appl_name|a=s" => \$appl_name, "test_time|t=s" => \$test_interval, "wan_speed|w=s" => \$test_wan_speed, "num_flows|f=s" => \$num_flows, 
		"sla|s=s" => \$test_pipemin_percentage, "burstmax|b=s" => \$test_pipemax_percentage, "priorities|p=s" => \$test_priorities,
		"usage|u=s" => \$traffic_type );

# Validating the inputs
if($test_interval < 80)
{
	print "Please enter the value greater than 80 seconds.\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Calculating the WAN speed
my @wan_speed_in;
my @wan_speed_out;
$i=0;
foreach(split(",", $test_wan_speed))
{
	@wan_speed_in[$i] = ($_ * 1000);
	@wan_speed_out[$i] = ($_ * 1000);
	$i++;
}


if ($traffic_type eq "tcp")
{
	@class_names = @{$cfg{"tcp_class_names"}}; # tcp classnames
	@initial_class_port = @{$cfg{"tcp_class_port"}};
}
else
{
	@class_names = @{$cfg{"udp_class_names"}};
	@initial_class_port = @{$cfg{"udp_class_ports"}};
   	@udp_traffic_bandwidth_percentage = @{$cfg{"udp_class_traffic_WAN_percentage"}};
	@udp_class_packet_size = @{$cfg{"udp_class_packet_size"}};			# UDP payload size in bytes
	@initial_priorities = @{$cfg{"udp_class_priorities"}}; 
	for(my $j=0; $j <= $#udp_traffic_bandwidth_percentage; $j++)
	{
		foreach(@wan_speed_in)
	    {
			if((to_percentage($_, @udp_traffic_bandwidth_percentage[$j]) / $num_flows) < 20)
			{
				print "Cannot create the flows in this rate ". to_percentage($_, @udp_traffic_bandwidth_percentage[$j]) / $num_flows . "K. Please reduce the flow count.\n";
				exit;
			}
		}
		if(@udp_class_packet_size[$j] < 22)
		{
			@udp_class_packet_size[$j] = 0;
			print "UDP packet size should not be less than 63 bytes. Packet size set to Default value for @class_names[$j].\n";
		}
	}
}



# Calculating the SLA and Burst Limit percentages
$i=0;
foreach(split(",", $test_pipemin_percentage))
{
	@initial_pipemin_percentage[$i] = $_;
	$i++;
}
$i=0;
foreach(split(",", $test_pipemax_percentage))
{
	@initial_pipemax_percentage[$i] = $_;
	$i++;
}
$i=0;
foreach(split(",", $test_priorities))
{
	@initial_priorities[$i] = $_;
	$i++;
}

# Calculating the traffic run duration
my $traffic_duration = $test_interval + 200;

# Login to Appliance, Client, Server
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));

# Check bypass is off
execute_not(is_bypass_on($appliance));
execute(set_shaping_on($appliance));

=cut
Commenting the creation of class, Assuming there is a iperf class created with port 5001 pattern

# Creating custom class with pattern 
for($i = 0 ; $i <= $#cust_pattern_names ; $i++)
{
	execute(create_pattern($appliance, @cust_pattern_names[$i], @cust_pattern_formats[$i]));
	execute(create_class($appliance, @cust_class_names[$i], $LINK0, @cust_pattern_names[$i]));
}
# sync after create class TODO: Need to move into common.pm
print $appliance "app\nsync\n\r";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync.\n");
}
=cut

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

foreach(my $w = 0 ; $w <= $#wan_speed_in ; $w++ )
{
	# Modifying the WAN speeds
	execute(set_wan_speed($appliance, $LINK0, @wan_speed_in[$w], @wan_speed_out[$w]));
	execute(set_wan_speed($appliance, $LINK1, @wan_speed_in[$w], @wan_speed_out[$w]));
	
	# Loading the inital priorities
	@priorities = @initial_priorities;
	
	# Modifying the pipe and priorities of a class
	for($i = 0 ; $i <= $#class_names ; $i++)
	{
		# Modifying the priorities of the class 
		execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));

		# Calculating the initial pipe min and max
		@min_bw[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemin_percentage[$i]);
		@burstmax[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemax_percentage[$i]);

		# Modifying the pipe of the class
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

		if ($traffic_type ne "tcp")
		{
			# Calculating the UDP traffic bandwidth
			@udp_traffic_bandwidth_per_flow[$i] = to_percentage(@wan_speed_in[$w], @udp_traffic_bandwidth_percentage[$i]) / $num_flows ;
		}

	}
	show_config_verbose($appliance, @class_names);

#RUN_2SLA_1
	if ($cfg{'RUN_2SLA_1'} eq "yes")
	{
		print_log($ANY, "Starting #1 - 2 SLA (@initial_pipemin_percentage[1]%,@initial_pipemin_percentage[2]%) (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[1,2];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}
	

#RUN_2SLA_2
	if ($cfg{'RUN_2SLA_2'} eq "yes")
	{
		# Setting SLA to 40%, 40% for SSL and LDAP
		@min_bw[1] = to_percentage(@wan_speed_in[$w], 40);
		@min_bw[2] = to_percentage(@wan_speed_in[$w], 40);
		print_log($LOG, "Changing pipe for SSL Pipemin:@min_bw[1] Pipemax:@burstmax[1]");
		print_log($LOG, "Changing pipe for LDAP Pipemin:@min_bw[2] Pipemax:@burstmax[2]");
		execute(set_pipe($appliance, @min_bw[1], @burstmax[1], @class_names[1]));
		execute(set_pipe($appliance, @min_bw[2], @burstmax[2], @class_names[2]));

		print_log($ANY, "Starting #2 - 2 SLA (40%,40%) (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[1,2];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);

		# Reseting the SLA 40% 40% to Default values for SSL and LDAP
		@min_bw[1] = to_percentage(@wan_speed_in[$w], @initial_pipemin_percentage[1]);
		@min_bw[2] = to_percentage(@wan_speed_in[$w], @initial_pipemin_percentage[2]);
		print_log($LOG, "Changing pipe for SSL Pipemin:@min_bw[1] Pipemax:@burstmax[1]");
		print_log($LOG, "Changing pipe for LDAP Pipemin:@min_bw[2] Pipemax:@burstmax[2]");
		execute(set_pipe($appliance, @min_bw[1], @burstmax[1], @class_names[1]));
		execute(set_pipe($appliance, @min_bw[2], @burstmax[2], @class_names[2]));
	}


#RUN_2BURST
	if ($cfg{'RUN_2BURST'} eq "yes")
	{
		# Set pipe max to SMB as 20% WAN
		@burstmax[3] = to_percentage(@wan_speed_in[$w], 20);
		@priorities[3] = 6;
		@priorities[4] = 3;
		print_log($LOG, "Changing pipe for SMB Pipemin:@min_bw[3] Pipemax:@burstmax[3]");
		execute(set_pipe($appliance, @min_bw[3], @burstmax[3], @class_names[3]));
		execute(change_policy($appliance, @priority_policies[4], "priority @priorities[4]"));
		execute(change_policy($appliance, @priority_policies[3], "priority @priorities[3]"));
		show_config_verbose($appliance, (@class_names[3]));

		print_log($ANY, "Starting #3 - 2 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[3,4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);

		# Reset to default values
		@burstmax[3] = to_percentage(@wan_speed_in[$w], @initial_pipemax_percentage[3]);
		@priorities[3] = @initial_priorities[3];
		@priorities[4] = @initial_priorities[4];
		print_log($LOG, "Changing pipe for SMB Pipemin:@min_bw[3] Pipemax:@burstmax[3]");
		execute(set_pipe($appliance, @min_bw[3], @burstmax[3], @class_names[3]));
		execute(change_policy($appliance, @priority_policies[4], "priority @priorities[4]"));
		execute(change_policy($appliance, @priority_policies[3], "priority @priorities[3]"));
		show_config_verbose($appliance, (@class_names[3]));
	}
	

#RUN_ALL_WITHONLY_PRIORITIES	
	if ($cfg{'RUN_ALL_WITHONLY_PRIORITIES'} eq "yes")
	{
		print_log($LOG, "Reset All pipes");
		@min_bw = (0, 0, 0, 0 , 0); # values in Kbps
		@burstmax = (0, 0 , 0, 0, 0); # values in Kbps
		@priorities = (3,4,5,6,7);
		for($i = 0; $i <= $#priorities ; $i++)
		{
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));
		}
		show_config_verbose($appliance, @class_names);

		print_log($ANY, "Starting #4 - All traffic with only priorities (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);

		# Reseting the proirities and pipes
		@priorities = @initial_priorities;
		for($i = 0 ; $i <= $#priorities ; $i++)
		{
			# Calculating the initial pipe min and max
			@min_bw[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemin_percentage[$i]);
			@burstmax[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemax_percentage[$i]);
			# Reseting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Modifying the priorities of the class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
		}
	}


#RUN_1SLA_1BURST
	#stop c4 traffic and start c5 traffic
	if ($cfg{'RUN_1SLA_1BURST'} eq "yes")
	{
		print_log($ANY, "Starting #5 - 1 SLA, 1 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0, 4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}


#RUN_1SLA_1BURST_WITHLIMIT
	if ($cfg{'RUN_1SLA_1BURST_WITHLIMIT'} eq "yes")
	{
		# Set pipe max to HTTP as 60%WAN 
		@burstmax[0] = to_percentage(@wan_speed_in[$w], 60);
		print_log($LOG, "Changing pipe for HTTP Pipemin:@min_bw[0] Pipemax:". @burstmax[0]);
		execute(set_pipe($appliance, @min_bw[0], @burstmax[0], @class_names[0]));
		show_config_verbose($appliance, (@class_names[0]));

		print_log($ANY, "Starting #6 - 1 SLA, 1 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0, 3];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);

		# Reseting the pipe max for HTTP to default
		@burstmax[0] = to_percentage(@wan_speed_in[$w], @initial_pipemax_percentage[0]);
		print_log($LOG, "Changing pipe for HTTP Pipemin:@min_bw[0] Pipemax:". @burstmax[0]);
		execute(set_pipe($appliance, @min_bw[0], @burstmax[0], @class_names[0]));
	}

#RUN_1SLA_2BURST
	if ($cfg{'RUN_1SLA_2BURST'} eq "yes")
	{
		print_log($ANY, "Starting #7 - 1 SLA, 2 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0, 3, 4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_2SLA_2BURST
	if ($cfg{'RUN_2SLA_2BURST'} eq "yes")
	{
		print_log($ANY, "Starting #8 - 2 SLA, 2 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[1..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	} 

#RUN_3SLA_1BURST
	if ($cfg{'RUN_3SLA_1BURST'} eq "yes")
	{
		# Setting the priority as 4
		@priorities[1] = 4;
		print_log($LOG, "Changing priority for SSL as Priority: @priorities[1]");
		execute(change_policy($appliance, @priority_policies[1], "priority @priorities[1]"));

		print_log($ANY, "Starting #9 - 3 SLA, 1 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0, 1, 2, 4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);

		# Reseting the proirities
		@priorities[1] = @initial_priorities[1];
		execute(change_policy($appliance, @priority_policies[1], "priority @priorities[1]"));
	}

#RUN_3SLA_2BURST
	if ($cfg{'RUN_3SLA_2BURST'} eq "yes")
	{
		print_log($ANY, "Starting #10 - 3 SLA, 2 BURST (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_8SLA_BURST_PRIORITIES
	if ($cfg{'RUN_8SLA_BURST_PRIORITIES'} eq "yes")
	{
		# Reseting the proirities and pipes
		@priorities = (0, 1, 2, 3, 4, 5, 6, 7);
		@pipemin_percentage = (6, 6, 6, 6, 6, 6, 6, 6);
		@pipemax_percentage = (0, 0, 0, 0, 0, 0, 0, 0);
		for($i = 0 ; $i <= $#priorities ; $i++)
		{
			# Calculating the initial pipe min and max
			@min_bw[$i] = to_percentage(@wan_speed_in[$w], int(50 / $#class_names));
			@burstmax[$i] = to_percentage(@wan_speed_in[$w], @pipemax_percentage[$i]);
			# Reseting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Modifying the priorities of the class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
		}
		print_log($ANY, "Starting #11 - 8 SLA with BURST and PRIORITIES (WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..7];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}
	
#RUN_8BURST_PRIORITIES
	if ($cfg{'RUN_8BURST_PRIORITIES'} eq "yes")
	{
		# Reseting the proirities and pipes
		@priorities = (0, 1, 2, 3, 4, 5, 6, 7);
		@pipemin_percentage = (0, 0, 0, 0, 0, 0, 0, 0);
		@pipemax_percentage = (0, 0, 0, 0, 0, 0, 0, 0);
		
		for($i = 0 ; $i <= $#priorities ; $i++)
		{
			# Calculating the pipe min and max
			@min_bw[$i] = to_percentage(@wan_speed_in[$w], @pipemin_percentage[$i]);
			@burstmax[$i] = to_percentage(@wan_speed_in[$w], @pipemax_percentage[$i]);
		
			# Seting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Modifying the priorities of the class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
		}
		print_log($ANY, "Starting #12 - 8 BURST and PRIORITIES(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..7];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}
	
	# Reseting the proirities and pipes
	@priorities = @initial_priorities;
	for($i = 0 ; $i <= $#class_names ; $i++)
	{
		# Calculating the pipe min and max
		@min_bw[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemin_percentage[$i]);
		@burstmax[$i] = to_percentage(@wan_speed_in[$w], @initial_pipemax_percentage[$i]);
	
		# Seting pipe
		execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

		# Modifying the priorities of the class 
		execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
	}
	
#RUN_3SLA_1BURST_PKTSIZE
	if ($cfg{'RUN_3SLA_1BURST_PKTSIZE'} eq "yes")
	{
		if($traffic_type ne "tcp")
		{
			@udp_class_packet_size = (1400, 1400, 1000, 64);
		}
		print_log($ANY, "Starting #14 - 3 SLA and 1 BURST with Packet Size(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..3];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_3SLA_2BURST_PKTSIZE
	if ($cfg{'RUN_3SLA_1BURST_PKTSIZE'} eq "yes")
	{
		if($traffic_type ne "tcp")
		{
			@udp_class_packet_size = (1000, 1000, 1000, 64, 64);
		}
		print_log($ANY, "Starting #15 - 3 SLA and 2 BURST with Packet Size(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_3SLA_1BURST_PKTSIZE_500PER_INPUT
	if ($cfg{'RUN_3SLA_1BURST_PKTSIZE_500PER_INPUT'} eq "yes")
	{
		if($traffic_type ne "tcp")
		{
			@udp_class_packet_size = (1000, 1000, 1000, 64);
			@udp_traffic_bandwidth_per_flow[3] = to_percentage(@wan_speed_in[$w], 500) / $num_flows ;
		}
		print_log($ANY, "Starting #16 - 3 SLA and 1 BURST with Packet Size(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..3];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_3SLA_2BURST_PKTSIZE_500PER_INPUT
	if ($cfg{'RUN_3SLA_2BURST_PKTSIZE_500PER_INPUT'} eq "yes")
	{
		if($traffic_type ne "tcp")
		{
			@udp_class_packet_size = (1000, 1000, 1000, 64, 64);
			@udp_traffic_bandwidth_per_flow[3] = to_percentage(@wan_speed_in[$w], 500) / $num_flows ;
			@udp_traffic_bandwidth_per_flow[4] = to_percentage(@wan_speed_in[$w], 500) / $num_flows ;
		}
		print_log($ANY, "Starting #17 - 3 SLA and 2 BURST with Packet Size(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}

#RUN_3SLA_2BURST_LINK
	if ($cfg{'RUN_3SLA_2BURST_LINK'} eq "yes")
	{
		@priorities = (3, 3, 3, 3, 3);
		@pipemin_percentage = (5, 10, 15, 0, 0);
		@pipemax_percentage = (0, 0, 0, 0, 0);
		for($i = 0 ; $i <= $#priorities ; $i++)
		{
			# Calculating the pipe min and max
			@min_bw[$i] = to_percentage(@wan_speed_in[$w], @pipemin_percentage[$i]);
			@burstmax[$i] = to_percentage(@wan_speed_in[$w], @pipemax_percentage[$i]);
		
			# Seting pipe
			execute(set_pipe($appliance, @min_bw[$i], @burstmax[$i], @class_names[$i]));

			# Modifying the priorities of the class 
			execute(change_policy($appliance, @priority_policies[$i], "priority @priorities[$i]"));
			
		}
		if($traffic_type ne "tcp")
		{
			@udp_class_packet_size = @{$cfg{"udp_class_packet_size"}};
			@udp_traffic_bandwidth_per_flow[3] = to_percentage(@wan_speed_in[$w], 100) / $num_flows ;
			@udp_traffic_bandwidth_per_flow[4] = to_percentage(@wan_speed_in[$w], 100) / $num_flows ;
		}
		
		print_log($ANY, "Starting #18 - 3 SLA and 2 BURST with Packet Size(WAN - " . (@wan_speed_in[$w] / 1000) ."Mbps)");
		@class_port = @initial_class_port[0..4];
		print_info(@class_port);
		start_iperf($appliance, $client, @class_port);
	}
	
	print_log($ANY, "Tests Completed");

}


# Deleting classes, policies
delete_policies($appliance, @priority_policies);

=cut
delete_classes($appliance, (@class_names[4]));
=cut

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

=sub collect_other_info
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
=cut
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
sub stop_other_service
{
	my ($ser_session) = @_;
	my $cmd = "service httpd stop";
	print $ser_session "$cmd\n";
	my $match = "Stopping httpd (via systemctl):                            [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print "Stopping httpd service failed.\n";
	}
	$cmd = "service vsftpd stop";
	print $ser_session "$cmd\n";
	$match = "Stopping vsftpd (via systemctl):                           [  OK";
	unless($ser_session->expect(15, $match))
	{
		print "Stopping vsftpd service failed.\n";
	}
	$cmd = "service smb stop";
	print $ser_session "$cmd\n";
	$match = "Stopping smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print "Stopping smb service failed.\n";
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
		print "Starting httpd service failed.\n";
	}
	$cmd = "service vsftpd start";
	print $ser_session "$cmd\n";
	$match = "Starting vsftpd (via systemctl):                           [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print "Starting vsftpd service failed.\n";
	}
	$cmd = "service smb start";
	print $ser_session "$cmd\n";
	$match = "Starting smb (via systemctl):                              [  OK  ]";
	unless($ser_session->expect(15, $match))
	{
		print "Starting smb service failed.\n";
	}
	return $SUCCESS;
}

