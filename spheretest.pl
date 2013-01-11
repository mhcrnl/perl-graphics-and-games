use lib 'perllib';
use Sphere;
use Cuboid;
use ThreeDCubesTest;
use Tk;
use GamesLib;
use Math::Trig;
use strict;

#bounces a ball around the screen in 3 dimensions with lighting
my $radius=80;
my $mw = MainWindow->new();
$mw->bind('<Return>'=>[\&go]);
our $screenx = 500;
our $screeny = 500;
our $screenz = 800;
my $cnv = $mw->Canvas(-width=>$screenx, -height=>$screeny)->pack();
my @focuspoint = (0); #length less than 3 should use default
our @lightsource = (250, 400, 300);

our $dist_light_right_wall = $screenx - $lightsource[0];
our $dist_light_left_wall = $lightsource[0];
our $dist_light_top_wall = $lightsource[1];
our $dist_light_bottom_wall = $screeny - $lightsource[1];
our $dist_light_rear_wall = $screenz - $lightsource[2];
our $dist_light_view_wall = $lightsource[2];

$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
our $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource);

my $sy = $screeny/20;
my $sz = $screenz/20;
my $rside; #build right wall
foreach my $a (0..9){
for (my $b = 20 ; $b-- ;){
$rside = Cuboid->new();
$rside->setDimensions(1,$sy,$sz);
$tdc->registerObject($rside,\@focuspoint,'#9999FF',$screenx,$sy*$a,$sz*$b);
}
}
for (my $a = 19 ; $a>9 ;$a--){
for (my $b = 20 ; $b-- ;){
$rside = Cuboid->new();
$rside->setDimensions(1,$sy,$sz);
$tdc->registerObject($rside,\@focuspoint,'#9999FF',$screenx,$sy*$a,$sz*$b);
}
}
my $lside; #build left wall
foreach my $a (0..9){
for (my $b = 20 ; $b-- ;){
$lside = Cuboid->new();
$lside->setDimensions(1,$sy,$sz);
$tdc->registerObject($lside,\@focuspoint,'#9999FF',0,$sy*$a,$sz*$b);
}
}
for (my $a = 19 ; $a>9 ;$a--){
for (my $b = 20 ; $b-- ;){
$lside = Cuboid->new();
$lside->setDimensions(1,$sy,$sz);
$tdc->registerObject($lside,\@focuspoint,'#9999FF',0,$sy*$a,$sz*$b);
}
}

my $top = Cuboid->new();
$top->setDimensions($screenx,1,$screenz);
$tdc->registerObject($top,\@focuspoint,'#99FF99',0,0,0);


#our $shadow = CanvasObject->new();
#my @temp;
#$temp[0] = [0,0,0];
#$temp[1] = [0,0,0];
#$temp[2] = [0,0,0];
#$temp[3] = [0,0,0];
#$temp[4] = [0,0,0];
#$temp[5] = [0,0,0];
#$temp[6] = [0,0,0];
#$temp[7] = [0,0,0];
#$temp[8] = [0,0,0];
#
#my @fv = ();
#$fv[0][0] = 0;
#$fv[0][1] = 2;
#$fv[0][2] = 1;
#$fv[0][3] = 0;
#
#$fv[1][0] = 0;
#$fv[1][1] = 3;
#$fv[1][2] = 2;
#$fv[1][3] = 1;
#
#$fv[2][0] = 0;
#$fv[2][1] = 4;
#$fv[2][2] = 3;
#$fv[2][3] = 2;
#
#$fv[3][0] = 0;
#$fv[3][1] = 5;
#$fv[3][2] = 4;
#$fv[3][3] = 3;
#
#$fv[4][0] = 0;
#$fv[4][1] = 6;
#$fv[4][2] = 5;
#$fv[4][3] = 4;
#
#$fv[5][0] = 0;
#$fv[5][1] = 7;
#$fv[5][2] = 6;
#$fv[5][3] = 5;
#
#$fv[6][0] = 0;
#$fv[6][1] = 8;
#$fv[6][2] = 7;
#$fv[6][3] = 6;
#
#$fv[7][0] = 0;
#$fv[7][1] = 1;
#$fv[7][2] = 8;
#$fv[7][3] = 7;
#	
#@{$shadow->{VERTEXLIST}}=@temp;
#@{$shadow->{FACETVERTICES}}=@fv;

