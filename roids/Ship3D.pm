package Ship3D;
use lib '..\perllib';
use CanvasObject;

@ISA = qw(CanvasObject);

sub new
{
	my $self=CanvasObject->new;
	shift;
	my @vertexList;
	my @facetVertices;
	my $i=0;

		#= x, y, z

		$vertexList[0] = [200, 200, 0];
		$vertexList[1] = [150, 160, 100];
		$vertexList[2] = [250, 160, 100];
		$vertexList[3] = [250, 240, 100];
		$vertexList[4] = [150, 240, 100];

		$vertexList[5] = [150, 160, 200];
		$vertexList[6] = [250, 160, 200];
		$vertexList[7] = [250, 240, 200];
		$vertexList[8] = [150, 240, 200];
		
		
		$vertexList[9] = [40, 120, 325];
		$vertexList[10] = [360, 120, 325];
		$vertexList[11] = [320, 290, 260];
		$vertexList[12] = [80, 290, 260];
		
		$vertexList[13] = [150, 200, 200];
		$vertexList[14] = [250, 200, 200];	
		
		
		$vertexList[15] = [200,200,160]; #use as centre point
		
		
		$vertexList[16] = [90, 130, 300];
		$vertexList[17] = [90, 130, 180];
		$vertexList[18] = [90, 140, 300];
		$vertexList[19] = [90, 140, 180];
		
		$vertexList[20] = [310, 130, 300];
		$vertexList[21] = [310, 130, 180];
		$vertexList[22] = [310, 140, 300];
		$vertexList[23] = [310, 140, 180];
		
		$vertexList[24] = [200, 160, 100];
		$vertexList[25] = [190, 160, 200];
		$vertexList[26] = [210, 160, 200];
		$vertexList[27] = [200, 120, 200];
		$vertexList[28] = [200, 90, 280];
		
		
		#decoration - cockpit
		$vertexList[29] = [185, 180, 50];
		$vertexList[30] = [215, 180, 50];
		
		#descoration - engines
		$vertexList[31] = [200, 200, 200];
		$vertexList[32] = [175, 180, 200];
		$vertexList[33] = [175, 220, 200];
		$vertexList[34] = [225, 180, 200];
		$vertexList[35] = [225, 220, 200];

#nose cone --------------------------------   

	$facetVertices[$i++] = [29,24,1,$i];
	$facetVertices[$i++] = [30,2,24,$i];
	$facetVertices[$i++] = [0,29,1,$i];
	$facetVertices[$i++] = [0,2,30,$i];
	$facetVertices[$i++] = [0,3,2,$i];
	$facetVertices[$i++] = [0,4,3,$i];
	$facetVertices[$i++] = [0,1,4,$i];
	   
	        
#body ---------------------------	        

	$facetVertices[$i++] = [1,24,5,$i];	        
	$facetVertices[$i++] = [24,25,5,$i];
	$facetVertices[$i++] = [24,2,6,$i];	        
	$facetVertices[$i++] = [24,6,26,$i];
	
	$facetVertices[$i++] = [2,3,14,$i];
	$facetVertices[$i++] = [3,4,7,$i];
	$facetVertices[$i++] = [4,8,7,$i];
	$facetVertices[$i++] = [4,1,13,$i];
	        	        

	        
#end plate ----------------------

	#$facetVertices[$i++] = [5,6,8,$i];
	#$facetVertices[$i++] = [6,7,8,$i];
	$facetVertices[$i++] = [5,6,31,$i];
	$facetVertices[$i++] = [8,31,7,$i];
	
	$facetVertices[$i++] = [5,32,13,$i,'blue'];
	$facetVertices[$i++] = [13,33,8,$i,'blue'];
	$facetVertices[$i++] = [34,6,14,$i,'blue'];
	$facetVertices[$i++] = [35,14,7,$i,'blue'];
	
	$facetVertices[$i++] = [13,32,31,$i,'cyan'];
	$facetVertices[$i++] = [13,31,33,$i,'cyan'];
	$facetVertices[$i++] = [31,34,14,$i,'cyan'];
	$facetVertices[$i++] = [31,14,35,$i,'cyan'];
	        
	        
#fins -----------------------------

#left lower

	$facetVertices[$i++] = [3,11,14,$i];
	$facetVertices[$i++] = [3,7,11,$i];  
	$facetVertices[$i++] = [11,7,14,$i,'blue'];

#right lower  

	$facetVertices[$i++] = [4,12,8,$i];
	$facetVertices[$i++] = [4,13,12,$i];  
	$facetVertices[$i++] = [12,13,8,$i,'blue'];
	
#right upper
	$facetVertices[$i++] = [1,5,17,$i];
	$facetVertices[$i++] = [5,16,17,$i];
	$facetVertices[$i++] = [19,13,1,$i];
	$facetVertices[$i++] = [19,18,13,$i];
	$facetVertices[$i++] = [1,17,19,$i, 'magenta'];
	$facetVertices[$i++] = [16,5,13,$i,'blue'];	          
	$facetVertices[$i++] = [13,18,16,$i,'blue'];
	$facetVertices[$i++] = [17,16,9,$i,'yellow'];        
	$facetVertices[$i++] = [18,19,9,$i];
	$facetVertices[$i++] = [17,9,19,$i,'magenta'];
	$facetVertices[$i++] = [9,16,18,$i,'green'];


#left upper
	$facetVertices[$i++] = [2,21,6,$i];
	$facetVertices[$i++] = [21,20,6,$i];
	$facetVertices[$i++] = [2,14,23,$i];
	$facetVertices[$i++] = [22,23,14,$i];
	$facetVertices[$i++] = [2,23,21,$i, 'magenta'];
	$facetVertices[$i++] = [20,14,6,$i, 'blue'];	          
	$facetVertices[$i++] = [20,22,14,$i,,'blue'];
	$facetVertices[$i++] = [21,10,20,$i,'yellow'];        
	$facetVertices[$i++] = [22,10,23,$i];
	$facetVertices[$i++] = [21,23,10,$i,'magenta'];
	$facetVertices[$i++] = [20,10,22,$i,'green'];

	    
	
#centre fin

	$facetVertices[$i++] = [24,26,27,$i];
	$facetVertices[$i++] = [24,27,25,$i];
	$facetVertices[$i++] = [27,26,28,$i];
	$facetVertices[$i++] = [27,28,25,$i];
	$facetVertices[$i++] = [28,26,25,$i];

#cockpit 

	$facetVertices[$i++] = [0,30,29,$i, 'yellow'];
	$facetVertices[$i++] = [24,29,30,$i, 'yellow'];

	   	
    	$self->{VERTEXLIST}=\@vertexList;
    	$self->{FACETVERTICES}=\@facetVertices;
    	$self->{SORT} = 1;
    	
	bless $self;
    	return $self;
}


sub getCentre
{
	#need different centering mechanism, tends to wonder if left to own devices
	my $self = shift;
	my @centre = @{${$self->{VERTEXLIST}}[15]};
	return \@centre;
}
1;