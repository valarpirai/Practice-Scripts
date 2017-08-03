#!/usr/bin/perl -w
# server.pl
#--------------------

use strict;
use Socket;

# use port 7890 as default
my $port = shift || 7890;
my $proto = getprotobyname('tcp');

# create a socket, make it reusable
socket(SOCKET, PF_INET, SOCK_STREAM, $proto) 
   or die "Can't open socket $!\n";
setsockopt(SOCKET, SOL_SOCKET, SO_REUSEADDR, 1) 
   or die "Can't set socket option to SO_REUSEADDR $!\n";

# bind to a port, then listen
bind( SOCKET, pack( 'Sn4x8', AF_INET, $port, "\0\0\0\0" ))
       or die "Can't bind to port $port! \n";
listen(SOCKET, 5) or die "listen: $!";
print "SERVER started on port $port\n";

# accepting a connection
my $client_addr;
while ($client_addr = accept(NEW_SOCKET, SOCKET)) {
	# send them a message, close connection
	print NEW_SOCKET "Smile from the server";
	close NEW_SOCKET;
}
