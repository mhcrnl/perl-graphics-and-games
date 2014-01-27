package CanvasObject;
use Math::Trig;
use GamesLib;
use strict;

sub new
{
	my $class = shift;
	my @canvasitems = ();
	my @focus = (0,0,0);
	my $self = {};
		my @vl;
		my @fc;
    	$self->{VERTEXLIST} = \@vl;
    	$self->{FACETVERTICES} = \@fc;
    	$self->{CANVASITEMS}=\@canvasitems;
    	$self->{FOCUSPOINT}=\@focus;
    	$self->{SHADE}='green';
    	$self->{NOFILL}=0;
    	$self->{OUTL} = '';
    	$self->{GORAUD} = 0;
    	$self->{MIN_EXTENT}=0;
    	$self->{MAX_EXTENT}=0;
    	bless($self,$class);
    	return $self;
}

sub getVertexFacetMap
{
	#create map for getting all the facets attached to a specific vertex
	my $self = shift;
	my @vertexFacetMap;
	my @fv = @{$self->{FACETVERTICES}};

	for (my $i = 0 ; $i < @fv ; $i++ )
	{		
		foreach(0..2)
		{
			push(@{$vertexFacetMap[$fv[$i][$_]]}, $i);
		}
	}

	return \@vertexFacetMap;
}

sub setColour
{
	my $self=shift;
	$self->{SHADE}=shift;
}

sub setFocus
{
	my $self=shift;
	my $focus = shift;
	$self->{FOCUSPOINT}=$focus if (@$focus == 3);
}

sub rotate
{
	my $self = shift;
	my $type = shift;
	my $angle = shift;
	my $trans1 = shift;
	my $trans2 = shift;
	$trans1 = 0 if (! $trans1);
	$trans2 = 0 if (! $trans2);
	my $rotMatrix;
	$rotMatrix = _rxMatrix($angle,$trans1,$trans2) if ($type eq 'x');
	$rotMatrix = _ryMatrix($angle,$trans1,$trans2) if ($type eq 'y');
	$rotMatrix = _rzMatrix($angle,$trans1,$trans2) if ($type eq 'z');
	
	_mapMatrix($self, $rotMatrix);
       

}


sub rotateComposite
{
	my $self = shift;
	my $type1 = shift;
	my $angle1 = shift;
	my $trans11 = shift;
	my $trans12 = shift;
	
	my $type2 = shift;
	my $angle2 = shift;
	my $trans21 = shift;
	my $trans22 = shift;
	
	my $matrix1;
	my $matrix2;
	
	$matrix1 = _rxMatrix($angle1,$trans11,$trans12) if ($type1 eq 'x');
	$matrix1 = _ryMatrix($angle1,$trans11,$trans12) if ($type1 eq 'y');
	$matrix1 = _rzMatrix($angle1,$trans11,$trans12) if ($type1 eq 'z');
	
	$matrix2 = _rxMatrix($angle2,$trans21,$trans22) if ($type2 eq 'x');
	$matrix2 = _ryMatrix($angle2,$trans21,$trans22) if ($type2 eq 'y');
	$matrix2 = _rzMatrix($angle2,$trans21,$trans22) if ($type2 eq 'z');
	
	my $rotMatrix = _matrixMultiply($matrix1, $matrix2);
	_mapMatrix($self, $rotMatrix);
}

sub _mapMatrix
{
	my $self = shift;
	my $rotMatrix = shift;
	my @vl = @{$self->{VERTEXLIST}};

	return if (scalar @{$self->{VERTEXLIST}} == 0);
	map{
	       	my $x = ${$_}[0];
	       	my $y = ${$_}[1];
	       	my $z = ${$_}[2];
	       	${$_}[0]=($x*$$rotMatrix[0][0]+
	                    $y*$$rotMatrix[0][1]+
	                    $z*$$rotMatrix[0][2]+
	                    $$rotMatrix[0][3]);
	                                      
	     	${$_}[1]=($x*$$rotMatrix[1][0]+
	                    $y*$$rotMatrix[1][1]+
	                    $z*$$rotMatrix[1][2]+
	                    $$rotMatrix[1][3]);
	                                   
	       	${$_}[2]=($x*$$rotMatrix[2][0]+
	                    $y*$$rotMatrix[2][1]+
	                    $z*$$rotMatrix[2][2]+
	                    $$rotMatrix[2][3]);
      } @{$self->{VERTEXLIST}} ;
	
}


