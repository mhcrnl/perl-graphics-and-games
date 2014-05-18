package Special;

use strict;

my $activeLife = 20;

sub new
{
	my $self = {};
	shift;
	$self->{ID} = shift;
	$self->{STARTTIME} = shift;
	$self->{PAUSETIME} = 0;
	bless $self;
	return $self;
}

sub hasExpired
{
	my $self = shift;
	
	return 1 if (time() - $self->{STARTTIME} > $activeLife);
	
	return 0
}

sub timeLeft
{
	my $self = shift;
	
	return $activeLife - (time() - $self->{STARTTIME});
}

return 1;