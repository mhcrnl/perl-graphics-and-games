package Music;
use strict;
use Win32::Process;


sub new
{
	my $self={};
	shift;
	$self->{PROCESS} = undef;
	bless $self;
    	return $self;
}

sub play
{
	my $self = shift;
	my $dir = shift;
	if (defined($self->{PROCESS})){
		$self->{PROCESS}->Resume();
	}else{
		my $path = "";
		
	    open(my $fh, '-|', 'perl -h') || die $!;
	
		while (my $line = <$fh>) {
		    if ($line =~ /[Uu]sage:\s*(.+?)\s/){
		    	$path = $1;
		    	last;
		    }
		}
		
		close $fh;
		Win32::Process::Create($self->{PROCESS},
		$path,
		"perl Music.pl $dir",
		0,
		NORMAL_PRIORITY_CLASS,
	               ".");
	}
}

sub stop
{
	my $self = shift;
	$self->{PROCESS}->Suspend();

}

sub end
{
	my $self = shift;
	$self->{PROCESS}->Kill(0) if (defined($self->{PROCESS}));
	$self->{PROCESS}=undef;
}

1;