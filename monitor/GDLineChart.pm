package GDLineChart;

use MonitorItem;
use Utils;
use GD;
use GD::Graph::lines;
use Math::Trig;
use strict;
use Tk;
use Tk::PNG;
use MIME::Base64;

our @ISA = qw(MonitorItem);

sub new
{
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{DATA} = undef;
	$self->{LEGEND} = undef;
	_draw($self);
	bless ($self, $class);
	return $self;
}

sub _draw
{
	my $self = shift;
	my ($x, $y, $height, $width) = $self->getLocation();
	
	return if ($width < 1 || $height < 1);
	
	my $graph = GD::Graph::lines->new($width, $height);
	$graph->set( 
      x_label           => $self->getDefinition('axes')->{xlabel},
      x_long_ticks    	=> 1,
      y_label           => $self->getDefinition('axes')->{ylabel},
      title             => $self->getDefinition('title'),
      y_max_value       => $self->getDefinition('range')->{max},
      y_min_value       => $self->getDefinition('range')->{min},
      y_tick_number     => 5,
      y_long_ticks    	=> 1,
      y_label_skip      => 1,
      bgclr				=> 'black',
      fgclr				=> 'gray',
      textclr			=> 'white',
      labelclr			=> 'white',
      axislabelclr		=> 'white',
      legendclr			=> 'white',
      line_width		=> 2
  	);
  	
  	$graph->set_legend(@{$self->{LEGEND}});
  	$graph->set_x_axis_font(Utils::getFontFolder()."arial.ttf", 9);
  	$graph->set_x_label_font(Utils::getFontFolder()."arial.ttf", 12);
  	$graph->set_y_axis_font(Utils::getFontFolder()."arial.ttf", 9);
  	$graph->set_y_label_font(Utils::getFontFolder()."arial.ttf", 12);
  	$graph->set_title_font(Utils::getFontFolder()."arialbd.ttf", 12);
  	$graph->set_legend_font(Utils::getFontFolder()."arial.ttf", 9);
	
	my $im = $graph->plot($self->{DATA});
	
	$self->{MW}->Photo($self->getId(), -format => 'png', -data => encode_base64($im->png));	
	$self->{CNV}->createImage($x, $y, -image=>$self->getId(), -anchor=>'nw', tags=>[$self->getId()]);
}

sub update
{
	my $self = shift;
	my $data = shift;
	my @gridData;
	my $limitResults = 9999999;
	$limitResults = $self->getDefinition('resultLimit') if ($self->getDefinition('resultLimit') > 0);
	
	for(0..@{$self->getDefinition('data')->{series}})
	{
		$gridData[$_] = [];
	}
	
	my $results = 0;
	$self->{LEGEND} = [];
	foreach(reverse @$data)
	{
		my $dataItem = $_;
		last if ($results++ > $limitResults);
		
		my $cnt = 1;
		foreach(@{$self->getDefinition('data')->{series}})
		{
			if ($cnt == 1)
			{
				push($gridData[0], Utils::checkModification($dataItem->{$self->getDefinition('labelField')}, $self->getDefinition('labelMod')));
			}
			push($gridData[$cnt], Utils::checkModification($dataItem->{$_->{valueField}}, $_->{valueMod}));

  			push(@{$self->{LEGEND}}, $_->{legend});

			$cnt++;
		}	
	}
	$self->{DATA} = \@gridData;
	$self->clear();
	_draw($self);
}

1;