use lib 'perllib';
use LineEq;
use Tk;
use CanvasObject;
use ThreeDCubesTest;
use Cuboid;
use strict;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();

	
	
	my $tempobj = Cuboid->new; 
	$tempobj->setDimensions(60,60,400);

	
my @focuspoint = (0,0,1000); #length less than 3 should use default
my @lightsource = (0, 0, -300);
$mw->bind('<Return>'=>[\&go]);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
our $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,90,1);
our $obj = $tdc->registerObject($tempobj,\@focuspoint,'#00ff00',220,150,100);


MainLoop;

#testing moving objects from in front of camera to partly behind for pixel draw - it does mess up I haven't figured it out yet
sub go{

$tdc->translate($obj,0,0,-30);

}