package Gate;
use CanvasObject;
use GamesLib;
use Cuboid;
use strict;
use Math::Trig;

our @ISA = qw(CanvasObject);

sub new
{
	my $self=CanvasObject->new;
	shift;
	my $blockwidth = shift;
	my $blockheight = shift;
	my $blockdepth = shift;
	#definition of block at top of gate
	
	my @vl;
	my @fv;
	
	#my $cube = Cuboid->new;
	#$cube->setDimensions(50,20,20);
	#$cube->translate(55.35, 0, 20);
	my $oradius = ($blockwidth/2)+$blockheight+($blockwidth*sin(deg2rad(45)));
	my $iradius = $oradius - $blockheight;
	my @focuspoint = (100, 100, 1000);
	
	my $modifier = 0;
	my $fvmod = 0;
	for (my $i = 0; $i < 8 ; $i++){
		my $cube = Cuboid->new;
		$cube->setDimensions($blockwidth,$blockheight,$blockdepth);
		$cube->translate(-($blockwidth/2), -$oradius, 0); #moves so centre of gate at 0,0 - any calling app will need to move it somewhere useful
		$cube->rotate('z',(45*$i),0,0);
		splice (@vl, @vl, 0, @{$cube->{VERTEXLIST}});
		splice (@fv, @fv, 0, @{$cube->{FACETVERTICES}});
		for (my $j = $fvmod ; $j < @fv ; $j++)
		{
			${$fv[$j]}[0]+=$modifier;
			${$fv[$j]}[1]+=$modifier;
			${$fv[$j]}[2]+=$modifier;
			${$fv[$j]}[3]+=$fvmod;
		}
		$modifier = @vl;
		$fvmod = @fv;
	}

	   	
	$self->{FOCUSPOINT}=\@focuspoint;
	$self->{VERTEXLIST}=\@vl;
	$self->{FACETVERTICES}=\@fv;
	$self->{SORT} = 1;
	$self->{IRADIUS} = $iradius;
	$self->{ORADIUS} = $oradius;
	bless $self;
	return $self;

}

sub pointInsideObject
{
	my $self = shift;
	my $point = shift;
	#get front of gate plane and normal through gate
	#get back plane and normal back through gate
	#if passing though vector camera to plane head towards each other in both cases
	
	my @backplane = _getNormal(\@{$self->{VERTEXLIST}[28]}, \@{$self->{VERTEXLIST}[4]}, \@{$self->{VERTEXLIST}[44]});
	#anti-clockwise - normal goes through gate
	
	my @foreplane = _getNormal(\@{$self->{VERTEXLIST}[40]}, \@{$self->{VERTEXLIST}[0]}, \@{$self->{VERTEXLIST}[24]});
	#use clockwise direction - will give normal pointing from front of gate to back - allows correct movement needed later

	my @vector1 = ($self->{VERTEXLIST}[0][0] - $$point[0],
			$self->{VERTEXLIST}[0][1] - $$point[1],
			$self->{VERTEXLIST}[0][2] - $$point[2]);
	_normalise(\@vector1);	
	my @vector2 = ($self->{VERTEXLIST}[4][0] - $$point[0],
			$self->{VERTEXLIST}[4][1] - $$point[1],
			$self->{VERTEXLIST}[4][2] - $$point[2]);		
		
	_normalise(\@vector2);
	my $answer1 = ($foreplane[0]*$vector1[0])+($foreplane[1]*$vector1[1])+($foreplane[2]*$vector1[2]);
	my $answer2 = ($backplane[0]*$vector2[0])+($backplane[1]*$vector2[1])+($backplane[2]*$vector2[2]);
	if ($answer1 < 0 && $answer2 < 0){
		my $centre = $self->getCentre();
		my $dist = distanceBetween($point, $centre);
		if ($dist < $self->{IRADIUS}){
			#passing through gate
			return 1;	
		}elsif ($dist <= $self->{ORADIUS}){
			#hit gate structure - though this is based on a circle/sphere - gate is octagonal - may be some slight discrepancies
			return 2;
		}
	
	}
	return 0;
}

1;