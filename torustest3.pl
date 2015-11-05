use lib 'perllib';
use Torus;
use Sphere;
use ThreeDCubesTest;
use Cuboid;
use strict;
use Tk;

use threads;
use threads::shared;

#changed so 3D engine can use threads properly on pixel draw - though now slightly more overhead in having to introduce threading here


our $cheight :shared = 0;
our $cwidth :shared = 0;
our $notify :shared = 0;
our %zbuf :shared;

my @lightsource = (225, 225, -500);

	our $tdc = ThreeDCubesTest->new(0, 0, \@lightsource,0,1);


my $actionthread = threads->new(\&_doAction,$tdc);



my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>600)->pack();
$cnv->createText(10, 20, -text=>'Loading, Please Wait ...', -font=>'{Arial Bold} 14',-fill=>'black', -anchor=>'w');



$mw->update;
$cheight=$cnv->Height;
$cwidth=$cnv->Width;

while  ($notify == 0 ){

	select (undef, undef, undef, 0.25);
	
}

$tdc->outputZBuffer(\$cnv,\%zbuf);
$mw->update;
$actionthread->join();


MainLoop;


sub _doAction{
	my $tdc = shift;
	while ($cheight==0 && $cwidth==0){
		select (undef, undef, undef, 0.25);
	}
	
	$tdc->{CAMERA}[0]=$cwidth/2;
	$tdc->{CAMERA}[1]=$cheight/2;
	$tdc->{WIDTH}=$cwidth;
	$tdc->{HEIGHT}=$cheight;
	my $torus = Torus->new(50, 60);
	my $torus2 = Torus->new(50, 60);
	my $sphere = Sphere->new(100);
	my $cube = Cuboid->new();
	$cube->setDimensions(140,140,140);

	my @focuspoint=(0);
	my $obj = $tdc->registerObject($torus,\@focuspoint,'#00ff00',200,140,155,0,1);
	my $obj2 = $tdc->registerObject($torus2,\@focuspoint,'#ff00ff',200,260,155,0,1);
	#my $obj3 = $tdc->registerObject($sphere,\@focuspoint,'#0000ff',100,300,55,0,1);
	my $obj4 = $tdc->registerObject($cube,\@focuspoint,'#ff0000',130,330,85,0,1);
	
	my $centre = $cube->getCentre();
	my $obj3 = $tdc->registerObject($sphere,\@focuspoint,'#0000ff',$$centre[0],$$centre[1],$$centre[2],0,1);
	
	$tdc->rotate($obj4,'y',80,80,1);
	$tdc->rotate($obj4,'x',50,50,1);
	$tdc->rotate($obj,'y',50,50,1);
	
	$tdc->rotate($obj2,'y',-35,35);
	
	while ($tdc->{BUFREADY} == 0){
		select (undef, undef, undef, 0.25);
	}
	%zbuf=%{$tdc->{ZBUF}};
	$notify=1;

	
}
