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

	until ($pass_sent == 1){
		if ($spawn->expect(1,"password:")) {
			$spawn->send("$_[2]\n");
			$pass_sent=1;
		}elsif($spawn->expect(1,"\(yes\/no\)")){
			$spawn->send("Yes\n");
		}		
	}
	#print "\nAfter Send Passwd";
	unless ($spawn->expect(1,"Last login:")) {
		die "\nLogin Error\n";	
	};

	#print "\nReturn";
	return $spawn;
}
1;