sub translate 
  {
  	my $self = shift;
  	my $x = shift;
  	my $y = shift;
  	my $z = shift;
  	$z = 0 if (! $z);
  	return if (scalar @{$self->{VERTEXLIST}} == 0);
  	map {${$_}[0]+=$x;${$_}[1]+=$y;${$_}[2]+=$z;}  @{$self->{VERTEXLIST}};
  	
    #for (my $i = 0 ; $i < @{$self->{VERTEXLIST}} ; $i++)
    #{
    #  ${$self->{VERTEXLIST}}[$i][0]+=$x;
    #  ${$self->{VERTEXLIST}}[$i][1]+=$y;
    #  ${$self->{VERTEXLIST}}[$i][2]+=$z;
    #}
  }




sub getCentre
{
	my $self = shift;
	my @centre;
	
	my ($minX,$maxX) = minMaxN($self,'x');
	my ($minY,$maxY) = minMaxN($self,'y');
	my ($minZ,$maxZ) = minMaxN($self,'z');
	
    $centre[0] = $minX + (($maxX - $minX)/2);
    $centre[1] = $minY + (($maxY - $minY)/2);
    $centre[2] = $minZ + (($maxZ - $minZ)/2);
    return \@centre;
}


sub minMaxN{
	my $self = shift;
	my $axis = shift;
	my $n = 0;
	$n=1 if ($axis eq 'y');
	$n=2 if ($axis eq 'z');
	my $min = ${$self->{VERTEXLIST}}[0][$n];
	my $max = $min;
	for (my $i = 1 ; $i < @{$self->{VERTEXLIST}} ; $i++)
	    {
	      if (${$self->{VERTEXLIST}}[$i][$n] < $min)
	      {
	        $min = ${$self->{VERTEXLIST}}[$i][$n];
	      }
	      elsif (${$self->{VERTEXLIST}}[$i][$n] > $max)
	      {
	        $max = ${$self->{VERTEXLIST}}[$i][$n];
	      }
    	}
    	return ($min,$max);
}




#sub minZ
#{
#	my $self = shift;
#    my $minZ = ${$self->{VERTEXLIST}}[0][2];
#    for (my $i = 1 ; $i < @{$self->{VERTEXLIST}} ; $i++)
#    {
#      if (${$self->{VERTEXLIST}}[$i][2] < $minZ)
#      {
#        $minZ = ${$self->{VERTEXLIST}}[$i][2];
#      }
#    }
#    return $minZ;
#}


sub _matrixMultiply
{
my $matrix1 = shift;
my $matrix2 = shift;
print "moo\n" if (! $matrix1);
print "cow\n" if (! $matrix2);
my @multiplied;

	for (my $i = 0 ; $i < 3 ; $i++){
		for (my $j = 0 ; $j < 4 ; $j++){

		$multiplied[$i][$j] = $$matrix1[$i][0]*$$matrix2[0][$j]+
					$$matrix1[$i][1]*$$matrix2[1][$j]+
					$$matrix1[$i][2]*$$matrix2[2][$j];
		

		}
	}
	return \@multiplied;

}

sub _rxMatrix
{
	my $angle = shift;
	my $trans1 = shift;
	my $trans2 = shift;
	my @rotMatrix;
	
          $rotMatrix[0][0] = 1;
          $rotMatrix[0][1] = 0;
          $rotMatrix[0][2] = 0;
          $rotMatrix[0][3] = 0;
          $rotMatrix[1][0] = 0;
          $rotMatrix[1][1] = cos(deg2rad($angle));
          $rotMatrix[1][2] = -(sin(deg2rad($angle)));
          $rotMatrix[1][3] = $trans1;
          $rotMatrix[2][0] = 0;
          $rotMatrix[2][1] = sin(deg2rad($angle));
          $rotMatrix[2][2] = cos(deg2rad($angle));
          $rotMatrix[2][3] = $trans2;
          
          return \@rotMatrix;
}