our @spheres = ();
my $temp = Sphere->new($radius);
my $shadow = Cuboid->new();
$shadow->setDimensions(20,20,1);
$spheres[0] = [$temp,$tdc->registerObject($temp,\@focuspoint,'red',0,20,0),6,3,5,$shadow,$tdc->registerObject($shadow,\@focuspoint,'#000000',0,0,1000)];
$temp = Sphere->new($radius);
$shadow = Cuboid->new();
$shadow->setDimensions(20,20,1);
$spheres[1] = [$temp,$tdc->registerObject($temp,\@focuspoint,'yellow',300,300,400),5,4,5,$shadow,$tdc->registerObject($shadow,\@focuspoint,'#000000',0,0,1000)];

#sphere sub array 0=Sphere Object, 1= Sphere ID in 3dcubes, 2= x vector, 3=y vector, 4=z vector, 5=shadow object, 6=Shadow ID in 3dcubes

MainLoop;

sub go
{

#$tdc->rotate($spheres[1][1],'x',90,90,1);

my @redrawList = ();
while(1){
	for (my $i = 0 ; $i < @spheres ; $i++){
		my $centre = $spheres[$i][0]->getCentre();
		if($spheres[$i][2]>0 && $$centre[0]>($screenx-$spheres[$i][0]->{RADIUS})){
			$spheres[$i][2]=$spheres[$i][2]*-1;
		}elsif($spheres[$i][2]<0 && $$centre[0]<$spheres[$i][0]->{RADIUS}){
			$spheres[$i][2]=$spheres[$i][2]*-1;
		}
		
		if($spheres[$i][3]>0 && $$centre[1]>($screeny-$spheres[$i][0]->{RADIUS})){
			$spheres[$i][3]=$spheres[$i][3]*-1;
		}elsif($spheres[$i][3]<0 && $$centre[1]<$spheres[$i][0]->{RADIUS}){
			$spheres[$i][3]=$spheres[$i][3]*-1;
		}
		if($spheres[$i][4]>0 && $$centre[2]>($screenz-$spheres[$i][0]->{RADIUS})){
			$spheres[$i][4]=$spheres[$i][4]*-1;
		}elsif($spheres[$i][4]<0 && $$centre[2]<$spheres[$i][0]->{RADIUS}+5){
			$spheres[$i][4]=$spheres[$i][4]*-1;
		}	
		$tdc->translate($spheres[$i][1],$spheres[$i][2],$spheres[$i][3],$spheres[$i][4],1);
		_shadow($i);
		#_shadowMK2($i);
	}
	my @temp = sort{_sort_func($a,$b)} @spheres;
	@spheres = @temp;
	#sphere and shadow translation have no update flags so that the can be updated at the same time
	#saves on processing (as both always move)	

	@redrawList = ();
	for (my $i = 0 ; $i < @spheres ; $i++){
		push (@redrawList,$spheres[$i][6]);
	}
	for (my $i = 0 ; $i < @spheres ; $i++){
		push (@redrawList,$spheres[$i][1]);
	}
	$tdc->redraw(\@redrawList,0); #mode 0 redraw, deletes and redraws object, instead of moving points, this usually sorts out z naughtiness
	select (undef, undef, undef, 0.01);
	
}
}


sub _sort_func
{
	my $a = shift;
	my $b = shift;
	my $ac = $$a[0]->getCentre();
	my $bc = $$b[0]->getCentre();
	return ($$bc[2] <=> $$ac[2]);
}


