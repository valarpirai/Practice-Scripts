#!/usr/bin/perl

use perl_modules::common;
use strict;

my $delim = ",";
sub parse_input
{
	my ($input_file, $alltest) = @_;
	
	my $file = "other_config/$input_file";
	open my $in, $file or die "Could not open $file: $!";

	while( my $line = <$in>)  
	{
		my @str = split($delim, $line);
		my %test = ();
		print join(",", @str);
		print "\n";
		$test{'wan_speed'} = @str[1];
		$test{'test_duration'} = @str[2];
		$test{'test_id'} = @str[0];
		
		my @str1 = @str[3..$#str];
		my $loop_count = ($#str1 / 7);
		print "loop " . $loop_count;
		my $i = 0;
		for(my $j = 0 ; $j < $loop_count; $j++)
		{
			my @class = (@str1[0+$i], @str1[1+$i], @str1[2+$i], @str1[3+$i], @str1[4+$i], @str1[5+$i], int(@str1[6+$i]));
			$i += 7;
			$test{"class_$j"} = [@class];
		}
		push @{$alltest} , \%test;
		#last if $. = 2;
	}

	close $in;
	return $SUCCESS;
}

my @alltest = ();
parse_input("test_60.csv", \@alltest);

for my $hash (@alltest) {
	#print $hash."\nvalar \n";
	my $id = 0;
	foreach (sort keys %{$hash})
	{
		if($_ ne "wan_speed" && $_ ne "test_duration" && $_ ne "test_id")
		{
			print "Class : " . $_;
			print " Pipe min : " . @{$hash->{$_}}[0];
			print " Pipe max : ".@{$hash->{$_}}[1];
			print " Flowrate min : ".@{$hash->{$_}}[2];
			print " Flowrate max : ".@{$hash->{$_}}[3];
			print " Priority : ".@{$hash->{$_}}[4];
			print " Traffic rate : ".@{$hash->{$_}}[5];
			print " No. of flows : ".@{$hash->{$_}}[6]. " ";
		}else
		{
			#print "\nKey: $_ and Value: $hash->{$_}";
			print " $_ : $hash->{$_}";
		}
		print "\n";
	}
	print "\n";
}
