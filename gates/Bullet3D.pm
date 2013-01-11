package Bullet3D;
use CanvasObject;

@ISA = qw(CanvasObject);

sub new
{
	my $self=CanvasObject->new;
	shift;
	my @vertexList;
	my @facetVertices;
	my @vector=(0,0,1);
	my $i=0;
	
	$vertexList[0] = [0, 0, 0];
	$vertexList[1] = [5, 5, 20];
	$vertexList[2] = [5, -5, 20];
	$vertexList[3] = [-5, -5, 20];
	$vertexList[4] = [-5, 5, 20];
	$vertexList[5] = [0, 0, 30];
	
	
	$facetVertices[$i++] = [0,1,2,$i];
	$facetVertices[$i++] = [0,2,3,$i];
	$facetVertices[$i++] = [0,3,4,$i];
	$facetVertices[$i++] = [0,4,1,$i];
	
	$facetVertices[$i++] = [2,1,5,$i];
	$facetVertices[$i++] = [3,2,5,$i];
	$facetVertices[$i++] = [4,3,5,$i];
	$facetVertices[$i++] = [1,4,5,$i];
	
	   	
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;
	$self->{VECTOR}=\@vector;
	$self->{CYCLE}=0;
	$self->{SORT}=1;
	   	
	bless $self;
    	return $self;
}

1;