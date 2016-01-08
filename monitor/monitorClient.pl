use MonitorComponent;
use Utils;
use XML::Simple;
use strict;
use Tk;

#read XML definition, by default this looks for an xml file with the same name as this pl file (monitorClient) in the same location as the pl file
my $config = XMLin(undef, KeyAttr => {monitor => '+name', item => '+name'}, ForceArray => [ 'monitor', 'component', 'series', 'item' ]);

our @monitors = (); 

foreach(keys(%{$config->{monitors}->{monitor}}))
{
    push(@monitors, MonitorComponent->new($config->{server}, $config->{port}, $config->{monitors}->{monitor}->{$_}));
}

our @frames = ();
our $mw = MainWindow->new();
$mw->OnDestroy([\&endit]);

$mw->geometry(($mw->screenwidth()-20)."x".($mw->screenheight()-80)."+1+1");

$mw->update();

foreach (@monitors)
{
	$frames[$_->{FRAMEID}] = 0;
}

foreach (@frames)
{
	$_ = $mw->Frame()->pack(-side=>'top', -anchor=>'w');
}

foreach (@monitors)
{
	$_->start($mw, $frames[$_->{FRAMEID}]);
}

our $width = $mw->Width;
our $height = $mw->Height;
our $resize = 0;
$mw->bind('<Configure>' => 
          sub 
          { 
          	#if window size has changed, redraw
          	my $w = shift;
          	return if ($w != $mw);
           	if ($w->Width != $width || $w->Height != $height)
           	{
           		$width = $w->Width;
           		$height = $w->Height;
	           	$resize = 1;
           	}
          });

our $go = 1;
our $flashDir = "plus";
our $flashVal = 0;

while($go)
{
	my $flash = flash();
	foreach (@monitors)
	{
		if ($resize)
		{
			$_->start($mw, $frames[$_->{FRAMEID}]);
		}
		$_->update($flash);
	}
	$resize = 0 if ($resize);
	$mw->update();
	select (undef, undef, undef, 0.05);
}

#MainLoop;


sub endit{
	$go = 0;
	foreach (@monitors)
	{
		$_->stop();
	}
	print "Finished\n";
}

sub flash
{
	if ($flashDir eq "plus"){
		$flashVal += 20;
		if ($flashVal > 225){
			$flashVal = 225;
			$flashDir = "minus"
		}
	}else{
		$flashVal -= 20;
		if ($flashVal < 0){
			$flashVal = 0;
			$flashDir = "plus"
		}	
	}
	return Utils::dec2hex($flashVal);

}
