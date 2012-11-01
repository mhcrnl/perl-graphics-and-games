package Ship;

use CanvasObject;
use Tk;
use Math::Trig;
use GamesLib;
use strict;

our @ISA = qw(CanvasObject);


sub new
{
	my $self=CanvasObject->new;
	shift;
	$self->{CNV} = shift;
	$self->{baseheat} = shift;
	$self->{baseguns} = shift;
	$self->{baserof} = shift;
	$self->{basepspeed} = shift;
	$self->{basemspeed} = shift;
	$self->{baseshield} = shift;
	$self->{baseguntype} = shift;
	$self->{baseturnrate} = 3;
	$self->{basebomb} = 2;
	$self->{basecol};
	
	$self->{heat} = $self->{baseheat};
	$self->{guns} = $self->{baseguns};
	$self->{rof} = $self->{baserof};
	$self->{pspeed} = $self->{basepspeed};
	$self->{mspeed} = $self->{basemspeed};
	$self->{shield} = $self->{baseshield};
	$self->{guntype} = $self->{baseguntype};
	$self->{turnrate} = 3;
	$self->{bomb} = 2;
	$self->{thrust} = 0;
	$self->{ID} = -1;
	$self->{TAG} = 'ship';
	my @vertexList;
	my @facetVertices;

		#= x, y, z
		$vertexList[0] = [40, 0, 10];
	    $vertexList[1] = [0, 100, 10];
	    $vertexList[2] = [40, 80, 12];
	    #separately defined triangles so flyapart works
	    $vertexList[3] = [40, 0, 10];
	    $vertexList[4] = [40, 80, 12];
	    $vertexList[5] = [80, 100, 10];

	    
	    $facetVertices[0][0] = 0;
	        $facetVertices[0][1] = 1;
	        $facetVertices[0][2] = 2;
	        $facetVertices[0][3] = 0;
		$facetVertices[1][0] = 3;
	        $facetVertices[1][1] = 4;
	        $facetVertices[1][2] = 5;
	        $facetVertices[1][3] = 1;

    	$self->{VERTEXLIST}=\@vertexList;
    	$self->{FACETVERTICES}=\@facetVertices;
	bless $self;
    	return $self;
}

sub setStats
{
	my $self = shift;
	my $conf = shift;
	
	$self->{baseheat} = ${$conf->{heat}};
	$self->{baseguns} = ${$conf->{guns}};
	$self->{baserof} = ${$conf->{rof}};
	$self->{basepspeed} = ${$conf->{pspeed}};
	$self->{basemspeed} = ${$conf->{mspeed}};
	$self->{baseshield} = ${$conf->{shield}};
	$self->{baseguntype} = $conf->{guntype};
	$self->{basecol} = $conf->{colour};
	$self->setColour($conf->{colour});
	
	resetStats($self);
}

sub resetStats
{
	my $self = shift;
	for my $k (keys %$self){
		if ($k =~ m/^base(.+)$/){
			$self->{$1} = $self->{$k};
		}
	}
}

sub getBoundingBox
{	
	my $self = shift;
	my $vl = $self->{VERTEXLIST};
	my $x = $$vl[0][0];
	my $y = $$vl[0][1];
	my $x1 = $$vl[0][0];
	my $y1 = $$vl[0][1];
	
	$x = $$vl[1][0] if ($$vl[1][0] < $x);
	$y = $$vl[1][1] if ($$vl[1][1] < $y);
	$x1 = $$vl[1][0] if ($$vl[1][0] > $x1);
	$y1 = $$vl[1][1] if ($$vl[1][1] > $y1);
	
	$x = $$vl[5][0] if ($$vl[5][0] < $x);
	$y = $$vl[5][1] if ($$vl[5][1] < $y);
	$x1 = $$vl[5][0] if ($$vl[5][0] > $x1);
	$y1 = $$vl[5][1] if ($$vl[5][1] > $y1);
	
	return ($x, $y, $x1, $y1, scalar @{$self->{FACETVERTICES}});
}

sub getEnginePosition
{
	my $self = shift;
	return (${$self->{VERTEXLIST}}[2][0],${$self->{VERTEXLIST}}[2][1]);
	
}

