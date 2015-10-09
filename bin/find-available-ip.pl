#!/usr/bin/env perl
use warnings;
use strict;
use IO::Socket::INET;
my($base) = $ARGV[0] || '';
if ($base !~ /^\d+\.\d+\.\d+$/) {
    print(STDERR "usage: $0 x.y.z\n");
    exit(1);
}
for my $i (int(rand(50)) + 60 .. 254) {
    if (!IO::Socket::INET->new(
        PeerAddr => my $x = "$base.$i",
        PeerPort => '22',
        Proto => 'tcp',
        Timeout => 1,
    )) {
        print($x);
        exit(0);
    }
}
print(STDERR "Unable to find a free IP address on $base\n");
exit(1);
