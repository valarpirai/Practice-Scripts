#!/usr/bin/perl

use perl_modules::common;
use strict;
use Getopt::Long;

# Parsing the command line arguments
my $appl_name;


GetOptions("appl_name|a=s" => \$appl_name);
unless ($appl_name)
{
	print "Please provide the appliance name.. Which appliance?\n";
	exit;
}

# Loading the configurations from file
execute(load_config($appl_name));

# Login to appliance with default user and password
my $appliance = execute_ssh(login($cfg{"appliance_ip"}, $cfg{"appliance_username"}, $cfg{"appliance_password"}));

# Login to Server and Client
my $server = execute_ssh(login($cfg{"server_ip"}, $cfg{"server_username"}, $cfg{"server_password"}));
my $client = execute_ssh(login($cfg{"client_ip"}, $cfg{"client_username"}, $cfg{"client_password"}));

my $i = 1;

while($i == 1)
{
	print check_client_server_connection($server);
	
	print rollback_image(\$appliance);
	sleep (300);
	
	print check_client_server_connection($server);
	
	print upgrade_to_latest_build(\$appliance);
	sleep (300);
}


# Closing the sessions
$appliance->soft_close();
$server->soft_close();
$client->soft_close();


sub check_client_server_connection()
{
	my ($session) = @_;
	
	print $session "ping -c 10 $cfg{'client_loc_eth_ip'} \n";
	
	unless($session->expect(12, "10 packets transmitted, 10 received, 0% packet loss,"))
	{
		return "Ping failed";
	}
	return $SUCCESS;
}