sub setDimensions
{
	#this basically resets obj with new values
	my $self = shift;
	my $width = shift;
	my $height = shift;

	if ($width > 0){
		${$self->{VERTEXLIST}}[5][0] = $width;
		${$self->{VERTEXLIST}}[0][0] = int($width/2);
	}
	if ($height > 0){
		${$self->{VERTEXLIST}}[5][1] = $height;
		${$self->{VERTEXLIST}}[1][1] = $height;
	}
	${$self->{VERTEXLIST}}[2][0] = ${$self->{VERTEXLIST}}[0][0];
	${$self->{VERTEXLIST}}[3][0] = ${$self->{VERTEXLIST}}[0][0];
	${$self->{VERTEXLIST}}[4][0] = ${$self->{VERTEXLIST}}[0][0];
	${$self->{VERTEXLIST}}[2][1] = ${$self->{VERTEXLIST}}[5][1]-20;
	${$self->{VERTEXLIST}}[4][1] = ${$self->{VERTEXLIST}}[5][1]-20;
	${$self->{VERTEXLIST}}[0][1] = 0;
	${$self->{VERTEXLIST}}[3][1] = 0;
	${$self->{VERTEXLIST}}[1][0] = 0;
	
	${$self->{VERTEXLIST}}[0][2] = 10;
	${$self->{VERTEXLIST}}[1][2] = 10;
	${$self->{VERTEXLIST}}[2][2] = 12;
	${$self->{VERTEXLIST}}[3][2] = 10;
	${$self->{VERTEXLIST}}[4][2] = 12;
	${$self->{VERTEXLIST}}[5][2] = 10;
}

#sub draw
#{
#	my $self = shift;
#	my $cnv = ${$self->{CNV}};
#	my $tag = shift;
#	my $vertexList = $self->{VERTEXLIST};
#	my $facetVertices = $self->{FACETVERTICES};
#	my $colour = $self->{SHADE};
#	my $outlineColour = $self->{SHADE};
#	$outlineColour = 'blue' if ($self->{shield} > 0);
#	for (my $i = 0 ; $i < @{$facetVertices} ; $i++)
#	{
#
#		my $x = $$vertexList[$$facetVertices[$i][0]][0];
#		my $y = $$vertexList[$$facetVertices[$i][0]][1];
#		my $x1 = $$vertexList[$$facetVertices[$i][1]][0];
#		my $y1 = $$vertexList[$$facetVertices[$i][1]][1];
#		my $x2 = $$vertexList[$$facetVertices[$i][2]][0];
#		my $y2 = $$vertexList[$$facetVertices[$i][2]][1];
#		if ($$facetVertices[$i][3] > 0){
#			$cnv->coords($$facetVertices[$i][3], $x,$y,$x1,$y1,$x2,$y2);
#		}else{
#			$$facetVertices[$i][3] = $cnv->createPolygon($x,$y,$x1,$y1,$x2,$y2, -fill=>$colour, -outline=>$outlineColour, -tags=>$tag);
#		}
#
#	}
#}

sub shieldOn
{
	my $self = shift;
	#my $cnv = ${$self->{CNV}};
	#my $facetVertices = $self->{FACETVERTICES};
	#foreach (@{$facetVertices}){
	#	$cnv->itemconfigure($$_[3], -outline=>'blue') if ($$_[3] != 0);
	#}
	$self->{OUTL} = 'blue';
}

sub shieldOff
{
	my $self = shift;
	#my $cnv = ${$self->{CNV}};
	#my $colour = $self->{SHADE};
	#my $facetVertices = $self->{FACETVERTICES};
	#foreach (@{$facetVertices}){
	#	$cnv->itemconfigure($$_[3], -outline=>$colour)  if ($$_[3] != 0);
	#}
	$self->{OUTL} = '';

}

sub delete{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	my $tag = shift;
	$cnv->delete($tag);
	${$self->{FACETVERTICES}}[0][3] = 0;
	${$self->{FACETVERTICES}}[1][3] = 0;
}

sub flyapart
{
	my $self = shift;
	my $x = 8;
	my $y = 4;
	${$self->{VERTEXLIST}}[0][0] += $x;
	${$self->{VERTEXLIST}}[0][1] += $y;
	${$self->{VERTEXLIST}}[1][0] += $x;
	${$self->{VERTEXLIST}}[1][1] += $y;
	${$self->{VERTEXLIST}}[2][0] += $x;
	${$self->{VERTEXLIST}}[2][1] += $y;
	${$self->{VERTEXLIST}}[3][0] -= $x;
	${$self->{VERTEXLIST}}[3][1] -= $y;
	${$self->{VERTEXLIST}}[4][0] -= $x;
	${$self->{VERTEXLIST}}[4][1] -= $y;
	${$self->{VERTEXLIST}}[5][0] -= $x;
	${$self->{VERTEXLIST}}[5][1] -= $y;
}

