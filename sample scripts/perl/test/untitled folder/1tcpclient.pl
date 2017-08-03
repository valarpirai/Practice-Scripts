#!/usr/bin/perl

use IO::Socket::INET;
use threads;

# flush after every write
$| = 1;

# initialize host and port
my $host = shift || 'localhost';
my $port = shift || 5000;

my $localhost = shift || 'localhost';
my $localport = shift || 5001;

my ($socket,$client_socket);

# creating object interface of IO::Socket::INET modules which internally creates
# socket, binds and connects to the TCP server running on the specific port.
$socket = new IO::Socket::INET (
PeerHost => $host,
PeerPort => $port,
Proto => 'tcp') or die "ERROR in Socket Creation : $!\n";

print "TCP Connection Success.\n";

my $output = "";
my @str = ();

# read the socket data sent by server.
$output = <$socket> or die "ERROR while reading from Server Socket: $!\n";
$output = format_out($output);
print "Connected to Server : \n$output";

while(1)
{
	$data = <STDIN>;
	print $socket "$data" or die "ERROR while writing on Server Socket: $!\n";
	if ($data =~ /^quit$/ || $data =~ /^exit$/ || $data =~ /^q$/)
	{
		last;
	}elsif($data =~ /^push.*/ || $data =~ /^pull.*/ )
	{
		my $d_file = substr $data , 5;
		chomp($d_file);
		
		$output = <$socket> or die "ERROR while reading PORT Number from Server: $!\n";
		$output = format_out($output);
		@str = split(" ", $output);
		my $rand_port = int(@str[2]);
		
		if ($data =~ /^push.*/)
		{
			#print push_file($host, $rand_port, $data) . "\n";
			my $t = threads->new(\&push_file, $host, $rand_port, $d_file);
			$t->join();
		}elsif($data =~ /^pull.*/)
		{
			#print pull_file($host, $rand_port, $data) . "\n";
			my $t = threads->new(\&pull_file, $host, $rand_port, $d_file);
			$t->join();
		}
	}
	$output = <$socket> or die "ERROR while reading from Server Socket: $!\n";
	$output = format_out($output);
	print "$output\n";
	
	$output = <$socket> or die "ERROR while reading from Server Socket: $!\n";
	$output = format_out($output);
	print "$output";
}

$socket->close();
#-----------------------------------------------------------------------

sub format_out
{
	my ($out) = @_;
	chomp($out);
	#print "$out\n";
	@str = split(" ", $out);
	$out = join("\n", @str);
	$out =~ s/([a-fA-F0-9][a-fA-F0-9])/chr(hex($1))/eg;
	#print "$out\n";
	return $out;
}
#-----------------------------------------------------------------------

sub push_file
{
	my ($t_host, $t_port, $file) = @_;
	my $d_socket = new IO::Socket::INET (
		PeerHost => $t_host,
		PeerPort => $t_port,
		Proto => 'tcp') or return "ERROR in DATA Socket Creation : $!\n";
	
	print "Conneted to server $t_host on $t_port.\n";
	print $d_socket "start_trans\n"; # Send start to server
	
	open IN, "<$file" || return $!;
	binmode IN;
	# Copy data from one file to network machine.
	while(<IN>)
	{
		print $d_socket "$_" || return "Error while copying file\n";
	}
	close IN;
		
	$d_socket->close();
	#print "push finish $file";
	return 0;
}
#-----------------------------------------------------------------------

sub pull_file
{
	my ($t_host, $t_port, $file) = @_;
	my $d_socket = new IO::Socket::INET (
		PeerHost => $t_host,
		PeerPort => $t_port,
		Proto => 'tcp') or return "ERROR in DATA Socket Creation : $!\n";
	
	print "Conneted to server $t_host on $t_port.\n";
	print $d_socket "start_trans\n"; # Send start to server
	
	my @s = split( "/", $file);
	$file = @s[$#s];
	print "writing to file $file.\n";
	open OUT, ">$file" || return $!;
	binmode OUT;
	# Copy data from one file to network machine.
	while(<$d_socket>)
	{
		print OUT $_ || return "Error while writing file\n"; # writing the file
	}
	close OUT;
		
	$d_socket->close();
	print "pull finish $file";
	return 0;
}
#-----------------------------------------------------------------------