sub _ryMatrix
{
	my $angle = shift;
	my $trans1 = shift;
	my $trans2 = shift;
	my @rotMatrix;
    $rotMatrix[0][0] = cos(deg2rad($angle));
    $rotMatrix[0][1] = 0;
    $rotMatrix[0][2] = sin(deg2rad($angle));
    $rotMatrix[0][3] = $trans1;
    $rotMatrix[1][0] = 0;
    $rotMatrix[1][1] = 1;
    $rotMatrix[1][2] = 0;
    $rotMatrix[1][3] = 0;
    $rotMatrix[2][0] = -(sin(deg2rad($angle)));
    $rotMatrix[2][1] = 0;
    $rotMatrix[2][2] = cos(deg2rad($angle));
    $rotMatrix[2][3] = $trans2;
    return \@rotMatrix;
}

sub _rzMatrix
{
	my $angle = shift;
	my $trans1 = shift;
	my $trans2 = shift;
	my @rotMatrix;
    $rotMatrix[0][0] = cos(deg2rad($angle));
    $rotMatrix[0][1] = -(sin(deg2rad($angle)));
    $rotMatrix[0][2] = 0;
    $rotMatrix[0][3] = $trans1;
    $rotMatrix[1][0] = sin(deg2rad($angle));
    $rotMatrix[1][1] = cos(deg2rad($angle));
    $rotMatrix[1][2] = 0;
    $rotMatrix[1][3] = $trans2;
    $rotMatrix[2][0] = 0;
    $rotMatrix[2][1] = 0;
    $rotMatrix[2][2] = 1;
    $rotMatrix[2][3] = 0;
    return \@rotMatrix;
}

sub sortz
{
	my $self = shift;
	my @temp = sort{_sort_func($self,$a,$b)} @{$self->{FACETVERTICES}};
	$self->{FACETVERTICES}=\@temp;	
	#foreach (@{$self->{FACETVERTICES}})
	#{
	#	my $aavgz = (${$self->{VERTEXLIST}}[$$_[0]][2]+${$self->{VERTEXLIST}}[$$_[1]][2]+${$self->{VERTEXLIST}}[$$_[2]][2])/3;
	#	print "$aavgz\n";
	#}

}

sub pointInsideObject
{
	return 0;
}

sub _sort_func
{
	my $self = shift;
	my $aref = shift;
	my $bref = shift;
	my $aavgz = (${$self->{VERTEXLIST}}[$$aref[0]][2]+${$self->{VERTEXLIST}}[$$aref[1]][2]+${$self->{VERTEXLIST}}[$$aref[2]][2])/3;
	my $bavgz = (${$self->{VERTEXLIST}}[$$bref[0]][2]+${$self->{VERTEXLIST}}[$$bref[1]][2]+${$self->{VERTEXLIST}}[$$bref[2]][2])/3;
	return ($bavgz <=> $aavgz);
}

sub getMaxExtent{
	#will need generic for when shapes don't implment one
	return -1;
}

sub vertexNormal
{
	#get average normal at vertex - probably expensive - has good blending and best used where angles from one facet to the next are not huge - terrain modelling would be a good example
	#takes a facet list generated by the implementing object
	my $self = shift;
	my $facetList = shift;
	my $facetVertices = $self->{FACETVERTICES};
	my $vertexList = $self->{VERTEXLIST};
		
		my @vertNormal = (0,0,0);
		for (my $i = 0 ; $i < @$facetList ; $i++){
			my $vert1 = $$facetVertices[$$facetList[$i]][0];
			my $vert2 = $$facetVertices[$$facetList[$i]][1];
			my $vert3 = $$facetVertices[$$facetList[$i]][2];

			my @normal = _getNormal(\@{$$vertexList[$vert1]},\@{$$vertexList[$vert2]},\@{$$vertexList[$vert3]},1);
			foreach(0..2){
				$vertNormal[$_] += $normal[$_];
			}
		}
		
		map{$_=$_/scalar(@$facetList)}@vertNormal;

		_normalise(\@vertNormal); 
		
		return \@vertNormal;
}


return 1;