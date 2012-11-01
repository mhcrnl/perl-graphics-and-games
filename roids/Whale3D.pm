package Whale3D;
use CanvasObject;


@ISA = qw(CanvasObject);

sub new
{
	my $self=CanvasObject->new;
	shift;
	my @vertexList;
	my @facetVertices;
	my $i=0;
	
	$vertexList[0] = [62, 40, 0];
	$vertexList[1] = [98, 40, 0];
	
	$vertexList[2] = [50, 0, 90];
	$vertexList[3] = [110, 0, 90];
	$vertexList[4] = [110, 100, 90];
	$vertexList[5] = [50, 100, 90];
	
	$vertexList[6] = [21,90, 98];
	$vertexList[7] = [2,65, 106];
	$vertexList[8] = [2,35, 106];
	$vertexList[9] = [21,10, 98];
	
	$vertexList[10] = [139,90, 98];
	$vertexList[11] = [158,65, 106];
	$vertexList[12] = [158,35, 106];
	$vertexList[13] = [139,10, 98];
	
	$vertexList[14] = [50, 0, 170];
	$vertexList[15] = [110, 0, 170];
	$vertexList[16] = [110, 90, 185];
	$vertexList[17] = [50, 90, 185];
	
	$vertexList[18] = [21,90, 170];
	$vertexList[19] = [2,65, 170];
	$vertexList[20] = [2,35, 170];
	$vertexList[21] = [21,10, 170];
	
	$vertexList[22] = [139,90, 170];
	$vertexList[23] = [158,65, 170];
	$vertexList[24] = [158,35, 170];
	$vertexList[25] = [139,10, 170];
	
	$vertexList[26] = [75, 40, 330];
	$vertexList[27] = [85, 40, 330];
	
	$vertexList[28] = [150, 40, 350];
	$vertexList[29] = [170, 39, 385];
	$vertexList[30] = [80, 39, 365];
	$vertexList[31] = [-10, 39, 385];
	$vertexList[32] = [10, 40, 350];
	
	$vertexList[33] = [80, 41, 365];
	
	$vertexList[34] = [158, 50, 120];
	$vertexList[35] = [158, 50, 170];
	$vertexList[36] = [240, 65, 180];
	
	$vertexList[37] = [2, 50, 120];
	$vertexList[38] = [2, 50, 170];
	$vertexList[39] = [-80, 65, 180];

	
	#snout ----------------------------------------
	$facetVertices[$i++] = [0,1,3,$i];
	$facetVertices[$i++] = [0,3,2,$i];
	$facetVertices[$i++] = [0,4,1,$i];
	$facetVertices[$i++] = [0,5,4,$i];
	
	$facetVertices[$i++] = [0,6,5,$i];
	$facetVertices[$i++] = [0,7,6,$i];
	$facetVertices[$i++] = [0,8,7,$i];
	$facetVertices[$i++] = [0,9,8,$i];
	$facetVertices[$i++] = [0,2,9,$i];
	
	$facetVertices[$i++] = [1,4,10,$i];
	$facetVertices[$i++] = [1,10,11,$i];
	$facetVertices[$i++] = [1,11,12,$i];
	$facetVertices[$i++] = [1,12,13,$i];
	$facetVertices[$i++] = [1,13,3,$i];
	
	#body -------------------------------------------
	
	$facetVertices[$i++] = [2,3,15,$i];
	$facetVertices[$i++] = [2,15,14,$i];
	$facetVertices[$i++] = [3,13,25,$i];
	$facetVertices[$i++] = [3,25,15,$i];
	$facetVertices[$i++] = [13,12,24,$i];
	$facetVertices[$i++] = [13,24,25,$i];
	$facetVertices[$i++] = [12,11,23,$i];
	$facetVertices[$i++] = [12,23,24,$i];
	$facetVertices[$i++] = [11,10,22,$i];
	$facetVertices[$i++] = [11,22,23,$i];
	$facetVertices[$i++] = [10,4,22,$i];
	$facetVertices[$i++] = [4,16,22,$i];
	$facetVertices[$i++] = [4,5,17,$i];
	$facetVertices[$i++] = [4,17,16,$i];
	$facetVertices[$i++] = [5,6,18,$i];
	$facetVertices[$i++] = [5,18,17,$i];
	$facetVertices[$i++] = [6,7,19,$i];
	$facetVertices[$i++] = [6,19,18,$i];
	$facetVertices[$i++] = [7,8,20,$i];
	$facetVertices[$i++] = [7,20,19,$i];
	$facetVertices[$i++] = [8,9,21,$i];
	$facetVertices[$i++] = [8,21,20,$i];
	$facetVertices[$i++] = [9,2,14,$i];
	$facetVertices[$i++] = [9,14,21,$i];
	
	#tail ----------------------------------------------
	$facetVertices[$i++] = [14,15,27,$i];
	$facetVertices[$i++] = [14,27,26,$i];
	$facetVertices[$i++] = [15,25,27,$i];
	$facetVertices[$i++] = [25,24,27,$i];
	$facetVertices[$i++] = [24,23,27,$i];
	$facetVertices[$i++] = [23,22,27,$i];
	$facetVertices[$i++] = [22,16,27,$i];
	$facetVertices[$i++] = [16,17,26,$i];
	$facetVertices[$i++] = [16,26,27,$i];
	$facetVertices[$i++] = [17,18,26,$i];
	$facetVertices[$i++] = [18,19,26,$i];
	$facetVertices[$i++] = [19,20,26,$i];
	$facetVertices[$i++] = [20,21,26,$i];
	$facetVertices[$i++] = [21,14,26,$i];
	
	# tailfin (fluke) -------------------------------------
	
		#top
	$facetVertices[$i++] = [27,28,29,$i];
	$facetVertices[$i++] = [27,29,30,$i];
	$facetVertices[$i++] = [32,26,30,$i];
	$facetVertices[$i++] = [31,32,30,$i];
	$facetVertices[$i++] = [26,27,30,$i];
		#bottom
	$facetVertices[$i++] = [33,28,27,$i];
	$facetVertices[$i++] = [33,29,28,$i];
	$facetVertices[$i++] = [26,33,27,$i];
	$facetVertices[$i++] = [32,33,26,$i];
	$facetVertices[$i++] = [31,33,32,$i];
		#infill
	$facetVertices[$i++] = [30,33,31,$i];
	$facetVertices[$i++] = [30,29,33,$i];
	
	#fins -------------------------------------------------
	$facetVertices[$i++] = [34,36,35,$i];
	$facetVertices[$i++] = [34,35,36,$i];
	$facetVertices[$i++] = [37,38,39,$i];
	$facetVertices[$i++] = [37,39,38,$i];
	
	   	
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;
	$self->{TAG}='whale';
	$self->{ID}=0;
	$self->{STATE}=0;
	$self->{SORT} = 1;
	$self->{GORAUD} = 2;
	   	
	bless $self;
    	return $self;
	
}

sub getBoundingBox
{
	my $self = shift;
	my $centre = $self->getCentre();
	#just return arbitary box for now based on centre
	return ($$centre[0]-50, $$centre[1]-50,$$centre[0]+50, $$centre[1]+50);
}

