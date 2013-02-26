use lib 'perllib';

use Cuboid;
use Sphere;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default

my $c = Cuboid->new;
my $c2 = Cuboid->new;
my $s = Sphere->new(50);
my @lightsource = (350, 150, -100);

$c->setDimensions(80,80,80);


$c2->setDimensions(80,80,80);


$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);
$tdc->{DOSHADOW}=1;

$tdc->registerObject($s,\@focuspoint,'#FF00FF',100,150,200,0,0);
$tdc->registerObject($c,\@focuspoint,'#FF00FF',200,90,130,0,1);
 $tdc->registerObject($c2,\@focuspoint,'#00FF00',280,130,30,0,0);

my $centre = $c->getCentre();



MainLoop;
