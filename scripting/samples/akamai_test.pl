#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

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


my $wan_speed_in  = "5000";
my $wan_speed_out = "5000";
execute(set_wan_speed($appliance, $LINK0, $wan_speed_in, $wan_speed_out));

my $start = 5;

my @class_names = ("cls1", "cls2", "cls3", "cls4", "cls5");  # Class Names
my @pattern_names = ("patt_1", "patt_2", "patt_3", "patt_4", "patt_5"); # pattern names
my @pattern_formats = ("port: 5001", "port: 5002", "port: 5003", "port: 5004", "port: 5005"); # pattern format

my @min_bw = (2000, 2500, 3000, 0 , 0); # values in Kbps
my @burstmax = (3000, 0 , 0, 0, 500); # values in Kbps
my @generate_traffic_at = (3500, 2000 , 5000, 1000, 1000); # values in Kbps
my @priority_policies = ("pl1", "pl2", "pl3", "pl4", "pl5"); # policy names
my @priorities = (5, 3, 4, 6, 7); # priority values

#delete_classes(@class_names);

# Create class and patterns
for($i = $start; $i < 5 ; $i++)
{
	execute(create_pattern($appliance, @pattern_names[$i], @pattern_formats[$i]));
	execute(create_class($appliance, @class_names[$i], $LINK0, @pattern_names[$i]));
}

# sync after create class
print $appliance "app\nsync\n\r";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync.\n");
	exit;
}

my $iperf_server_pid = 0;
my $iperf_client_pid = 0;

# Start iperf server listening on 5001 and 5005 ports
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5001"));
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5002"));
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5003"));
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5004"));
execute(start_iperf_server($server, \$iperf_server_pid, " -u -p 5005"));


#execute(start_iperf_client($client, \$iperf_client_id, " -u -b 2M -t 120"));

print $appliance "policy\n\r";

# pipe creation
for($i = $start; $i < 5 ; $i++)
{
	print $appliance "new pipe min @min_bw[$i] burstmax: @burstmax[$i] @class_names[$i]\n";
	my $match = "Added new pipe min:" . @min_bw[$i] . "kbps, max:" . @burstmax[$i] . "kbps for class @class_names[$i] (any)successfully";
	unless($appliance->expect(1, $match))
	{
		execute("Failed to assign pipe min for @class_names[$i].\n");
	}
}

print $appliance "policy\n\r";
# Policy Creation
for($i = $start; $i < 5 ; $i++)
{
	print $appliance "new policy @priority_policies[$i] priority @priorities[$i]\n";
	my $match = "New policy @priority_policies[$i] created successfully";
	unless($appliance->expect(1, $match))
	{
		execute("Failed to create policy @priority_policies[$i].\n");
	}
	
	print $appliance "assign policy @priority_policies[$i] @class_names[$i]\n";
	my $match = "Assigned policy @priority_policies[$i] to @class_names[$i] successfully";
	unless($appliance->expect(1, $match))
	{
		execute("Failed to assing policy @priority_policies[$i] to @class_names[$i].\n");
	}
}		

my $options = "";
# iperf client start
for($i = 0; $i < 5 ; $i++)
{
	$options = " -c $cfg{\"server_loc_eth_ip\"} -t $test_duration -u -b @generate_traffic_at[$i]"."K -P 1 -p 500".($i + 1);
	execute(start_iperf_client($client, \$iperf_client_pid, $options));
	sleep  (1);
}

sleep ($test_duration);

print "\nTest Finished\n";

#print $server "sleep $test_duration\n";
#$server->expect($test_duration, "[root@");

delete_classes(@class_names);
delete_policies(@priority_policies);

=print $appliance "logout\n\r";
print $server "logout\n\r";
print $client "logout\n\r";
=cut

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();

sub delete_classes
{
	print $appliance "app\n\r";
	# Delete class
	foreach(@_)
	{
		print $appliance "delete class $_\n";
		my $match = "Deleted class $_ successfully";
		unless($appliance->expect(20, $match))
		{
			execute("Failed to delete class $_.\n");
		}
	}
}

sub delete_policies
{
	
	print $appliance "policy\n\r";
	# Delete policies
	foreach(@_)
	{
		print $appliance "delete policy $_\n";
		my $match = "Deleted policy $_ successfully";
		unless($appliance->expect(1, $match))
		{
			execute("Failed to delete policy $_.\n");
		}
	}
}


