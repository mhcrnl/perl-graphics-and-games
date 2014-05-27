package Roid3D;
use lib '../perllib';
use GamesLib;
use Math::Trig;
use CanvasObject;
use Tk;

@ISA = qw(CanvasObject);



sub new
{
	#basically a deformed sphere (based on sphereAlt)
	my $self=CanvasObject->new;
	shift;
	
	$self->{MX} = shift; #movement x
	$self->{MY} = shift; #movement y
	$self->{TDC} = shift; #reference to 3d handler
	$self->{SIZE} = shift;
	$self->{HP} = shift; # hit points
	$self->{TAG} = shift;
	$self->{DEAD} = 0;
	$self->{ID} = 0;
	$self->{SPINX} = 5 - rand(10);
	$self->{SPINY} = 5 - rand(10);	
	
	$self->{RADIUS} = 15;
	my $angleProg = 60; #angle progression (should be a number that divides 360 with no remainder) - smaller value will generate more facets, bigger number more angular
	
	if ($self->{SIZE} == 2)
	{
		$self->{RADIUS} = 30;
		$angleProg = 45;
	}elsif ($self->{SIZE} == 4)
	{
		$self->{RADIUS} = 60;
		$angleProg = 36;
	}
	
	my @vertexList;
	my @facetVertices;
	
	my $ymodifier = int($self->{RADIUS}/8);
	my @arc;
	$points = (360/$angleProg);
	$pointsarc = (180/$angleProg) ;
	
	for (my $i = 0 ; $i < $pointsarc-1 ; $i++){
		$circleRad = sin(deg2rad(($i+1)*$angleProg))*$self->{RADIUS};
		$circleRad=$circleRad*-1 if ($circleRad < 0);
		
		$y = cos(deg2rad(($i+1)*$angleProg))*$self->{RADIUS};
		my $halfRadius = int($circleRad/2);
		for (my $j = 0 ; $j < $points ; $j++){
			my $modifiedRadius = $circleRad - $halfRadius + rand($halfRadius);
			my $x = $modifiedRadius*sin(deg2rad($j*$angleProg));
			my $z = $modifiedRadius*cos(deg2rad($j*$angleProg));
			my $arrayadr = ($i*$points)+$j;
			my $ymod = $y - $ymodifier + int(rand($ymodifier));
			$vertexList[$arrayadr] = [$x,$ymod,$z];
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
	push(@vertexList,[0,$self->{RADIUS},0]);
	push(@vertexList,[0,-$self->{RADIUS},0]);
	
	for (my $i = 0 ; $i < $points ; $i++){
		my $addr = scalar @vertexList -2;
		my $j = $i+1;
		$j = 0 if ($i==$points-1);
		push(@facetVertices,[$addr,$i,$j,$idno]);
		$idno++;
		$addr = scalar @vertexList -1;
		push(@facetVertices,[$addr,$j+($points*($pointsarc-2)),$i+($points*($pointsarc-2)),$idno]);
		$idno++;
	}
	push(@vertexList,[0,0,0]);
		   
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;
	$self->{SORT}=1;
	my $t = int(rand(180));
	$self->rotate('x', $t);
	$t = int(rand(180));
	$self->rotate('y', $t);

	bless $self;
	return $self;
	
}

sub getCentre
{
	my $self = shift;
	my @centre = @{${$self->{VERTEXLIST}}[scalar @{$self->{VERTEXLIST}} - 1]};
	return \@centre;
}

sub offScreen
{
	my $self = shift;
	my $xlimit = shift;
	my $ylimit = shift;
	
	my $centre = getCentre();
	
	return 1 if($$centre[0] > $xlimit + $self->{RADIUS});
	return 1 if($$centre[1] > $ylimit + $self->{RADIUS});
	return 1 if($$centre[0] < -$self->{RADIUS});
	return 1 if($$centre[1] < -$self->{RADIUS});
	return 0;
}

sub split
{
	#todo
}

sub delete
{
	my $self = shift;
	${$self->{TDC}}->removeObject($self->{ID});
}

sub getBoundingBox
{
	my $self = shift;
	my $r = $self->{RADIUS};
	my $centre = $self->getCentre();
	
	return ($$centre[0]-$r, $$centre[1]-$r, $$centre[0]+$r, $$centre[1]+$r);
}

sub update
{
	my $self = shift;
	${$self->{TDC}}->rotate($self->{ID}, 'x', $self->{SPINX}, $self->{SPINX},1);
	${$self->{TDC}}->rotate($self->{ID}, 'y', $self->{SPINY}, $self->{SPINY},1);
	${$self->{TDC}}->translate($self->{ID}, $self->{MX}, $self->{MY}, 0,1);
}