#!/usr/bin/perl

use perl_modules::common;

sub method_1
{
	my ($var1, $var2) = @_;
	
	print $$var1." ".$$var2."\n";
	$$var1 = "value1";
	${$var2} = "value2";
}

sub test_ref
{
	my $session_1_dup  = $_[0];
	
	my $session_1 = $$session_1_dup;
	
	#print $session_1."  ".$_[0]."\n";
	print $session_1."  ".$$_[0]."s\n\n";
	
	print $session_1 "ifconfig eth0\n";
	$session_1->expect(100,"inet");
	print "\nLogin to 228\n";

	$session_1 = execute_ssh(login("192.168.1.94", "admin", "admin"));
	
	print $session_1 "system\nshow img\n";
	
	$$session_1_dup = $session_1;
	
	return $SUCCESS;
}


$session = "tests";
$test = "screen";
print $session ." ". $test."\n";

method_1(\$session,\$test);

print "session :".$session ."  Test : ". $test."\n";
execute(load_config("228"));

$ssh = execute_ssh(login("192.168.1.94", "testcom", "testpass"));

print "\nSending Date\n";

print $ssh "date\nuptime\n";
$ssh->expect(100,"up");
#test_ref(\$ssh);
			print "\nUp Expect success\n";
			print "\nBefore: ";
			print $ssh->before();
			print "\nMatch: ";
			print $ssh->match();
			print "\nAfter: ";
			print $ssh->after();
			print "\nUp End Expect\n";

print $ssh "ifconfig eth0\n";
			print "\nIF Bef Expect success\n";
			print "\nBefore: ";
			print $ssh->before();
			print "\nMatch: ";
			print $ssh->match();
			print "\nAfter: ";
			print $ssh->after();
			print "\nIf Bef End Expect\n";
$ssh->expect(100,"inesgdfgt");
			print "\nIF Aft Expect success\n";
			print "\nBefore: ";
			print $ssh->before();
			print "\nMatch: ";
			print $ssh->match();
			print "\nAfter: ";
			print $ssh->after();
			print "\nIf Aft End Expect\n";
$ssh->expect(100,"eth");
			print "\nIF Aft Expect success\n";
			print "\nBefore: ";
			print $ssh->before();
			print "\nMatch: ";
			print $ssh->match();
			print "\nAfter: ";
			print $ssh->after();
			print "\nIf Aft End Expect\n";
$ssh->send("logout\n");
$ssh->expect(100,"closed");
			print "\nLog Aft Expect success\n";
			print "\nBefore: ";
			print $ssh->before();
			print "\nMatch: ";
			print $ssh->match();
			print "\nAfter: ";
			print $ssh->after();
			print "\nLog Aft End Expect\n";
print "\nEnd of the Script\n";
