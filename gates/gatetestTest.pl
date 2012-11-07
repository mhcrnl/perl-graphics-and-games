use lib '..\perllib';
use ThreeDCubesTest;
use Gate;
use Bullet3D;
use Tk;
use strict;
use Math::Trig;
use CanvasObject;
use GamesLib;
use Cuboid;

$|=1;
my $mw = MainWindow->new();
$mw->OnDestroy([\&endit]);
$mw->resizable(0,0);
my $menuframe = $mw->Frame(-borderwidth=>2, -background=>'brown')->pack(-side=>'top', -fill=>'x');
my $toolmenu = $menuframe->Menubutton(-text=>'Help', -relief=>'raised')->pack(-side=>'left');
$toolmenu->command(-label=>'Instructions',-command=>[\&dispInstructions]);
$mw->bind($toolmenu,'<Enter>', sub{$toolmenu->configure(-relief=>'sunken');});
$mw->bind($toolmenu,'<Leave>', sub{$toolmenu->configure(-relief=>'raised');});


my $cnv = $mw->Canvas(-width=>500, -height=>500, -background=>'black')->pack();
my @focuspoint = (0); #length less than 3 should use default, not required with fov anyway.
my @lightsource = (225, 225, -500);
#my @lightsource = (); #lightsource will be the camera so wherever we are facing is well lit - does show up triangles at close range as polygon mode can't goraud shade

$mw->update; #needed for $canvas->Height to work , could even put up a loading panel while the 3d stuff is underway
my $tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource, 80); #will use fov perspective method, viewing angle is 80 degrees

$tdc->setLightsourceMoveWithCam(1); #light moves with camera, but isn't the camera itself, this way we don't see the triangles so much

#may need to update tdc to draw furthest items first (similar to what is done with triangles in an object)
#am handling draw order from this script
my $posy = int($mw->screenheight()/2 -300);
my $posx = int($mw->screenwidth()/2 -200);
$mw->geometry("+$posx+$posy");


$mw->bind('<Return>'=>[\&go]);
$mw->bind('<d>'=>[\&dkeydown]);
$mw->bind('<KeyRelease-d>'=>[\&dkeyup]);
$mw->bind('<a>'=>[\&akeydown]);
$mw->bind('<KeyRelease-a>'=>[\&akeyup]);
$mw->bind('<w>'=>[\&wkeydown]);
$mw->bind('<KeyRelease-w>'=>[\&wkeyup]);
$mw->bind('<s>'=>[\&skeydown]);
$mw->bind('<KeyRelease-s>'=>[\&skeyup]);
$mw->bind('<space>'=>[\&firepress]);
$mw->bind('<q>'=>[\&qkeydown]);
$mw->bind('<KeyRelease-q>'=>[\&qkeyup]);
$mw->bind('<e>'=>[\&ekeydown]);
$mw->bind('<KeyRelease-e>'=>[\&ekeyup]);
$mw->bind('<j>'=>[\&jkeydown]);
$mw->bind('<KeyRelease-j>'=>[\&jkeyup]);
$mw->bind('<l>'=>[\&lkeydown]);
$mw->bind('<KeyRelease-l>'=>[\&lkeyup]);
$mw->bind('<i>'=>[\&ikeydown]);
$mw->bind('<KeyRelease-i>'=>[\&ikeyup]);
$mw->bind('<k>'=>[\&kkeydown]);
$mw->bind('<KeyRelease-k>'=>[\&kkeyup]);


