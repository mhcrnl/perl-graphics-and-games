package MessageList;

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
	$self->{DATA} = undef;
	_draw($self);
	bless ($self, $class);
	return $self;
}

sub _draw
{
	my $self = shift;
	my ($x, $y, $h, $w) = $self->getLocation();
	my $fontSize = $self->getDefinition('fontSize');
	$fontSize = 10 if ($fontSize eq "");
	
	foreach(@{$self->{DATA}})
	{
		$x = 20;
		my ($width, $height, $id) = Utils::getGDLabel($self->{MW}, $_->{TIME}, $self->getId(), $fontSize);
		$self->{CNV}->createImage($x, $y, -image=>$id, -anchor=>'nw', tags=>[$self->getId()]);
		$x += $width + 5;
		my $maxWidth = $w - $width - 5;
		if ($w == 0){
			$maxWidth = $self->{CNV}->Width - $x - $width - 5;
		}
		next if ($maxWidth < 1);
		($width, $height, $id) = Utils::getGDWrappedLabel($self->{MW}, $_->{VALUE}, $self->getId(), $fontSize, $maxWidth, $_->{COLOUR}, $_->{TEXTCOLOUR}, 1);
		$self->{CNV}->createRectangle($x, $y, $x + $width, $y + $height, -fill=>$_->{COLOUR}, tags=>[$self->getId(), $_->{FLASHTAG}]);
		$self->{CNV}->createImage($x, $y, -image=>$id, -anchor=>'nw', tags=>[$self->getId()]);
		$y += $height + 3;
	}
}

sub update
{
	my $self = shift;
	my $data = shift;
	return if (@$data == 0);
	
	my $limitResults = 9999999;
	$limitResults = $self->getDefinition('resultLimit') if ($self->getDefinition('resultLimit') > 0);
	
	$self->{DATA} = [];
	my $timeField = $self->getDefinition('timeField');
	my @messages = sort {$b->{$timeField} <=> $a->{$timeField}} @$data;
	
	my $valueField = $self->getDefinition('valueField');
	my $valueMod = $self->getDefinition('valueMod');
	
	my $alertField = $self->getDefinition('alertLevelField');
	
	my $timeMod = $self->getDefinition('timeMod');
	
	my $cnt = 0;
	
	foreach (@messages)
	{
		last if ($cnt++ > $limitResults);
		my %d;
		$d{TIME} = Utils::checkModification($_->{$timeField}, $timeMod);
		$d{VALUE} = Utils::checkModification($_->{$valueField}, $valueMod);
		$d{ALERTLEVEL} = $_->{$alertField};
		
		$d{COLOUR} = $self->getDefinition('alertLevels','defaultBackground');
		$d{TEXTCOLOUR} = $self->getDefinition('alertLevels','defaultTextColour');
		
		my $colour = $self->getDefinition('alertLevels', 'item', $d{ALERTLEVEL}, 'colour');
		my $textcolour = $self->getDefinition('alertLevels', 'item', $d{ALERTLEVEL}, 'textColour');
		my $flash = $self->getDefinition('alertLevels', 'item', $d{ALERTLEVEL}, 'flash');
		
		$d{COLOUR} = $colour if ($colour ne "");
		$d{TEXTCOLOUR} = $textcolour  if ($textcolour ne "");
		$d{FLASHTAG} = ($flash eq "true") ? 'flash' : 'static';
		push(@{$self->{DATA}}, \%d);
	}
	
	$self->clear();
	_draw($self);
}