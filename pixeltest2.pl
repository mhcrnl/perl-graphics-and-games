use lib 'perllib';
use LineEq;
use Tk;
use CanvasObject;
use strict;

my $mw = MainWindow->new();
my $cnv = $mw->Canvas(-width=>400, -height=>400)->pack();
my @vertexList;
my @line;
    $vertexList[0] = [50, 50, 0];
    $vertexList[1] = [50, 150, 0];
    $vertexList[2] = [150, 180, 0];
	my $tempobj = CanvasObject->new;    
	@{$tempobj->{VERTEXLIST}}=@vertexList; 
    
foreach (1..180){
$cnv->delete('all');
my $centre = $tempobj->getCentre();
$tempobj->translate(-$$centre[0], -$$centre[1], 0);
$tempobj->rotate('z',1,$$centre[0],$$centre[1]);


    $line[0] = LineEq->new($vertexList[0][0],$vertexList[0][1],$vertexList[1][0],$vertexList[1][1]);
    $line[1] = LineEq->new($vertexList[1][0],$vertexList[1][1],$vertexList[2][0],$vertexList[2][1]);
    $line[2] = LineEq->new($vertexList[2][0],$vertexList[2][1],$vertexList[0][0],$vertexList[0][1]);
    
    my $minx=$vertexList[0][0];
    my $maxy=$vertexList[0][1];
    my $maxx=$vertexList[0][0];
    my $miny=$vertexList[0][1];
    
    for(0..2){
    	if ($vertexList[$_][0] > $maxx){
    		$maxx = $vertexList[$_][0];
    	}elsif ($vertexList[$_][0] < $minx){
    		$minx = $vertexList[$_][0];
    	}
    	if ($vertexList[$_][1] > $maxy){
		$maxy = $vertexList[$_][1];
	}elsif ($vertexList[$_][1] < $miny){
		$miny = $vertexList[$_][1];
    	}
    }
    

    for my $x (int($minx+0.5)..int($maxx+0.5)){
	my $starty='n';
	my $endy='n';
	for my $i (0..2){
		my $y = $line[$i]->yAtx($x);
		if ($y ne 'n' && $x>=$line[$i]->{MINX} && $x<=$line[$i]->{MAXX}){
			if ($starty eq 'n'){
				if ($y <= $maxy && $y >= $miny){
				$starty=$y;
				$endy=$y;
				}
			}else{
				if ($y <= $maxy && $y >= $miny){
					$starty=$y if($y < $starty);
					$endy=$y if($y > $endy);
				}
			}
		}
	}
		#print "$x : $starty : $endy\n";
	if ($starty ne 'n' && $endy ne 'n'){
	for my $y (int($starty+0.5)..int($endy+0.5)){
		$cnv->createRectangle($x, $y,$x, $y, -fill=>'green',-outline=>'green');
		#also need to figure the z value for a point if it were to go into a z buffer
	}
	}
    }
    
    
 $mw->update; 

 }
 MainLoop;