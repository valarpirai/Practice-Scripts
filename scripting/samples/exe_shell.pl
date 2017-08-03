#!/usr/bin/perl

use Expect;

$session = Expect->new();
print $session `ls -lrt`;
if ($session->expect(10, "README.txt"))
{
	print "Found\n";
}
else
{
	print "NOT Found\n";
}
