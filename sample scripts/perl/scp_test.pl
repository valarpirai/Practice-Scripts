#!/usr/bin/perl

use Expect;

$host = "192.168.1.209";
$passwd = "testpass";
$user = "root";
$scp_cmd="scp root\@10.0.0.1:/tmp/payloads.tar /tmp/payloads.tar";



my $session = ssh_login($host,$user,$passwd);
if($? == 0){
#print "here";
print $session " \r";
#print "here $scp_cmd";
print $session "$scp_cmd\r";
unless ($session->expect(30,"password: ")) {};
print $session "$passwd\r";
unless ($session->expect(30,".*$user.*")) {};
print $session "exit\r";

$session->soft_close(); 
print "\nend";
}else {
print "\nElse\n";
}

#Usage ssh_login("192.168.1.26","username","password")
sub ssh_login
{
	my ($ip_addr, $username, $password) = @_;

	# SSH login to the appliance
	my $spawn;
	unless($spawn=Expect->spawn("ssh $username\@$ip_addr"))
	{
		print "Not able to login to $ip_addr\n";
		return undef;
	}
	# If its first time login, it needs confirmation for adding to known hosts
	if($spawn->expect(3, '-re','.*\(yes\/no\).*'))
	{
		print $spawn "yes\n";
	}

	unless($spawn->expect(15, '-re','.*password:.*'))
	{
		print "Timed out when waiting for password for SSH\n";
		return undef;
	}

	$spawn->send("$password\r");

	#This code will handle any errors after the password is sent
	unless($spawn->expect(10, '-re', '.*[#$>]')) 
	{
		if($spawn->before() =~ /(Permission.*\s*.*)/) 
		{
			print "\nInvalid password for $ip_addr\n";
		} else 
		{
			print "Connection timed out after providing password\n";
		}
		return undef;
	}

	return $spawn;
}