$mw->bind('<D>'=>[\&dkeydown]);
$mw->bind('<KeyRelease-D>'=>[\&dkeyup]);
$mw->bind('<A>'=>[\&akeydown]);
$mw->bind('<KeyRelease-A>'=>[\&akeyup]);
$mw->bind('<W>'=>[\&wkeydown]);
$mw->bind('<KeyRelease-W>'=>[\&wkeyup]);
$mw->bind('<S>'=>[\&skeydown]);
$mw->bind('<Q>'=>[\&qkeydown]);
$mw->bind('<KeyRelease-Q>'=>[\&qkeyup]);
$mw->bind('<E>'=>[\&ekeydown]);
$mw->bind('<KeyRelease-E>'=>[\&ekeyup]);
$mw->bind('<KeyRelease-S>'=>[\&skeyup]);
$mw->bind('<J>'=>[\&jkeydown]);
$mw->bind('<KeyRelease-J>'=>[\&jkeyup]);
$mw->bind('<L>'=>[\&lkeydown]);
$mw->bind('<KeyRelease-L>'=>[\&lkeyup]);
$mw->bind('<I>'=>[\&ikeydown]);
$mw->bind('<KeyRelease-I>'=>[\&ikeyup]);
$mw->bind('<K>'=>[\&kkeydown]);
$mw->bind('<KeyRelease-K>'=>[\&kkeyup]);
$mw->bind('<FocusOut>'=>[\&focusOut]);
$mw->bind('<FocusIn>'=>[\&focusIn]);

our $movespeed = 5;
#our $movespeed = 0;
our @gate;
our @drawOrder;
our @targets;
our $nextGate = 0;
our $go = 0;
our $rotvert = 0;
our $rothoriz = 0;
our $roll = 0;
our $slide = 0;
our $raise = 0;
our $turnamount = 4;
our @bullets = ();
our $lastfire;
our %distances;
our $drawDistance = 1500;

#need someway to generate a (sane) course automatically
$gate[5]{'pos'} = [200,200,501];
$gate[5]{'angle'} = ['y',-60];
$gate[5]{'width'} = 50;
$gate[4]{'pos'} = [80,230,800];
$gate[4]{'angle'} = ['x',90];
$gate[4]{'width'} = 40;
$gate[3]{'pos'} = [250,200,1250];
$gate[3]{'angle'} = ['y',30];
$gate[3]{'width'} = 30;
$gate[2]{'pos'} = [300,70,1300]; #gate centre point
$gate[2]{'angle'} = ['x',40];
$gate[2]{'width'} = 30;

$gate[1]{'pos'} = [200,20,1800];
$gate[1]{'angle'} = ['x',0];
$gate[1]{'width'} = 25;
$gate[0]{'pos'} = [260,0,1800];
$gate[0]{'angle'} = ['x',0];
$gate[0]{'width'} = 25;
our $nextGate = @gate-1;


buildStarField();

$targets[0]{'pos'} = [220,100,300]; #this currently specifies top left corner of cube (1st vertex) might change that - most others are centre points - just cuboid is quite old
$targets[1]{'pos'} = [230,70,1360];
$targets[2]{'pos'} = [200,400,1800];
#$targets[3]{'pos'} = [400,200,0];
#$targets[4]{'pos'} = [0,200,0];


for (my $i = 0 ; $i < @targets ; $i++){
	$targets[$i]{'obj'} = Cuboid->new;
	$targets[$i]{'obj'}->setDimensions(40,40,40);
	$targets[$i]{'obj'}->setColour('magenta');
	$targets[$i]{'obj'}->translate($targets[$i]{'pos'}[0],$targets[$i]{'pos'}[1],$targets[$i]{'pos'}[2]);
	$targets[$i]{'id'} = ($targets[$i]{'pos'}[2] < 1200) ? $tdc->registerObject($targets[$i]{'obj'},\@focuspoint,'',0,0,0)  : -1;
	push(@drawOrder,$targets[$i]{'id'}) if($targets[$i]{'id'} > -1) ;
}

