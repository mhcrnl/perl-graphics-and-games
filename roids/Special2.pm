package Special2;

use strict;

sub new
{
	my $self = {};
	shift;
	$self->{TYPE} = shift;
	$self->{DISPLAYFUNC} = shift;
	$self->{WHILEDISPLAYINGFUNC} = shift;
	$self->{STARTEFFECTFUNC} = shift;
	$self->{ENDEFFECTFUNC} = shift;	
	$self->{LABEL} = shift;
	$self->{TICKTIME} = shift;
	$self->{LIFE} = shift;
	$self->{TICKSINUSE} = 0;
	if ($self->{LIFE} == 0){
		$self->{LIFE} = 20;
	}
	bless $self;
	return $self;
}

sub display
{
	my $self = shift;
	&{$self->{DISPLAYFUNC}};
}

sub whileDisplaying
{
	my $self = shift;
	&{$self->{WHILEDISPLAYINGFUNC}};
}

sub start
{
	my $self = shift;
	&{$self->{STARTEFFECTFUNC}};
	$self->{TICKSINUSE} = 0;
}

sub end
{
	my $self = shift;
	&{$self->{ENDEFFECTFUNC}};
}

sub resetTimer
{
	my $self = shift;
	$self->{TICKSINUSE} = 0;
}

sub tick
{
	my $self = shift;
	$self->{TICKSINUSE}++;
}

sub hasExpired
{
	my $self = shift;
	
	return 1 if ($self->{TICKTIME} * $self->{TICKSINUSE} > $self->{LIFE});
	
	return 0;
}

sub timeLeft
{
	my $self = shift;
	
	return sprintf "%.2f", $self->{LIFE} - ($self->{TICKTIME} * $self->{TICKSINUSE});
}

return 1;