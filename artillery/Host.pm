package Host;

use IO::Socket;
use IO::Handle;

sub new{
	my $self={};
	shift;
	$self->{SERVER} = IO::Socket::INET->new( Proto     => 'tcp',
	                                  LocalPort => '8001',
	                                  Listen    => 1,
	                                  Reuse     => 1);
	
	die "can't setup server: $!" unless $self->{SERVER}; #already in use
	$self->{CLIENT} = undef;
	bless $self;
    	return $self;
}

sub accept
{
	my $self = shift;
	my ($client,$clientaddr) = $self->{SERVER}->accept();
	$self->{CLIENT} = $client;
	$self->{CLIENT}->autoflush(1);
	return 1;
}

sub closecon
{
	my $self = shift;
	#print "closing\n";
	close $self->{SERVER} if (defined($self->{SERVER}));
	close $self->{CLIENT} if (defined($self->{CLIENT}));
	$self->{SERVER} = undef;
	$self->{CLIENT} = undef;
}

sub sendMessage
{
	my $self = shift;
	my $message = shift;
	my $handle = $self->{CLIENT};
	print $handle "$message\n" if (defined($handle));
}

sub getMessage
{
	my $self = shift;
	my $handle = $self->{CLIENT};
	if (defined (my $line = <$handle>)) {
		return $line;
	}else{
		return "NoCon\n";
	}
	return "NoCon\n";
}

1;