package SphereSegment;
use Math::Trig;
use CanvasObject;
use Tk;

@ISA = qw(CanvasObject);



sub new
{

	#hopefully will provide an 8th of a sphere, with coords in arcs (they will then need joining in triangles - to be done)
	my $self=CanvasObject->new;
	shift;
	my $sphereradius=shift;
	$sphereradius=100 if ($sphereradius==0);
	my @vertexList;
	my @facetVertices;
	my $arcprogression = ($sphereradius>199) ? 6 : (($sphereradius<50) ? 15 : (($sphereradius>100) ? 9 : 10));
	my @zeds;
	my $finalarc = 0;
	my $cnt=0;
	my $idno = 0;
	my $pointsperarc=(90/$arcprogression);
	for (my $i = 0 ; $i<$pointsperarc ; $i++)
	{
	my $arc = "arc$i";
	$finalarc=$i;
	my $y = $sphereradius-((sin(deg2rad($i*$arcprogression)))*$sphereradius);
	
	for (my $j = 0; $j<=90 ; $j+=$arcprogression)
	{
		my $temprad = $sphereradius;
		$temprad = $temprad-$zeds[$i] if ($zeds[$i]);
		my $x = $sphereradius+((sin(deg2rad($j)))*$temprad);
		
		my $z = $sphereradius-(cos(deg2rad($j))*$temprad);
		
		$vertexList[$cnt] = [$x,$y,($z)];
		if ($i == 0){
			push (@zeds,$z); 
		}
		$cnt++;
	}
	}
	$vertexList[$cnt] =  [$sphereradius,0,($sphereradius)];
	 #note this are anti-clockwise arcs 
	$pointsperarc++;
	for (my $i=0 ; $i<$pointsperarc-2 ; $i++)
	{
		my $a = $i*$pointsperarc;
		my $b = ($pointsperarc*$i)+1;
		my $c = $pointsperarc*($i+1);
		for (my $j = 1 ; $j < ($pointsperarc*2)-1 ; $j++){
			if ($j%2 == 0){
				$a++;
				$b+=$pointsperarc;
			}elsif ($j>1){
				$c++;
				$b-=($pointsperarc-1);
			}
			#print "$a, $b, $c\n";
			push (@facetVertices, [$a, $b, $c, $idno]);
			$idno++;
		}
	}

	my $a = $finalarc*($pointsperarc);
	my $b = $a+1;
	my $c = $cnt;
	for (my $j = 0 ; $j < $pointsperarc-1 ; $j++){
		$a+=1 unless ($j==0);
		$b+=1 unless ($j==0);
		#print "$a, $b, $c\n";
		push (@facetVertices, [$a, $b, $c, $idno]);
		$idno++;
	}
	$self->{VERTEXLIST}=\@vertexList;
	$self->{FACETVERTICES}=\@facetVertices;
	$self->{RADIUS}=$sphereradius;
	bless $self;
	return $self;
	
}
return 1;

