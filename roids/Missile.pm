package Missile;

use Tk;

sub new
{
	my $self={};
	shift;
	$self->{X} = shift;
	$self->{Y} = shift;
	$self->{CNV} = shift;
	$self->{ARRID} = shift;
	$self->{SPEED} = 0;
	$self->{ID} = 0;
	$self->{TRAILID} = 0;
	bless $self;
    	return $self;
}

sub draw
{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	my $direction = shift;
	my $size = 3;
	my $effect = 0;
	my $colour = 'red';
	if ($self->{ID} == 0){
		$effect = int(rand(5.9));
		$colour = 'red';
		if ($effect == 1){$colour = 'blue';}
		elsif ($effect == 2){$colour = 'green';}
		elsif ($effect == 3){$colour = 'yellow';}
		elsif ($effect == 4){$colour = 'cyan';}
		elsif ($effect == 5){$colour = 'magenta';}
	}
	
	$self->{SPEED}+=0.05 if ($self->{SPEED} < 20);
	$self->{X}-=$self->{SPEED} if ($direction == 0);
	$self->{Y}-=$self->{SPEED} if ($direction > 0);
	if ($direction == 0){
		my $x1 = $self->{X}-$size;
		my $y1 = $self->{Y};
		my $x2 = $self->{X}+$size;
		my $y2 = $self->{Y}-$size;
		my $x3 = $self->{X}+$size;
		my $y3 = $self->{Y}+$size;
		my $tx1 = $self->{X}+$size;
		my $ty1 = $self->{Y};
		my $tx2 = $self->{X}+$size+($self->{SPEED}*3);
		my $ty2 = $self->{Y};
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createPolygon($x1, $y1, $x2, $y2, $x3, $y3, -fill=>$colour, -outline=>$colour, -tags=>["missile","eff:$effect",$self->{ARRID}]);
			$self->{TRAILID} = $cnv->createLine($tx1, $ty1, $tx2, $ty2, -fill=>'yellow', -tags=>'trail');
		}else{
			$cnv->coords($self->{ID},$x1, $y1, $x2, $y2, $x3, $y3);
			$cnv->coords($self->{TRAILID},$tx1, $ty1, $tx2, $ty2);
		}
	}else{
		my $x1 = $self->{X};
		my $y1 = $self->{Y}-$size;
		my $x2 = $self->{X}-$size;
		my $y2 = $self->{Y}+$size;
		my $x3 = $self->{X}+$size;
		my $y3 = $self->{Y}+$size;
		my $tx1 = $self->{X};
		my $ty1 = $self->{Y}+$size;
		my $tx2 = $self->{X};
		my $ty2 = $self->{Y}+$size+($self->{SPEED}*3);
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createPolygon($x1, $y1, $x2, $y2, $x3, $y3, -fill=>$colour, -outline=>$colour, -tags=>["missile","eff:$effect",$self->{ARRID}]);
			$self->{TRAILID} = $cnv->createLine($tx1, $ty1, $tx2, $ty2, -fill=>'yellow', -tags=>'trail');
		}else{
			$cnv->coords($self->{ID},$x1, $y1, $x2, $y2, $x3, $y3);
			$cnv->coords($self->{TRAILID},$tx1, $ty1, $tx2, $ty2);
		}	
	}
}

sub delete
{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	if ($self->{ID} > 0){
	$cnv->delete($self->{ID});
	$cnv->delete($self->{TRAILID});
	}
	$self->{ID}=0;
}




return 1;