for (my $i = 0 ; $i < @gate ; $i++){
	$gate[$i]{'obj'} = Gate->new($gate[$i]{'width'},20,20);
	if ($i == @gate-1){$gate[$i]{'obj'}->setColour('green');}
	else{$gate[$i]{'obj'}->setColour('yellow');}
	$gate[$i]{'obj'}->rotate($gate[$i]{'angle'}[0], $gate[$i]{'angle'}[1]);
	$gate[$i]{'obj'}->translate($gate[$i]{'pos'}[0],$gate[$i]{'pos'}[1],$gate[$i]{'pos'}[2]); #translation done separately to register object, as it may be too far away to be registerd at this point, but still need to figure out where it is
	$gate[$i]{'id'} = ($gate[$i]{'pos'}[2] < 1200) ? $tdc->registerObject($gate[$i]{'obj'},\@focuspoint,'',0,0,0) : -1;
	push(@drawOrder,$gate[$i]{'id'}) if($gate[$i]{'id'} > -1) ;
}
$mw->update;
$mw->focusForce;

MainLoop;


sub dispInstructions
{
	my $class = 'Side Instructions';
	#if (_checkChildren($class)){
		my $w=$mw->Toplevel(-class=>$class);
		my $g = "450x400+100+100";
		$w->geometry($g);
		$w->resizable(0,0);
		my @lines;
		push(@lines,'');
		push(@lines,"Return\t - Start/Pause");
		push(@lines,"W\t - Pitch Down");
		push(@lines,"S\t - Pitch Up");
		push(@lines,"A\t - Turn Left");
		push(@lines,"D\t - Turn Right");
		push(@lines,'');
		push(@lines,"I\t - Raise");
		push(@lines,"K\t - Lower");
		push(@lines,"J\t - Slide Left");
		push(@lines,"L\t - Slide Right");
		push(@lines,'');
		push(@lines,"Space\t - Fire");
		push(@lines,'');
		push(@lines,'Complete the ring course and hit targets along the way');
		push(@lines,'');
		push(@lines,'When used as the roids side game you will be awarded a power up crystal for hitting all targets');
		push(@lines,'Hitting a gate will result in a penalty effect');
		

		my $sf = $w->Scrolled('Canvas', -width=>450, -height =>400, -highlightbackground=>'black', -background=>'#E7FFC2', -scrollbars=>'e')->pack(-side=>'left');
		
		my $y = 5;
		foreach (@lines)
		{
			$sf->createText(5,$y, -text=>$_, -anchor=>'w');
			$y+=15;
		}
		$y+=20;
		$sf->configure(-scrollregion=>"0 0 450 $y");
	#}
}


sub focusIn
{
	if ($go == -2){
		$go = 0;
		go();
	}
}

sub focusOut
{
	#pause if game playing
	if ($go == 1){
		go();
		$go = -2;
	}
	
}