sub _shadow
{
my $index=shift;
#may move to 3D library if it works well enough - not general purpose enough - bit specific to this demo

#this will trace through the centre of the object so giving the centre of the shadow to start with.
my $centre = $spheres[$index][0]->getCentre();
my @lightvector = ($$centre[0] - $lightsource[0],$$centre[1]-$lightsource[1],$$centre[2]-$lightsource[2]);
_normalise(\@lightvector);

my $shadow_drawn = 0;


#this currently assumes lightsource is within wall boundary.
if ($lightvector[0] > 0 || $lightvector[0] < 0){
	my $ratio = $dist_light_right_wall / $lightvector[0];
	$ratio=($dist_light_left_wall / $lightvector[0])*-1 if ($lightvector[0]< 0);
	my $shadow_y = $lightsource[1] +($lightvector[1] * $ratio);
	my $shadow_z = $lightsource[2] +($lightvector[2] * $ratio);
	if ($shadow_y > 0 && $shadow_y < $screeny && $shadow_z > 0 && $shadow_z < $screenz){
		#draw shadow on right wall
		_draw_shadow($index,$screenx,$shadow_y,$shadow_z) if ($lightvector[0] > 0);
		#draw shadow on left wall
		_draw_shadow($index,0,$shadow_y,$shadow_z) if ($lightvector[0] < 0);
		$shadow_drawn = 1;
	}
	
}
if ($shadow_drawn == 0 && $lightvector[2] > 0){
	my $ratio = ($dist_light_rear_wall / $lightvector[2]);
	my $shadow_y = $lightsource[1] +($lightvector[1] * $ratio);
	my $shadow_x = $lightsource[0] +($lightvector[0] * $ratio);
	if ($shadow_y > 0 && $shadow_y < $screeny && $shadow_x > 0 && $shadow_x < $screenx){
		#draw shadow on back wall
		_draw_shadow($index,$shadow_x,$shadow_y,$screenz);
		$shadow_drawn = 1;
	}
	
}
if ($shadow_drawn == 0 && ($lightvector[1] < 0 || $lightvector[1]> 0)){
	my $ratio = ($dist_light_bottom_wall / $lightvector[1]);
	$ratio=($dist_light_top_wall / $lightvector[1])*-1 if ($lightvector[1]< 0);
	my $shadow_z = $lightsource[2] +($lightvector[2] * $ratio);
	my $shadow_x = $lightsource[0] +($lightvector[0] * $ratio);
	if ($shadow_z > 0 && $shadow_z < $screenz && $shadow_x > 0 && $shadow_x < $screenx){
		#draw shadow on ceiling
		_draw_shadow($index,$shadow_x,0,$shadow_z) if ($lightvector[1]< 0);
		#draw shadow on floor
		_draw_shadow($index,$shadow_x,$screeny,$shadow_z) if ($lightvector[1]> 0);
		$shadow_drawn = 1;
	}
	
}

if ($shadow_drawn == 0)
{
	#it's in the plane of the camera, move it out of the way
	_draw_shadow($index,0,0,-100);
}

}




