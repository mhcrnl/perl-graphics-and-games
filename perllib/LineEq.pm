package LineEq;

use strict;


sub new
{
	shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x = shift;
	my $y = shift;
	my $self;
	$self->{X} = undef;
	$self->{Y} = undef;
	$self->{GRAD} = undef;
	$self->{C} = undef;
	
	my $dx = $x1 - $x;
	if ($dx == 0){
		#equation is x = $x (vertical line)
		$self->{X} = $x;
	}else{
		my $dy = $y1 - $y;
		if ($dy == 0){
			#equation is y = $y (horizontal)
			$self->{Y} = $y;

		}else{
			my $grad = $dy/$dx;
			my $c = $y - ($grad*$x);
			#equation is y=$grad(x) + $c
			$self->{GRAD} = $grad;
			$self->{C} = $c;

		}
	} 
	$self->{STARTX}=$x1;
	$self->{STARTY}=$y1;
	
	if ($x1 > $x){
		$self->{MINX}=$x;
		$self->{MAXX}=$x1;
	}
	else{
			$self->{MINX}=$x1;
			$self->{MAXX}=$x;
	}
	if ($y1 > $y){
		$self->{MINY}=$y;
		$self->{MAXY}=$y1;
	}
	else{
		$self->{MINY}=$y1;
		$self->{MAXY}=$y;
	}
	my $dmx = $self->{MAXX} - $self->{MINX};
	my $dmy = $self->{MAXY} - $self->{MINY};
	$self->{LEN} = sqrt(($dmx*$dmx)+($dmy*$dmy)); 
	bless $self;
	return $self;
	
}

sub xAty
{
	my $self=shift;
	my $y=shift;
	if (defined($self->{X})){
		return $self->{X};
	}elsif(defined($self->{Y})){
		return 'n';
	}else{
		my $x = ($y - $self->{C})/$self->{GRAD};
		return $x;
	}
}

sub yAtx
{
	my $self=shift;
	my $x=shift;
	if (defined($self->{X})){
		return 'n';
	}elsif(defined($self->{Y})){
		return $self->{Y};
	}else{
		my $y = ($self->{GRAD}*$x) + $self->{C};
		return $y;
	}
}
1;