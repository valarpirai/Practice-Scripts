#!/usr/bin/perl -w
# client.pl
#----------------

use strict;
use Socket;

# initialize host and port
my $host = shift || 'localhost';
my $port = shift || 7890;
my $server = "192.168.1.26";

# create the socket, connect to the port
socket(SOCKET,PF_INET,SOCK_STREAM,(getprotobyname('tcp'))[2])
   or die "Can't create a socket $!\n";
connect( SOCKET, pack( 'Sn4x8', AF_INET, $port, $server ))
       or die "Can't connect to port $port! \n";

my $line;
while ($line = <SOCKET>) {
	print "$line\n";
}
close SOCKET or die "close: $!";
