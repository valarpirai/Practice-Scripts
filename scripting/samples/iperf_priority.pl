#!/usr/bin/perl

=This script will read the input from the other_config/traffic_with_pipe_priority.csv file

Traffic with pipe and priority.

Script Input Line:  1000,1000 ,32,0,3 ,0,0,3 ,1,500 ,1,200 ,50,

WAN speed  IN - 1000 Kbps
WAN speed  OUT - 1000 Kbps

SLA for class (pipe min) - 32 Kbps
SLA for class (pipe max) - 0 Kbps
My_class priority - 3

SLA for Other Traffic (pipe min) - 0 Kbps
SLA for Other Traffic (pipe max) - 0 Kbps
Other Traffic priority - 3

My_Class Traffic - no_of_flows: 1, flow_rate :500 Kbps
Other Traffic - no_of_flows: 1, flow_rate :200 Kbps

Test total Duration: 50

Here I print the flow count, bandwidth used, data tranfered for both the interface level and class level.

=cut
=Things should taken care

=cut



use perl_modules::common;
use strict;
use Getopt::Long;

my $delim = ",";
my $test_interval = 10;

# Parsing the command line arguments
my $appl_name;
GetOptions("appl_name|a=s" => \$appl_name);
unless ($appl_name)
{
	print "\nPlease provide the appliance name.. Which appliance?\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));
my $appliance_root = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_root_username"}, $cfg{"appliance_root_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));


# Check bypass is off
execute_not(is_bypass_on($appliance));
execute(set_shaping_on($appliance));

my $EC_class_name = "cls1";
my $EC_priority_policy_name = "priority_policy1";
my $OT_class_name = "cls2";
my $OT_priority_policy_name = "priority_policy2";

my $wan_in;
my $wan_out;
my $EC_pipe_min;
my $EC_pipe_max;
my $EC_priority;
my $OT_pipe_min;
my $OT_pipe_max;
my $OT_priority;

my $EC_no_of_flows;
my $EC_total_rate;
my $OT_no_of_flows;
my $OT_total_rate;

my $total_duration;

my $excess_available = 0;
=te
# Create a pattern
my $pattern_name = "pattern_iperf";
my $pattern_format = "port: 6001";
execute(create_pattern($appliance, $pattern_name, $pattern_format));

# Create a class
execute(create_class($appliance, $EC_class_name, $LINK0, $pattern_name));

$pattern_name = "other_traffic";
$pattern_format = "port: 5001";
execute(create_pattern($appliance, $pattern_name, $pattern_format));

# Create a class
execute(create_class($appliance, $OT_class_name, $LINK0, $pattern_name));

# sync after create class
print $appliance "sync\n";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync. $appliance->before()\n");
}

# Priority policy Creation
execute(create_policy($appliance, $EC_priority_policy_name, "priority 3"));
execute(create_policy($appliance, $OT_priority_policy_name, "priority 3"));

assign_policy($appliance, $EC_priority_policy_name, $EC_class_name);
assign_policy($appliance, $OT_priority_policy_name, $OT_class_name);
=cut
my $iperf_server_id = 0;
my $iperf_client_id = 0;

# Start iperf server listening on 5001 and 5002 ports
execute(start_iperf_server($server, \$iperf_server_id, " -u -p 6001"));
execute(start_iperf_server($server, \$iperf_server_id, " -u -p 5001"));

# Load test parameters from the local file "rate_conf"
my $local_session=Expect->new();
$local_session->log_stdout(0);
$local_session->send(`cat other_config/traffic_with_pipe_priority.csv\n`);
$local_session->expect(1,"cat");
my $after = $local_session->before();

my @cat_output = split("\n",$after);

