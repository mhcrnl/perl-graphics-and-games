package StatusGrid;

use strict;
use Tk;
use MonitorItem;
our @ISA = qw(MonitorItem);

sub new
{
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{VALUES} = [];
	_draw($self);
	bless ($self, $class);
	return $self;
}

sub _draw
{
	my $self = shift;
	my ($x, $y) = $self->getLocation();
	my $blockSize = $self->getSize('w', 'blockSize');
	my $columns = $self->getDefinition('columns');
	
	my $rowcnt = 0;
	my $colcnt = 0;
	foreach(@{$self->{VALUES}})
	{
		my $xx = $x + ($blockSize * $colcnt);
		my $yy = $y + ($blockSize * $rowcnt); 
		my $centrex = $xx + ($blockSize / 2);
		my $centrey = $yy + ($blockSize / 2);
		$self->{CNV}->createRectangle($xx, $yy, $xx + $blockSize, $yy + $blockSize, -fill=>$_->{COLOUR}, tags=>[$_->{TAG}, $self->getId()]);
		$self->{CNV}->createText($centrex, $centrey - 10, -text=>$_->{LABEL}, -font=>'{Arial Bold} '.$self->getDefinition('fontSize'), -fill=>$_->{TEXTCOLOUR}, anchor=>'c', tags=>[$self->getId()]);
		$self->{CNV}->createText($centrex, $centrey + 10, -text=>$_->{VALUE}, -font=>'{Arial Bold} '.$self->getDefinition('fontSize'), -fill=>$_->{TEXTCOLOUR}, anchor=>'c', tags=>[$self->getId()]);
		if (++$colcnt == $columns)
		{
			$colcnt = 0;
			$rowcnt++;
		}
	}
}

sub update
{
	my $self = shift;
	my $data = shift;
	return if (@$data == 0);
	$self->{VALUES} = [];
	foreach(@{$self->getDefinition('data', 'item')})
	{
		my %d;
		$d{LABEL} = $_->{legend};
		$d{VALUE} = Utils::checkModification(@$data[0]->{$_->{valueField}}, $_->{valueMod});
		
		$d{COLOUR} = $self->getDefinition('statusValues','defaultColour');
		$d{COLOUR} = '#FFFFFF' if ($d{COLOUR} eq "");
		$d{TEXTCOLOUR} = $self->getDefinition('statusValues','defaultTextColour');
		$d{TEXTCOLOUR} = '#000000' if ($d{TEXTCOLOUR} eq "");
		foreach(@{$self->getDefinition('statusValues','item')})
		{
			if ((defined($_->{end}) && $d{VALUE} > $_->{start} && $d{VALUE} <= $_->{end})
				|| (!defined($_->{end}) && $d{VALUE} eq $_->{start}))
			{
				$d{COLOUR} = $_->{colour} if (defined($_->{colour}));
				$d{TEXTCOLOUR} = $_->{textColour} if (defined($_->{textColour}));
				$d{TAG} = defined($_->{flash}) ? "flash" : "static";
				last;
			}
		}
		
		push(@{$self->{VALUES}}, \%d);
	}
	$self->clear;
	$self->_draw;
}