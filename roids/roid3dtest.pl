use lib '../perllib';
use Roid3D;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default
my $roid = Roid3D->new(60, 30);
my @lightsource = (225, 225, -100);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,0);

my $obj = $tdc->registerObject($roid,\@focuspoint,'#DDDDDD',200,200,100);

$tdc->rotate($obj,'y',1,360);
$tdc->rotate($obj,'x',1,360);
$tdc->rotate($obj,'z',1,360);


MainLoop;