package SphereAlt;
use lib 'perllib';
use GamesLib;
use Math::Trig;
use CanvasObject;
use Tk;

@ISA = qw(CanvasObject);



sub new
{

	my $self=CanvasObject->new;
	shift;
	my $sphereradius=shift;
	#my $sphereradius=0;
	$sphereradius=100 if ($sphereradius==0);
	my @vertexList;
	my @facetVertices;
	my $angleProg=10;

	my @arc;
	$points = (360/$angleProg);
	$pointsarc = (180/$angleProg) ;
	
	for (my $i = 0 ; $i < $pointsarc-1 ; $i++){
		$circleRad = sin(deg2rad(($i+1)*$angleProg))*$sphereradius;
		$circleRad=$circleRad*-1 if ($circleRad < 0);
		
		$y = cos(deg2rad(($i+1)*$angleProg))*$sphereradius;
		#print "---------\n";
		for (my $j = 0 ; $j < $points ; $j++){
			my $x = $circleRad*sin(deg2rad($j*$angleProg));
			my $z = $circleRad*cos(deg2rad($j*$angleProg));
			my $arrayadr = ($i*$points)+$j;
			$vertexList[$arrayadr] = [$x,$y,$z];
			#print "$arrayadr\n";
		}
		
	}
	for (my $i = 0 ; $i < $pointsarc-2 ; $i++){
	
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
	push(@vertexList,[0,$sphereradius,0]);
	push(@vertexList,[0,-$sphereradius,0]);
	
	for (my $i = 0 ; $i < $points ; $i++){
		my $addr = scalar @vertexList -2;
		print "$addr\n";
		my $j = $i+1;
		$j = 0 if ($i==$points-1);
		push(@facetVertices,[$addr,$i,$j,$idno]);
		$idno++;
		$addr = scalar @vertexList -1;
		push(@facetVertices,[$addr,$j+($points*($pointsarc-2)),$i+($points*($pointsarc-2)),$idno]);
		$idno++;
	}
	#print "$idno\n";
	push(@vertexList,[0,0,0]);

		   	
	$self->{GORAUD} = 1;  
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;
	$self->{RADIUS}=$sphereradius;
	bless $self;
	return $self;
	
}

sub getCentre
{
	my $self = shift;
	my @centre = @{${$self->{VERTEXLIST}}[scalar @{$self->{VERTEXLIST}} - 1]};
	return \@centre;
}


sub vertexNormal
{
	#easy to work out in a sphere, it is the vector sphere centre to point
	my $self=shift;
	my $vertexNo = shift;
	my $centre = $self->getCentre();
	my @vertex = @{${$self->{VERTEXLIST}}[$vertexNo]};
	
	my @vertNormal = ($vertex[0] - $$centre[0],$vertex[1] - $$centre[1],$vertex[2] - $$centre[2]);
	
	_normalise(\@vertNormal);
	
	return \@vertNormal;

}

sub pointInsideObject
{
	#quite easy just have to be within the radius
	my $self = shift;
	my $point = shift;
	my $centre = $self->getCentre();
	return 1 if (distanceBetween($point,$centre) <= $self->{RADIUS});
	
	return 0;
}

return 1;
