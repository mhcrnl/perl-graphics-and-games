package Music;
use strict;
use Win32::Process;
#use Win32::TieRegistry;#updated to AP 5.10.1 build 1007 and TieRegistry no longer appears to pick up reg entry (on vista) have to go to older module
use Win32::Registry;


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
		#$Registry->Delimiter("/");
		#my $key= $Registry->{"HKEY_LOCAL_MACHINE/Software/perl"};
		#my $path= $key->{"/BinDir"};
		my $key;
		$::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\Perl\\", $key);
		my ($type, $path);
    		$key->QueryValueEx("BinDir", $type, $path);
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