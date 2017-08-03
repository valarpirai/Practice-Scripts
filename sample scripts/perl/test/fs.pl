#!/usr/bin/perl

use strict;
use warnings;

my $present_dir = `pwd`;
my $hostname = `hostname`;

chomp($present_dir);
chomp($hostname);

my $data = "";
my $output = "";

while(1)
{
	print_out("$hostname:$present_dir\$ ");
	$data = <STDIN>;
	
	if ($data =~ /^vi$/ || $data =~ /^less$/ || $data =~ /^top$/)
	{
		print_out("");
	}elsif ($data =~ /^quit$/ || $data =~ /^exit$/ || $data =~ /^q$/)
	{
		last;
	}elsif ($data =~ /^cd .*/)
	{
		change_directory($data);
	}elsif ($data =~ /^pwd$/)
	{
		print_out($present_dir . "\n");
	}elsif ($data =~ /^ls.*/)
	{
		chomp($data);
		if ($data =~ /^.*\/.*/)
		{
			$output = `$data` || $!;
		}else
		{
			$output = `$data $present_dir` || $!;
		}
		print_out($output);
	}else
	{	
		$output = `$data` || $!;
		print_out($output);
	}
=va
	elsif ($data =~ /^pwd$/)
	{
		$output = `pwd`;
		print_out($output);
	}elsif ($data =~ /^ls$/)
	{
		list_files($present_dir);
	}elsif ($data =~ /^$/) # Handling the "Enter" Key press
	{}else
	{
		chomp($data);
		print_out("\'$data\' Command not found\n");
	}
=cut	
}

print_out("exit\n");
exit 0;
#-----------------------------------------------------------------------

sub list_files
{
	my ($dir) = @_;
	
	chomp($dir);
	
	opendir(DIR, $dir) or return "Cannot open directory $dir $!";

	while (my $file = readdir(DIR))
	{
		if (-f "$dir/$file")
		{
			print_out("f- $file\n");
		}elsif (-d "$dir/$file")
		{
			print_out("d- $file\n");
		}
	}
	closedir(DIR);
	return 0;
}
#-----------------------------------------------------------------------

sub push
{
	
}
#-----------------------------------------------------------------------

sub pull
{
	
}
#-----------------------------------------------------------------------

sub change_directory
{
	my ($cmd) = @_;
	my @val = split( " ", $cmd);
	if (-d "$present_dir/$val[1]")
	{
		$present_dir = "$present_dir/$val[1]";
		if ($val[1] =~ /^..$/)
		{
			my @s = split( "/", $present_dir);
			@s = @s[1..$#s - 2];
			$present_dir = "/" . join("/", @s);
		}elsif ($val[1] =~ /^.$/)
		{
			my @s = split( "/", $present_dir);
			@s = @s[1..$#s - 1];
			$present_dir = "/" . join("/", @s);
		}
	}elsif (-d $val[1])
	{
		$present_dir = $val[1];
	}else
	{
		print_out("Invalid Directory \'$val[1]\'\n");
	}
	return 0;
}
#-----------------------------------------------------------------------

sub print_out
{
	my (@text) = @_;
	print @text;
	return 0;
}
