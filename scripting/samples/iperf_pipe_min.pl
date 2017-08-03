#!/usr/bin/perl

=This script will read the input from the other_config/traffic_with_pipe.csv file

Traffic with pipe min.

Script Input Line:  32,,1000,U,10,40,150,1,40,200,,250,200,32,

SLA for class (pipe min) - 32 Kbps
WAN speed  - 1000 Kbps
Other Traffic - no_of_flows: 10, flow_duration: 40, flow_rate :150 Kbps
My_Class Traffic - no_of_flows: 1, flow_duration: 40, flow_rate :200 Kbps

Here I check the flow count, bandwidth used, data tranfered for both the interface level and class level.
=cut
=Things should taken care

=cut



use perl_modules::common;
use strict;
use Getopt::Long;

my $delim = ",";

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

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));

# Check bypass is off
execute_not(is_bypass_on($appliance));

# Check shaping is on, unless turn on it
unless(is_shaping_on($appliance) eq $SUCCESS)
{
	print $appliance "policy\nset shaping on\n";
	unless($appliance->expect(5, "Shaping turned on successfully"))
	{
		execute("Failed to turn on Shaping.\n");
		exit;
	}
}
my $class_name = "cls2";
=te
# Create a pattern
my $pattern_name = "pattern_iperf";
my $pattern_format = "port: 5002";
execute(create_pattern($appliance, $pattern_name, $pattern_format));



# Create a class
execute(create_class($appliance, $class_name, $LINK0, $pattern_name));

# sync after create class
print $appliance "sync\n";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync. $appliance->before()\n");
	exit;
}
=cut
my $iperf_server_id = 0;
my $iperf_client_id = 0;

# Start iperf server listening on 5001 and 5002 ports
execute(start_iperf_server($server, \$iperf_server_id, " -u -p 5001"));
execute(start_iperf_server($server, \$iperf_server_id, " -u -p 5002"));

#execute(start_iperf_client($client, \$iperf_client_id, " -u -b 2M -t 120"));


# Load test parameters from the local file "rate_conf"
my $local_session=Expect->new();
$local_session->log_stdout(0);
$local_session->send(`cat other_config/traffic_with_pipe.csv\n`);
$local_session->expect(1,"cat");
my $after = $local_session->before();

my @cat_output = split("\n",$after);

foreach (@cat_output) 
{
	#print "This element is $_\n";
	my ($conf_string) = $_;
	my @str = split($delim, $conf_string);
=foreach (@str) 
	{
		print " $_ \n";
	}
=cut	
	# Modifying the WAN speed
	my $wan_speed_in  = "@str[2]";
	my $wan_speed_out = "@str[2]";
	execute(set_wan_speed($appliance, $LINK0, $wan_speed_in, $wan_speed_out));
	
	print $appliance "policy\n\rnew pipe min @str[0] burstmax: @str[2] $class_name\n";
	#print $appliance "policy\n new pipe min @str[0] $class_name\n";
	my $match = "Added new pipe min:" . @str[0] . "kbps, max:" . @str[2] . "kbps for class $class_name (any)successfully";
	#my $match = "Added new pipe min:" . @str[0] . "kbps, max:kbps for class $class_name (any)successfully";
	unless($appliance->expect(1, $match))
	{
		execute("Failed to assign pipe min for $class_name.\n");
		exit;
	}
	
	print_log($ANY, "Test starting with the Config.\nOther Traffic - no_of_flows: @str[4], flow_duration: @str[5], flow_rate :@str[6]\nTraffic in class no_of_flows: @str[7], flow_duration: @str[8], flow_rate :@str[9]");
	my $first = use_this_configuration($_);
	my $second = use_this_configuration($_);
	my $third = use_this_configuration($_);
	
	my $result = "Test Result :\n1. $first"."2. $second"."3. $third";
	print_log($ANY, $result);
	print $result;
}


# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();

print "Log file : " . $global_cfg{"log_file"};
print "Output file :" . $global_cfg{"output_file"};

