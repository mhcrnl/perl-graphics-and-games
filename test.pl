use lib 'perllib';
use LineEq;
use Tk;
use CanvasObject;
use ThreeDCubesTest;
use strict;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @vertexList;
my @line;
    $vertexList[0] = [100, 100, 20];
    $vertexList[1] = [100, 200, 20];
    $vertexList[2] = [200, 100, 20];
    
 my @facetVertices;   
   	$facetVertices[0][0] = 0;
      $facetVertices[0][1] = 1;
       $facetVertices[0][2] = 2;
	$facetVertices[0][3] = 0;
	
	
	my $tempobj = CanvasObject->new;    
	@{$tempobj->{VERTEXLIST}}=@vertexList; 
	@{$tempobj->{FACETVERTICES}}=@facetVertices; 
	
my @focuspoint = (0); #length less than 3 should use default
my @lightsource = (400, 225, -100);
$mw->update;
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,1);
my $obj = $tdc->registerObject($tempobj,\@focuspoint,'#00ff00',0,0,100);


$tdc->rotate($obj,'z',5,90);


MainLoop;