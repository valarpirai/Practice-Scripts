#!/usr/bin/perl

use perl_modules::common;

execute(load_config("228"));

$ssh_server = execute_ssh(login("192.168.1.206", "root", "testpass"));
$ssh_client = execute_ssh(login("192.168.1.228", "root", "testpass"));
$ssh_appliance = execute_ssh(login("192.168.1.228", "admin", "admin"));

print "\nSending Date\n";

print $ssh_server "date\nuptime\n";
$ssh_server->expect(10,"up");
$iperf_server_pid = "";
$iperf_client_pid = "";

start_iperf_server($ssh_server, \$iperf_server_pid, "");

start_iperf_client($ssh_client, \$iperf_client_pid, " -c 5.0.0.2");

print "\nServer PID :".$iperf_server_pid;
print "\nClient PID :".$iperf_client_pid;
#$ssh_server->soft_close();
print $ssh_server " netstat -natup | grep iperf\n";
#$ssh_server->expect(1, "valar");
#$ssh_server->hard_close();
#sleep(60);
$ssh_server->expect(1, "valar");

$ssh_client->expect(20, "+  Done");
print $ssh_client "\n\n\n";
unless($ssh_client->expect(10, "+  Done"))
{
	print "\n\nERROR PROCESS NOT TERMINATED.\n"
}

print "\nEnd of the Script\n";
