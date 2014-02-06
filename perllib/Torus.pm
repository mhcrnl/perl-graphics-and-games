package Torus;
use Math::Trig;
use CanvasObject;
use Tk;
use GamesLib;

@ISA = qw(CanvasObject);



sub new
{

	my $self=CanvasObject->new;
	shift;
	
	my $tuberadius = shift; #radius of torus tube
	my $radius = shift; #radius of hole in torus
	my @circle;
	my @vertexList;
	my @facetVertices;
	my $arcprogression = 18;
	my $idno = 0;
	my $points = 360/$arcprogression;
	my @circlecentre = ($tuberadius,$radius+($tuberadius*2),$tuberadius);
	#make an initial circle 2d circle in x-z plane (y doesn't change)
	for (my $i = 0 ; $i < $points ; $i++){
		my $angle = deg2rad($i*$arcprogression);
		my $x = $tuberadius - ($tuberadius*sin($angle));
		my $z = $tuberadius - ($tuberadius*cos($angle));
		$circle[$i] = [$x,$radius+($tuberadius*2),$z];
		#print join(',',@{$circle[$i]})."\n";
	}
	#note, this is a clockwise circle
	#print "---------\n";
	#now move circle in a circle in y plane around centre point of torus
	
	for (my $i = 0 ; $i < $points ; $i++){
		my $angle = deg2rad($i*$arcprogression);
		for (my $j = 0 ; $j < @circle ; $j++){
			my $radiustopoint = ($radius+($tuberadius*2))-$circle[$j][2];
			my $y =$radiustopoint*sin($angle);
			my $z = $radiustopoint - ($radiustopoint*cos($angle));
			my $arrayadr = ($i*$points)+$j;
			$vertexList[$arrayadr] = [$circle[$j][0],$circle[$j][1]-$y,$circle[$j][2]+$z];
		}
		#circle centre points - used for easier shading
		my $radiustopoint = $radius+$tuberadius;
		my $y =$radiustopoint*sin($angle);
		my $z = $radiustopoint - ($radiustopoint*cos($angle));
		$vertexList[(($points*$points)+$i)] = [$circlecentre[0],$circlecentre[1]-$y,$circlecentre[2]+$z];
		
	}
	
	#join circles together (working out the triangles)
	for (my $i = 0 ; $i < $points-1 ; $i++){
	
		my $a = $i*$points;
		my $b = ($points*$i)+1;
		my $c = $points*($i+1);
		for (my $j = 1 ; $j < ($points*2)-1 ; $j++){
			if ($j%2 == 0){
				$a++;
				$b+=$points;
			}elsif ($j>1){
				$c++;
				$b-=($points-1);
			}
			push (@facetVertices, [$c, $b, $a,$idno]);
			$idno++;
		}
		#tie last points in circle to first points
		push (@facetVertices, [$points*($i+2)-1, $points*$i,($points*($i+1))-1,$idno]);
		$idno++;
		push (@facetVertices, [$points*($i+2)-1, $points*($i+1),$points*$i,$idno]);
		$idno++;
	
	}
	#tie last circle to first
	my $a = $points -1;
	my $b = ($points*$points)-2;
	my $c = ($points*$points)-1;
	for (my $j = 1 ; $j < ($points*2)-1 ; $j++){
		if ($j%2 == 0){
			$a--;
			$c=$points-($j*0.5);
		}elsif ($j>1){
			$b--;
			$c=($points*$points)-(($j+1)*0.5);
		}
		#print "$a, $b, $c\n";
		push (@facetVertices, [$c, $b, $a,$idno, '#000000']);
		$idno++;
	}
	#my $len = @vertexList;
	my $len = $points*$points;
	push (@facetVertices, [$points-1, 0,$len-1,$idno, '#000000']);
	$idno++;
	push (@facetVertices, [0, $len-$points,$len-1,$idno, '#000000']);
	
	my $cnt=0;

	$self->{POINTS}=$points;
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;	
	$self->{SORT} = 1;
	bless $self;
	
	$self->translate(-$tuberadius,-($radius+$tuberadius*2),-($radius+$tuberadius*2));
	$self->rotate('y',90,0,0);
	
	return $self;

}


sub vertexNormal
{
	
	my $self=shift;
	my $vertexNo = shift;
	my $points = $self->{POINTS}; 
	my @vertex = @{${$self->{VERTEXLIST}}[$vertexNo]};
	
	my $circlecentre = ($points*$points)+int($vertexNo/$points);
	my @centre = @{${$self->{VERTEXLIST}}[$circlecentre]};
	
	my @vertNormal = ($vertex[0] - $centre[0],$vertex[1] - $centre[1],$vertex[2] - $centre[2]);
	
	_normalise(\@vertNormal);
	
	return \@vertNormal;

}

return 1;