=foreach (@cat_output) 
{
	my $delim = ",";
	#print "This element is $_\n";
	my ($conf_string) = $_;
	my @str = split($delim, $conf_string);
	
=foreach (@str) 
	{
		print " $_ \n";
	}
= cut	
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
		$report = $report . "Flow count       - Actual_external = $run_stats{\"ls_ext_flow_count\"},  - Expected_external = ".(@str1[4] + @str1[7]).".\n";
	}
	$report = $report . "Flow count       - Actual_external = $run_stats{\"ls_ext_flow_count\"},  - Expected_external = ".(@str1[4] + @str1[7]).".\n";
	# Check only the class flows are counted in class stats
	unless($run_stats{"cs_in_flow_count"} == @str1[7] || ($run_stats{"cs_out_flow_count"} == @str1[7]))
	{
		$report = $report . "Flow count       - Actual_outnound = $run_stats{\"cs_out_flow_count\"},  - Expected_outbound =  " . @str1[7] . ".\n";
	}
	$report = $report . "Flow count       - Actual_outnound = $run_stats{\"cs_out_flow_count\"},  - Expected_outbound =  " . @str1[7] . ".\n";
	
	
	# Check amount of data transfered in traffic
	my $total_data = (($data_class_traffic + $data_other_traffic) / 8);
	my $data_transmitted_int = ($after_stats{"ls_int_tx_bytes"} - $before_stats{"ls_int_tx_bytes"} / 1024);
	my $data_transmitted_ext = ($after_stats{"cs_out_tx_bytes"} - $before_stats{"cs_out_tx_bytes"} / 1024);
	
	unless($data_transmitted_int >= $total_data || $data_transmitted_ext >= $total_data)
	{
		$report = $report . "Interface data tranfered - Actual_internal =  $data_transmitted_int KB,  -  Expected_internal = $total_data KB.\n";
	}
	$report = $report . "Interface data tranfered - Actual_internal =  $data_transmitted_int KB,  -  Expected_internal = $total_data KB.\n";
	
	my $class_data_transfered = ($data_class_traffic / 8);
	my $data_transmitted_in = (($after_stats{"cs_in_tx_bytes"} - $before_stats{"cs_in_tx_bytes"}) / 1024);
	my $data_transmitted_out = (($after_stats{"cs_out_tx_bytes"} - $before_stats{"cs_out_tx_bytes"}) / 1024);
	
	unless($data_transmitted_in >= $class_data_transfered || $data_transmitted_out >= $class_data_transfered)
	{
		#$report = $report . "Class data transfered    -  Actual_inbound  = $data_transmitted_in KB, outbound = $data_transmitted_out KB, Expected = $class_data_transfered KB\n";
		$report = $report . "Class data transfered    -  Actual_inbound  = $data_transmitted_in KB,  -  Expected_inbound  =  $class_data_transfered KB\n";
	}
	$report = $report . "Class data transfered    -  Actual_inbound  = $data_transmitted_in KB,  -  Expected_inbound  =  $class_data_transfered KB\n";
	
	# Check bandwidth in traffic runtime stats, check all the traffic are accounted
	my $total_traffic =$bw_class_traffic + $bw_other_traffic;
	#my $check_1 = $run_stats{"ls_int_tx_kbps"} <= ($total_traffic + 8) || $run_stats{"ls_int_tx_kbps"} >= ($total_traffic - 8);
	#my $check_2 = $run_stats{"ls_ext_tx_kbps"} <= ($total_traffic + 8) || $run_stats{"ls_ext_tx_kbps"} <= ($total_traffic - 8);
	
	my $check_1 = ($run_stats{"ls_int_tx_kbps"} >= $total_traffic);
	my $check_2 = ($run_stats{"ls_ext_tx_kbps"} >= $total_traffic);
	
	unless($check_1)
	{
		$report = $report . "Interface bandwidth Actual_internal = $run_stats{\"ls_int_tx_kbps\"} Kbps, external = $run_stats{\"ls_ext_tx_kbps\"} Kbps, Expected = $total_traffic Kbps.\n";
	}
	$report = $report . "Interface bandwidth Actual_internal = $run_stats{\"ls_int_tx_kbps\"} Kbps, external = $run_stats{\"ls_ext_tx_kbps\"} Kbps, Expected = $total_traffic Kbps.\n";
	#unless($run_stats{"ls_int_rx_kbps"} == ($bw_class_traffic + $bw_other_traffic) || ($run_stats{"ls_ext_rx_kbps"} == ($bw_class_traffic + $bw_other_traffic))
	#{
	#	return "Failed. Interface bandwidth is not matching.\n";
	#}
	
	# Checking only the class traffic bandwith
	
	#$check_1 = $run_stats{"cs_in_tx_kbps"} <= ($bw_class_traffic + 8) || $run_stats{"cs_in_tx_kbps"} >= ($bw_class_traffic - 8);
	#$check_2 = $run_stats{"cs_out_tx_kbps"} <= ($bw_class_traffic + 8) || $run_stats{"cs_out_tx_kbps"} <= ($bw_class_traffic - 8);
	
	$check_1 = ($run_stats{"cs_in_tx_kbps"} >= $bw_class_traffic);
	$check_2 = ($run_stats{"cs_out_tx_kbps"} >= $bw_class_traffic);
	
	unless($check_1)
	{
		$report = $report . "Class bandwidth inbound = $run_stats{\"cs_in_tx_kbps\"} Kbps, outbound = $run_stats{\"cs_out_tx_kbps\"} Kbps, Expected = $bw_class_traffic Kbps\n";
	}
	$report = $report . "Class bandwidth inbound = $run_stats{\"cs_in_tx_kbps\"} Kbps, outbound = $run_stats{\"cs_out_tx_kbps\"} Kbps, Expected = $bw_class_traffic Kbps\n";
	print_log($LOG, "\nActual Bandwidth and Amount of Data Trasfered\n");
	print_log($LOG, "Badwidth Traffic A " . $run_stats{"cs_in_tx_kbps"} . "Kbps\n");
	print_log($LOG, "Badwidth Traffic B " . ($run_stats{"ls_int_tx_kbps"} - $run_stats{"cs_in_tx_kbps"}) . "Kbps\n");
	print_log($LOG, "Data transfer in Traffic A " . $class_data_transfered . "KB\n");
	print_log($LOG, "Data transfer in Traffic B " . ($data_transmitted_int - $data_transmitted_in) . "KB\n");
	
	return $report;
}
=cut
