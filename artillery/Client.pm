package Client;

use IO::Socket;
use IO::Handle;

sub new{
	my $self={};
	$self->{SERVER} = undef;
	bless $self;
    	return $self;
}

sub connect
{
	my $self = shift;
	my $ip = shift;
	$self->{SERVER} = IO::Socket::INET->new(Proto     => "tcp",
	                                    PeerAddr  => $ip,
	                                    PeerPort  => 8001,
	                                    Timeout => 10)
	           or return 0;
	
	
    	$self->{SERVER}->autoflush(1);
    	return 1;
}

sub getMessage
{
	my $self = shift;
	my $handle = $self->{SERVER};
	if (defined (my $line = <$handle>)) {
		return $line;
	}else{
		return "NoCon\n";
	}
	return "NoCon\n";
}

sub sendMessage
{
	my $self = shift;
	my $message = shift;
	my $handle = $self->{SERVER};
	print $handle "$message\n" if (defined($handle));
}


sub closecon
{
	my $self = shift;
	#print "closing\n";
	close $self->{SERVER} if (defined($self->{SERVER}));
	$self->{SERVER} = undef;
}

1;