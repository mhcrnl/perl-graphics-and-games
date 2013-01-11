package Shockwave;

use Tk;

sub new
{
	my $self={};
	shift;
	$self->{X} = shift;
	$self->{Y} = shift;
	$self->{X1} = $self->{X};
	$self->{Y1} = $self->{Y};
	$self->{X2} = $self->{X};
	$self->{Y2} = $self->{Y};
	$self->{ADDX} = shift;
	$self->{ADDY} = shift;
	$self->{ADDX1} = shift;
	$self->{ADDY1} = shift;
	$self->{ADDX2} = shift;
	$self->{ADDY2} = shift;
	$self->{CNV} = shift;
	$self->{ROUND} = 'WAVE';
	$self->{ID} = 0;
	bless $self;
    	return $self;
}

sub removeAfterHit
{
	return 0;
}


sub draw
{
	my $self=shift;
	my $cnv=${$self->{CNV}};
	$self->{X} += $self->{ADDX};
	$self->{Y} += $self->{ADDY};
	$self->{X1} += $self->{ADDX1};
	$self->{Y1} += $self->{ADDY1};
	$self->{X2} += $self->{ADDX2};
	$self->{Y2} += $self->{ADDY2};
	my $colour = 'green';
	
	if ($self->{ID} == 0){
		$self->{ID} = $cnv->createLine($self->{X}, $self->{Y}, $self->{X1}, $self->{Y1},$self->{X2}, $self->{Y2}, -smooth=>1, -splinesteps=>20, -width=>11, -fill=>$colour, -tags=>'shockwave');
	}else{
		$cnv->coords($self->{ID},$self->{X}, $self->{Y}, $self->{X1}, $self->{Y1},$self->{X2}, $self->{Y2});
	}


}

sub offScreen
{

	my $self = shift;
	my $xlimit = shift;
	my $ylimit = shift;
	return 1 if (($self->{X} < 0 ||
			$self->{Y} < 0 ||
			$self->{X} > $xlimit ||
			$self->{Y} > $ylimit) &&
			($self->{X1} < 0 ||
			$self->{Y1} < 0 ||
			$self->{X1} > $xlimit ||
			$self->{Y1} > $ylimit) &&
			($self->{X2} < 0 ||
			$self->{Y2} < 0 ||
			$self->{X2} > $xlimit ||
			$self->{Y2} > $ylimit));
	return 0;
}

sub delete
{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	$cnv->delete($self->{ID});
}



return 1;