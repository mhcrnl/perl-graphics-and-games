package MonitorItem;

use Utils;

our $itemCount = 0;

=head1 NAME

MonitorItem

=head1 DESCRIPTION

Abstract class for monitor component items

=head1 METHODS

The following methods are available:

=over 7

=item B<$item-E<gt>new($xmlDefinition, $mainWindow, $canvas)>

Constructor, generates ID for this component

=cut

sub new{
	my $self={};
	my $class = shift;
	$self->{DEF} = shift;
	$self->{MW} = shift;
	$self->{CNV} = shift;
	$self->{ID} = $class.$itemCount++;
	bless ($self, $class);
	return $self;
}

=item B<$item-E<gt>getLocation())>

Gets standard location information from the items XML definition

=cut

sub getLocation
{
	my $self = shift;
	my $x = defined($self->{DEF}->{location}->{x}) ? $self->getSize('w', 'location', 'x') : 0;
	my $y = defined($self->{DEF}->{location}->{y}) ? $self->getSize('h', 'location', 'y')  : 0;
	my $height = defined($self->{DEF}->{height}) ? $self->getSize('h', 'height')  : 0;
	my $width = defined($self->{DEF}->{width}) ? $self->getSize('w', 'width')  : 0;
	return ($x, $y, $height, $width);
}

=item B<$item-E<gt>update(\@data))>

Must be implemented by the an inheriting class, method will be used to update how the component appears on screen

=cut

sub update
{
	my $self = shift;
	print ref($self).": update not implemented\n";
}

=item B<$item-E<gt>getDefinition(@keys))>

Retrieve an item from the defintion XML, @keys is the list of nodes under which the item is located (under the component node in the source XML)

=cut

sub getDefinition
{
	#my $self = shift;
	#my $name = shift;
	#return "" if (!defined($self->{DEF}->{$name}));
	#return (defined($self->{DEF}->{$name})) ? $self->{DEF}->{$name} : "";
	my ($self, @keys) = @_;
	return _getDefinition($self->{DEF}, @keys);
}

=item B<$item-E<gt>getSize($direction, @keys))>

Helper function for calculating size values, especially if they have been defined as a percentage
$direction can be 'h' (height) or 'w' (width)
@keys is the list of nodes under which the item is located (under the component node in the source XML)

=cut

sub getSize
{
	my ($self, $direction, @key) = @_;
	my $val = $self->getDefinition(@key);
	if ($val =~ m/^(\d+)\%$/ && defined($self->{CNV}))
	{
		$val = ($self->{CNV}->Width / 100) * $1 if ($direction eq "w");
		$val = ($self->{CNV}->Height / 100) * $1 if ($direction eq "h");
	}

	return $val;
}

=item B<$item-E<gt>clear())>

Remove all items from the canvas associated with this component

=cut

sub clear
{
	my $self = shift;
	$self->{CNV}->delete($self->getId());
}

=item B<$item-E<gt>getId())>

Retrieve the ID that has been generated for this component

=cut

sub getId
{
	my $self = shift;
	return $self->{ID};
}

#Recursive method used by getDefinition to retrieve an xml defintion item
sub _getDefinition
{
	my ($hashref, @keys) = @_;
	return "" if (scalar @keys == 0);
	
	my $key = shift(@keys);
	return "" if (ref($hashref) ne "HASH");
	return "" if (!defined($hashref->{$key}));
	return $hashref->{$key} if (scalar @keys == 0);
	return _getDefinition($hashref->{$key}, @keys);
	
}

1;
=back