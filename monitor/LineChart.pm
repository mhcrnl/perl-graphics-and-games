package LineChart;

use Utils;
use Math::Trig;
use strict;
use Tk;

sub new
{
	my $self={};
	shift;
	$self->{DEF} = shift;
	$self->{MW} = shift;
	$self->{CNV} = shift;
	$self->{DATA} = undef;
	$self->{MW}->DefineBitmap("stipple$b" => 8, 1, pack('b8', '00110011'));
	_draw($self);
	bless $self;
	return $self;
}

sub _draw
{
	my $self = shift;
	my $x = $self->{DEF}->{location}->{x};
	my $y = $self->{DEF}->{location}->{y};
	my $height = Utils::getSize($self, $self->{DEF}->{height}, 'h');
	my $width = Utils::getSize($self, $self->{DEF}->{width}, 'w');
	return if ($width < 1 || $height < 1);
	
	my $range = $self->{DEF}->{range}->{max} - $self->{DEF}->{range}->{min};
	my $multiplier = $self->{DEF}->{range}->{max} / $range;
	
	for(my $i = 0 ; $i < 4 ; $i++)
	{
		my $ly = $y + (($height/4) * $i); 
		my $label = $self->{DEF}->{range}->{max} - (($range / 4) * $i);
		$self->{CNV}->createLine($x, $ly, $x + $width, $ly, -fill=>'white', -width=>1, -stipple => "stipple$b", tags=>['lineChart']);
		$self->{CNV}->createText($x - 4, $ly, -text=>int($label), -font=>'{Arial Bold} 9', -fill=>'white', anchor=>'e', tags=>['lineChart']);
	}	
	$self->{CNV}->createLine($x, $y, $x, $y + $height, -fill=>'white', -width=>2, tags=>['lineChart']);
	$self->{CNV}->createLine($x, $y + $height, $x + $width, $y + $height, -width=>2, -fill=>'white', tags=>['lineChart']);
	$self->{CNV}->createText($x - 4, $y + $height, -text=>$self->{DEF}->{range}->{min}, -font=>'{Arial Bold} 9', -fill=>'white', anchor=>'e', tags=>['lineChart']);
	
	return if (!defined($self->{DATA}));
	
	my $cnt = 0;
	foreach(keys(%{$self->{DATA}}))
	{
		my $series = $_;
		my @data = @{$self->{DATA}->{$series}};
		next if (scalar @data <= 1);
		
		#TODO factor in below zero base level
		#TODO labels
		my $incrX = $width / (@data - 1);
		my $sx = $x;
		my $sy = $y + (((1-($data[0]{VALUE} / $self->{DEF}->{range}->{max})) * $height) * $multiplier);
		$self->{CNV}->createText($x + $width + 10, $y + (16 * $cnt), -text=>$series, -font=>'{Arial Bold} 10', -fill=>$data[0]{COLOUR}, anchor=>'nw', tags=>['lineChart']);
		
		for(my $i = 1 ; $i < @data ; $i++)
		{
			my $nx = $sx + $incrX;
			my $ny = $y + (((1-($data[$i]{VALUE} / $self->{DEF}->{range}->{max})) * $height) * $multiplier);
			$self->{CNV}->createLine($sx, $sy, $nx, $ny, -width=>2, -fill=>$data[$i]{COLOUR}, tags=>['lineChart']);
			$sx = $nx;
			$sy = $ny;
		}
		$cnt++;
	}
}

sub update
{
	my $self = shift;
	my $data = shift;
	my %gridData;
	my $limitResults = 9999999;
	$limitResults = $self->{DEF}->{resultLimit} if (defined($self->{DEF}->{resultLimit}));

	foreach(@{$self->{DEF}->{data}->{series}})
	{
		$gridData{$_->{legend}} = [];
	}

	my $cnt = 0;
	foreach(reverse @$data)
	{
		my $dataItem = $_;
		last if ($cnt++ > $limitResults);
		
		foreach(@{$self->{DEF}->{data}->{series}})
		{
			my %d;
			$d{COLOUR} = $_->{colour};
			$d{VALUE} = Utils::checkModification($dataItem->{$_->{valueField}}, $_->{valueMod});
			push(@{$gridData{$_->{legend}}} , \%d);
		}	
	}

	$self->{DATA} = \%gridData;
	$self->{CNV}->delete('lineChart');
	_draw($self);
}

1;