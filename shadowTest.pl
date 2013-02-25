use lib 'perllib';

use Cuboid;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default

my $sphere = Cuboid->new;
my $sphere2 = Cuboid->new;
my @lightsource = (350, 150, -100);

$sphere->setDimensions(80,80,80);


$sphere2->setDimensions(80,80,80);


$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);
$tdc->{DOSHADOW}=1;

my $obj = $tdc->registerObject($sphere,\@focuspoint,'#FF00FF',200,90,130,0,1);
my $obj2 = $tdc->registerObject($sphere2,\@focuspoint,'#00FF00',280,130,30,0,0);

#$tdc->rotate($obj,'y',45,45,1);


MainLoop;
