package Missile;

use Tk;

sub new
{
	my $self={};
	shift;
	my $x = shift;
	my $y = shift;
	$self->{CNV} = shift;
	$self->{DIR} = shift;
	$self->{ARRID} = shift;
	$self->{SPEED} = 4;
	$self->{ID} = 0;
	$self->{TRAILID} = 0;

	$self->{RAND} = int (rand(3.9));
	my $effect = int(rand(5.9));
	my $colour = 'red';
	if ($effect == 1){$colour = 'blue';}
	elsif ($effect == 2){$colour = 'green';}
	elsif ($effect == 3){$colour = 'yellow';}
	elsif ($effect == 4){$colour = 'cyan';}
	elsif ($effect == 5){$colour = 'magenta';}
	
	$self->{EFF} = $effect;
	$self->{COLOUR} = $colour;
	
	my @loc;
	my @trail;
	my $size = 3;
	
	if ($self->{DIR} == 0){
		@loc =([$x-$size,$y],[$x+$size,$y-$size],[$x+$size,$y+$size]);
		@trail = ([$x+$size,$y],[$x+$size,$y]);
	}else{
		@loc =([$x,$y-$size],[$x-$size,$y+$size],[$x+$size,$y+$size]);
		@trail = ([$x,$y+$size],[$x,$y+$size]);
	}
	$self->{LOC} = \@loc;
	$self->{TRAIL} = \@trail;
	bless $self;
    	return $self;
}


sub draw{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	$self->{SPEED}+=0.1 if ($self->{SPEED} < 25);
	
	my $speed = sqrt(($self->{SPEED}*$self->{SPEED}) - ($self->{RAND}*$self->{RAND}));
	
	my $addx = $speed;
	my $addy = $self->{RAND};
	$addy=$addy*-1 if ( $self->{ARRID} % 2 == 0);
	
	if ($self->{DIR} > 0){
		$addy = $speed;
		$addx = $self->{RAND};
	}
	foreach(0..2){
		${$self->{LOC}}[$_][0] -= $addx;
		${$self->{LOC}}[$_][1] -= $addy;
	}

	${$self->{TRAIL}}[0][0] -= $addx;
	${$self->{TRAIL}}[0][1] -= $addy;
	if ($self->{DIR} == 0){
		${$self->{TRAIL}}[1][0] = ${$self->{TRAIL}}[0][0]+($self->{SPEED}*3);
		${$self->{TRAIL}}[1][1] = ${$self->{TRAIL}}[0][1] + $addy;
	}else{
		${$self->{TRAIL}}[1][0] = ${$self->{TRAIL}}[0][0] + $addx;
		${$self->{TRAIL}}[1][1] = ${$self->{TRAIL}}[0][1]+($self->{SPEED}*3);
	}


	if ($self->{ID} == 0){
		$self->{ID} = $cnv->createPolygon(${$self->{LOC}}[0][0], ${$self->{LOC}}[0][1], ${$self->{LOC}}[1][0], ${$self->{LOC}}[1][1], ${$self->{LOC}}[2][0], ${$self->{LOC}}[2][1], -fill=>$self->{COLOUR}, -outline=>$self->{COLOUR}, -tags=>["missile","eff:".$self->{EFF},$self->{ARRID}]);
		$self->{TRAILID} = $cnv->createLine(${$self->{TRAIL}}[0][0], ${$self->{TRAIL}}[0][1], ${$self->{TRAIL}}[1][0], ${$self->{TRAIL}}[1][1], -fill=>'yellow', -tags=>'trail');
	}else{
		$cnv->coords($self->{ID},${$self->{LOC}}[0][0], ${$self->{LOC}}[0][1], ${$self->{LOC}}[1][0], ${$self->{LOC}}[1][1], ${$self->{LOC}}[2][0], ${$self->{LOC}}[2][1]);
		$cnv->coords($self->{TRAILID},${$self->{TRAIL}}[0][0], ${$self->{TRAIL}}[0][1], ${$self->{TRAIL}}[1][0], ${$self->{TRAIL}}[1][1]);
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