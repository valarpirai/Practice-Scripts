#!/usr/bin/perl

use IO::Socket::INET;
use threads;

# flush after every write
$| = 1;

my $localport = shift || 5000;

my ($socket,$client_socket);
my ($peeraddress,$peerport);

# creating object interface of IO::Socket::INET modules which internally does
# socket creation, binding and listening at the specified port address.
$socket = new IO::Socket::INET (
LocalHost => '0.0.0.0',
LocalPort => $localport,
Proto => 'tcp',
Listen => 5,
Reuse => 1
) or die "ERROR in Socket Creation : $!\n";

print "SERVER Waiting for client connection on port $localport\n";
my @threads = ();
my $count = 0;
while(1)
{
	# waiting for new client connection.
	$client_socket = $socket->accept();
	# get the host and port number of newly connected client.
	$peer_address = $client_socket->peerhost();
	$peer_port = $client_socket->peerport();

	print "Accepted New Client Connection From : $peer_address, $peer_port\n ";
	my $t = threads->new(\&each_client, $client_socket, $count);
	push @threads, $t;
	$count += 1;
}

foreach (@threads) 
{
	my $num = $_->join();
	print "done with $num\n";
}
$socket->close();
#---------------------------------------------------------------------------------

sub each_client
{
	my ($client_socket, $count) = @_;
	
	my $present_dir = `pwd`;
	my $hostname = `hostname`;

	chomp($present_dir);
	chomp($hostname);

	my $data = "";
	my $output = "";

	while(1)
	{
		print_out($client_socket, "$hostname:$present_dir\$ ");
		
		# read operation on the newly accepted client
		$data = <$client_socket> or last;
		print "$count\$CMD - $data";
		if ($data =~ /^vi.*/ || $data =~ /^less.*/ || $data =~ /^man.*/ || $data =~ /^top$/)
		{
			print_out($client_socket, "");
		}elsif ($data =~ /^quit$/ || $data =~ /^exit$/ || $data =~ /^q$/)
		{
			last;
		}elsif($data =~ /^push.*/ || $data =~ /^pull.*/ )
		{
			my $rand_port = int(rand(60500) + 5000);
			my $d_file = substr $data , 5;
			chomp($d_file);
			print "Server PORT: $rand_port\n";
			
			print_out($client_socket, "Server PORT: $rand_port");
			
			if ($data =~ /^push.*/)
			{
				print_out($client_socket, push_file($rand_port, $d_file));
			}elsif($data =~ /^pull.*/)
			{
				print_out($client_socket, pull_file($rand_port, $d_file));
			}
		}elsif ($data =~ /^cd .*/)
		{
			#change_directory(\$present_dir, $data);
			print_out($client_socket, "");
		}elsif ($data =~ /^pwd$/)
		{
			print_out($client_socket, $present_dir . "\n");
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
			print_out($client_socket, $output);
		}else
		{	
			$output = `$data` || $!;
			my $err_c = `echo $?`;
			print "Exit code - $err_c\n";
			print_out($client_socket, $output);
		}
	}
	print "No. $count diconnected.\n";
	$client_socket->close();
	return $count;
}
#-----------------------------------------------------------------------

sub change_directory
{
	my ($pre_dir, $cmd) = @_;
	my @val = split( " ", $cmd);
	if (-d "$$pre_dir/$val[1]")
	{
		$$pre_dir = "$$pre_dir/$val[1]";
		if ($val[1] =~ /^..$/)
		{
			my @s = split( "/", $$pre_dir);
			@s = @s[1..$#s - 2];
			$$pre_dir = "/" . join("/", @s);
		}elsif ($val[1] =~ /^.$/)
		{
			my @s = split( "/", $$pre_dir);
			@s = @s[1..$#s - 1];
			$$pre_dir = "/" . join("/", @s);
		}
	}elsif (-d $val[1])
	{
		$$pre_dir = $val[1];
	}else
	{
		print_out($client_socket, "Invalid Directory \'$val[1]\'\n");
	}
	
	return 0;
}
#-----------------------------------------------------------------------

sub print_out
{
	my ($socket, $output) = @_;

	$output =~ s/(.)/sprintf("%X",ord($1))/eg;
	my @str = split("\n", $output);
	$output = join(" ", @str);
	print $socket "$output\n" or return 1;
	return 0;
}
#-----------------------------------------------------------------------

sub push_file
{
	my ($r_port, $file) = @_;
	my $DS_socket = new IO::Socket::INET (
	LocalHost => '0.0.0.0',
	LocalPort => $r_port,
	Proto => 'tcp',
	Listen => 1
	) or return "ERROR in Socket Creation : $!\n";

	print "DATA SERVER Waiting for client connection on port $r_port\n";
	
	# waiting for new client connection.
	$cli_socket = $DS_socket->accept();
	# get the host and port number of newly connected client.
	$peer_address = $cli_socket->peerhost();
	$peer_port = $cli_socket->peerport();
	
	my @s = split( "/", $file);
	$file = @s[$#s];
	print "writing to file $file.\n";
	print "Accepted DATA Connection From : $peer_address, $peer_port\n ";
	
	my $start = <$cli_socket>;
	chomp($start);
	unless( $start eq "start_trans")
	{
		$cli_socket->close();
		print "push failed $file.\n";
		return 1;
	}
	
	open OUT, ">$file" || return "Error while writing file\n";
	binmode OUT;
	while(<$cli_socket>)
	{
		print OUT $_; # writing the file
	}
	close OUT;
	$cli_socket->close();
	print "push finish $file\n";
	print "DATA SERVER closed on port $r_port\n";
	$DS_socket->close();
	return 0;
}
#-----------------------------------------------------------------------

sub pull_file
{
	my ($r_port, $file) = @_;
	my $DS_socket = new IO::Socket::INET (
	LocalHost => '0.0.0.0',
	LocalPort => $r_port,
	Proto => 'tcp',
	Listen => 1
	) or return "ERROR in Socket Creation : $!\n";

	print "DATA SERVER Waiting for client connection on port $r_port\n";
	
	# waiting for new client connection.
	$cli_socket = $DS_socket->accept();
	# get the host and port number of newly connected client.
	$peer_address = $cli_socket->peerhost();
	$peer_port = $cli_socket->peerport();
	
	my $start = <$cli_socket>;
	chomp($start);
	unless( $start eq "start_trans")
	{
		$cli_socket->close();
		print "pull failed $file\n";
		return 1;
	}
	
	print "Accepted DATA Connection From : $peer_address, $peer_port.\n ";
	
	open IN, "<$file" || return $!;
	binmode IN;
	# Copy data from one file to network machine.
	while(<IN>)
	{
		print $cli_socket "$_" || return "Error while copying file.\n";
	}
	close IN;
	
	$cli_socket->close();
	print "pull finished $file\n";
	$DS_socket->close();
	print "DATA SERVER closed on port $r_port\n";
	return 0;
}
#-----------------------------------------------------------------------
