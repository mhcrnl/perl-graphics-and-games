use lib 'perllib';
use Torus;
use Sphere;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>480)->pack();
my @focuspoint = (0); #length less than 3 should use default

my $sphere = Sphere->new(150);
my $sphere2 = Sphere->new(150);
my @lightsource = (225, 225, -100);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);

my $obj = $tdc->registerObject($sphere,\@focuspoint,'#FF00FF',300,275,151,0,1);
my $obj2 = $tdc->registerObject($sphere2,\@focuspoint,'#00FF00',230,100,151,0,0);

#$tdc->rotate($obj,'y',45,45,1);


MainLoop;
