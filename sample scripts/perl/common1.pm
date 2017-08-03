#!/usr/bin/perl

package common;

use Expect;
use strict;
  use warnings;
  our $VERSION = '1.00';
  use base 'Exporter';
  our @EXPORT = qw(printstr version ssh_login);

sub version {
print "\nit is from perl module\n";
}


sub printstr
{
	print "\nit is from perl module\n";
}


#Usage ssh_login("192.168.1.26","username","password")
sub ssh_login($$$)
{
	print "\nParams : $_[0] $_[1] $_[2]\n";
	my $spawn=Expect->spawn("ssh $_[1]\@$_[0]") or die "Cannot Spawn\n";
	my $pass_sent=0;
	# log everything if you want
	#$spawn->log_file("/tmp/autossh.log.$$");
=test
	until ($pass_sent == 1){
		if($spawn->expect(2,"No route")){
			print "if part\n";
			die("Cannot connect to host $_[0]\n");
		}
		if($spawn->expect(1,"password:")) {
			$spawn->send("$_[2]\n");
			$pass_sent=1;
			print "pass part\n";
		}
		if($spawn->expect(1,"\(yes\/no\)")){
			$spawn->send("Yes\n");
			print "yes no part\n";
		}else{
			print "else part\n";
		}
	}
	print "\nAfter Send Passwd";
	unless ($spawn->expect(1,"Last login:")) {
		die "\nLogin Error\n";	
	};
=cut
	if($spawn->expect(1, '-re','.*\(yes\/no\).*')){
		if($spawn->before()) {
			#print $spawn->before();
			#print "\nadd";
			print $spawn "yes\n";
		}
	}
	unless($spawn->expect(10, '-re','.*password:.*')){
		if($spawn->before()) {
			#print $spawn->before();
			print "\n";
		}
		else {
			print "Timed out\n";
			exit;
		}
	}
	if($spawn->match()){	
		#print "Sending password to the host\n";
		$spawn->send("$_[2]\r");
		#print "\n";
	}
	#print "Crossed\n";
#This code will handle any errors after the password is sent

	unless($spawn->expect(10, '-re', '.*[#$>]')) {
		if($spawn->before() =~ /(Permission.*\s*.*)/) {
			#print "\nv2";
			print "\nInvalid password\n";
		}
		else {
			print "timed out\n";
		}
		exit;
	}
	#print "sending date command\n";

	$spawn->send("date\r");
	$spawn->expect(15, '-re', '.*[#$>]' );

	#print "\nReturn";
	return $spawn;
}

1;