sub _shadowMK2
{
	my $index=shift;

	
	#attempt to trace lines around object
	my $centre = $spheres[$index][0]->getCentre();
	my @lightvector = ($$centre[0] - $lightsource[0],$$centre[1]-$lightsource[1],$$centre[2]-$lightsource[2]);
	_normalise(\@lightvector);
	
	my $xangle = -rad2deg(asin($lightvector[1]));
	my $yangle = rad2deg(asin($lightvector[0]));
	my $radius=$spheres[$index][0]->{RADIUS};
	my $fortyfive = $radius*sin(deg2rad(45));
	my @temp;
	$temp[0] = [0,0,0];
	$temp[1] = [$radius,0,0];
	$temp[2] = [$fortyfive,$fortyfive,0];
	$temp[3] = [0,$radius,0];
	$temp[4] = [-$fortyfive,$fortyfive,0];
	$temp[5] = [-$radius,0,0];
	$temp[6] = [-$fortyfive,-$fortyfive,0];
	$temp[7] = [0,-$radius,0];
	$temp[8] = [$fortyfive,-$fortyfive,0];
	
	my $tempobj = CanvasObject->new;
	@{$tempobj->{VERTEXLIST}}=@temp;
	$tempobj->rotate('x',$xangle,0,0);
	$tempobj->rotate('y',$yangle,0,0);
	#print "$xangle : $yangle\n";
	$tempobj->translate($$centre[0],$$centre[1],$$centre[2]);
	
	for (0..8)
	{
		my $point_set = 0;
		@lightvector = (${$tempobj->{VERTEXLIST}}[$_][0] - $lightsource[0],${$tempobj->{VERTEXLIST}}[$_][1]-$lightsource[1],${$tempobj->{VERTEXLIST}}[$_][2]-$lightsource[2]);
		_normalise(\@lightvector);
		if ($lightvector[0] > 0 || $lightvector[0] < 0){
			my $ratio = $dist_light_right_wall / $lightvector[0];
			$ratio=($dist_light_left_wall / $lightvector[0])*-1 if ($lightvector[0]< 0);
			my $shadow_y = $lightsource[1] +($lightvector[1] * $ratio);
			my $shadow_z = $lightsource[2] +($lightvector[2] * $ratio);
			if ($shadow_y > 0 && $shadow_y < $screeny && $shadow_z > 0 && $shadow_z < $screenz){
				${$tempobj->{VERTEXLIST}}[$_][0] = $screenx;
				${$tempobj->{VERTEXLIST}}[$_][1] = $shadow_y;
				${$tempobj->{VERTEXLIST}}[$_][2] = $shadow_z;
				if ($lightvector[0] < 0){	
					${$tempobj->{VERTEXLIST}}[$_][0] = 0;
				}
				$point_set = 1;
			}
			
		}
		if ($point_set == 0 && $lightvector[2] > 0){
			my $ratio = ($dist_light_rear_wall / $lightvector[2]);
			$ratio = ($dist_light_view_wall / $lightvector[2])*-1 if ($lightvector[2]< 0);
			my $shadow_y = $lightsource[1] +($lightvector[1] * $ratio);
			my $shadow_x = $lightsource[0] +($lightvector[0] * $ratio);
			if ($shadow_y > 0 && $shadow_y < $screeny && $shadow_x > 0 && $shadow_x < $screenx){
				${$tempobj->{VERTEXLIST}}[$_][0] = $shadow_x;
				${$tempobj->{VERTEXLIST}}[$_][1] = $shadow_y;
				${$tempobj->{VERTEXLIST}}[$_][2] = $screenz;
				if ($lightvector[2] < 0){	
				 ${$tempobj->{VERTEXLIST}}[$_][2] = -1;
				}
				$point_set = 1;
			}
	
		}
		if ($point_set == 0 && ($lightvector[1] < 0 || $lightvector[1]> 0)){
			my $ratio = ($dist_light_bottom_wall / $lightvector[1]);
			$ratio=($dist_light_top_wall / $lightvector[1])*-1 if ($lightvector[1]< 0);
			my $shadow_z = $lightsource[2] +($lightvector[2] * $ratio);
			my $shadow_x = $lightsource[0] +($lightvector[0] * $ratio);
			if ($shadow_z > 0 && $shadow_z < $screenz && $shadow_x > 0 && $shadow_x < $screenx){
				${$tempobj->{VERTEXLIST}}[$_][0] = $shadow_x;
				${$tempobj->{VERTEXLIST}}[$_][1] = $screeny;
				${$tempobj->{VERTEXLIST}}[$_][2] = $shadow_z;
				if ($lightvector[1] < 0){	
					${$tempobj->{VERTEXLIST}}[$_][1] = 0;
				}
				$point_set = 1;
			}
			
		}
		#if ($point_set == 0)
		#{
		#	#it's in the plane of the camera, move it out of the way
		#	${$tempobj->{VERTEXLIST}}[$_][0] = ${$tempobj->{VERTEXLIST}}[0][0];
		#	${$tempobj->{VERTEXLIST}}[$_][1] = ${$tempobj->{VERTEXLIST}}[0][1];
		#	${$tempobj->{VERTEXLIST}}[$_][2] = ${$tempobj->{VERTEXLIST}}[0][2];
		#}
	}
	@{$shadow->{VERTEXLIST}}=@{$tempobj->{VERTEXLIST}};
}




sub _draw_shadow
{
	my $index = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;
	#print "$x,$y,$z\n";
	my $centre = $spheres[$index][5]->getCentre();
	$tdc->translate($spheres[$index][6],$x - $$centre[0],$y - $$centre[1],$z - $$centre[2],1);
	
}