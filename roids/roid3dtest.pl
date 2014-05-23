use lib '../perllib';
use Roid3D;
use ThreeDCubesTest;
use Tk;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @focuspoint = (0); #length less than 3 should use default

my @lightsource = (225, 225, -100);
$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,0);

my $roid = Roid3D->new(2, 2, \$tdc,1);
$roid->{ID} = $tdc->registerObject($roid,\@focuspoint,'#AAAAAA',200,200,80);

my $cnt = 0;
while ($cnt < 100)
{
	select (undef, undef, undef, 0.05);
	$roid->update();
	$tdc->_updateAll();
	$cnt++;
}


MainLoop;