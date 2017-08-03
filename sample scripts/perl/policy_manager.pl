#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

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

my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));

execute_not(is_bypass_on($appliance));

# Create a pattern
my $new_pattname = "pattern_iperf";
my $new_patt_format = "port: 5001";
execute(create_pattern($appliance, $new_pattname, $new_patt_format));



# Create a class
#my $predef_pattname = "ftp_rule";
my $new_classname = "my_class";
execute(create_class($appliance, $new_classname, $LINK0, "pattern_iperf"));

print $appliance "sync\n";
unless($appliance->expect(30, "Activated new patterns and classes successfully"))
{
	execute("Failed to sync. $appliance->before()\n");
	exit;
}

# Modifying the WAN speed
my $wan_speed_in  = "5000";
my $wan_speed_out = "5000";
execute(set_wan_speed($appliance, $LINK0, $wan_speed_in, $wan_speed_out));

my $iperf_server_id = 0;
my $iperf_client_id = 0;

execute(start_iperf_server($server, \$iperf_server_id, " -u -p 5001"));
execute(start_iperf_server($server, \$iperf_server_id, " -u -p 5002"));

#execute(start_iperf_client($client, \$iperf_client_id, " -u -b 2M -t 120"));

my $local_session=Expect->new();
$local_session->log_stdout(0);
$local_session->send(`cat conf\n`);
$local_session->expect(1,"cat");
my $after = $local_session->before();

my @cat_output = split("\n",$after);
my $id;
my $delim = "/ /";
my %stats = ();

foreach (@cat_output) 
{
	#print "This element is $_\n";
	my @str1 = split($delim, $_);
	foreach (@str1) 
	{
		print " $_ ";
	}
	#$local_session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate
	#32 128 U 200 2 1 20 10 1 400 200 32 
	start_iperf_clients($client, \$id, "9.0.0.1", @str1[3], @str1[4], 120, @str1[5], " -p 5001");	
	start_iperf_clients($client, \$id, "9.0.0.1", @str1[6], @str1[7], 120, @str1[8], " -p 5002");	
	
	sleep (65);	
	execute(get_link_stats($appliance, \%stats, $LINK0));
	execute(get_flow_summary($appliance, \%stats));

	print "bandwidth usage Received: ".(($stats{"ext_rx_Bps"} * 8 ) / 1024)."Kbps\n";
	print "bandwidth usage Transmitted: ".(($stats{"ext_tx_Bps"} * 8 ) / 1024)."Kbps\n";
}
=push @threads, threads->new(\&start_iperf_server, $server, \$iperf_server_id, " -u");

push @threads, threads->new(\&start_iperf_client, $client, \$iperf_client_id, " -u -b 10M -t 120");



foreach (@threads) 
{
	execute($_->join());
}
unless($client->expect(120, "Server Report:"))
{
	print "Iperf client failed to connect server\n";
}


sleep(65);

#print "\n\njoin thread\n";
print "Server $iperf_server_id \nClient $iperf_client_id\n";

my %config = ();
execute(get_link_stats($appliance, \%config, $LINK0));
execute(get_flow_summary($appliance, \%config));

foreach (keys %config)
{
    print $_ ," : " ,$config{$_}, "\n";
}

print "bandwidth usage Received: ".(($config{"ext_rx_Bps"} * 8 ) / 1024)."Kbps\n";
print "bandwidth usage Transmitted: ".(($config{"ext_tx_Bps"} * 8 ) / 1024)."Kbps\n";
=cut
# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();


#-------------------------------------------------------------------------------
sub start_iperf_clients
{
	my ($session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate, $option) = @_;
	
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
	}
	unless(defined $total_duration)
	{
		$total_duration = 120;
	}
	unless(defined $flow_rate)
	{
		$flow_rate = 15;
	}
	
	if($flow_rate == 1)
	{
		$flow_rate = 15;
	}
	my $options;
	
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
			#sleep (1);
		}
	}else
	{
		return "Cannot start iperf Clients\n";
	}
	
	return $SUCCESS;
}

