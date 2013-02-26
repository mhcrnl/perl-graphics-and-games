package Cuboid;

use CanvasObject;
use GamesLib;
use strict;

our @ISA = qw(CanvasObject);



sub new
{
	my $self=CanvasObject->new;
	my @vertexList;
	my @facetVertices;
		#= x, y, z
	    $vertexList[0] = [0, 0, 0];
	    $vertexList[1] = [0, 100, 0];
	    $vertexList[2] = [100, 100, 0];
	    $vertexList[3] = [100, 0, 0];
	    $vertexList[4] = [0, 0, 100];
	    $vertexList[5] = [0, 100, 100];
	    $vertexList[6] = [100, 100, 100];
	    $vertexList[7] = [100, 0, 100];
	    
	    $facetVertices[0][0] = 0;
	      $facetVertices[0][1] = 1;
	        $facetVertices[0][2] = 3;
	        $facetVertices[0][3] = 0;
	        $facetVertices[1][0] = 1;
	        $facetVertices[1][1] = 2;
	        $facetVertices[1][2] = 3;
	        $facetVertices[1][3] = 1;
	          $facetVertices[2][0] = 0;
	        $facetVertices[2][1] = 3;
	        $facetVertices[2][2] = 4;
	        $facetVertices[2][3] = 2;
	        $facetVertices[3][0] = 3;
	        $facetVertices[3][1] = 7;
	        $facetVertices[3][2] = 4;
	        $facetVertices[3][3] = 3;
	            $facetVertices[4][0] = 4;
	        $facetVertices[4][1] = 5;
	        $facetVertices[4][2] = 0;
	        $facetVertices[4][3] = 4;
	        $facetVertices[5][0] = 5;
	        $facetVertices[5][1] = 1;
	        $facetVertices[5][2] = 0;
	        $facetVertices[5][3] = 5;
	            $facetVertices[6][0] = 7;
	        $facetVertices[6][1] = 6;
	        $facetVertices[6][2] = 4;
	        $facetVertices[6][3] = 6;
	        $facetVertices[7][0] = 6;
	        $facetVertices[7][1] = 5;
	        $facetVertices[7][2] = 4;
	        $facetVertices[7][3] = 7;
	            $facetVertices[8][0] = 3;
	        $facetVertices[8][1] = 2;
	        $facetVertices[8][2] = 7;
	        $facetVertices[8][3] = 8;
	        $facetVertices[9][0] = 2;
	        $facetVertices[9][1] = 6;
	        $facetVertices[9][2] = 7;
	        $facetVertices[9][3] = 9;
	            $facetVertices[10][0] = 2;
	        $facetVertices[10][1] = 1;
	        $facetVertices[10][2] = 6;
	        $facetVertices[10][3] = 10;
	        $facetVertices[11][0] = 1;
	        $facetVertices[11][1] = 5;
	   $facetVertices[11][2] = 6;
	   $facetVertices[11][3] = 11;
	   
	   
	   	$self->{VERTEXLIST}=\@vertexList;
	   	$self->{FACETVERTICES}=\@facetVertices;
		$self->{MAX_EXTENT}=_calcMaxExtent(100,100,100);
		$self->{MIN_EXTENT}=50;
		bless $self;
	   	return $self;

}

sub setDimensions
{
	#this needs to change really this can only set the dimension in the starting position
	
	my $self = shift;
	my $width = shift;
	my $height = shift;
	my $depth = shift;
	if ($width > 0 && $height > 0 && $depth > 0){
		$self->{MIN_EXTENT} = $width/2;
		$self->{MIN_EXTENT} = $height if ($height/2 > $self->{MIN_EXTENT});
		$self->{MIN_EXTENT} = $depth if ($depth/2 > $self->{MIN_EXTENT});
		for (my $i = 0 ; $i < @{$self->{VERTEXLIST}}; $i++)
		{
			${$self->{VERTEXLIST}}[$i][0] = $width if (${$self->{VERTEXLIST}}[$i][0] > 0);
			${$self->{VERTEXLIST}}[$i][1] = $height if (${$self->{VERTEXLIST}}[$i][1] > 0);
			${$self->{VERTEXLIST}}[$i][2] = $depth if (${$self->{VERTEXLIST}}[$i][2] > 0);

		}


	}

	$self->{MAX_EXTENT}=_calcMaxExtent($width,$height,$depth);

}

sub getMaxExtent{
	my $self=shift;
	return $self->{MAX_EXTENT};
}

sub getMinExtent{
	my $self=shift;
	return $self->{MIN_EXTENT};
}


sub _calcMaxExtent{
	#max distance centre to surface
	my $width = shift;
	my $height = shift;
	my $depth = shift;
	
	my $temphyp = sqrt((($width/2)*($width/2))+(($height/2)*($height/2)));
	return sqrt(($temphyp*$temphyp)+(($depth/2)*($depth/2)));
	
}


sub pointInsideObject
{
	#may want similar functions for other shapes too
	#for a regular shape, like a cube, a point is inside an object if all faces read as backfaces in relation to the point being tested
	my $self = shift;
	my $point = shift;
	my @vector = ();
	my @a;
	my @b;
	my @c;
	my @normal;
	my $return = 1;
	my $centre = $self->getCentre();
	my $dist =  distanceBetween($centre,$point);
	return 0 if ($dist > $self->getMaxExtent()); #must be within this distance of centre to be within it
	return 1 if ($dist <= $self->getMinExtent()); #has to be in object at this distance 
	for (my $i = 0 ; $i < @{$self->{FACETVERTICES}} ; $i++) #each face has 2 triangles, only need to check one
	{
		if (${$self->{FACETVERTICES}}[$i][3] % 2 == 0){ #array may be sorted by z distance. If we get all the even number ids, it ensures we get one triangle from each face
		#can pick any point in triangle to take point to face vector
		@vector = (${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][0] - $$point[0],
				${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][1] - $$point[1],
				${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][2] - $$point[2]);
		_normalise(\@vector);
		@a = (${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][0],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][1],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][0]][2]);
		@b = (${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][1]][0],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][1]][1],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][1]][2]);
		@c = (${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][2]][0],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][2]][1],${$self->{VERTEXLIST}}[${$self->{FACETVERTICES}}[$i][2]][2]);
		@normal = _getNormal(\@a,\@b,\@c);
		my $answer = ($normal[0]*$vector[0])+($normal[1]*$vector[1])+($normal[2]*$vector[2]);
		if ($answer <= 0) #vectors heading towards each other, cannot be within shape
		{
			$return = 0;
			last;
		}
		}
	}
	return $return;
}



return 1;