#!/usr/bin/perl

package common;

use Expect;
use strict;
  use warnings;
  our $VERSION = '1.00';
  use base 'Exporter';
  our @EXPORT = qw(printstr ssh_login);

#Usage ssh_login("192.168.1.26","username","password", print output 0 / 1)
sub ssh_login($$$$)
{
	print "\nParams : $_[0] $_[1] $_[2]\n";
	my $spawn=Expect->spawn("ssh $_[1]\@$_[0]") or die "Cannot Spawn\n";
	$spawn->log_stdout($_[3]);
	if($spawn->expect(1, '-re','.*\(yes\/no\).*')){
		if($spawn->before()) {
			print $spawn "yes\n";
		}
	}
	unless($spawn->expect(10, '-re','.*password:.*')){
		if($spawn->before()) {
			print "\n";
		}
		else {
			print "Timed out\n";
			exit;
		}
	}
	if($spawn->match()){	
		$spawn->send("$_[2]\r");
	}
	#This code will handle any errors after the password is sent
	unless($spawn->expect(10, '-re', '.*[#$>]')) {
		if($spawn->before() =~ /(Permission.*\s*.*)/) {
			print "\nInvalid password\n";
		}
		else {
			print "timed out\n";
		}
		exit;
	}
	$spawn->log_stdout(0);
	return $spawn;
}

1;
