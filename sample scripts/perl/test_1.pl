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


my $duration = 5;
my $loop_count = $test_duration / $duration;

for($i = 1; $i < $loop_count ; $i++)
{
	# iperf client start traffic A
	$options = " -c $cfg{\"server_loc_eth_ip\"} -t $duration -u -b 4000K -P 1 -p 5001";
	execute(start_iperf_client($client, \$iperf_client_pid, $options));

	# start traffic B
	$options = " -c $cfg{\"server_loc_eth_ip\"} -t $duration -u -b 1500K -P 1 -p 5002";
	execute(start_iperf_client($client, \$iperf_client_pid, $options));
	
	sleep ($duration / 2);
}

# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();
