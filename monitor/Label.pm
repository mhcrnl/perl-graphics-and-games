package Label;

use Utils;
use strict;
use Tk;

use MonitorItem;
our @ISA = qw(MonitorItem);

sub new
{
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{VALUE} = "";
	bless ($self, $class);
	$self->_draw();
	return $self;
}

sub _draw
{
	my $self = shift;
	my ($x, $y) = $self->getLocation();
	$self->{CNV}->createText($x, $y, -text=>$self->{VALUE}, -font=>'{Arial Bold} '.$self->getDefinition('fontSize'), -fill=>'white', anchor=>'c', tags=>[$self->getId()]);
}

sub update
{
	my $self = shift;
	my $data = shift;
	return if (@$data == 0);
	my $val = $$data[0]->{$self->getDefinition('valueField')};
	$self->{VALUE} = Utils::checkModification($val, $self->getDefinition('valueMod'));
	$self->clear(); 
	$self->_draw();
}

1;