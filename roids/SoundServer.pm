package SoundServer;
use strict;
use IO::Socket;
use IO::Handle;
if ($^O eq "MSWin32"){
use Win32::Process;
#use Win32::TieRegistry;#updated to AP 5.10.1 build 1007 and TieRegistry no longer appears to pick up reg entry (on vista) have to go to older module
#use Win32::Registry;
}

$SIG{CHLD}='IGNORE';

sub new
{
	my $self={};
	shift;
	my $no_channels = shift;
	my $channels;
	#print "$^O\n";
	if ($^O eq "MSWin32"){
		$channels = _setSoundServer($no_channels);
		if (@$channels < 2){
			print "sound not viable\n";
			$self->{PLAY} = \&playNone;
		}else{
			$self->{CHANNELS} = $channels;
			$self->{CURCHAN} = 0;
			$self->{PLAY} = \&playWin32;
		}
	}else{
		$self->{PLAY} = \&playOther;
	}
	bless $self;
    	return $self;
}

sub play
{
	my $self = shift;
	my $sound = shift;
	&{$self->{PLAY}}($self, $sound);
}

sub playWin32
{
	my $self = shift;
	my $sound = shift;
	my $channel = 0;
	if ($sound eq "special"){
		$channel = @{$self->{CHANNELS}}-1;
	}else{
	$channel = $self->{CURCHAN};
	if ($self->{CURCHAN} >= @{$self->{CHANNELS}}-2){ #reserve last channel, for rare long sounds
		$self->{CURCHAN} = 0;
	}else{
		$self->{CURCHAN}++;
	}
	}
	my $file = _getFile($sound);
	#print "$file - $channel\n";
	my $handle = ${$self->{CHANNELS}}[$channel];
	print $handle "Play:$file\n";
}

sub playOther
{
	#place holder until can find linux sound modules etc.
}

sub playNone
{
	
}

sub _getFile
{
	my $sound = shift;
	return "PETROL.WAV" if ($sound eq "bomb");
	return "TELEPORT.WAV" if ($sound eq "special"); #might need to reserve a channel (3 sec duration)
	return "MINETICK.WAV" if ($sound eq "hit2");
	return "MINEIMPACT.WAV" if ($sound eq "hit1");
	return "EXPLOSION1.WAV" if ($sound eq "die");
	return "EXPLOSION3.WAV" if ($sound eq "aliendie");
	return "SHOTGUNFIRE.WAV" if ($sound eq "bulletAP");
	return "MAGICBULLET.WAV" if ($sound eq "bulletBEAM");
	return "HANDGUNFIRE.WAV" if ($sound eq "bulletEXP");
	return "HOLYGRENADEIMPACT.WAV" if ($sound eq "shieldoff");
	return "DRILLIMPACT.WAV" if ($sound eq "bulletSTD");
}

sub _setSoundServer
{
	my $no_channels = shift;
	my @channels;
	my @p;
	#$Registry->Delimiter("/");
	#my $key= $Registry->{"HKEY_LOCAL_MACHINE/Software/perl"};
	#my $path= $key->{"/BinDir"};
	#my $key;
	#$::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\Perl\\", $key);
	#my ($type, $path);
    #$key->QueryValueEx("BinDir", $type, $path);
    # these registry settings are specific to ActivePerl - do something different if we want to be able to use different ones, such as Strawberry Perl
    #we could pull the perl directory from PATH (search for perl.exe), or more straight forward may be to check the perl usage (though this string could possibly change?)
    my $path = "";
    open(my $fh, '-|', 'perl -h') or die $!;

	while (my $line = <$fh>) {
	    if ($line =~ /[Uu]sage:\s*(.+?)\s/){
	    	$path = $1;
	    	last;
	    }
	}
	
	close $fh;
    
	for (my $i = 0 ; $i < $no_channels ; $i++){
		my $port = 7001+$i;
		print "$port\n";
		 Win32::Process::Create($p[$i],
		  $path,
		  "perl soundServer.pl $port",
		   0,
		   NORMAL_PRIORITY_CLASS,
                   ".");
	}
	sleep 1;
	for (my $i = 0 ; $i < $no_channels ; $i++){
		my $port = 7001+$i;
		my $go = 1;
		my $handle = IO::Socket::INET->new(Proto     => "tcp",
		                    PeerAddr  => "localhost",
		                    PeerPort  => $port,
                                    Timeout => 10) or $go = 0;
                if ($go){
                	push(@channels, $handle);
                	print $handle "POKE\n";
                }else{
                	print "Could not connect: $!\n";
                }
	}
	sleep 2;
	return \@channels;

}

sub end
{
	my $self = shift;
	for (my $i = 0 ; $i < @{$self->{CHANNELS}} ; $i++){
		my $handle = ${$self->{CHANNELS}}[$i];
		print $handle "END\n";
		close $handle;
	}
}

return 1;