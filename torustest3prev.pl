use lib 'perllib';
use Torus;
use Sphere;
use ThreeDCubesTest;
use Cuboid;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>600)->pack();
my @focuspoint = (0); #length less than 3 should use default
my $torus = Torus->new(50, 60);
my $torus2 = Torus->new(50, 60);
my $sphere = Sphere->new(100);
my $cube = Cuboid->new();
$cube->setDimensions(140,140,140);

my @lightsource = (225, 225, -100);
$cnv->createText(10, 20, -text=>'Loading, Please Wait ...', -font=>'{Arial Bold} 14',-fill=>'black', -anchor=>'w');
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);
my $obj = $tdc->registerObject($torus,\@focuspoint,'#00ff00',200,140,155,0,1);
my $obj2 = $tdc->registerObject($torus2,\@focuspoint,'#ff00ff',200,260,155,0,1);
my $obj4 = $tdc->registerObject($cube,\@focuspoint,'#ff0000',130,330,85,0,1);

my $centre = $cube->getCentre();
my $obj3 = $tdc->registerObject($sphere,\@focuspoint,'#0000ff',$$centre[0],$$centre[1],$$centre[2],0,1);

$tdc->rotate($obj4,'y',80,80,1);
$tdc->rotate($obj4,'x',50,50,1);
$tdc->rotate($obj,'y',50,50,1);

$tdc->rotate($obj2,'y',-35,35);


MainLoop;
