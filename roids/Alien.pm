package Alien;
use Missile;
use Tk;

sub new
{
	my $self={};
	shift;
	my @missiles = ();
	$self->{X} = shift;
	$self->{Y} = shift;
	$self->{CNV} = shift;
	if (int(rand(1.99)) == 0){
		$self->{XSPEED} = 0;
		$self->{YSPEED} = 2;
	}else{
		$self->{XSPEED} = 2;
		$self->{YSPEED} = 0;
	}
	$self->{HP} = 14;
	$self->{ID} = 0;
	$self->{MISSILES}=\@missiles;
	$self->{MISSILESOFF} = 0;
	$self->{OFFSCREEN} = 0;
	bless $self;
    	return $self;
}

sub draw
{

	my $self = shift;
	my $cnv = ${$self->{CNV}};
	return if ($self->{OFFSCREEN}==2);
	if ($self->{OFFSCREEN}==0){
		$self->{X} -= $self->{XSPEED};
		$self->{Y} -= $self->{YSPEED};
		my $x1 = $self->{X}-12;
		my $y1 = $self->{Y};
		my $x2 = $self->{X};
		my $y2 = $self->{Y}-12;
		my $x3 = $self->{X}+12;
		my $y3 = $self->{Y};
		my $x4 = $self->{X};
		my $y4 = $self->{Y}+12;
		if ($self->{ID} == 0){
			$self->{ID} = $cnv->createPolygon($x1, $y1,$x2, $y2,$x3, $y3,$x4, $y4, -fill=>'magenta', -tags=>'alien');
		}else{
			$cnv->coords($self->{ID}, $x1, $y1,$x2, $y2,$x3, $y3,$x4, $y4);
		}
		if (($self->{XSPEED} == 0 && $self->{Y} > 0 && ($self->{Y}%80) == 0) ||
			($self->{XSPEED} > 0 && $self->{X} > 0 && ($self->{X}%80) == 0)){
			my $curcnt = scalar @{$self->{MISSILES}};
			push(@{$self->{MISSILES}}, Missile->new($self->{X}-12, $self->{Y}, \$cnv, $curcnt));
		}
	}
	#my @temp = ();
	foreach (@{$self->{MISSILES}})
	{
		if (($self->{XSPEED} == 0 && $_->{X} > 0) ||
			($self->{XSPEED} > 0 && $_->{Y} > 0)){
			$_->draw($self->{XSPEED});
	#		push(@temp, $_);
		} elsif ($_->{ID} != 0){
			$_->delete();
			$self->{MISSILESOFF}++;
		#	$_=undef;
		}
	}
	#@{$self->{MISSILES}} = @temp;
}

sub delete
{
	my $self=shift;
	my $cnv=${$self->{CNV}};
	if ($self->{OFFSCREEN} == 0){
		$self->{OFFSCREEN} = 1;
		$cnv->delete($self->{ID});
	}
	draw($self);
	my $temp = @{$self->{MISSILES}};
	return 0 if ($temp == $self->{MISSILESOFF});
	return 1;
}

sub clear
{
	my $self=shift;
	my $cnv=${$self->{CNV}};
	$self->{OFFSCREEN} = 2;
	$cnv->delete($self->{ID});
	foreach(@{$self->{MISSILES}}){
		$_->delete();
		$_=undef;
	}
	@{$self->{MISSILES}}=();
}

sub checkMissileCollision
{
	my $self=shift;
	my $tag=shift;
	my $arrid = shift;
	my $cnv=${$self->{CNV}};
	#foreach my $m (@{$self->{MISSILES}}){
	my $m = ${$self->{MISSILES}}[$arrid];
		my @keys = $cnv->find('overlapping', $m->{X}-2, $m->{Y}-2, $m->{X}+2, $m->{Y}+2);
		return (0,0) if (scalar @keys <= 2); #background and warhead (may need to check if background missing though)
		foreach my $id (@keys)
		{
			if (${$cnv->itemcget($id, -tags)}[0] eq $tag){
				$m->{X}=-1;
				$m->{Y}=-1;
				return ($m->{ID},$m->{TRAILID});
			}
		}
	#}
	return (0,0);
}

sub hit
{
	my $self=shift;
	my $cnv=${$self->{CNV}};
	$self->{HP}--;
	if ($self->{HP} == 0){
		$self->{OFFSCREEN} = 1;
		$cnv->delete($self->{ID});
		return 1;
	}
	return 0;
}



return 1;