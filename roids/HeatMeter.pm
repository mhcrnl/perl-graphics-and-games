package HeatMeter;
use GamesLib;
use strict;
use Tk;


sub new
{
	my $self={};
	shift;
	$self->{CNV} = shift;
	$self->{COOLRATE} = shift;
	$self->{HEAT} = 0;
	${$self->{CNV}}->createText(5,10, -anchor=>'w',-fill=>'white',-text=>"Heat");
	
	my $closure = {};
	
	#testing closure setup, keeps the object data private
	$closure->{RESET} = sub {
		$self->{HEAT}=0;
	};
	
	$closure->{COOL} = sub {
		my $heat=shift;
		$self->{HEAT} = $self->{HEAT}*$self->{COOLRATE};
		$self->{HEAT} = 0 if ($self->{HEAT} < 1);
		$self->{HEAT} += $heat if ($heat);
		_draw($self);
	};
	
	$closure->{HEAT} = sub {
		my $heatAmount = shift;
		return 1 if ($heatAmount < 0);
		if ($self->{HEAT}+$heatAmount <= 100){
			$self->{HEAT}+=$heatAmount;
			_draw($self);
			return 1;
		}
		return 0;
	};
		

    bless $closure;
    return $closure;
    	
}

sub cool
{
	my $closure = shift;
	&{$closure->{COOL}};
}

sub heat
{
	my $closure = shift;
	&{$closure->{HEAT}};
}

sub reset
{
	my $closure = shift;
	&{$closure->{RESET}};
}


sub _draw
{
	my $self = shift;
	my $cnv = $self->{CNV};
	$$cnv->delete('all');
	my $heat = int($self->{HEAT});
	my ($red, $green, $blue);
	for (my $i = 0 ; $i < $heat ; $i++){
		
		if ($i < 51){
			$red = "00";
			$blue = dec2hex(255 - ((2.55*$i)*2));
			$green = dec2hex((2.55*$i)*2);
		}else{
			$red = dec2hex((2.55*($i-50))*2);
			$blue = "00";
			$green =  dec2hex(255 - ((2.55*($i-50))*2));
		}
		my $colour = "#".$red.$green.$blue;
		my $y = 280-($i*2);
		$$cnv->createRectangle(0,$y,30,($y-2), -fill=>$colour, -outline=>$colour);
	}
	$$cnv->createText(5,10, -anchor=>'w',-fill=>'white',-text=>"Heat");
	$$cnv->createText(5,25, -anchor=>'w',-fill=>'white',-text=>"$heat %");
	$$cnv->update;
}




1;
