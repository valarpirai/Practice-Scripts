#!/usr/bin/perl

# Need to add stats checking code

use perl_modules::common;
use strict;
use Getopt::Long;

my $delim = ",";

# Parsing the command line arguments
my $appl_name;
my $test_duration;
my $i = 1;

GetOptions("appl_name|a=s" => \$appl_name,
			"test_duration|t=s" => \$test_duration);
unless ($appl_name)
{
	print "Please provide the appliance name.. Which appliance?\n";
	exit;
}
unless ($test_duration)
{
	print "Please provide the test duration. use option -t N\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

#$global_cfg{"log_file"} = "burst_iperf_log";
#$global_cfg{"output_file"} = "burst_iperf_output";


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

my $iperf_server_pid = 0;
my $iperf_client_pid = 0;

# Start iperf server listening on 5001 and 5002 ports
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5001"));
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5002"));





my $options = "";
# iperf client start traffic A
$options = " -c $cfg{\"server_loc_eth_ip\"} -t $test_duration -u -b 2000K -P 1 -p 5001";
execute(start_iperf_client($client, \$iperf_client_pid, $options));


# start traffic B
my $b_duration = $test_duration / 6;
my $sleep_duration = $b_duration / 6;

$b_duration = $b_duration - $sleep_duration;

for($i = 1; $i < 5 ; $i++)
{
	sleep  ($sleep_duration);
	
	$options = " -c $cfg{\"server_loc_eth_ip\"} -t $b_duration -u -b 1500K -P 1 -p 5002";
	execute(start_iperf_client($client, \$iperf_client_pid, $options));
	
	sleep ($b_duration);
}

# Closing the sessions
$appliance->soft_close();
$client->soft_close();
$server->soft_close();

=sub check_stats
{
	my (@before_stats, @after_stats, @running_stats) = @_;
	
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
		$report = $report . "Flow count       - Actual_outbound = $run_stats{\"cs_out_flow_count\"},  - Expected_outbound =  " . @str1[7] . ".\n";
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
=cut
