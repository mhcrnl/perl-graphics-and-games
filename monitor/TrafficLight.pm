package TrafficLight;
use Utils;
use Math::Trig;
use strict;
use Tk;
use MonitorItem;
our @ISA = qw(MonitorItem);

sub new
{
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{VALUE} = 0;
	_draw($self);
	bless ($self, $class);
	return $self;
}

sub _draw
{
	my $self = shift;
	my $cnv = $self->{CNV};
	my $start = 110;
	my $end = 240;
	my $graduation = 15;
	my ($x, $y, $height, $width) = $self->getLocation();
	my $incr = ($width/2) / $graduation;
	my $sinIncr = 90 / $graduation;
	
	my $diff = $end - $start;
	my $percent = int(($self->{VALUE} / $self->getDefinition('maxValue')) * 100);
	
	for(my $i = 0 ; $i < $graduation ;$i++)
	{
		my $colourVal = $start + ($diff * sin(deg2rad($i*$sinIncr)));
		my $colourhex = Utils::dec2hex(int($colourVal));
	
		my $tag = 'flash'; 
		my $colour = "#".$colourhex."2222";
		$colour = "#".$colourhex.$colourhex."22" if ($percent < 90);
		$colour = "#22".$colourhex."22" if ($percent < 60);
		$tag = 'static' if ($percent < 90); 
		
		my $curWidth = $width - ($width * ($i/$graduation));
		my $xx = $x + ($incr * $i);
		my $yy = $y + ($incr * $i);
		$cnv->createOval($xx, $yy, $xx+$curWidth, $yy+$curWidth, -outline=>$colour, -fill=>$colour, -outline=>$colour, -tags=>[$tag, $self->getId()]);
	}
	
	$cnv->createText($x + $width/2, $y + $width/2, -text=>$percent.'%', -font=>'{Arial Bold} '.$self->getDefinition('fontSize'), -fill=>'white', -tags=>['value', $self->getId()]);
}

sub update
{
	my $self = shift;
	my $data = shift;
	return if (@$data == 0);
	my $val = $$data[0]->{$self->getDefinition('valueField')};
	$self->{VALUE} = Utils::checkModification($val, $self->getDefinition('valueMod'));
	$self->clear();
	_draw($self);
}


1;