#-------------------------------------------------------------------------------
sub start_iperf_clients
{
	my ($session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate, $option) = @_;
	my $seconds_to_run;
	unless(defined $server_ip)
	{
		return "Please provide server ip.\n";
	}
	unless(defined $no_of_flows)
	{
		$no_of_flows = 1;
	}
	unless(defined $flow_duration)
	{
		$flow_duration = 120;
		$seconds_to_run = 1;
	}
	unless(defined $total_duration)
	{
		$total_duration = 120;
	}
	unless(defined $flow_rate)
	{
		$flow_rate = 15;
	}
	
	if($flow_rate < 15)
	{
		$flow_rate = 15;
	}
	if($flow_duration < 120)
	{
		$seconds_to_run = 120;
	}
	my $options;
	#for(my $i = 0; $i < $seconds_to_run ; $i++ )
	#{	
		if( $no_of_flows <= 350 && $no_of_flows > 0)
		{
			$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P $no_of_flows ".$option;
			execute(start_iperf_client($session, $pid_ref, $options));
		}elsif($no_of_flows > 0)
		{
			my $thread_count = $no_of_flows;
			
			for (my $j=0; $j <= $no_of_flows; $j+=350) 
			{	
				if($thread_count >= 350 && ($thread_count / 350) > 0)
				{
					$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P 350 ".$option;
				}elsif($thread_count <= 350)
				{
					$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P ".$thread_count." ".$option;
				}
				execute(start_iperf_client($session, $pid_ref, $options));
				$thread_count -= 350;
			}
		}else
		{
			return "Cannot start iperf Clients\n";
		}
	#	sleep(1);
	#}
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub use_this_configuration
{
	my $pid;
	my %run_stats = ();
	my %before_stats = ();
	my %after_stats = ();
	my $test_duration = 120;
	my $bw_other_traffic = 0;
	my $bw_class_traffic = 0;
	my $data_other_traffic = 0;
	my $data_class_traffic = 0;
	my $report = "";
	my $final = "";
	
	execute(get_link_stats($appliance, \%before_stats, $LINK0));
	execute(get_class_stats($appliance, \%before_stats, $class_name));
	
	my ($conf_string) = $_;
	my @str1 = split($delim, $conf_string);
	
	#$local_session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate, $option
	#32,,1000,U,5,10,15,1,120,200,,250,200,32,
	
	start_iperf_clients($client, \$pid, "9.0.0.1", @str1[4], @str1[5], $test_duration, @str1[6], " -p 5001");	# Other Traffic
	sleep(1);
	start_iperf_clients($client, \$pid, "9.0.0.1", @str1[7], @str1[8], $test_duration, @str1[9], " -p 5002");	# Class Traffic
	
	sleep ((@str1[8] / 2) + 5);
	
	execute(get_link_stats($appliance, \%run_stats, $LINK0));
	execute(get_class_stats($appliance, \%run_stats, $class_name));
	
	$bw_other_traffic = @str1[4] * @str1[6];
	$bw_class_traffic = @str1[7] * @str1[9];
	$data_other_traffic = @str1[4] * @str1[4] * @str1[6];
	$data_class_traffic = @str1[7] * @str1[8] * @str1[9];
		
	sleep (@str1[8]);

	execute(get_link_stats($appliance, \%after_stats, $LINK0));
	execute(get_class_stats($appliance, \%after_stats, $class_name));

	# Compare_stats taken at traffic running
	
	#foreach (sort keys %run_stats)
	#{
	#    print $_ ," : " ,$run_stats{$_}, "  ";
	#}
	
	print_log($LOG, "\nExpected Bandwidth and Amount of Data Trasfered\n");
	print_log($LOG, "Badwidth usage in Traffic A " . $bw_class_traffic . "Kbps\n");
	print_log($LOG, "Badwidth usage in Traffic B " . $bw_other_traffic . "Kbps\n");
	print_log($LOG, "Data transfer in Traffic A " . ($data_class_traffic / 8) . "KB\n");
	print_log($LOG, "Data transfer in Traffic B " . ($data_other_traffic / 8) . "KB\n");
	
	
	# Checking on both the interfaces
	# Check flow count in traffic runtime stats, check all the flows are couted in interface stats
	unless($run_stats{"ls_int_flow_count"} == (@str1[4] + @str1[7]) || ($run_stats{"ls_ext_flow_count"} == (@str1[4] + @str1[7])))
	{
		$final = "Failed";
		$report = $report . "Flow count       - Actual_external = $run_stats{\"ls_ext_flow_count\"},  - Expected_external = ".(@str1[4] + @str1[7]).".\n";
	}
	
	
	# Check only the class flows are counted in class stats
	unless($run_stats{"cs_in_flow_count"} == @str1[7] || ($run_stats{"cs_out_flow_count"} == @str1[7]))
	{
		$final = "Failed";
		$report = $report . "Class Flow count       - Actual_outbound = $run_stats{\"cs_out_flow_count\"},  - Expected_outbound =  " . @str1[7] . ".\n";
	}
		
	
	# Check amount of data transfered in traffic
	my $total_data = (($data_class_traffic + $data_other_traffic) / 8);
	my $data_transmitted_int = ($after_stats{"ls_int_tx_bytes"} - $before_stats{"ls_int_tx_bytes"}) / 1024;
	my $data_transmitted_ext = ($after_stats{"cs_out_tx_bytes"} - $before_stats{"cs_out_tx_bytes"}) / 1024;
	
	unless($data_transmitted_int >= $total_data)
	{
		$final = "Failed";
		$report = $report . "Interface data tranfered - Actual_internal =  $data_transmitted_int KB,  -  Expected_internal = $total_data KB.\n";
	}
	
	
	my $class_data_transfered = ($data_class_traffic / 8);
	my $data_transmitted_in = (($after_stats{"cs_in_tx_bytes"} - $before_stats{"cs_in_tx_bytes"}) / 1024);
	my $data_transmitted_out = (($after_stats{"cs_out_tx_bytes"} - $before_stats{"cs_out_tx_bytes"}) / 1024);
	
	unless($data_transmitted_in >= $class_data_transfered)
	{
		#$report = $report . "Class data transfered    -  Actual_inbound  = $data_transmitted_in KB, outbound = $data_transmitted_out KB, Expected = $class_data_transfered KB\n";
		$final = "Failed";
		$report = $report . "Class data transfered    -  Actual_inbound  = $data_transmitted_in KB,  -  Expected_inbound  =  $class_data_transfered KB\n";
	}
	
	
	# Check bandwidth in traffic runtime stats, check all the traffic are accounted
	my $total_traffic =$bw_class_traffic + $bw_other_traffic;
	#my $check_1 = $run_stats{"ls_int_tx_kbps"} <= ($total_traffic + 8) || $run_stats{"ls_int_tx_kbps"} >= ($total_traffic - 8);
	#my $check_2 = $run_stats{"ls_ext_tx_kbps"} <= ($total_traffic + 8) || $run_stats{"ls_ext_tx_kbps"} <= ($total_traffic - 8);
	
	my $display_bw;
	if($total_traffic <= @str1[2])
	{
		$display_bw = $total_traffic;
	}else
	{
		$display_bw = @str1[2];
	}
	
	my $check_1 = ($run_stats{"ls_int_tx_kbps"} >= $display_bw);
	my $check_2 = ($run_stats{"ls_ext_tx_kbps"} >= $display_bw);
	
	unless($check_1)
	{
		$final = "Failed";
		$report = $report . "Interface bandwidth Actual_internal = $run_stats{\"ls_int_tx_kbps\"} Kbps,  - Expected = $display_bw Kbps.\n";
	}
	
	# Checking only the class traffic bandwith
	
	#$check_1 = $run_stats{"cs_in_tx_kbps"} <= ($bw_class_traffic + 8) || $run_stats{"cs_in_tx_kbps"} >= ($bw_class_traffic - 8);
	#$check_2 = $run_stats{"cs_out_tx_kbps"} <= ($bw_class_traffic + 8) || $run_stats{"cs_out_tx_kbps"} <= ($bw_class_traffic - 8);
	
	if($bw_class_traffic <= @str1[2])
	{
		$display_bw = $bw_class_traffic;
	}else
	{
		$display_bw = @str1[2];
	}
	
	$check_1 = ($run_stats{"cs_in_tx_kbps"} >= $display_bw);
	$check_2 = ($run_stats{"cs_out_tx_kbps"} >= $display_bw);
	
	unless($check_1)
	{
		$final = "Failed";
		$report = $report . "Class bandwidth   - Actual_inbound = $run_stats{\"cs_in_tx_kbps\"} Kbps,   - Expected_inbound = $display_bw Kbps\n";	
	}
	if($final ne "Failed")
	{
		$final = "Passed";
	}
	$report = $final.".\n". $report;
	
	print_log($LOG, "\nActual Bandwidth and Amount of Data Trasfered\n");
	print_log($LOG, "Badwidth Traffic A " . $run_stats{"cs_in_tx_kbps"} . "Kbps\n");
	print_log($LOG, "Badwidth Traffic B " . ($run_stats{"ls_int_tx_kbps"} - $run_stats{"cs_in_tx_kbps"}) . "Kbps\n");
	print_log($LOG, "Data transfer in Traffic A " . $class_data_transfered . "KB\n");
	print_log($LOG, "Data transfer in Traffic B " . ($data_transmitted_int - $data_transmitted_in) . "KB\n");
	
	return $report;
}
