package Bullet;

use Tk;
use GamesLib;
use Math::Trig;
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
		$self->{TRACKING} = shift;
		my $length=0;
		if ($self->{ADDX} == 0){
			$length=sqrt($self->{ADDY}*$self->{ADDY});
		}elsif ($self->{ADDY} == 0){
			$length=sqrt($self->{ADDX}*$self->{ADDX});
		}else{
			$length = sqrt(($self->{ADDX}*$self->{ADDX})+($self->{ADDY}*$self->{ADDY}))
		}
	$self->{LENGTH} = $length;
	bless $self;
    	return $self;
}


sub _alterTrajectory{
	my $self=shift;

	return if ($self->{TRACKING} == 0 || ! defined($self->{TRACKING}) || (defined($self->{TRACKING}) && $self->{TRACKING}->{DEAD}==1));
	
	my ($rx,$ry) = $self->{TRACKING}->getCentre();

	my ($addx, $addy) = getLine($self->{LENGTH}, $rx, $ry, $self->{X}, $self->{Y});
	
	#trying to get a nice curve
	
	my @roidvec = ($addx,$addy,0);
	_normalise(\@roidvec);
	my $roiddeg = rad2deg(acos($roidvec[1]));
	$roiddeg = 360 - $roiddeg if ($roidvec[0] < 0);
	
	my @bulvec = ($self->{ADDX},$self->{ADDY},0);
	_normalise(\@bulvec);
	my $buldeg = rad2deg(acos($bulvec[1]));
	$buldeg = 360 - $buldeg if ($bulvec[0] < 0);
	
	my $dif = $roiddeg - $buldeg;
	 $dif-=360 if ($dif > 180);
	  $dif+=360 if ($dif < -180);
	
	$dif = sprintf "%.2f", $dif;
	
	$dif = 5 if ($dif > 5);
	$dif = -5 if ($dif < -5);
	
	my $tempvec = CanvasObject->new;
	my @vector;
	$vector[0] = [$self->{ADDX},$self->{ADDY},0];
	$tempvec->{VERTEXLIST} = \@vector;
	$tempvec->rotate('z',-$dif,0,0);
	
	$self->{ADDX} = $vector[0][0];
	$self->{ADDY} = $vector[0][1];
	
	$tempvec = undef;
	#$self->{ADDX} = $addx;
	#$self->{ADDY} = $addy;
}

sub _generateBeam
{
	my $self=shift;
	my $xlimit=shift;
	my $ylimit=shift;
	my $tag=shift;
	my $cnv=${$self->{CNV}};
	my ($xl, $yl);
		my $cyclestox = -1;
		my $cyclestoy = -1;

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

		
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createLine($self->{X}, $self->{Y}, $xl, $yl, -width=>2, -fill=>'green', -tags=>$tag);
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


sub doExplosion{
	my $self = shift;
	my $bularrayRef = shift;
	my $cnv = $self->{CNV};
	my $tag = "CLU";
	my $x = $self->{X};
	my $y = $self->{Y};
	
	my $tempvec = CanvasObject->new;
	my @vector;
	$vector[0] = [0,6,0];
	$tempvec->{VERTEXLIST} = \@vector;
	
	foreach (0..14){
		push(@$bularrayRef, Bullet->new($x, $y, $vector[0][0], $vector[0][1], $cnv, $tag));
		$tempvec->rotate('z',24,0,0);
	}
	

		$tempvec = undef;
}



sub removeAfterHit{

	my $self=shift;
	return 1 if ($self->{ROUND} =~ m/STD|CLU|TRK|SER/);
	
	return 0;
}

sub draw
{
	my $self=shift;
	my $xlimit=shift;
	my $ylimit=shift;
	my $bularrayRef = shift;
	my $tag=shift;
	$tag='bullet' if (! $tag);
	
	_alterTrajectory($self) if ($self->{ROUND} eq 'TRK' && $self->{CNT} > 10); #tracking round
	
	my $cnv=${$self->{CNV}};
	my $x = $self->{X};
	my $y = $self->{Y};
	$self->{X} += $self->{ADDX};
	$self->{Y} += $self->{ADDY};
	my $colour = 'green';
	$colour = 'blue' if ($self->{ROUND} eq 'AP');
	$colour = 'cyan' if ($self->{ROUND} eq 'EXP');
	$colour = 'yellow' if ($self->{ROUND} eq 'TRK');
	
	if($self->{ROUND} eq 'BEAM'){
		#beam weapon
		_generateBeam($self,$xlimit,$ylimit,$tag);
		
	}elsif($self->{ROUND} eq 'SEN'){
		#sentry
		if ($self->{CNT} > 400){
			$self->{X} = $xlimit+10;
		}else{
			if ($self->{ID} == 0){
				$self->{ID} = $cnv->createOval($x, $y, $x+10, $y+10, -width=>2, -fill=>$colour, -tags=>$tag);
			}else{
				$cnv->coords($self->{ID},$x, $y, $x+10, $y+10);
			}
			
		
			if ($self->{CNT} % 2 == 0){
			my $tempvec = CanvasObject->new;
			my @vector;
			$vector[0] = [0,6,0];
			$tempvec->{VERTEXLIST} = \@vector;
			
			$tempvec->rotate('z',$self->{CNT}*5,0,0);	
			
			#changed to impart sentry momentum to the sentry rounds
			push(@$bularrayRef, Bullet->new($self->{X}+5, $self->{Y}+5, $self->{ADDX}+$vector[0][0], $self->{ADDY}+$vector[0][1], \$cnv, 'SER'));
			push(@$bularrayRef, Bullet->new($self->{X}+5, $self->{Y}+5, $self->{ADDX}-$vector[0][0], $self->{ADDY}-$vector[0][1], \$cnv, 'SER'));
				

			$tempvec = undef;
			}
		}		
		
		$self->{CNT}++;
		
		
	}else{
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createLine($x, $y, $self->{X}, $self->{Y}, -width=>2, -fill=>$colour, -tags=>$tag);
		}else{
			$cnv->coords($self->{ID},$x, $y, $self->{X}, $self->{Y});
		}
		$self->{CNT}++;
		if($self->{ROUND} eq 'CLU'){
			#cluster munition
			$self->{X} = $xlimit+10 if($self->{CNT} == 16);
		}
		elsif($self->{ROUND} eq 'SER'){
			#sentry round
			$self->{X} = $xlimit+10 if($self->{CNT} == 35);
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
	$self->{TRACKING} = undef;
}



return 1;