sub _move
{
	print "start\n";
	my $cnt =0;
	my $mod = 2;
	while ($go==1){
		my $then = getTime();
		if ($gate[0]{'id'} > -1){
		#will produce a side to side movement on last gate
			if ($cnt == 40){
				$cnt = 0;
				$mod = ($mod == 2)?-2:2;
			}else{
				$cnt++;
			}
			$tdc->translate($gate[0]{'id'},$mod,0,0,1);
			$gate[0]{'pos'}[0]+=$mod;
		}
		
		my @drawBullets = ();
		foreach my $b (@bullets){
			my ($dist_travelled, $dist_camera) = $tdc->translateVectoredObject($b,15,1);
			if ($dist_travelled < 700){
				#may want to work out distance of bullet to target first, may cut down on processing (not done atm)
				my $col = 0;
				$col = $tdc->collisionCheck_object($b,$targets[0]{'id'}) if (@targets > 0 && $targets[0]{'id'} > -1);
				if ($col == 1){
					$tdc->removeObject($b,1);
					$tdc->removeObject($targets[0]{'id'},1);
					shift(@targets);
				}else{
					push(@drawBullets,$b);
					$distances{$b}=$dist_camera;
				}
			}else{
				#remove when out of range
				_remove($b);
			}
		
		}
		@bullets = @drawBullets;
		##make sure furthest objects drawn first (polygon mode has no z-buffer)
		#may be some oddities as it's based on object centre point
		#could collision check bullets on gates but going to start eating performance even more
		@drawOrder = sort{_sort_func($a,$b)} @drawOrder;
		@{$tdc->{DRAWORDER}} = @drawOrder;
		$tdc->moveCamera('z', $movespeed,1);
		
		#create/remove gates as necessary
		_handleObjects(\@gate);
		_handleObjects(\@targets);

	
		if ($rotvert != 0){
			$tdc->moveCamera('pan_vert',$rotvert,1);
		}
		if ($rothoriz != 0){
			$tdc->moveCamera('pan_horiz',$rothoriz,1);
		}
		if ($roll != 0){
			$tdc->moveCamera('roll',$roll,1);
		}
		if ($slide != 0){
			$tdc->moveCamera('horiz',$slide,1);
		}
		if ($raise != 0){
			$tdc->moveCamera('vert',$raise,1);
		}
		if ($gate[$nextGate]{'dist'} < $gate[$nextGate]{'obj'}->{ORADIUS} +10){

				my $pass = $tdc->collisionCheck_point(\@{$tdc->{CAMERA}},$gate[$nextGate]{'id'}) ; #this is fine as long as gate box structure bigger than movement speed, otherwise have to check every point we've been through
				#only checking collision with camera point, and not any structure around that point at the moment
				#currently ignores gates that aren't the active one - can hit them until your heart's content!
				if ($pass == 1)
				{
					$gate[$nextGate]{'obj'}->{SHADE} = 'red';
					$nextGate--; #end of course if -1
					if ($nextGate > -1){
						$gate[$nextGate]{'obj'}->{SHADE} = 'green';
						#could do with indicator to next gate if it's out of view
					}else{
						if (scalar @targets == 0){ 
							print "Complete\n";
						}else{
							print "Incomplete\n";
						}
						$go = -1;
					}
				}elsif ($pass == 2)
				{
					#stop - crashed into gate
					print "Hit Gate\n";
					$go = -1;
				}

		}
		$tdc->_updateAll();
		my $now = getTime();
		my $tdif = 0.05 - ($now-$then);
		my $wait = sprintf "%.3f", $tdif;
		if ($wait > 0){
			select (undef, undef, undef, $wait);
		}
	
	}
	if ($go == -1){
		sleep 1;
		$mw->destroy;
		exit 0;
	}
}


sub _handleObjects
{
	my $objects = shift;
		for (my $i = 0 ; $i < @$objects ; $i++){
			$$objects[$i]{'dist'} = distanceBetween(\@{$tdc->{CAMERA}}, \@{$$objects[$i]{'pos'}});
			if ($$objects[$i]{'dist'} < $drawDistance && $$objects[$i]{'id'} > -1){
				$distances{$$objects[$i]{'id'}} = $$objects[$i]{'dist'};
			}elsif ($$objects[$i]{'dist'} < $drawDistance && $$objects[$i]{'id'} < 0){
				$$objects[$i]{'id'} = $tdc->registerObject($$objects[$i]{'obj'},\@focuspoint,'',0,0,0,1);
				$distances{$$objects[$i]{'id'}} = $$objects[$i]{'dist'};
				unshift(@drawOrder,$$objects[$i]{'id'});	
			}
			elsif ($$objects[$i]{'dist'} >= $drawDistance && $$objects[$i]{'id'} > -1){
				#now need to remove an object if it goes out of sight
				_remove($$objects[$i]{'id'});
				$$objects[$i]{'id'} = -1;	
			}		
		}
}

sub _remove
{
	my $id = shift;
				
	$tdc->removeObject($id,1);
	@drawOrder = grep{$_!=$id}@drawOrder;
	delete $distances{$id};
	
}


sub _sort_func
{
	my $aref = shift;
	my $bref = shift;
	#sort largest to smallest
	return ($distances{$bref} <=> $distances{$aref});
	
}



