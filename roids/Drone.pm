package Drone;

use Bullet;
use Math::Trig;
use Tk;
use GamesLib;

sub new
{
	my $self={};
	shift;
	$self->{X} = shift;
	$self->{Y} = shift;
	$self->{HP} = shift;
	$cnv = shift;
	$self->{ROUND}=shift;
	$self->{CNV} = $cnv;
	$self->{ID} = $$cnv->createPolygon($self->{X}-7, $self->{Y}, $self->{X}-3,$self->{Y}-7, $self->{X}+3,$self->{Y}-7, $self->{X}+7, $self->{Y},$self->{X}+3, $self->{Y}+7,$self->{X}-3, $self->{Y}+7, -fill=>'yellow', -outline=>'yellow', -tags=>'drone');
	$self->{BULLET} = undef;
	bless $self;
    	return $self;
}

sub plotDeflectionShot
{
	my $self = shift;
	my $shipobj = shift;
	my $screenx = shift;
	my $screeny = shift;
	if (defined($self->{BULLET}))
	{
		_moveBullet($self, $screenx, $screeny);
		return;
	}
	my $cnv = $self->{CNV};
	my @shipcoords = $$cnv->coords('ship');
	my $sx = @shipcoords[4];
	my $sy = @shipcoords[5];
	my $tx = $sx;
	my $ty = $sy;
	my $bspeed = 8;
	if ($shipobj->{thrust} > 0 && $shipobj->{thrust} < $bspeed && $self->{ROUND} eq 'STD'){ #if ship going faster than bullet, will only intercept if ship heading towards drone, cannot be arsed figuring it out (would use dot products etc), just fire at the ship
		#take shot to intercept ship, assuming no course change
		my ($x, $y, $msx, $msy) = $shipobj->getFireLine($shipobj->{thrust},0);
		my $cycle = 0;
		while(1){
			#probably an equation that sorts this out quickly somewhere
			#instead of this trial and error approach
			$cycle++;
			$tx+=$msx;
			$ty+=$msy;
			my $dx = $self->{X} - $tx;
			my $dy = $self->{Y} - $ty;
			#print "$msx : $msy : $tx : $ty : $dx : $dy\n";
			my $interceptLength = sqrt(($dx*$dx)+($dy*$dy));
			my $temp =$interceptLength/$bspeed;
			if ($interceptLength/$bspeed <= $cycle){ #$bspeed (bulletspeed) is distance a shot will cover over 1 cycle
				my $addx = ($dx/$cycle)*-1;
				my $addy = ($dy/$cycle)*-1;
				$self->{BULLET} = Bullet->new($self->{X}, $self->{Y}, $addx, $addy, $cnv, $self->{ROUND});
				last;
			}
		}
		

		
	}else{ #fires where ship is now
			my $dx = $self->{X} - $tx;
			my $dy = $self->{Y} - $ty;
			my $interceptCycles = sqrt(($dx*$dx)+($dy*$dy))/$bspeed;
			my $addx = ($dx/$interceptCycles)*-1;
			my $addy = ($dy/$interceptCycles)*-1;
			
			if ($self->{ROUND} eq 'BEAM'){ #laser round - introduce error to give some chance
				my $randx = 0.5+rand(1);
				my $randy = 0.4+rand(1.6);
				$addx = $addx*$randx;
				$addy = $addy*$randy;
			}
			
			$self->{BULLET} = Bullet->new($self->{X}, $self->{Y}, $addx, $addy, $cnv, $self->{ROUND});
	}
}


sub _moveBullet
{
	my $self = shift;
	my $screenx = shift;
	my $screeny = shift;
	my $b = $self->{BULLET};
	if ($b->offScreen($screenx, $screeny)){
		$b->delete();
		$self->{BULLET} = undef;
	}else{
		$b->draw($screenx, $screeny, 'roid'); #pretend its an asteroid, will get picked up in collision check with no more work
	}
}

sub move
{
#try to home in on ship to a certain distance
	my $self = shift;
	my @shipcoords = $$cnv->coords('ship');
	my $sx = @shipcoords[4];
	my $sy = @shipcoords[5];
	my $dx = $self->{X} - $sx;
	my $dy = $self->{Y} - $sy;
	my $len = sqrt(($dx*$dx)+($dy*$dy));
	if ($len > 100){
		my ($addx, $addy) = getLine(3,$sx, $sy, $self->{X}, $self->{Y});
		 $self->{X}+= $addx;
		 $self->{Y}+= $addy;
		 $$cnv->coords($self->{ID}, $self->{X}-7, $self->{Y}, $self->{X}-3,$self->{Y}-7, $self->{X}+3,$self->{Y}-7, $self->{X}+7, $self->{Y},$self->{X}+3, $self->{Y}+7,$self->{X}-3, $self->{Y}+7);
	} #else orbit?


}



1;