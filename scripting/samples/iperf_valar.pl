#!/usr/bin/perl

use perl_modules::common;
use threads;

execute(load_config("228"));

$session = execute_ssh(login("192.168.1.209", "root", "testpass"));
$id = 0;

$session=Expect->new();
$session->log_stdout(0);

$out = $session->send(`cat conf\n`);
$session->expect(1,"cat");
$after = $session->before();

@str = split("\n",$after);
my $delim = "/ /";

foreach (@str) 
{
	#print "This element is $_\n";
	@str1 = split($delim, $_);
	foreach (@str1) 
	{
		print " $_ ";
	}
	#$session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate
	#32 128 U 200 2 1 20 10 1 400 200 32 
	start_iperf_clients($session, \$id, "9.0.0.1", @str1[3], @str1[4], 120, @str1[5], " -p 5001");	
	start_iperf_clients($session, \$id, "9.0.0.1", @str1[6], @str1[7], 120, @str1[8], " -p 5002");	
	print "\n";
}




=my @arr = (1,2,3,4);


foreach (@arr) {
   push @threads, threads->new(\&start_iperf_clients, $session, );
}
print "\n\nThread creation\n\n";

foreach (@threads) {
   $_->join();
}
=cut

print "\n\nEnd of script\n\n";

#-------------------------------------------------------------------------------
sub start_iperf_server
{
	my ($session, $pid_ref, $options) = @_;
	
	my $cmd = "iperf -s ";
	
	if(defined $options)
	{
		$cmd .= $options;
	}
	
	print $session "$cmd&\n";
	my $match = $options."&";
	if($session->expect(2, $match))
	{
		my @out=split("\n", $session->after());
		$$pid_ref = int(substr(trim(@out[1]),4));
	}

	$match = "Server listening on ";
	unless($session->expect(1, $match))
	{
		return "Failed to start iperf server.\n";
	}
		
	return $SUCCESS;
}

#-------------------------------------------------------------------------------
sub start_iperf_client
{
	my ($session, $pid_ref, $options) = @_;
	
	my $cmd = "iperf";
	
	if(defined $options)
	{
		$cmd .= $options;
	}
	
	print $session "$cmd\n";
	my $match = "\$ $cmd";
	if($session->expect(2, $match))
	{
		my @out=split("\n", $session->after());
		$$pid_ref = int(substr(trim(@out[1]),4));
	}
	
	$match = "Client connecting to $cfg{\"server_loc_eth_ip\"}";
	unless($session->expect(1, $match))
	{
		return "Failed to start iperf Client.\n";
	}
	return $SUCCESS;
}
#-------------------------------------------------------------------------------
sub start_iperf_clients
{
	my ($session, $pid_ref, $server_ip, $no_of_flows, $flow_duration, $total_duration, $flow_rate) = @_;
	
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
	
	my $options;
	
	if( $no_of_flows <= 350 && $no_of_flows > 0)
	{
		$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P $no_of_flows";
		execute(start_iperf_client($session, $pid_ref, $options));
	}elsif($no_of_flows > 0)
	{
		my $thread_count = $no_of_flows;
		
		for (my $j=0; $j <= $no_of_flows; $j+=350) 
		{	
			if($thread_count >= 350 && ($thread_count / 350) > 0)
			{
				$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P 350";
			}elsif($thread_count <= 350)
			{
				$options = " -c $server_ip -t $flow_duration -u -b $flow_rate"."K -P ".$thread_count;
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
#-------------------------------------------------------------------------------

sub thread_tes
{
	my($val, $session, $pid_ref, $flow_duration, $total_duration, $no_of_flows, $flow_rate) = shift;
	
	start_iperf_clients($session, $pid_ref, $flow_duration, $total_duration, $no_of_flows, $flow_rate);
	
	for($i=0; $i<100; $i++)
	{
		print "\tthread :$val val: $i";
	}
	return ($val + 4);
}
