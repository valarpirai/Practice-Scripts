#!/usr/bin/env perl

print "Hello World!\n";

=ca
$str = '[0] =0x4A ,[1] =0x06 ,[2] =0x0E ,[3] =0xF1 ,[4] =0x95 ,[5] =0x3B ,[6] =0xD9 ,[7] =0x90 ,[8] =0x5B ,[9] =0x63 ,[10]=0xCA ,[11]=0xA9 ,[12]=0x37 ,[13]=0xC8 ,[14]=0x8D ,[15]=0xDA ,[16]=0x64 ,#[17]=0x82 ,[18]=0x99 ,[19]=0x9F ,[20]=0xE1 ,[21]=0x1A ,[22]=0x3B ,[23]=0xB6 ,[24]=0xFC ,[25]=0x68 ,[26]=0xC0 ,[27]=0xD2 ,[28]=0x7B ,[29]=0x01 ,[30]=0x21 ,[31]=0xDD';
$str =~ s/\s*,?\[.*?\]\s*=0x//gi;
print $str, "\n";


$str =~ s/([0-9A-F]{2})/0x$1, /gi;
print $str, "\n";


# Initial string
$string = "abcdefjhijklmnopqrstuvwx\nva";
print $string . "\n";
# convert each character from the string into HEX code
$string =~ s/(.)/sprintf("%x",ord($1))/eg;

print "$string\n";
$string = "abcdefjhijklmnopqrstuvwx\nvaASDF!@#\$#@%^%^%^&&%^&*(()_+{}\":';?/><,.";
print $string . "\n";
$string =~ s/(.)/sprintf("%X",ord($1))/eg;
print "$string\n";

$string =~ s/([a-fA-F0-9][a-fA-F0-9])/chr(hex($1))/eg;

print "$string\n";
=cut
		open IN, "<tcpserver.pl" || return $!;
		open OUT, ">vala.pl" || return $!;
		binmode IN;
		binmode OUT;
		# Copy data from one file to other file.
		while(<IN>)
		{
			print OUT $_ || return "Error while copying file\n";
		}
		close IN;
		close OUT;
