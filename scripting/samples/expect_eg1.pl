#!/usr/bin/perl

use perl_modules::common;

execute(load_config("228"));

$ssh = execute_ssh(login("192.168.1.94", "testcom", "testpass"));

print $ssh "date\n";
		print "\n\nExpect date\n";
		print "\nBefore: ". $ssh->before();
		print "\nMatch: ". $ssh->match();
		print "\nAfter: ". $ssh->after();
		print "\nExpect End date\n\n";
print $ssh "uptime\n";
		$ssh->expect(10,"up");
		print "\n\nExpect uptime\n";
		print "\nBefore: ". $ssh->before();
		print "\nMatch: ". $ssh->match();
		print "\nAfter: ". $ssh->after();
		print "\nExpect End uptime\n\n";
print $ssh "w\n";
		$ssh->expect(10,"12345");
		print "\n\nExpect 12345\n";
		print "\nBefore: ". $ssh->before();
		print "\nMatch: ". $ssh->match();
		print "\nAfter: ". $ssh->after();
		print "\nExpect End 12345\n\n";
print $ssh "whoami\n";
		$ssh->expect(10,"valar");
		print "\n\nExpect valar\n";
		print "\nBefore: ". $ssh->before();
		print "\nMatch: ". $ssh->match();
		print "\nAfter: ". $ssh->after();
		print "\nExpect End valar\n\n";
print $ssh "who\n";
		$ssh->expect(10,"tty");
		print "\n\nExpect tty\n";
		print "\nBefore: ". $ssh->before();
		print "\nMatch: ". $ssh->match();
		print "\nAfter: ". $ssh->after();
		print "\nExpect End tty\n\n";
print $ssh "logout\n";
print "\nEnd of script\n";