sub getFireLine
{
	#does not use z coord
	my $self = shift;
	my $incr = shift;
	my $mod = shift;
	my $vertexList = $self->{VERTEXLIST};
	my $facetVertices = $self->{FACETVERTICES};
	my $addx = 0;
	my $addy = 0;
	my $x;
	my $y;
	my $x1 = sprintf "%.2f",$$vertexList[0][0]; 
	my $y1 = sprintf "%.2f",$$vertexList[0][1]; 
	if ($mod < 3){
		$x = sprintf "%.2f",$$vertexList[2][0]; 
		$y = sprintf "%.2f",$$vertexList[2][1];
	}elsif ($mod == 3){
		$x = sprintf "%.2f",$$vertexList[1][0]; 
		$y = sprintf "%.2f",$$vertexList[1][1];
	}elsif ($mod == 4){
		$x = sprintf "%.2f",$$vertexList[5][0]; 
		$y = sprintf "%.2f",$$vertexList[5][1];
	}	
	
	
	($addx, $addy) = getLine($incr, $x1, $y1, $x, $y);
	
	if($mod == 1 || $mod == 2){
		my ($shiftx, $shifty) = getLine(15, $x1, $y1, $x, $y);	
		if ($mod == 1){
			$x1 = $x - $shifty;
			$y1 = $y + $shiftx;
		}else{
			$x1 = $x + $shifty;
			$y1 = $y - $shiftx;
		}
	}
	return ($x1, $y1, $addx, $addy);
}


sub checkCollision
{
	#check if points on outer lines of ship overlap any other object
	my $self = shift;
	my $tag = shift;
	my $vertexList = $self->{VERTEXLIST};
	my $addx = 0;
	my $addy = 0;
	my $x1 = 0;
	my $y1 = 0;
	my $x = 0;
	my $y = 0;
	my $collision = 0;
	my $length = 0;
	
	my @outline = (0,1,0,5,2,1,2,5);
	
	for (my $i = 0; $i < @outline ; $i+=2){
	
		$x = sprintf "%.2f",$$vertexList[$outline[$i]][0]; 
		$y = sprintf "%.2f",$$vertexList[$outline[$i]][1]; 
		$x1 = sprintf "%.2f",$$vertexList[$outline[$i+1]][0]; 
		$y1 = sprintf "%.2f",$$vertexList[$outline[$i+1]][1]; 
		$length = _getLength($x,$y,$x1,$y1);
		$collision = _checkOverlap($tag,$x, $y, $x1, $y1, $self->{CNV}, $length);
	
		last if ($collision != 0);
	}
	
	return $collision;
	
	
}

sub _getLength
{
	my $x = shift;
	my $y = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $length = 0;
	
	my $dx = $x - $x1;
	my $dy = $y - $y1;
	
	if ($dx == 0){
		$length = $dy ;
	}elsif ($dy == 0){
		$length = $dx ;
	}else{
		$length = sqrt(($dx*$dx)+($dy*$dy));
	}
	$length = $length*-1 if ($length < 0);
	
	return $length;
}


sub _checkOverlap
{
	#doesn't use z, just checks in the 2d plane - developed for use in 2d roids game
	my $tag = shift;
	my $x = shift;
	my $y = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $cnv = shift;
	my $length = shift;
	my $repeat = $length/4;
	my $collision = "";
	#check every 4 units, try to keep some performance on this check - though possible something could sneak through if small enough e.g. drone bullet though has not done so yet
	my ($addx, $addy) = getLine(4, $x, $y, $x1, $y1);
	for (my $i = 0 ; $i < $repeat ; $i++)
	{
		my @t = $$cnv->find('overlapping', int($x1+($addx*$i)),int($y1+($addy*$i)),int($x1+($addx*$i)),int($y1+($addy*$i)) );
		$collision=_checkTags($tag, \@t, $cnv);
		if ($collision != 0){
			#$$cnv->createRectangle(int($x1),int($y1),int($x1)+2,int($y1)+2, -fill=>'yellow', -outline=>'yellow');
			#$$cnv->createRectangle(int($x1+($addx*$i)),int($y1+($addy*$i)),int($x1+($addx*$i))+2,int($y1+($addy*$i))+2, -fill=>'green', -outline=>'green');
			last ;
		}
	}
	if ($collision == 0){
		my @t = $$cnv->find('overlapping', int($x),int($y),int($x),int($y) );
		$collision=_checkTags($tag, \@t, $cnv);
		#if ($collision ne ""){
		#$$cnv->createRectangle(int($x),int($y),int($x)+2,int($y)+2, -fill=>'cyan', -outline=>'cyan');
		#}
	}

	return $collision;
}

sub _checkTags
{
	my $tag = shift;
	my $list = shift;
	my $cnv = shift;
	my $collision = 0;
	
	foreach my $id (@$list)
	{
		if (${$$cnv->itemcget($id, -tags)}[0] =~ m/^$tag$/){
			$collision=$id;
			last;
		}
	}
	return $collision;
}

sub getCentre
{
	my $self = shift;
	my @centre = @{${$self->{VERTEXLIST}}[2]};
	return \@centre;
}


return 1;