sub buildStarField
{
	my $radius = 2000;
	foreach(1..150){
		my $xangle = int(rand(90));
		my $yangle = int(rand(90));
		my $y = sin($yangle)*$radius;
		my $adj = cos($yangle)*$radius;
		my $x = sin($xangle)*$adj;
		my $z = cos($xangle)*$adj;
		
		$x = $x * -1 if (int(rand(1.99)) == 1);
		$y = $y * -1 if (int(rand(1.99)) == 1);
		$z = $z * -1 if (int(rand(1.99)) == 1);
		
		$x+=250;
		$y+=250; #start camera position, shouldn't be hardcoded
		
		my $starObj = CanvasObject->new;

		$starObj->{VERTEXLIST}[0] = [$x,$y,$z];
		$tdc->registerBackPoint($starObj, 'white', 3);
		
	}

}


sub go
{
	if ($go == 0){
		$go = 1;
		_move();
	}else{
		$go = 0;
	}
}



sub dkeydown
{
	 $rothoriz = $turnamount if ($rotvert == 0 && $rothoriz == 0 && $go == 1);
}

sub dkeyup
{
	 $rothoriz = 0;
}

sub akeydown
{
	$rothoriz = -$turnamount if ($rotvert == 0 && $rothoriz == 0 && $go == 1);
}

sub akeyup
{
	$rothoriz = 0;
}

sub wkeydown
{
	$rotvert = -$turnamount if ($rotvert == 0 && $rothoriz == 0 && $go == 1);
}

sub wkeyup
{
	$rotvert = 0;
}

sub skeydown
{
	$rotvert = $turnamount if ($rotvert == 0 && $rothoriz == 0 && $go == 1);
}

sub skeyup
{
	$rotvert = 0;
}

sub qkeydown
{
	$roll = -$turnamount if ($roll && $go == 1);
}

sub qkeyup
{
	$roll = 0;
}
sub ekeydown
{
	$roll = $turnamount if ($roll && $go == 1);
}

sub ekeyup
{
	$roll = 0;
}


sub jkeydown
{
	$slide = -$turnamount if ($slide == 0 && $go == 1);
}

sub jkeyup
{
	$slide  = 0;
}
sub lkeydown
{
	$slide  = $turnamount if ($slide == 0 && $go == 1);
}

sub lkeyup
{
	$slide  = 0;
}

sub ikeydown
{
	$raise = $turnamount if ($raise == 0 && $go == 1);
}

sub ikeyup
{
	$raise  = 0;
}
sub kkeydown
{
	$raise  = -$turnamount if ($raise == 0 && $go == 1);
}

sub kkeyup
{
	$raise  = 0;
}


sub firepress
{
	my $time = getTime();
	my $dif = $time - $lastfire;
	if ($dif >=1 && $go == 1){	
		$lastfire = $time;
		my $b = Bullet3D->new;
		my $camvec = $tdc->_getCameraVector();
		@{$b->{VECTOR}} = ($$camvec[0],$$camvec[1],$$camvec[2]);
		
		my $mod=1;
		$mod=-1 if ($$camvec[2] < 0);
		
		my $xrot = sprintf("%.2d",(rad2deg(asin($$camvec[1]))*-1)*$mod);
		my $yrot = sprintf("%.2d",rad2deg(asin($$camvec[0]))*$mod);

		$b->rotate('z',45,0,0);
		$b->rotateComposite('y',$yrot,0,0,'x',$xrot,0,0);
		
		
		my $bid = $tdc->registerObject($b,\@focuspoint,'cyan',${$tdc->{CAMERA}}[0]+(${$tdc->{CAMVEC_R}}[0]*20),${$tdc->{CAMERA}}[1]+(${$tdc->{CAMVEC_R}}[1]*20),${$tdc->{CAMERA}}[2]+(${$tdc->{CAMVEC_R}}[2]*20));
		#object created with a vector, moved by calling translateVectoredObject
		
		push (@bullets, $bid);
		push (@drawOrder, $bid);
	
	}

}


sub endit
{
	print "end\n";
	#print "Complete\n";
}