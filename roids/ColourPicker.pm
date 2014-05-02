package ColourPicker;
use lib '..\perllib';
use strict;
use GamesLib;
use Tk;

sub new{

	my $self={};
	shift;
	my $mw = shift;
	$self->{MW} = $mw;
	my $cnv = $$mw->Canvas(-height=>400, -width=>350)->pack();
	$self->{CNV} = \$cnv;
	$self->{AC} = 0;
	$self->{COLOUR} = '#ff0000';
	
	$cnv->createText(75,350, -text=>'R'); 
	$cnv->createText(175,350, -text=>'G');
	$cnv->createText(275,350, -text=>'B'); 
	
	$cnv->createRectangle(50, 80, 100, 340, -tags=>'r');
	$cnv->createRectangle(150, 80, 200, 340, -tags=>'g');
	$cnv->createRectangle(250, 80, 300, 340, -tags=>'b');
	
	$cnv->createRectangle(51, 84, 99, 339, -fill=>'red', -outline=>'red', -tags=>'red');
	$cnv->createRectangle(151, 339, 199, 339, -fill=>'green', -outline=>'green', -tags=>'green');
	$cnv->createRectangle(251, 339, 299, 339, -fill=>'blue', -outline=>'blue', -tags=>'blue');
	
	$cnv->createRectangle(50, 360, 300, 380, -fill=>'red', -outline=>'black', -tags=>'colour');
	
	bless $self;
	$$mw->bind('<Motion>', sub{motionhandler($self);});
	$$mw->bind('<ButtonPress-1>', sub{pickcolour($self);});
	$$mw->bind('<ButtonRelease-1>', sub{stop($self);});
	return $self;


}

sub getColour
{
	my $self=shift;
	my $cnv=$self->{CNV};
	my ($x, $y, $x1, $y1) = $$cnv->coords('red');
	my $r = $y1-$y;
	($x, $y, $x1, $y1) = $$cnv->coords('green');
	my $g = $y1-$y;
	($x, $y, $x1, $y1) = $$cnv->coords('blue');
	my $b = $y1-$y;
	
	return "#".dec2hex($r).dec2hex($g).dec2hex($b);
}


sub motionhandler{
	my $self=shift;
	my $cnv=$self->{CNV};
	my $mw=$self->{MW};
	if ($self->{AC} > 0){
		my $colour = 'red';
		if ($self->{AC} == 2){
			$colour = 'green';
		}elsif($self->{AC} == 3) {
			$colour = 'blue';
		}
		my $yloc = ($$mw->pointery)-($$cnv->rooty);
		my ($x, $y, $x1, $y1) = $$cnv->coords($colour);
		#print "$x, $y, $x1, $y1\n";
		$yloc = $y1-255 if ($yloc < $y1-255);
		$yloc = $y1 if ($yloc > $y1);
		$$cnv->coords($colour, $x, $yloc, $x1, $y1);
		$self->{COLOUR} = getColour($self);
		$$cnv->itemconfigure('colour', -fill=>$self->{COLOUR});
		$$mw->update;
	}

}


sub pickcolour{
	my $self=shift;
	my $cnv=$self->{CNV};
	my $mw=$self->{MW};
	my $xloc = ($$mw->pointerx)-($$cnv->rootx);
	my $yloc = ($$mw->pointery)-($$cnv->rooty);
	my ($x, $y, $x1, $y1) = $$cnv->coords('r');
	$self->{AC} = 1 if ($xloc > $x && $xloc < $x1 && $yloc > $y && $yloc < $y1);
	($x, $y, $x1, $y1) = $$cnv->coords('g');
	$self->{AC} = 2 if ($xloc > $x && $xloc < $x1 && $yloc > $y && $yloc < $y1);
	($x, $y, $x1, $y1) = $$cnv->coords('b');
	$self->{AC} = 3 if ($xloc > $x && $xloc < $x1 && $yloc > $y && $yloc < $y1);
	
}

sub stop{
	my $self=shift;
	$self->{AC} = 0;
}



1;