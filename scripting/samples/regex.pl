#!/usr/bin/perl

$out = `cat index.html | grep eagle-x86`;
print $out;
print "\n\n";

($match) = $out =~   /(?<=>)eagle-.*.rpm/g;
print $match;
print "\n\n";

