use lib '../perllib';
use Whale3D;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default
my $whale = Whale3D->new();
my @lightsource = (225, 225, -100);
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $obj = $tdc->registerObject($whale,\@focuspoint,'#99BBFF',10,150,200,0,1);

my $centre = $whale->getCentre();
print join (":",@$centre);

$tdc->rotate($obj,'x',450,450);
#my @point=(200,200,200);
#$tdc->rotateAroundPoint($obj,'z',-1,450,\@point);


MainLoop;