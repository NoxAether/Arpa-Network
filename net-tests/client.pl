#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

# Configuration
my $host = '20.5.40.81';
my $port = 9000;

# Attempt to connect
my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => 5,
) or die "Socket error: $!\n";

# Ensure immediate flush
$socket->autoflush(1);

# Send message
my $message = "one\n";
print $socket $message
    or die "Send error: $!\n";

# Read response
my $response = '';
my $bytes = $socket->recv($response, 1024);
if (defined $bytes) {
    print "Received: $response";
} else {
    warn "Read error: $!\n";
}

# Clean up
$socket->close()
    or warn "Close error: $!\n";
