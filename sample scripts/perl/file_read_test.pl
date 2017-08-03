#!/usr/bin/perl

use Expect;

my $thread_count = 1;
if($thread_count >= 350 && ($thread_count / 350) >= 0)
{
	print '($thread_count / 350)'.($thread_count / 350)."\n";
}else
{
	print "Else part".'($thread_count / 350)'.($thread_count / 350)."\n";
}

print "end\n";




$session=Expect->new();
$session->log_stdout(0);

$out = $session->send(`cat conf\n`);
$session->expect(1,"cat");
$after = $session->before();

@str = split("\n",$after);
my $delim = "/ /";

foreach (@str) 
{
	#print "This element is $_\n";
	@str1 = split($delim, $_);
	foreach (@str1) 
	{
		print " $_ ";
	}
	
	print "\n";
}
