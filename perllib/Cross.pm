package Cross;
use CanvasObject;
use Cuboid;
use Tk;

@ISA = qw(CanvasObject);



sub new
{

	my $self=CanvasObject->new;
	shift;
	my $linelength = shift;
	my $linewidth = shift;
	my $depth = shift;
	my $armlength = ($linelength-$linewidth)/2;
	my $transx = $linelength/2;
	my $transy = $linewidth/2;
	my @vl;
	my @fv;
	my $cross;
	my $modifier = 0;
	my $fvmod = 0;
		$cross = Cuboid->new;
		$cross->setDimensions($armlength,$linewidth,$depth);
		$cross->translate(-$transx, -$transy, 0);
		$cross->rotate('z',45,0,0);
		@vl = @{$cross->{VERTEXLIST}};
		@fv = @{$cross->{FACETVERTICES}};
		$modifier = @vl;
		$fvmod = @fv;
		
		$cross = Cuboid->new;
		$cross->setDimensions($armlength,$linewidth,$depth);
		$cross->translate(-$transx, -$transy, 0);
		$cross->rotate('z',-45,0,0);		
		splice (@vl, @vl, 0, @{$cross->{VERTEXLIST}});
		splice (@fv, @fv, 0, @{$cross->{FACETVERTICES}});
		for (my $j = $fvmod ; $j < @fv ; $j++)
		{
			${$fv[$j]}[0]+=$modifier;
			${$fv[$j]}[1]+=$modifier;
			${$fv[$j]}[2]+=$modifier;
			${$fv[$j]}[3]+=$fvmod;
		}
		$modifier = @vl;
		$fvmod = @fv;
		
		$cross = Cuboid->new;
		$cross->setDimensions($armlength,$linewidth,$depth);
		$cross->translate(-$transx, -$transy, 0);
		$cross->rotate('z',135,0,0);		
		splice (@vl, @vl, 0, @{$cross->{VERTEXLIST}});
		splice (@fv, @fv, 0, @{$cross->{FACETVERTICES}});
		for (my $j = $fvmod ; $j < @fv ; $j++)
		{
			${$fv[$j]}[0]+=$modifier;
			${$fv[$j]}[1]+=$modifier;
			${$fv[$j]}[2]+=$modifier;
			${$fv[$j]}[3]+=$fvmod;
		}
		$modifier = @vl;
		$fvmod = @fv;
		
		$cross = Cuboid->new;
		$cross->setDimensions($armlength,$linewidth,$depth);
		$cross->translate(-$transx, -$transy, 0);
		$cross->rotate('z',-135,0,0);		
		splice (@vl, @vl, 0, @{$cross->{VERTEXLIST}});
		splice (@fv, @fv, 0, @{$cross->{FACETVERTICES}});
		for (my $j = $fvmod ; $j < @fv ; $j++)
		{
			${$fv[$j]}[0]+=$modifier;
			${$fv[$j]}[1]+=$modifier;
			${$fv[$j]}[2]+=$modifier;
			${$fv[$j]}[3]+=$fvmod;
		}
		
		$modifier = @vl;
		$fvmod = @fv;
		
		$cross = Cuboid->new;
		$cross->setDimensions($linewidth,$linewidth,$depth);
		$cross->translate(-$transy, -$transy, 0);
		$cross->rotate('z',45,0,0);		
		splice (@vl, @vl, 0, @{$cross->{VERTEXLIST}});
		splice (@fv, @fv, 0, @{$cross->{FACETVERTICES}});
		for (my $j = $fvmod ; $j < @fv ; $j++)
		{
			${$fv[$j]}[0]+=$modifier;
			${$fv[$j]}[1]+=$modifier;
			${$fv[$j]}[2]+=$modifier;
			${$fv[$j]}[3]+=$fvmod;
		}
		
	
	$cross = undef;

	   	
	$self->{VERTEXLIST}=\@vl;
	$self->{FACETVERTICES}=\@fv;
	$self->{SORT} = 1;
	bless $self;
	return $self;
}