foreach (@cat_output) 
{
	#print "This element is $_\n";
	my ($conf_string) = $_;
	my @str = split($delim, $conf_string);
	
	$wan_in = @str[0];
	$wan_out = @str[1];
	$EC_pipe_min = @str[2];
	$EC_pipe_max = @str[3];
	$EC_priority = @str[4];
	$OT_pipe_min = @str[5];
	$OT_pipe_max = @str[6];
	$OT_priority = @str[7];
	
	$EC_no_of_flows = @str[8];
	$EC_total_rate = @str[9];
	$OT_no_of_flows = @str[10];
	$OT_total_rate = @str[11];
	
	$total_duration = trim(@str[12]);
	
=foreach (@str) 
	{
		print " $_ \n";
	}
=cut	
	set_pipe($appliance, 0, 0, $EC_class_name);
	set_pipe($appliance, 0, 0, $OT_class_name);
	
	# Modifying the WAN speed
	execute(set_wan_speed($appliance, $LINK0, $wan_in, $wan_out));
		
	set_pipe($appliance, $EC_pipe_min, $EC_pipe_max, $EC_class_name);
	change_policy($appliance, $EC_priority_policy_name, "priority $EC_priority");
		
	set_pipe($appliance, $OT_pipe_min, $OT_pipe_max, $OT_class_name);
	change_policy($appliance, $OT_priority_policy_name, "priority $OT_priority");
		
	print_log($ANY, "Test starting with the Config.\nOther Traffic - no_of_flows: $OT_no_of_flows, class_rate :$OT_total_rate, priority: $OT_priority\nTraffic in class no_of_flows: $EC_no_of_flows, class_rate :$EC_total_rate, priority: $EC_priority");
	print_log($ANY, "WAN speed In : $wan_in Out: $wan_out.\nOther Traffic - pipe min: $OT_pipe_min burstmax: $OT_pipe_max \nClass Traffic - pipe min: $EC_pipe_min burstmax: $EC_pipe_max");
	my $result = "Test Result :\n";
	set_shaping_off($appliance);
	
	$result = $result . "Shaping OFF : \n" . use_this_configuration();
	set_shaping_on($appliance);
	$result = $result . "Shaping ON : \n";
	for(my $run = 1 ; $run <= 3 ; $run++)
	{
		sleep($test_interval);
		$result = $result . "$run )." . use_this_configuration();
	}
	
	print_log($ANY, $result);
	print $result;
}

delete_policies($appliance,($EC_priority_policy_name, $OT_priority_policy_name));
#delete_classes($appliance,($EC_class_name, $OT_class_name));

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();
$appliance_root->soft_close();

print "\nLog file : " . $global_cfg{"log_file"};
print "\nOutput file : " . $global_cfg{"output_file"}."\n";

