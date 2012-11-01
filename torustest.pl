use lib 'perllib';
use Torus;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default
my $torus = Torus->new(50, 50);
my @lightsource = (225, 225, -100);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,0);
my $obj = $tdc->registerObject($torus,\@focuspoint,'green',200,200,155);

$tdc->rotate($obj,'y',5,205);
#$tdc->rotate($obj,'z',9,360);
#$tdc->rotate($obj,'y',5,45);
foreach(1..40){
	$tdc->rotate($obj,'y',-45,-45, 1);
	$tdc->rotate($obj,'z',9,9, 1);
	$tdc->rotate($obj,'y',45,45);
}

$tdc->rotate($obj,'x',9,360);
my @point=(200,250,200);
$tdc->rotateAroundPoint($obj,'z',5,720,\@point);

MainLoop;
