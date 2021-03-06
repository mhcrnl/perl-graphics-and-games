use lib 'perllib';
use Torus;
use Deathstar;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>480)->pack();
my @focuspoint = (0); #length less than 3 should use default

my $sphere = Deathstar->new(100);
my @lightsource = (225, 225, -100);
$mw->update;
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,0);

my $obj = $tdc->registerObject($sphere,\@focuspoint,'#EEEEEE',200,200,201,0,1);

$tdc->rotate($obj,'x',-1,120,0);

MainLoop;