#-------------------------------------------------------------------------------
sub use_this_configuration
{
	my $pid;
	my %run_stats = ();
	my %before_stats = ();
	my %after_stats = ();
	my %other_stats = ();
	
	my $bw_other_traffic = 0;
	my $bw_class_traffic = 0;
	my $data_other_traffic = 0;
	my $data_class_traffic = 0;
	my $report = "";
	my $final = "";
	
	#execute(get_link_stats($appliance, \%before_stats, $LINK0));
	#execute(get_class_stats($appliance, \%before_stats, $EC_class_name));
	
	#$local_session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate, $option
	#1000,1000,32,0,3,0,0,3,1,500,1,200,50
	
	my $EC_flow_rate = ($EC_total_rate / $EC_no_of_flows);
	my $OT_flow_rate = ($OT_total_rate / $OT_no_of_flows);
	
	unless( $EC_flow_rate > 15 && $OT_flow_rate > 15)
	{
		return "Cannot run with this flow rate\n";
	}
	
	execute(start_iperf_clients($client, \$pid, $cfg{'server_loc_eth_ip'}, $EC_no_of_flows, $total_duration, $total_duration, $EC_flow_rate, " -p 5001"));	# Other Traffic
	execute(start_iperf_clients($client, \$pid, $cfg{'server_loc_eth_ip'}, $OT_no_of_flows, $total_duration, $total_duration, $OT_flow_rate, " -p 6001"));	# Class Traffic
	
	my $start_time = "";
	execute(get_date($appliance_root, \$start_time, " +\"%T\""));
	
	sleep ($total_duration);
	
	my $end_time = "";
	execute(get_date($appliance_root, \$end_time, " +\"%T\""));
	
	sleep (1);
	
	execute(get_link_stats($appliance, \%run_stats, $LINK0, undef, $start_time, $end_time));
	execute(get_class_stats($appliance, \%run_stats, $EC_class_name, undef, $LINK0, $start_time, $end_time));
	execute(get_class_stats($appliance, \%other_stats, $OT_class_name, undef, $LINK0, $start_time, $end_time));
	
	$bw_other_traffic = $OT_no_of_flows * $OT_flow_rate;
	$bw_class_traffic = $EC_no_of_flows * $EC_flow_rate;
	$data_other_traffic = $OT_no_of_flows * $OT_flow_rate * $total_duration;
	$data_class_traffic = $EC_no_of_flows * $EC_flow_rate * $total_duration;
	
	#execute(get_link_stats($appliance, \%after_stats, $LINK0));
	#execute(get_class_stats($appliance, \%after_stats, $EC_class_name));

	# Compare_stats taken at traffic running
	#foreach (sort keys %run_stats)
	#{
	#    print $_ ," : " ,$run_stats{$_}, "  ";
	#}
	
	print_log($OUT, "Expected Bandwidth and Amount of Data Trasfered
Bandwidth usage in Traffic A " . $bw_class_traffic . "Kbps 
Bandwidth usage in Traffic B " . $bw_other_traffic . "Kbps
Data transfer in Traffic A " . ($data_class_traffic / 8) . "KB
Data transfer in Traffic B " . ($data_other_traffic / 8) . "KB");
	
	
	# Checking on both the interfaces
	# Check flow count in traffic runtime stats, check all the flows are couted in interface stats
	$report = $report . "Flow count             - Actual_external = $run_stats{\"ls_ext_flow_count\"}.\n";
	$report = $report . "Class Flow count       - Actual_outbound = $run_stats{\"cs_out_flow_count\"}".".\n";
	$report = $report . "Other Class Flow count - Actual_outbound = $other_stats{\"cs_out_flow_count\"}".".\n";

	# Check bandwidth in traffic runtime stats, check all the traffic are accounted
	my $total_traffic = $bw_class_traffic + $bw_other_traffic;
	my $display_bw = expected_interface_bandwidth();
	my $deviation = ($display_bw * 2)  / 100;
	
	my $check_1 = $run_stats{"ls_int_tx_kbps"} <= ($display_bw + $deviation) && $run_stats{"ls_int_tx_kbps"} >= ($display_bw - $deviation);
	my $check_2 = $run_stats{"ls_ext_tx_kbps"} <= ($display_bw + $deviation) && $run_stats{"ls_ext_tx_kbps"} >= ($display_bw - $deviation);
	
	$report = $report . "Interface bandwidth    - Actual_internal = $run_stats{\"ls_int_tx_kbps\"} Kbps.\n";
	
	# Checking only the class traffic bandwith
	if($bw_class_traffic <= $wan_in)
	{
		$display_bw = $bw_class_traffic;
	}else
	{
		$display_bw = $wan_in;
	}
	
	$display_bw = expected_class_bandwidth();
	$deviation = ($display_bw * 2)  / 100;
	
	$check_1 = $run_stats{"cs_in_tx_kbps"} <= ($display_bw + $deviation) && $run_stats{"cs_in_tx_kbps"} >= ($display_bw - $deviation);;
	$check_2 = $run_stats{"cs_out_tx_kbps"} <= ($display_bw + $deviation) && $run_stats{"cs_out_tx_kbps"} >= ($display_bw - $deviation);
	
	$report = $report . "Class bandwidth        - Actual_inbound = $run_stats{\"cs_in_tx_kbps\"} Kbps\n";	
	$report = $report . "Other Class bandwidth  - Actual_inbound = $other_stats{\"cs_in_tx_kbps\"} Kbps\n";	
	
	
		
	# Check amount of data transfered in traffic
	my $total_data = (($data_class_traffic + $data_other_traffic) / 8);
	my $data_transmitted_int = $run_stats{"ls_int_tx_bytes"} / 1000;
	my $data_transmitted_ext = $run_stats{"cs_out_tx_bytes"} / 1000;
	$deviation = ($total_data * 2)  / 100;
	
	$report = $report . "Interface data transferred - Actual_internal =  $data_transmitted_int KB.\n";
		
	my $class_data_transfered = ($data_class_traffic / 8);
	my $data_transmitted_in = $run_stats{"cs_in_tx_bytes"} / 1000;
	my $data_transmitted_out = $run_stats{"cs_out_tx_bytes"} / 1000;
	$deviation = ($class_data_transfered * 2)  / 100;
	
	$report = $report . "Class data transferred       -  Actual_inbound  = $data_transmitted_in KB.\n";
	$report = $report . "Other Class data transferred -  Actual_inbound  = " . ($other_stats{"cs_in_tx_bytes"} / 1000) . " KB.\n";
	
	return $report;
}

#-------------------------------------------------------------------------------
sub expected_class_bandwidth
{
	# My Class traffic
	my $actual_rate = $EC_total_rate;
	
	$actual_rate = myclass_check($actual_rate);
	
	# Other Traffic
	my $OT_actual_rate = $OT_total_rate;
	if($OT_pipe_max == 0)
	{
		$OT_pipe_max = $wan_in;
	}
	if($OT_total_rate >= $OT_pipe_max)
	{
		$OT_actual_rate = $OT_pipe_max;
	}
	
	# Checking priority
	if($EC_priority == $OT_priority)
	{
		if(($actual_rate + $OT_actual_rate) >= $wan_in)
		{
			$actual_rate = $wan_in / 2;
			$actual_rate = myclass_check($actual_rate);
		}
	}else
	{
		$excess_available = $wan_in - ($actual_rate + $OT_actual_rate);
		if(($actual_rate + $OT_actual_rate) >= $wan_in)
		{
			$actual_rate = $actual_rate + burst_prio_rate($EC_priority);	
			$actual_rate = myclass_check($actual_rate);
		}else
		{
			if($EC_priority > $OT_priority)
			{
				$actual_rate = $actual_rate + burst_prio_rate($EC_priority);	
				$actual_rate = myclass_check($actual_rate);
			}else
			{
				$actual_rate = $actual_rate + burst_prio_rate($EC_priority);	
				my $min = $EC_pipe_min;
				if($EC_total_rate <= $min)
				{
					$min = $EC_total_rate;
				}
				if($min >= $actual_rate)
				{
					$actual_rate = $min;
				}
			}
		}
	}
	
	return $actual_rate;
=wan_in
	$EC_total_rate, $OT_total_rate
	$EC_pipe_max, $EC_pipe_min, $EC_priority
	
	$OT_pipe_max, $OT_pipe_min, $OT_priority
=cut
		
}
#-------------------------------------------------------------------------------
sub myclass_check
{
	my ($actual_rate1) = @_;
	
	if($EC_pipe_max == 0)
	{
		$EC_pipe_max = $wan_in;
	}
	
	if($EC_total_rate >= $EC_pipe_max)
	{
		$actual_rate1 = $EC_pipe_max;
	}
	
	return $actual_rate1;
}


#-------------------------------------------------------------------------------
sub burst_prio_rate
{
	return ($_ / 36) * $excess_available;
}


#-------------------------------------------------------------------------------
sub expected_interface_bandwidth
{
	my $max = $EC_pipe_max + $OT_pipe_max;
	if($EC_pipe_max == 0 ||  $OT_pipe_max == 0)
	{
		$max = $wan_in;
	}
	
	my $expected_bandwidth = $EC_total_rate + $OT_total_rate;
	
	if($max > $wan_in)
	{
		$max = $wan_in;
	}
	
	if($expected_bandwidth >= $max)
	{
		$expected_bandwidth = $max;
	}
	
	return $expected_bandwidth;
}
