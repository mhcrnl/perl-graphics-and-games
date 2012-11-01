use lib 'perllib';
use Torus;
use Sphere;
use Cuboid;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>480)->pack();
my @focuspoint = (0); #length less than 3 should use default
$mw->update;
my $sphere = Sphere->new(150);
my $cube = Cuboid->new();
$cube->setDimensions(212,212,212);
my @lightsource = (225, 225, -100);
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);

my $obj = $tdc->registerObject($sphere,\@focuspoint,'#FF00FF',50,49,75,0,1);
my $obj2 = $tdc->registerObject($cube,\@focuspoint,'yellow',94,94,119,0,1);


$tdc->rotate($obj2,'y',46,46,1);
$tdc->rotate($obj2,'x',45,45,0);


MainLoop;
