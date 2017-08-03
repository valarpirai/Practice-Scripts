#!/usr/bin/perl

use Expect;

$session=Expect->new();
#exec("cat /tmp/test_lic");
$session->log_stdout(0);
print $session `date\n`;

$out = $session->send(`cat /tmp/test_lic\n`);

$session->expect(1," Customer Id    \|Key                  \|Mac Address      \|Link Speed\|Links\|Features   \|Classes\| Flows \|Policies\|Expiry    \|Active \|");

#print "\n\nBefore : ".$session->before()." \nMatch : ".$session->match() ."\nAfter :". $session->after()."\n";


$after = $session->after();

@str = split("\n",$after);

#foreach (@str) 
#{
#	print "This element is $_\n";
#}

$str1=@str[2];
$str2=@str[3];


#print "\nasdf: $str1 \n asdf: $str2\n";

$delim = "\\|";
@first_line = split($delim, $str1);
@second_line = split($delim, $str2);

foreach (@first_line) 
{
	print "First String $_ v \n";
}
foreach (@second_line) 
{
	print "Second Line $_ v\n";
}






#$session->expect(1,"-re",".*---");
#print "Before : ".$session->before()." \nMatch : ".$session->match() ."\nAfter :". $session->after()."\n";


#$session->expect(1,"|");

#print "\n\nBefore : ".$session->before()." \nMatch : ".$session->match() ."\nAfter :". $session->after()."\n";

#$lic_string=$session->after();

#print "\nTest".$out;
