package BarList;

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
	my ($x, $y) = $self->getLocation();
	my $maxBarWidth = $self->getSize('w', 'maxBarWidth');
	my $cnv = $self->{CNV};
	my $rowHeight = 10;
	my $labelWidth = 0;
	
	foreach(@{$self->{DATA}})
	{
		my ($width, $height, $id) = Utils::getGDLabel($self->{MW}, $_->{LABEL}, $self->getId(), 9);
		$cnv->createImage($x, $y, -image=>$id, -anchor=>'nw', tags=>[$self->getId()]);
		$labelWidth = $width if ($width > $labelWidth);
		$y += $rowHeight + 4;
	}
	
	my $barX = $x + $labelWidth + 4;
	$y = $self->getSize('h', 'location', 'y');
	
	foreach(@{$self->{DATA}})
	{
		my $percent = $_->{VALUE} / $self->getDefinition('maxValue');
		
		my $tag = 'flash'; 
		my $colour = "#FF2222";
		$colour = "#FFFF22" if ($percent < 0.9);
		$colour = "#22FF22" if ($percent < 0.6);
		$tag = 'static' if ($percent < 0.9); 
		
		my $bWidth = $percent * $maxBarWidth;
		$cnv->createRectangle($barX, $y, $barX + $bWidth, $y + $rowHeight, -fill=>$colour, tags=>[$tag, $self->getId()]);
		$cnv->createText($barX + $maxBarWidth + 4, $y, -text=>$_->{VALUE}." (".sprintf("%.2f", $percent*100)."%)", -font=>'{Arial Bold} 9', -fill=>'white', anchor=>'nw', tags=>[$self->getId()]);
		$y += $rowHeight + 4;
	}
	
}

sub update
{
	my $self = shift;
	my $data = shift;
	my @gridData;
	my $limitResults = 9999999;
	$limitResults = $self->getDefinition('resultLimit') if ($self->getDefinition('resultLimit') > 0);

	my $cnt = 0;
	foreach(@$data)
	{
		last if ($cnt++ > $limitResults);
		my %d;
		$d{VALUE} = Utils::checkModification($_->{$self->getDefinition('valueField')}, $self->getDefinition('valueMod'));
		$d{LABEL} = Utils::checkModification($_->{$self->getDefinition('labelField')}, $self->getDefinition('labelMod'));
		
		push(@gridData, \%d);
	}
	
	$self->{DATA} = \@gridData;
	$self->clear();
	_draw($self);
}

1;