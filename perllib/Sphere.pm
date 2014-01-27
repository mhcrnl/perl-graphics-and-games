package Sphere;
use CanvasObject;
use SphereSegment;
use Tk;
use GamesLib;

@ISA = qw(CanvasObject);



sub new
{

	my $self=CanvasObject->new;
	shift;
	my $sphereradius = shift;
	
	my @vl;
	my @fv;
	my @centre = ($sphereradius) x 3;
	my $sphereseg;
	my $modifier = 0;
	my $fvmod = 0;
	for (my $i = 0; $i < 4 ; $i++){
		$sphereseg = SphereSegment->new($sphereradius);
		$sphereseg->translate(0 - $centre[0], 0, 0 - $centre[2]);
		$sphereseg->rotate('y',(90*$i),$centre[0],$centre[2]);
		#splice (@vl, @vl, 0, @{$sphereseg->{VERTEXLIST}});
		#splice (@fv, @fv, 0, @{$sphereseg->{FACETVERTICES}});
		push (@vl, @{$sphereseg->{VERTEXLIST}});
		push (@fv, @{$sphereseg->{FACETVERTICES}});
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
	for (my $i = 0; $i < 4 ; $i++){
		$sphereseg = SphereSegment->new($sphereradius);
		$sphereseg->translate(0, 0 -$centre[1], 0 - $centre[2]);
		$sphereseg->rotate('x',180,$centre[1],$centre[2]);
		$sphereseg->translate(0 - $centre[0], 0, 0 - $centre[2]);
		$sphereseg->rotate('y',(90*$i),$centre[0],$centre[2]);
		#splice (@vl, @vl, 0, @{$sphereseg->{VERTEXLIST}});
		#splice (@fv, @fv, 0, @{$sphereseg->{FACETVERTICES}});
		push (@vl, @{$sphereseg->{VERTEXLIST}});
		push (@fv, @{$sphereseg->{FACETVERTICES}});
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
	
	
	$sphereseg = undef;
	
	push(@vl,[$sphereradius,$sphereradius,$sphereradius]);
	   	
	$self->{GORAUD} = 1;  	
	$self->{VERTEXLIST}=\@vl;
	$self->{FACETVERTICES}=\@fv;
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


sub getMaxExtent{
	my $self=shift;
	return $self->{RADIUS}-1; #take a bit off as its not a perfect sphere
}

sub getMinExtent{
	my $self=shift;
	return $self->{RADIUS}-1;
}

sub pointInsideObject
{
	#quite easy just have to be within the radius of the centre
	my $self = shift;
	my $point = shift;
	my $centre = $self->getCentre();
	return 1 if (distanceBetween($point,$centre) < $self->{RADIUS});
	
	return 0;
}

return 1;

