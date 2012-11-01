package Roid;

use Tk;

sub new
{
	my $self={};
	shift;
	$self->{X} = shift;
	$self->{Y} = shift;
	#$self->{RADIUS} = shift;
	$self->{SIZE} = shift;
	$self->{MX} = shift;
	$self->{MY} = shift;
	$self->{HP} = shift;
	$self->{COL} = shift;
	$self->{CNV} = shift;
	$self->{ID} = 0;
	bless $self;
    	return $self;
}


sub split
{
	my $self=shift;
	#my $radius = int($self->{RADIUS}/2);
	my $size = int($self->{SIZE}/2);
	my $rand = 50+int(rand(100)); 
	my $mx = ($self->{MX}/100)*$rand; #new x vector between 50% and 150% of original
	$mx = $mx*-1 if ($rand % 4 == 0); #25% change to reverse direction
	$rand = 50+int(rand(100));
	my $my = ($self->{MY}/100)*$rand;
	$my = $my*-1 if ($rand % 4 == 0);
	#return ($self->{X}, $self->{Y}, $radius, $mx, $my);
	return ($self->{X}, $self->{Y}, $size, $mx, $my);
}

sub draw
{
	my $self=shift;
	my $cnv=${$self->{CNV}};
	my $size = $self->{SIZE};
	$self->{X} += $self->{MX};
	$self->{Y} += $self->{MY};
	#curcular roids
	#if ($self->{ID} == 0){
	#	$self->{ID} = $cnv->createOval($self->{X}-$self->{RADIUS}, $self->{Y}-$self->{RADIUS}, $self->{X}+$self->{RADIUS}, $self->{Y}+$self->{RADIUS}, -fill=>$self->{COL}, -outline=>'white', -tags=>'roid');
	#}else{
	#	$cnv->coords($self->{ID},$self->{X}-$self->{RADIUS}, $self->{Y}-$self->{RADIUS}, $self->{X}+$self->{RADIUS}, $self->{Y}+$self->{RADIUS});
	#}
	
	
	#irregular roids
	if ($self->{ID} == 0){
		my @a;
		$a[0] = [$self->{X}+int(rand(10*$size)),$self->{Y}+int(rand(10*$size))];
		$a[1] = [$self->{X}+(10*$size)+int(rand(10*$size)),$self->{Y}+int(rand(10*$size))];
		$a[2] = [$self->{X}+(20*$size)+int(rand(10*$size)),$self->{Y}+int(rand(10*$size))];
		$a[3] = [$self->{X}+(20*$size)+int(rand(10*$size)),$self->{Y}+(10*$size)+int(rand(10*$size))];
		$a[4] = [$self->{X}+(20*$size)+int(rand(10*$size)),$self->{Y}+(20*$size)+int(rand(10*$size))];
		$a[5] = [$self->{X}+(10*$size)+int(rand(10*$size)),$self->{Y}+(20*$size)+int(rand(10*$size))];
		$a[6] = [$self->{X}+int(rand(10*$size)),$self->{Y}+(20*$size)+int(rand(10*$size))];
		$a[7] = [$self->{X}+int(rand(10*$size)),$self->{Y}+(10*$size)+int(rand(10*$size))];
		$self->{ID} = $cnv->createPolygon($a[0][0],$a[0][1],$a[1][0],$a[1][1],$a[2][0],$a[2][1],$a[3][0],$a[3][1],$a[4][0],$a[4][1],$a[5][0],$a[5][1],$a[6][0],$a[6][1],$a[7][0],$a[7][1], -fill=>$self->{COL}, -outline=>'white', -tags=>'roid');
	}else{
		my @a = $cnv->coords($self->{ID});
		for ($i = 0; $i < @a ;$i++){
			if ($i%2 == 0){
				$a[$i]+=$self->{MX};
			}else{
				$a[$i]+=$self->{MY};
			}
	}
		$cnv->coords($self->{ID},$a[0],$a[1],$a[2],$a[3],$a[4],$a[5],$a[6],$a[7],$a[8],$a[9],$a[10],$a[11],$a[12],$a[13],$a[14],$a[15]);
		
	}
	
	
	

}

sub getBoundingBox{
	my $self = shift;
	my $cnv=${$self->{CNV}};
	my @a = $cnv->coords($self->{ID});
	my ($minx,$miny,$maxx,$maxy) = ($a[0],$a[1],$a[0],$a[1]);
	for (my $i = 2 ; $i < @a ; $i++){
		if ($i%2 == 0){
			if ($a[$i] > $maxx){
				$maxx = $a[$i];
			}elsif ($a[$i] < $minx){
				$minx = $a[$i];
   			}
  		}else{
  			if ($a[$i] > $maxy){
  				$maxy = $a[$i];
  			}elsif ($a[$i] < $miny){
  				$miny = $a[$i];
  			}   
  		}
 	}
 	return ($minx,$miny,$maxx,$maxy);
}


sub offScreen
{
	my $self = shift;
	my $xlimit = shift;
	my $ylimit = shift;
	#return 1 if ($self->{X} < 0-$self->{RADIUS}); 
	#return 1 if ($self->{Y} < 0-$self->{RADIUS}); 
	#return 1 if ($self->{X} > $xlimit+$self->{RADIUS}); 
	#return 1 if ($self->{Y} > $ylimit+$self->{RADIUS});
	
	
	return 1 if($self->{X} > $xlimit);
	return 1 if($self->{Y} > $ylimit);
	return 1 if($self->{X}+(30*$self->{SIZE}) < 0);
	return 1 if($self->{Y}+(30*$self->{SIZE}) < 0);
	return 0;
}

sub delete
{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	$cnv->delete($self->{ID});
}



return 1;