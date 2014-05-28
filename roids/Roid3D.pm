package Roid3D;
use lib '../perllib';
use GamesLib;
use Math::Trig;
use CanvasObject;
use Tk;

@ISA = qw(CanvasObject);

=head1 NAME

Roid3D - Data object for a 3D asteroid object

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 METHODS

The following methods (in addition to those provided by the
superclass) are available:

=over 5

=item $roid3d->new($movex, $movey, $size, $hitpoints)

Create a new 3D asteroid object, it will shift it's position by $movex and $movey with a random rotation every time update is called
This basically builds a sphere and deforms it by altering the radius and y values by a random number for each point

=cut

my $vertexFacetMap;

sub new
{
	#basically a deformed sphere (based on sphereAlt)
	my $self=CanvasObject->new;
	shift;
	
	$self->{MX} = shift; #movement x
	$self->{MY} = shift; #movement y
	$self->{SIZE} = shift;
	$self->{HP} = shift; # hit points
	$self->{TAG} = '';
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

	if (! $vertexFacetMap){
		#to be used in finding shared normals without re-searching the facetvertices array every time
		$vertexFacetMap = $self->getVertexFacetMap(); 
	}
	
	bless $self;
	return $self;
	
}

=item $roid3d->getCentre

Returns reference to array defining the centre point of the object (x,y,z)

=cut

sub getCentre
{
	my $self = shift;
	my @centre = @{${$self->{VERTEXLIST}}[scalar @{$self->{VERTEXLIST}} - 1]};
	return \@centre;
}

=item $roid3d->offScreen($xlimit, $ylimit)

Returns true if no part of the object is visible any more based on the screen limits given

=cut

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

=item $roid3d->getBoundingBox

Returns coordinates of a rectangle that fully encloses the asteroid object

=cut

sub getBoundingBox
{
	my $self = shift;
	my $r = $self->{RADIUS};
	my $centre = $self->getCentre();
	
	return ($$centre[0]-$r, $$centre[1]-$r, $$centre[0]+$r, $$centre[1]+$r);
}

=item $roid3d->update

Move and rotate the asteroid as defined by the object's attributes

=cut

sub update
{
	my $self = shift;
	my $centre = $self->getCentre();
	$self->translate(-$$centre[0], -$$centre[1], -$$centre[2]);
	$self->rotate('x', $self->{SPINX});
	$self->rotate('y', $self->{SPINY});
	$self->translate($$centre[0]+$self->{MX}, $$centre[1]+$self->{MY}, $$centre[2],);
}

sub vertexNormal
{
	my $self = shift;
	my $vertexNo = shift;
	my $facetNo = shift;
	if (! $vertexFacetMap){
		$vertexFacetMap = $self->getVertexFacetMap(); 
	}
	
	my $vertexNormal = $self->SUPER::vertexNormal($vertexNo, $facetNo, $$vertexFacetMap[$vertexNo]);
	
	return $vertexNormal;
}

1;

=back