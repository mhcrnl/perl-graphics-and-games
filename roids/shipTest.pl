use lib '..\perllib';
use Tk;
use ThreeDCubesTest;
use Ship3D;

$mw = MainWindow->new;
$mw->bind('<w>'=>[\&x1]);
$mw->bind('<s>'=>[\&x2]);

$mw->bind('<a>'=>[\&y1]);
$mw->bind('<d>'=>[\&y2]);

$mw->bind('<q>'=>[\&z1]);
$mw->bind('<e>'=>[\&z2]);

$userframe = $mw->Frame(-borderwidth=>2)->pack;
$cnv = $userframe->Canvas(-width=>500, -height =>500)->pack;


my @lightsource = (200, 200, -50); 
$mw->update; #needed for $canvas->Height to work
$tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource);

my $ship = Ship3D->new();

my @focus = (0);
our $obj = $tdc->registerObject($ship,\@focus,'red',0,0,50);

$mw->update;
MainLoop;

sub y1{
	$tdc->rotate($obj,'y',-1,10);
}

sub y2{
	$tdc->rotate($obj,'y',1,10);
}

sub x1{
	$tdc->rotate($obj,'x',-1,10);
}

sub x2{
	$tdc->rotate($obj,'x',1,10);
}

sub z1{
	$tdc->rotate($obj,'z',-1,10);
}

sub z2{
	$tdc->rotate($obj,'z',1,10);
}