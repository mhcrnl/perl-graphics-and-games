use strict;
use IO::Socket;
use IO::Handle;
use Win32::Sound;


my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                  LocalPort => $ARGV[0],
                                  Listen    => 1,
                                  Reuse     => 1);
                                  
die "can't setup server: $!" unless $server;
Win32::Sound::Volume('100%');
my ($client,$clientaddr) = $server->accept();
#will only ever deal with the one connection, no forking or re-acceptance required etc.

while (<$client>){

	my $cmd = $_;
	chomp($cmd);
	if ($cmd =~ m/^Play:(.+)$/){
		#Win32::Sound::Volume('100%'); #may send vol info later
		Win32::Sound::Play("effects\\$1");
		#print "$1\n";
	}elsif ($cmd eq "POKE"){
		Win32::Sound::Volume('0%');
		Win32::Sound::Play("effects\\DRILLIMPACT.WAV");
		Win32::Sound::Volume('100%');
	}elsif ($cmd eq "END"){
		close $client;
	}

}
close $server;


