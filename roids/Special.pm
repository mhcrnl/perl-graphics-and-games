package Special;

use strict;

=head1 NAME

Special 

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

Data store for special pickups

=head1 METHODS

The following methods are available:

=over 4

=item Special->new($id, $label, $ticktime, [$life])

Create a new special object:
$id = Key of special
$label = Text to display for the special
$ticktime = Length of each game tick in seconds 
$life = How long the special lasts in seconds

=cut

sub new
{
	my $self = {};
	shift;
	$self->{ID} = shift;	
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

=item $special->tick

Increment the tick counter

=cut

sub tick
{
	my $self = shift;
	$self->{TICKSINUSE}++;
}

=item $roid3d->offScreen($xlimit, $ylimit)

Returns true if special has been active longer than it's life

=cut

sub hasExpired
{
	my $self = shift;
	
	return 1 if ($self->{TICKTIME} * $self->{TICKSINUSE} > $self->{LIFE});
	
	return 0;
}

=item $roid3d->offScreen($xlimit, $ylimit)

Returns time left in seconds until the special ends

=cut

sub timeLeft
{
	my $self = shift;
	
	return sprintf "%.2f", $self->{LIFE} - ($self->{TICKTIME} * $self->{TICKSINUSE});
}

return 1;

=back