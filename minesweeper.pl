use Tk;
use Tk::DialogBox;
use strict;

our $sizex = 20;
our $sizey = 15;
our $mines = 30;
our $uncovered = 0;
our $marked = 0;

my @area;


_populateArea(\@area);


my $mw = MainWindow->new(-background=>'black');
foreach my $y (0..($sizey-1)){
	foreach my $x (0..($sizex-1)){
		my $gridSq = $mw->Label(-text=>' ', -height=>1, -width=>2, -background=>'gray')->grid(-column=>$x, -row=>$y, -pady=>1, -padx=>1,-ipady=>1, -ipadx=>1);
		$mw->bind($gridSq, '<Button-1>', [\&select, \$mw, \$gridSq, \@area, $y, $x]);
		$mw->bind($gridSq, '<Button-3>', [\&mark, \$mw, \$gridSq, \@area,]);
	}
}

MainLoop;


sub _populateArea
{
my $area = shift;
$uncovered = 0;
$marked = 0;
foreach (0..($sizey-1)){
	@{$$area[$_]} = (' ') x $sizex;
}

foreach (1..$mines){
	my $x = int(rand($sizex-0.01));
	my $y = int(rand($sizey-0.01));
	while ($$area[$y][$x] eq 'M'){
		$x = int(rand($sizex-0.01));
		$y = int(rand($sizey-0.01));
	}
	$$area[$y][$x] = 'M'; #mine
	
	$$area[$y-1][$x-1]++ if ($x>0 && $y>0 && $$area[$y-1][$x-1] ne 'M');
	$$area[$y][$x-1]++ if ($x>0 && $$area[$y][$x-1] ne 'M');
	$$area[$y+1][$x-1]++ if ($y<$sizey-1 && $x>0 && $$area[$y+1][$x-1] ne 'M');
	$$area[$y-1][$x]++ if ($y>0 && $$area[$y-1][$x] ne 'M');
	$$area[$y+1][$x]++ if ($y<$sizey-1 && $$area[$y+1][$x] ne 'M');
	$$area[$y-1][$x+1]++ if ($y>0 && $x<$sizex-1 && $$area[$y-1][$x+1] ne 'M');
	$$area[$y][$x+1]++ if ($x<$sizex-1 && $$area[$y][$x+1] ne 'M');
	$$area[$y+1][$x+1]++ if ($x<$sizex-1 && $y<$sizey-1 && $$area[$y+1][$x+1] ne 'M');
}

#print join(", ",@{$_})."\n" foreach (@$area);
}

sub select
{
	shift;
	my $w = shift;
	my $label = shift;
	my $area = shift;
	my $y = shift;
	my $x = shift;
	$$label->configure(-text=>$$area[$y][$x]);
	if ($$area[$y][$x] eq 'M'){
		_reveal($area, $w);
		_endDialog($w,$area,"Loser!","BOOM!!!");

	}else{
		$uncovered++;
		$$label->configure(-background=>'white');
		if ($uncovered == ($sizex*$sizey)-$mines && $marked==$mines){
			_endDialog($w,$area,"Winner!","Winner!");
		}
	}
	
}


sub _endDialog
{
	my $w = shift;
	my $area = shift;
	my $title = shift;
	my $message = shift;
	my $dialog = $$w->DialogBox(-title=>$title, -buttons=>['Again','Exit']);
	$dialog->add('Label', -text=>$message, -font=>'{Arial Bold} 14')->pack;
	my $result = $dialog->Show;
	if ($result eq 'Again'){
		#reset
		foreach (@{$$w->gridSlaves()}){
			$_->configure(-background=>'gray');
			$_->configure(-text=>' ');
		}
		_populateArea($area);
	}else{
		$$w->destroy;
	}
}

sub _reveal
{
	my $area = shift;
	my $w = shift;
	foreach my $y (0..($sizey-1)){
		foreach my $x (0..($sizex-1)){
			my $l = ${$$w->gridSlaves(-column=>$x, -row=>$y)}[0];
			$l->configure(-text=>$$area[$y][$x]);
			 if ($l->cget(-background) eq 'orange'){
			 	$l->configure(-background=>'green');
			 }elsif ($$area[$y][$x] eq 'M'){
			 	$l->configure(-background=>'red');
			 }
			 
		}
	}
}

sub mark
{
	shift;
	my $w = shift;
	my $label = shift;
	my $area = shift;
	if ($$label->cget(-background) eq 'gray'){
		$$label->configure(-background=>'orange');
		$marked++;
		if ($uncovered == ($sizex*$sizey)-$mines && $marked==$mines){
			_endDialog($w,$area,"Winner!","Winner!");
		}
	}elsif ($$label->cget(-background) eq 'orange'){
		$$label->configure(-background=>'gray');
		$marked--;
	}
}