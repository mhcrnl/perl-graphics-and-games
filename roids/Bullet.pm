package Bullet;

use Tk;
use GamesLib;
use strict;

sub new
{
	my $self={};
	shift;
	$self->{X} = shift;
	$self->{Y} = shift;
	$self->{ADDX} = shift;
	$self->{ADDY} = shift;
	$self->{CNV} = shift;
	$self->{ROUND} = shift;
	$self->{ID} = 0;
	$self->{CNT} = 0;
	bless $self;
    	return $self;
}


sub draw
{
	my $self=shift;
	my $xlimit=shift;
	my $ylimit=shift;
	my $tag=shift;
	$tag='bullet' if (! $tag);
	my $cnv=${$self->{CNV}};
	my $x = $self->{X};
	my $y = $self->{Y};
	$self->{X} += $self->{ADDX};
	$self->{Y} += $self->{ADDY};
	my $colour = 'green';
	$colour = 'blue' if ($self->{ROUND} eq 'AP');
	$colour = 'cyan' if ($self->{ROUND} eq 'EXP');
	
	if($self->{ROUND} eq 'BEAM'){
		#beam weapon

		my ($xl, $yl);
		my $cyclestox = -1;
		my $cyclestoy = -1;
		#print $xlimit." - ".$self->{X}." - ".$self->{ADDX}."\n";
		if ($self->{ADDX} < 0){
			$cyclestox = $self->{X}/($self->{ADDX}*-1);
		}elsif($self->{ADDX} > 0){
			$cyclestox = ($xlimit - $self->{X})/$self->{ADDX};
		}
		if ($self->{ADDY} < 0){
			$cyclestoy = $self->{Y}/($self->{ADDY}*-1);
		}elsif($self->{ADDY} > 0){
			$cyclestoy = ($ylimit - $self->{Y})/$self->{ADDY};
		}
		#print "$cyclestox : $cyclestoy\n";
		if (($cyclestox < $cyclestoy && $cyclestox != -1) || $cyclestoy == -1){
			#print "moo\n";
			$xl=$self->{X}+($self->{ADDX}*$cyclestox);
			$yl=$self->{Y}+($self->{ADDY}*$cyclestox);
		}else{
			#print "cow\n";
			$xl=$self->{X}+($self->{ADDX}*$cyclestoy);
			$yl=$self->{Y}+($self->{ADDY}*$cyclestoy);		
		}
		#print "$x : $y : $xl : $yl\n";
		
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createLine($x, $y, $xl, $yl, -width=>2, -fill=>$colour, -tags=>$tag);
		}else{
			$self->{CNT}++;
			#prettified laser effect
			my $amt = 16*$self->{CNT};
			my $col = '#'.dec2hex($amt).dec2hex(255-$amt).'00';
			$cnv->itemconfigure($self->{ID}, -fill=>$col);
			$cnv->itemconfigure($self->{ID}, -width=>1) if ($self->{CNT} == 9);
			$self->{X} = $xlimit+10 if($self->{CNT} == 14);
		}
	}
	else{
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createLine($x, $y, $self->{X}, $self->{Y}, -width=>2, -fill=>$colour, -tags=>$tag);
		}else{
			$cnv->coords($self->{ID},$x, $y, $self->{X}, $self->{Y});
		}
		
		if($self->{ROUND} eq 'CLU'){
			#cluster munition
			$self->{CNT}++;
			$self->{X} = $xlimit+10 if($self->{CNT} == 16);
		}
	}

}

sub offScreen
{
	my $self = shift;
	my $xlimit = shift;
	my $ylimit = shift;
	return 1 if ($self->{X} < 0); 
	return 1 if ($self->{Y} < 0); 
	return 1 if ($self->{X} > $xlimit); 
	return 1 if ($self->{Y} > $ylimit);
	return 0;
}

sub delete
{
	my $self = shift;
	my $cnv = ${$self->{CNV}};
	$cnv->delete($self->{ID});
}



return 1;