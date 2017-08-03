#!/usr/bin/perl

use common;
use Getopt::Long;

#The default configurations 

my $lic_url="ftp://valar:testpass@192.168.1.204/tmp/lic_NPC.txt";
my $config_file = "app.cfg";
my %config = ();

#Script Begins here
GetOptions("lic|l=s" => \$lic_url,
	"config|c=s" => \$config_file);

%config = do $config_file;

=com
print "Start \n";
print $lic_url."\n";


my @key = keys %config;
foreach (@key) {
print "$_ $config{$_}";
print "\n";}

=cut
upload_license(%config);
print "\nEnd\n";


#This method will upload and apply license
sub upload_license($){
	#print " $config{'app_ip'}, testcom, $config{'admin_passwd'} ";
	$ssh_app = ssh_login($config{'app_ip'}, $config{'admin_user'}, $config{'admin_passwd'}); # Start SSH with the appliance = "192.168.1.206","root","testpass"

	#$ssh_app->log_stdout(1); # For printing ssh commands Output set 1, othre wise 0
	$ssh_app->log_file("/tmp/autossh.log.$$"); #print output in a file
	
	#print $ssh_app "system\r";
	#print $ssh_app "show config\r";
	#print $ssh_app "config license $lic_url\r";
	
	#print $ssh_app "logout\r";
	#print "\nin my function\n";
	print $ssh_app "date\n";
	print $ssh_app "exit\n";
	#print "\nin my function\n";
	$ssh_app->soft_close();
}
