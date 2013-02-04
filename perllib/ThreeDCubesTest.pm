
#testing out different 3d manipulation functions

package ThreeDCubesTest;
use Tk;
use CanvasObject;
use Math::Trig;
use GamesLib;
use LineEq;
use threads;
use threads::shared;
use strict;
#cut down version for roids, no set-up for other types of object, left out JBwingui specific things
#objects to be set-up outside this package not in it, so don't have to do specific object set-up functions
#use generic create object function instead, this basically handles drawing and moving etc



sub new{
	shift;
	my $displaycanvas = shift;
	my $mw = shift;
	my $lightsource = shift;
	my $viewangle = shift;
	my $pixeldraw = shift;
	$pixeldraw = 0 if(! $pixeldraw);
	my $self = {};
	$self->{SHAPES}=[];
	$self->{BACKPOINTS}=[];
	$self->{DRAWORDER}=[];
	$self->{FREEKEYS}=[];
    	$self->{LIGHTSOURCE}=$lightsource; #can currently handle only one source of light
    	$self->{CNT}=0;
    	$self->{DISPLAY}=$displaycanvas;
    	$self->{CAMERA}=[0,0,0];
    	$self->{HEIGHT} = 0;
    	$self->{WIDTH} = 0;
    	if ($displaycanvas != 0){
    		$self->{CAMERA}=[int($$displaycanvas->Width/2),int($$displaycanvas->Height/2),0]; #will probably want to handle screen resize
    		$self->{HEIGHT} = $$displaycanvas->Height;
    		$self->{WIDTH} = $$displaycanvas->Width;
		}
    	$self->{CAMVEC_F} = [0,0,1]; #forward
    	$self->{CAMVEC_U} = [0,-1,0]; #up
    	$self->{CAMVEC_R} = [1,0,0]; #right
    	$self->{TRANSFORMS} = [0,0,0];
    	
    	$self->{CAMERA_VIEW_ANGLE}=$viewangle; #if zero will use perspective functions using focuspoints and fixed camera
    						#if greater, will use field of view function and moveable camera, ignores focuspoints
    						
    	$self->{MOVE_LS_WITH_CAM} = 0;
    	
    	$self->{PXDRAW} = $pixeldraw;
    	$self->{MW}=$mw;
    	$self->{ZBUF} = 0;
    	$self->{BUFREADY}=0;
	bless $self;
	return $self;

}


sub setLightsourceMoveWithCam{
	my $self = shift;
	$self->{MOVE_LS_WITH_CAM}  = shift;
}


sub registerBackPoint
{
	#background object, will move with camera, might want a similar background object method too
	my $self = shift;
	my $obj = shift;
	my $colour = shift;
	my $size = shift;
	push(@{$self->{BACKPOINTS}}, $obj);
	my $id = @{$self->{BACKPOINTS}}-1;
	my $fovpoint = _getFieldView($self,$id, 'BACKPOINTS');
	#print $$fovpoint[0][2]."\n";
	if ($$fovpoint[0][2] > 0){
		${$self->{DISPLAY}}->createOval($$fovpoint[0][0],$$fovpoint[0][1], $$fovpoint[0][0]+$size,$$fovpoint[0][1]+$size, -fill=>$colour, -tags=>'bg');
	}
	
}

sub registerObject
{
	my $self = shift;
	my $obj = shift;
	my $focuspoint = shift;
	my $colour = shift;
	my $movex = shift;
	my $movey = shift;
	my $movez = shift;
	my $unshift = shift;
	my $nodraw = shift;


	my $objnum;
	if (@{$self->{FREEKEYS}} > 0){
		$objnum = shift @{$self->{FREEKEYS}};
	}else{
		$objnum = $self->{CNT};
		$self->{CNT}++;
	}
	my $dispheight = $self->{HEIGHT};
	my $dispwidth = $self->{WIDTH};	
	my @fp = ($dispwidth/2,$dispheight/2,1000); #should be centre of canvas
	if (@$focuspoint == 3){
		@fp = @$focuspoint;
	}
	$self->{SHAPES}[$objnum]= $obj;
	$self->{SHAPES}[$objnum]->setFocus(\@fp);
	$self->{SHAPES}[$objnum]->setColour($colour) if ($colour ne '');
	$self->{SHAPES}[$objnum]->translate($movex,$movey,$movez);
	$self->{SHAPES}[$objnum]->sortz() if ($self->{PXDRAW}==0);
	if ($unshift){
		unshift (@{$self->{DRAWORDER}}, $objnum);
	}else{
		push (@{$self->{DRAWORDER}}, $objnum);
	}
	_drawObject($self,0,$objnum) if (! $nodraw);
	return $objnum;
}


sub _getCameraVector
{

	my $self=shift;

	my @vector =($self->{CAMVEC_F}[0],$self->{CAMVEC_F}[1],$self->{CAMVEC_F}[2]); 
	
	return \@vector;
	
}


sub setColour
{
	my $self = shift;
	my $id = shift;
	my $colour = shift;
	$self->{SHAPES}[$id]->{SHADE} = $colour;
	_drawObject($self,1,$id);
}

sub getColour
{
	my $self = shift;
	my $id = shift;

	return $self->{SHAPES}[$id]->{SHADE};
}

sub rotate
{
	#around object centre point
	my $self= shift;
	my $obj = shift;
	my $axis = shift;
	my $rate = shift;
	my $angle = shift;
	my $noupdate = shift;
	my $centre = $self->{SHAPES}[$obj]->getCentre();
	
	rotateAroundPoint($self,$obj,$axis,$rate,$angle,$centre,$noupdate);

	
}


sub rotateAroundPoint
{
	#keeping seperate from rotate, though basically the same, makes it easier to spot wich you are using in calling code
	my $self= shift;
	my $obj = shift;
	my $axis = shift;
	my $rate = shift;
	my $angle = shift;
	my $point = shift;
	my $noupdate = shift;

	my @c;
	my @trans;

	if ($axis eq 'x'){
		@c = ($$point[1],$$point[2]);
		@trans = (0,-$$point[1],-$$point[2]);
	}elsif ($axis eq 'y'){
		@c = ($$point[0],$$point[2]);
		@trans = (-$$point[0],0,-$$point[2]);
	}else{
		@c = ($$point[0],$$point[1]);
		@trans = (-$$point[0],-$$point[1],0);
	}
	#negative rate will move object in anti-clockwise direction
	my $repeat = int($angle/$rate);
	$repeat = $repeat*-1 if ($repeat < 0);
	for (1..$repeat){
		$self->{SHAPES}[$obj]->translate($trans[0], $trans[1], $trans[2]);
		$self->{SHAPES}[$obj]->rotate($axis,$rate,$c[0],$c[1]);
		if (! $noupdate){
			_drawObject($self,1,$obj);
			_updateWindow($self);
		}
	}
	
}

sub _rotateLightSource{
	my $self = shift;
	my $axis = shift;
	my $amount = shift;
	my $temp = CanvasObject->new;
	my @ls;
	$ls[0] = [$self->{LIGHTSOURCE}[0]-$self->{CAMERA}[0],$self->{LIGHTSOURCE}[1]-$self->{CAMERA}[1],$self->{LIGHTSOURCE}[2]-$self->{CAMERA}[2]];
	$temp->{VERTEXLIST} = \@ls;
	$temp->rotate($axis,$amount,0,0);
	foreach(0..2){
		$self->{LIGHTSOURCE}[$_] = $ls[0][$_]+$self->{CAMERA}[$_];
	}
}


sub moveCamera
{
	#movement in relation to camera position, e.g. Moving forward moves in the direction the camera is facing
	
	
	my $self = shift;
	my $direction = shift;
	my $amount = shift;
	my $noupdate = shift;
	my $vector = _getCameraVector($self);
	if ($direction eq 'vert' || $direction eq 'horiz'){
		my @tempv;
		$tempv[0]=[$$vector[0],$$vector[1],$$vector[2]];
		my $tempobj = CanvasObject->new;
		@{$tempobj->{VERTEXLIST}}=@tempv;
		if ($direction eq 'vert'){
			$tempobj->rotate('x',90,0,0); 
		}
		elsif ($direction eq 'horiz'){
			$tempobj->rotate('y',90,0,0);
		}
		@tempv=(${$tempobj->{VERTEXLIST}}[0][0],${$tempobj->{VERTEXLIST}}[0][1],${$tempobj->{VERTEXLIST}}[0][2]);
		$tempobj=undef;
		$self->{CAMERA}[0]+= ($tempv[0]*$amount);
		$self->{CAMERA}[1]+= ($tempv[1]*$amount);
		$self->{CAMERA}[2]+= ($tempv[2]*$amount);
		
		if ($self->{MOVE_LS_WITH_CAM} == 1){
			$self->{LIGHTSOURCE}[0]+= ($tempv[0]*$amount);
			$self->{LIGHTSOURCE}[1]+= ($tempv[1]*$amount);
			$self->{LIGHTSOURCE}[2]+= ($tempv[2]*$amount);
		}
		for(my $i = 0 ; $i < @{$self->{BACKPOINTS}} ; $i++){
			$self->{BACKPOINTS}[$i]->translate(($tempv[0]*$amount), ($tempv[1]*$amount), ($tempv[2]*$amount));
		}
	}
	elsif ($direction eq 'z'){
	#move along camera vector	
		$self->{CAMERA}[0]+= ($$vector[0]*$amount);
		$self->{CAMERA}[1]+= ($$vector[1]*$amount);
		$self->{CAMERA}[2]+= ($$vector[2]*$amount);
		#print $self->{LIGHTSOURCE}[0]." : ".$self->{LIGHTSOURCE}[1]." : ".$self->{LIGHTSOURCE}[2]."\n";
		if ($self->{MOVE_LS_WITH_CAM} == 1){
			$self->{LIGHTSOURCE}[0]+= ($$vector[0]*$amount);
			$self->{LIGHTSOURCE}[1]+= ($$vector[1]*$amount);
			$self->{LIGHTSOURCE}[2]+= ($$vector[2]*$amount);
		}
		for(my $i = 0 ; $i < @{$self->{BACKPOINTS}} ; $i++){
			$self->{BACKPOINTS}[$i]->translate(($$vector[0]*$amount), ($$vector[1]*$amount), ($$vector[2]*$amount));
		}
	}
	elsif ($direction eq 'pan_horiz'){ 

		camVecTest($self,'y',$amount);
		_rotateLightSource($self,'y',$amount) if ($self->{MOVE_LS_WITH_CAM} == 1);
		_panBackground($self);
	}
	elsif ($direction eq 'pan_vert'){

		camVecTest($self,'x',$amount);
		_rotateLightSource($self,'x',$amount) if ($self->{MOVE_LS_WITH_CAM} == 1);
		_panBackground($self);
	}
	elsif ($direction eq 'roll'){

			camVecTest($self,'z',$amount);
			_rotateLightSource($self,'z',$amount) if ($self->{MOVE_LS_WITH_CAM} == 1);
			_panBackground($self);
	}
	if (! $noupdate){
		_updateAll($self) ;
		
	}
	_drawRollMarker($self); #needs to be an option
	
	
}


sub _drawRollMarker{ #artificial horizon type jobbie
	my $self = shift;
	my $dispheight = ${$self->{DISPLAY}}->Height;
	my $dispwidth = ${$self->{DISPLAY}}->Width;
	
	my $rollMark = CanvasObject->new;
	my @points;
	my $centrex = $dispwidth*0.5;
	my $centrey = $dispheight*0.5;
	$points[0] = [-$centrex,0,0];
	$points[1] = [$centrex,0,0];
	$rollMark->{VERTEXLIST} = \@points;
	$rollMark->rotate('z',-${$self->{TRANSFORMS}}[2],$centrex,$centrey);
	my $yLoc = $centrey * (${$self->{TRANSFORMS}}[0]/90);
	my $xLoc = $centrex * (${$self->{TRANSFORMS}}[1]/90);
	$rollMark->translate(0,$yLoc);
	${$self->{DISPLAY}}->delete("rollMarker");
	${$self->{DISPLAY}}->createLine($points[0][0],$points[0][1],$points[1][0],$points[1][1], -fill=>"red", -tags=>"rollMarker", -arrow=>"last");
	${$self->{DISPLAY}}->createLine($centrex-$xLoc,0,$centrex-$xLoc,20, -fill=>"white", -tags=>"rollMarker");
	${$self->{DISPLAY}}->createLine($dispwidth+($centrex-$xLoc),0,$dispwidth+($centrex-$xLoc),20, -fill=>"blue", -tags=>"rollMarker");
}

sub camVecTest{

	my $self = shift;
	my $dir = shift;
	my $amount = shift;	
		#getting there - seems to be a better but not yet perfect - rollmarker shows wierd setting at 90 degrees straight up or down, though doesn't seem to affect it when it comes down again (using 4 degree turnrate helps - less chance of hitting 90)
		
	my ($xRot,$yRot,$zRot,$tempvec) = _getTransforms($self);	
		
		$tempvec->rotate($dir,$amount,0,0); # must be in this order, as is order in getTransforms
		$tempvec->rotate('z',$zRot,0,0);
		$tempvec->rotate('x',$xRot,0,0);
		$tempvec->rotate('y',$yRot,0,0);
		

		foreach(0..2){
				$self->{CAMVEC_F}[$_] = ${$tempvec->{VERTEXLIST}}[0][$_];
				$self->{CAMVEC_R}[$_] = ${$tempvec->{VERTEXLIST}}[1][$_];
				$self->{CAMVEC_U}[$_] = ${$tempvec->{VERTEXLIST}}[2][$_];
		}

	 ($xRot,$yRot,$zRot,$tempvec) = _getTransforms($self);
	 ${$self->{TRANSFORMS}}[0] = $xRot;
	 ${$self->{TRANSFORMS}}[1] = $yRot;
	${$self->{TRANSFORMS}}[2] = $zRot;
	$tempvec=undef;
}




sub _panBackground
{
	my $self = shift;
	${$self->{DISPLAY}}->delete('bg');
	for(my $i = 0 ; $i < @{$self->{BACKPOINTS}} ; $i++){
		my $fovpoint = _getFieldView($self,$i, 'BACKPOINTS');
		if ($$fovpoint[0][2] > 0){
			${$self->{DISPLAY}}->createOval($$fovpoint[0][0],$$fovpoint[0][1], $$fovpoint[0][0]+3,$$fovpoint[0][1]+3, -fill=>'white', -tags=>'bg');
		}
	}
}

sub moveCameraInWorld
{
	my $self = shift;
	my $direction = shift;
	my $amount = shift;

	#camera moves in relation to the world view, not in relation to how the camera is oriented
	if ($direction eq 'vert'){
		$self->{CAMERA}[1]+=$amount;
		$self->{LIGHTSOURCE}[1]+=$amount if ($self->{MOVE_LS_WITH_CAM} == 1);
	}
	elsif ($direction eq 'horiz'){
		$self->{CAMERA}[0]+=$amount;
		$self->{LIGHTSOURCE}[0]+=$amount if ($self->{MOVE_LS_WITH_CAM} == 1);
	}
	elsif ($direction eq 'z'){
		$self->{CAMERA}[2]+=$amount;
		$self->{LIGHTSOURCE}[2]+=$amount if ($self->{MOVE_LS_WITH_CAM} == 1);
	}
	#now update all objects
	_updateAll($self);
}




sub _updateAll
{
	my $self = shift;
	if ($self->{PXDRAW} == 1){
			_drawObject($self,0,0); #pixel draw always refreshes all items so only call it once
	}else{
	for(my $i = 0 ; $i < @{$self->{DRAWORDER}} ; $i++){
		if (! $self->{SHAPES}[$self->{DRAWORDER}[$i]] eq "")
		{
			_drawObject($self,0,$self->{DRAWORDER}[$i]);
			#draw mode 0 refreshes entire display, deletes all items and redraws
			#ensures draw order is correct, but might be a better way somewhere
		}
	}
	}
	_updateWindow($self);
}


sub removeObject
{
	my $self=shift;
	my $obj=shift;
	my $noupdate = shift;
	if (@{$self->{SHAPES}} > $obj){
	if (! $self->{SHAPES}[$obj] eq "")
	{
		foreach (@{$self->{SHAPES}[$obj]->{CANVASITEMS}}){
			${$self->{DISPLAY}}->delete($_) if ($_ > 0);
		}
	}
	$self->{SHAPES}[$obj] = undef;
	$self->{SHAPES}[$obj] = "";
	@{$self->{DRAWORDER}} = grep{$_!=$obj}@{$self->{DRAWORDER}};
	push (@{$self->{FREEKEYS}}, $obj); #reuse empty array elements
	}
	_updateWindow($self) if (! $noupdate);
}

sub translateVectoredObject
{
	#associated object has a vector component, it is moving under it's own steam
	my $self=shift;
	my $obj=shift;
	my $amount = shift;
	my $noupdate = shift;
	my $x = ${$self->{SHAPES}[$obj]->{VECTOR}}[0] * $amount;
	my $y = ${$self->{SHAPES}[$obj]->{VECTOR}}[1] * $amount;
	my $z = ${$self->{SHAPES}[$obj]->{VECTOR}}[2] * $amount;
	translate($self,$obj,$x,$y,$z, $noupdate);
	#return distance covered for life of object, and distance from camera
	my $centre = $self->{SHAPES}[$obj]->getCentre();
	my $dist = distanceBetween(\@{$self->{CAMERA}}, $centre);
	$self->{SHAPES}[$obj]->{CYCLE}++;
	return ($amount*$self->{SHAPES}[$obj]->{CYCLE},$dist);
}

sub translate
{
	#x,y,z values are the amount to modify by, not the final x,y,z position
	my $self= shift;
	my $obj = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;
	my $noupdate = shift;

	$self->{SHAPES}[$obj]->translate($x, $y, $z);
	if (! $noupdate){
		_drawObject($self,1,$obj);
		_updateWindow($self);
	}
}


sub zoom
{
	my $self = shift;
	my $obj = shift;
	_zoom($self,1,$obj);
}

sub _zoom
{
	#makes object fly into position from focuspoint, perspective mode only
	my $self = shift;
	my $mode = shift;
	my $obj = shift;
	my $focuspoint = $self->{SHAPES}[$obj]->{FOCUSPOINT};
	my $maxz = $$focuspoint[2] - 400;
	my $rate = 2;
	my $steps = int($maxz/$rate);
	my $remainder=$maxz%$rate;
	my $vertexList = $self->{SHAPES}[$obj]->{VERTEXLIST};

	for (my $i = 0 ; $i < @{$vertexList}; $i++)
	{
		$$vertexList[$i][2] = $$vertexList[$i][2] + $maxz;
	}
	_drawObject($self,$mode,$obj);
	_updateWindow($self);
	for (my $j=1 ; $j <= $steps ; $j++){
	for (my $i = 0 ; $i < @{$vertexList}; $i++)
	{
		$$vertexList[$i][2] = $$vertexList[$i][2] - $rate;
		if ($j == $steps){
			$$vertexList[$i][2] -= $remainder;
		}
	}
	_drawObject($self,1,$obj);
	_updateWindow($self);
	}

}



sub redraw
{
	#redraw specific objects
	my $self = shift;
	my $objs = shift; #array ref
	my $mode = shift;
	return if ($self->{PXDRAW} == 1);
	#may want to factor in draworder - currently will redraw in order given
	
	foreach (@$objs){
		_drawObject($self,$mode,$_);
	}
	_updateWindow($self);
}


sub getItemIds
{
	my $self=shift;
	my $obj = shift;
	return $self->{SHAPES}[$obj]->{CANVASITEMS}; 
}


sub _drawObject
{
	my $self = shift;
	my $drawmode = shift;
	my $obj = shift;
	if ($self->{PXDRAW}==0){_drawObjectPoly($self,$drawmode,$obj);}
	elsif ($self->{PXDRAW}==1){_drawObjectPixel($self);} #has to redraw everything regardless
}


sub _drawObjectPixel
{
	#removes and updates all objects (recalc of z buffer)
	
	#might test out a threaded function here - won't make much difference though as it's the actual drawing that takes all the time
	#you would do this to speed up processing of multiple objects - likely to be slower for few objects (tested as indeed slower)- hopefully better for more
	#not even sure this will help at all under windows, as fork is a pseudo-fork i.e. it doesn't create a separate process like it does on Unix/Linux
	
	#except that the threads module doesn't play nice with Tk elements (as each thread basically starts as a copy of the state of calling thread when created) 
	#- so the interpreter will attempt to close windows when a thread is joined and the interpreter goes splat! One way around it is not to close the thread, but that's a shit idea really! -will eat memory
	#would need a thread pool before before any Tk elements are created, need some rejigging as the MainWindow and Canvas elements are passed into this module
	#but a pool would steal some cpu cycles when not used - need some Java style threading.
	
	#ok a solution - if we don't know about the window - assume client program dealing with it (see torustest3.pl) and can safely use threads
	#otherwise use single thread setup
	my $self = shift;
	my $displaycanvas = $self->{DISPLAY};
	my %zbuf :shared;
 # pixel draw - very slow (in Tk) - easily deals with overlapping objects - easy collision detection (though not checking that here)
		
		#print "-----\n";
		
		my $threadcnt = 4;
		my @tnotify :shared;
		my @tdata :shared;
		my @thread = (0) x $threadcnt;
		@tnotify = (0) x $threadcnt;
		@tdata = (-1) x $threadcnt;
		
		
		for(my $j = 0 ; $j < @{$self->{DRAWORDER}} ; $j++){
			if ($displaycanvas != 0){
				#print "SINGLE THREAD\n";
				_pixelDraw($self,\%zbuf,$j);
				
			}else{
				#print "MULTI THREAD\n";
			#test of threading executing 4 threads
			while(1){
				#find a free thread slot
				my $sent = 0;
				for (my $id = 0 ; $id < $threadcnt ; $id++){
					if ($tnotify[$id] != 1){
						if ($tnotify[$id] == 2){ 
							$thread[$id]->join(); #playing with creating a new thread for each object, may be some performance advantage in not having a worker looping waiting for another
						}
						$tnotify[$id] = 1;
						$tdata[$id] = $j;
						if ($thread[$id] == 0){
							$thread[$id] = threads->new(\&_drawObjectPixelWorker,$self,\%zbuf,$id,\@tnotify,\@tdata);
						}
						$sent = 1;
						last;
					}
				}
				if ($sent == 1){last;}
				else {select (undef, undef, undef, 0.1);}
			}
			}
			
		}
		while(1 && $displaycanvas == 0){
			#wait for threads to finish
			my $done = 1;
			for (my $id = 0 ; $id < $threadcnt ; $id++){
				
				if ($tnotify[$id] == 1){
					#still running
					$done = 0;
				}
				elsif ($tnotify[$id] == 2){
					#$tdata[$id] = -1;
					$tnotify[$id] = -1;
					$thread[$id]->join(); #see threads/Tk problem above
					
				} 
				
			}
			if ($done == 1){last;}
			else {select (undef, undef, undef, 0.1);}
		}
		$self->{ZBUF} = \%zbuf;
		if ($displaycanvas == 0){

			$self->{BUFREADY}=1;	
		}else{
			
			outputZBuffer($self,$displaycanvas,\%zbuf);
		}

		
}

sub _drawObjectPixelWorker{
	
	my $self = shift;
	my $zbuf = shift;
	my $tid = shift;
	my $notify = shift;
	my $tdata = shift;
	
	
	#while ($$notify[$tid] > -1){
	#		if ($$tdata[$tid] == -1){
	#			select (undef, undef, undef, 0.1);
	#			next;
	#		}
			_pixelDraw($self,$zbuf,$$tdata[$tid]);
			$$tdata[$tid] = -1;
			$$notify[$tid] = 2;
			
	#}
}

sub _pixelDraw{
	#separated this with a view to threading
	my $self = shift;
	my $zbuf = shift;
	my $id = shift;
	my $fovflag = $self->{CAMERA_VIEW_ANGLE};
	if (! $self->{SHAPES}[$self->{DRAWORDER}[$id]] eq ""){
				my $obj = 	$self->{DRAWORDER}[$id];
				#print "$obj\n";
				my $vertexList = $self->{SHAPES}[$obj]->{VERTEXLIST};
				my $facetVertices = $self->{SHAPES}[$obj]->{FACETVERTICES};
				my $arrayref;
				my @camVertList;
				if ($fovflag){
					$arrayref = _getFieldView($self,$obj, 'SHAPES');
					@camVertList = @{$arrayref};
				}else{
					$arrayref = _getPerspective($self,$obj);
					@camVertList = @{$arrayref};
				}
				
				for (my $i = 0 ; $i < @{$facetVertices} ; $i++){
				my $idno = $$facetVertices[$i][3];
				
				my $bf = _checkBackFace($self,\@{$camVertList[$$facetVertices[$i][0]]},\@{$camVertList[$$facetVertices[$i][1]]},\@{$camVertList[$$facetVertices[$i][2]]},$fovflag, $idno);
				
				if ($bf < 0){
					_buildZBuffer($i,$obj,$self,(@{$$facetVertices[$i]} > 4) ? $$facetVertices[$i][4] : 0,$zbuf,\@camVertList,$vertexList,$facetVertices,$fovflag, $idno);
				}
				}
			}
}

sub outputZBuffer{
	my $self = shift;
	my $cnv = shift;
	my $bufref = shift;

	my %zbuffer = %$bufref;
	$$cnv->delete('all');
	$self->{BUFREADY}=0;
			foreach my $key (keys %zbuffer){
			#print "$key\n";
			#print $zbuffer{$key}."\n";
			if ($key=~m/^(\d+)_(\d+)c$/){
				my $tempy = $2;
				my $tempx = $1;
				#draw pixels as defined by zbuffer
				$$cnv->createRectangle($tempx, $tempy,$tempx, $tempy, -fill=>$zbuffer{$key},-outline=>$zbuffer{$key});
			}
		}
	
	
}

sub _drawObjectPoly
{
	#n.b. only creates or updates the given object
	my $self = shift;
	my $drawmode = shift;
	my $obj = shift;
	my $fovflag = $self->{CAMERA_VIEW_ANGLE};
	my $colour;
	my $ditem;
	my $drawflag = 1;
	my $lastobj = 0;
	my $arrayref;
	my @camVertList; #object vertexlist transformed to camera coordinates
	my $facetVertices;
	if ($fovflag){
		$arrayref = _getFieldView($self,$obj, 'SHAPES');
		@camVertList = @{$arrayref};
	}else{
		$arrayref = _getPerspective($self,$obj);
		@camVertList = @{$arrayref};
	}
	if ($self->{SHAPES}[$obj]->{SORT} && $self->{PXDRAW}==0){
		#if torus/cross etc. (complex shape)
		if ($fovflag){
			#facetvertices array sorted on camera transformation coordinates
			my $tempobj = CanvasObject->new();
			$tempobj->{VERTEXLIST}=\@camVertList;
			my @fv = @{$self->{SHAPES}[$obj]->{FACETVERTICES}};
			$tempobj->{FACETVERTICES}=\@fv;
			$tempobj->sortz();
			$facetVertices = $tempobj->{FACETVERTICES};
			$tempobj = undef;
		}else{
			$self->{SHAPES}[$obj]->sortz();
			$facetVertices = $self->{SHAPES}[$obj]->{FACETVERTICES};
		}
	} else{
		$facetVertices = $self->{SHAPES}[$obj]->{FACETVERTICES};
	}
	my $displayitems = $self->{SHAPES}[$obj]->{CANVASITEMS};
	my $displaycanvas = $self->{DISPLAY};
	my $vertexList = $self->{SHAPES}[$obj]->{VERTEXLIST};
	my $focuspoint = $self->{SHAPES}[$obj]->{FOCUSPOINT};

	
	#make sure display array is empty and any items associated are removed
	if ($drawmode == 0){
	foreach my $itemid (grep{$_>0} @{$displayitems}){
		$$displaycanvas->delete($itemid);
	}
	@{$displayitems} = (0) x @{$facetVertices};
	}

	my $outline='';
	
	#polygon draw - not bad on speed but difficult to order objects
	
	for (my $i = 0 ; $i < @{$facetVertices} ; $i++)
	{
	

		$drawflag = 0;
		#only draw facet if all z values are lower than the focus point z value
		$drawflag = 1 if (($$vertexList[$$facetVertices[$i][0]][2] < $$focuspoint[2] &&
		$$vertexList[$$facetVertices[$i][1]][2] < $$focuspoint[2] &&
		$$vertexList[$$facetVertices[$i][2]][2] < $$focuspoint[2]) ||
		$fovflag);
		my $x = $camVertList[$$facetVertices[$i][0]][0];
		my $y = $camVertList[$$facetVertices[$i][0]][1];
		my $x1 = $camVertList[$$facetVertices[$i][1]][0];
		my $y1 = $camVertList[$$facetVertices[$i][1]][1];
		my $x2 = $camVertList[$$facetVertices[$i][2]][0];
		my $y2 = $camVertList[$$facetVertices[$i][2]][1];
			
		my $idno = $$facetVertices[$i][3];
		my $bf = _checkBackFace($self,\@{$camVertList[$$facetVertices[$i][0]]},\@{$camVertList[$$facetVertices[$i][1]]},\@{$camVertList[$$facetVertices[$i][2]]},$fovflag, $idno);

		if ($bf < 0){ #minus values mean vectors heading towards each other, therefore front face	
				#$bf = 1; #now check if off screen - doesn't draw if all three points are off screen - anything behind camera already not drawn
				#foreach(0..2){
				#	if ($camVertList[$$facetVertices[$i][$_]][0] >= 0 && $camVertList[$$facetVertices[$i][$_]][0] <= $$displaycanvas->Width && $camVertList[$$facetVertices[$i][$_]][1] >= 0 && $camVertList[$$facetVertices[$i][$_]][1] <= $$displaycanvas->Height)
				#
				#	{
				#		$bf=-1;
				#		last;
				#	}
				#	
				#}
				#however it is possible for all three points to be offscreen and the facet still be visible in front of you - so taken this out for rethink
				
				if (($x < 0 && $x1 < 0 && $x2 < 0)
				 || ($x1 < 0 && $y1 < 0 && $y2 < 0)
				 || ($x > $$displaycanvas->Width && $x1 > $$displaycanvas->Width && $x2 > $$displaycanvas->Width)
				 || ($x1 > $$displaycanvas->Height && $y1 > $$displaycanvas->Height && $y2 > $$displaycanvas->Height)
				){ $bf=1;} #this won't draw if all points of the facet are off screen on the same side
				
				if ($bf < 0){
				my @point = _getTriangleCentre(\@{$$vertexList[$$facetVertices[$i][0]]},\@{$$vertexList[$$facetVertices[$i][1]]},\@{$$vertexList[$$facetVertices[$i][2]]});
				if ($self->{SHAPES}[$obj]->{NOFILL} == 1){
					$colour = $self->{SHAPES}[$obj]->{SHADE};
				}
				else{
					$colour = _getShade($self,\@{$$vertexList[$$facetVertices[$i][0]]},\@{$$vertexList[$$facetVertices[$i][1]]},\@{$$vertexList[$$facetVertices[$i][2]]},$obj,\@point,(@{$$facetVertices[$i]} > 4) ? $$facetVertices[$i][4] : 0);
				}
				if ($self->{SHAPES}[$obj]->{OUTL} eq ''){
					$outline=$colour;
				}else{
					$outline=$self->{SHAPES}[$obj]->{OUTL};
				}
				}
		}

		my $tag = $self->{SHAPES}[$obj]->{TAG};
			$tag = 'none' if (! $tag);
		if ($drawmode == 0){
		if ($bf < 0 && $drawflag ==1){
			#whole face shaded same colour only as drawing by polygon not pixel
			#use master coords, not perspective coords for lighting
			
			if ($self->{SHAPES}[$obj]->{NOFILL} == 1){
				$ditem = $$displaycanvas->createPolygon($x,$y,$x1,$y1,$x2,$y2, -outline=>$outline, -tags=>''.$tag);
			}else{
				$ditem = $$displaycanvas->createPolygon($x,$y,$x1,$y1,$x2,$y2, -fill=>$colour, -outline=>$outline, -tags=>''.$tag);
			}
			$$displayitems[$idno] = $ditem;
		}
		}
		else
		{
			#would hope this mode of redraw is faster - but not sure - it is a little
			if ($bf < 0 && $$displayitems[$idno] > 0 && $drawflag ==1){
				$ditem = $$displayitems[$idno];
				$$displaycanvas->coords($ditem, $x,$y,$x1,$y1,$x2,$y2);
				if ($self->{SHAPES}[$obj]->{NOFILL} == 1){
					$$displaycanvas->itemconfigure($ditem, -outline=>$outline);
				}else{
					$$displaycanvas->itemconfigure($ditem, -fill=>$colour, -outline=>$outline);
				}
				$$displaycanvas->raise($ditem, $lastobj) if ($lastobj > 0);
				$lastobj = $ditem;
				
			}
			elsif ($bf < 0 && $$displayitems[$idno] == 0 && $drawflag ==1){
				if ($self->{SHAPES}[$obj]->{NOFILL} == 1){
					$ditem = $$displaycanvas->createPolygon($x,$y,$x1,$y1,$x2,$y2, -outline=>$outline, -tags=>''.$tag);
				}else{
					$ditem = $$displaycanvas->createPolygon($x,$y,$x1,$y1,$x2,$y2, -fill=>$colour, -outline=>$outline, -tags=>''.$tag);
				}
				$$displayitems[$idno] = $ditem;
				$lastobj = $ditem;
			}
			elsif (($bf >= 0 && $$displayitems[$idno] > 0) || ($$displayitems[$idno] > 0 && $drawflag ==0)){
				$$displaycanvas->delete($$displayitems[$idno]);
				$$displayitems[$idno] = 0;
			}
		}
				
	} #end for
	
	

}

sub _getTriangleCentre
{
	my @pt;
	$pt[0] = shift;
	$pt[1] = shift;
	$pt[2] = shift;
	
	my $maxx = $pt[0][0];
	my $minx = $pt[0][0];
	my $maxy = $pt[0][1];
	my $miny = $pt[0][1];
	my $maxz = $pt[0][2];
	my $minz = $pt[0][2];
	
	foreach (1..2){
		if ($pt[$_][0] > $maxx){
			$maxx = $pt[$_][0];
		}elsif ($pt[$_][0] < $minx){
			$minx = $pt[$_][0];
		}
		if ($pt[$_][1] > $maxy){
			$maxy = $pt[$_][1];
		}elsif ($pt[$_][1] < $miny){
			$miny = $pt[$_][1];
		}
		if ($pt[$_][2] > $maxz){
			$maxz = $pt[$_][2];
		}elsif ($pt[$_][2] < $minz){
			$minz = $pt[$_][2];
		}
	}
	
	return ($minx+(($maxx-$minx)/2),$miny+(($maxy-$miny)/2),$minz+(($maxz-$minz)/2));
	
	
}

sub _buildZBuffer #called per facet
{
	#really only use for static stuff TK is not nearly fast enough
	

	#my $cnv=shift;
	my $facetNo=shift;
	my $obj = shift;
	my $self = shift;
	my $basecolour = shift;
	my $zbuf = shift;
	my $camVertList = shift;
	my $vertexList = shift;
	my $facetVertices = shift;
	my $fovflag=shift;
	my $idno=shift;
	
	my @pt;
	my @mpt;

	for (0..2){
		$pt[$_] = \@{$$camVertList[$$facetVertices[$facetNo][$_]]}; #from screen coords
		$mpt[$_] = \@{$$vertexList[$$facetVertices[$facetNo][$_]]}; #from object coords
	}

		
	my @normal = _getNormal($pt[0],$pt[1],$pt[2]);
	
	
	my @line; #equation of each line forming the triangle
	$line[0] = LineEq->new($pt[0][0],$pt[0][1],$pt[1][0],$pt[1][1]);
	$line[1] = LineEq->new($pt[1][0],$pt[1][1],$pt[2][0],$pt[2][1]);
    $line[2] = LineEq->new($pt[2][0],$pt[2][1],$pt[0][0],$pt[0][1]);
    	
    #get extent of triangle
    my $minx=$pt[0][0];
	my $maxy=$pt[0][1];
	my $maxx=$pt[0][0];
   	my $miny=$pt[0][1];
    	
 	for (1..2){
 		if ($pt[$_][0] > $maxx){
	    		$maxx = $pt[$_][0];
	    	}elsif ($pt[$_][0] < $minx){
	    		$minx = $pt[$_][0];
	    	}
	    	if ($pt[$_][1] > $maxy){
				$maxy = $pt[$_][1];
			}elsif ($pt[$_][1] < $miny){
				$miny = $pt[$_][1];
	    	}
 	}
 	
	    	
	    	my $dispWidth = $self->{WIDTH};
	    	my $dispHeight = $self->{HEIGHT};
		$minx=0 if ($minx < 0);
		$miny=0 if ($miny < 0);
		$maxx=$dispWidth if ($maxx > $dispWidth);
		$maxy=$dispHeight if ($maxy > $dispHeight);

	    		
 
 	#get the colour at each corner of triangle
    	 my @colourdec;
    	 my @percentColour;
    	  my @vert;
    	  for (0..2){
    	  	$vert[$_] = [$mpt[$_][0],$mpt[$_][1],$mpt[$_][2]];
    	  }

    	 
    	 if ($self->{SHAPES}[$obj]->{GORAUD} == 1){ #some objects may define method for finding vertex normals as certain shapes can find the shared normal more easily, e.g. Spheres


		for (0..2){
				my $vertNormal = $self->{SHAPES}[$obj]->vertexNormal($$facetVertices[$facetNo][$_]);
    	 		($colourdec[$_],$percentColour[$_]) = _getColourIntensity($self,$obj,$vertNormal,$vert[$_]);
    	 	}
    	 	
    	 	
	}elsif ($self->{SHAPES}[$obj]->{GORAUD} == 2){ #get average normal at vertex - probably expensive - has good blending and best used where angles from one facet to the next are not huge - terrain modelling would be a good example
    	 
    	 for (my $v = 0 ; $v < 3 ; $v++){
		my $vertNo = $$facetVertices[$facetNo][$v];

		my @facets = ();

		for (my $i = 0 ; $i < @{$facetVertices} ;$i++){
			if ($$facetVertices[$i][0] == $vertNo
			|| $$facetVertices[$i][1] == $vertNo
			|| $$facetVertices[$i][2] == $vertNo){
				my $bf = _checkBackFace($self,\@{$$camVertList[$$facetVertices[$i][0]]},\@{$$camVertList[$$facetVertices[$i][1]]},\@{$$camVertList[$$facetVertices[$i][2]]},$fovflag, $idno);
				#if ($bf < 0.25){ #takes into account some rearward facing facets, but not those getting near to facing directly away
				#this should produce more realistic shading
				#however this may fall foul of a problem at some angles (like the whale fins) where two facets face away from each other producing a perpendicular normal so the shading will be well off what it should be
				#so may be better just to use the forward facing facets 
				#push(@facets,$i);}
				
				push(@facets,$i) if ($bf < 0);
			}
		}

		my @vertNormal = (0,0,0);
		for (my $i = 0 ; $i < @facets ; $i++){
			my $vert1 = $$facetVertices[$facets[$i]][0];
			my $vert2 = $$facetVertices[$facets[$i]][1];
			my $vert3 = $$facetVertices[$facets[$i]][2];


			my @normal = _getNormal(\@{$$vertexList[$vert1]},\@{$$vertexList[$vert2]},\@{$$vertexList[$vert3]},1);
			foreach(0..2){
				$vertNormal[$_] += $normal[$_];
			}
		}
		foreach(0..2){
			$vertNormal[$_] = ($vertNormal[$_] / scalar(@facets));
		}

		_normalise(\@vertNormal); 
		($colourdec[$v],$percentColour[$v]) = _getColourIntensity($self,$obj,\@vertNormal,$vert[$v]);    	 
    	 }
    	 
    	 
    	 }else{ # otherwise just use face normal and light vectors to vertices
    	 	foreach (0..2){ #this shading model is perfect for some shapes e.g. Cubes or simple highly angular shapes
    	 		($colourdec[$_],$percentColour[$_]) = _getShade($self,$mpt[0],$mpt[1],$mpt[2],$obj,$vert[$_],$basecolour,1);
    	 		
    	 	}
    	 }
    	 

    	 #update the zbuffer - no drawing is done here
    	 
    	 #scanline for each x of extent of triangle
    	 foreach my $x (int($minx+0.5)..int($maxx+0.5)){
    	 	my @activeLines =();
    	 	my @yVals =();
    	 	for (my $i = 0 ; $i < @line ; $i++){
    	 		#gets the y values of each line of the triangle for this scanline
    	 		if ($x>=$line[$i]->{MINX} && $x<=$line[$i]->{MAXX}){
    	 			my $y = $line[$i]->yAtx($x);
    	 			if ($y ne 'n' && $y>=$line[$i]->{MINY} && $y<=$line[$i]->{MAXY}){
    	 				push(@activeLines, $i);
    	 				push(@yVals, $y);
    	 			}
    	 		}
    	 	
    	 	}

		#we generally get 2 lines from the above, but it is possible all three lines may have valid y values, we need to discard 1 if so
    	 	if (scalar @activeLines == 3){
    	 	
    	 		my $dif1 = $yVals[0]-$yVals[1];
    	 		my $dif2 = $yVals[1]-$yVals[2];
    	 		my $dif3 = $yVals[0]-$yVals[2];
    	 		$dif1=$dif1*-1 if ($dif1 < 0);
    	 		$dif2=$dif2*-1 if ($dif2 < 0);
    	 		$dif3=$dif3*-1 if ($dif3 < 0);
    	 		
    	 		if (($dif1 < $dif2 && $dif1 < $dif3) || ($dif3 < $dif2 && $dif3 < $dif1)){
    	 			shift @yVals;
    	 			shift @activeLines;
    	 		}elsif ($dif2 < $dif1 && $dif2 < $dif3){
    	 			pop @yVals;
    	 			pop @activeLines;
    	 		}
    	 	}

    	 	
    	 	next if (scalar @activeLines != 2); #we need 2 lines to draw between, if we don't have two, go to the next scanline
    	 			
		if ($yVals[0] > $yVals[1]){
			@yVals = reverse @yVals;
			@activeLines = reverse @activeLines;
		}
		
		my $lineLen =  int($yVals[1]+0.5) - int($yVals[0]+0.5);
		my @yToProcess = ();
		
		{ #lock block
		lock($zbuf);
		if ($lineLen != 0){
		foreach my $y (int($yVals[0]+0.5)..int($yVals[1]+0.5)){
		if ($y >=$miny && $y <=$maxy){
			#get z value for pixel
			my $z = -1;
			if (sqrt(($x-$pt[0][0])*($x-$pt[0][0])) < 1 &&  sqrt(($y-$pt[0][1])*($y-$pt[0][1])) < 1){
				$z = -((-($normal[0]*($pt[1][0]-$x) + $normal[1]*($pt[1][1]-$y))/$normal[2]) - $pt[1][2]);
			}else{
				$z = -((-($normal[0]*($pt[0][0]-$x) + $normal[1]*($pt[0][1]-$y))/$normal[2]) - $pt[0][2]);
			}
		
			#check if hidden by something

			my $zval = $zbuf->{"$x"."_$y"."z"};
			
			if ($z >= 0 && (! $zval || $zval>$z )){
				push (@yToProcess,[$y,$z]);
			}
			
		}
		}
		}
		next if (scalar @yToProcess == 0);

		my @pointInt = ();
		#interpolate the colour for the start and end of this scanline
		foreach my $al (0..1){
			#distance from start point

			my $dx = $x - $line[$activeLines[$al]]->{STARTX};
			my $dy = $yVals[$al] - $line[$activeLines[$al]]->{STARTY};
			my $len = sqrt(($dx*$dx)+($dy*$dy));

			#which is how much of total
			my $percentLen = $len / $line[$activeLines[$al]]->{LEN};

			#so therefore colour intensity at this point is
			my $startInt = $percentColour[$activeLines[$al]]; 

			my $addr = $activeLines[$al] +1;
			$addr = 0 if ($addr == 3);
			my $endInt = $percentColour[$addr];

			$pointInt[$al] = $startInt+(($endInt - $startInt)*$percentLen);
		}

		
		my $difColour = $pointInt[1] - $pointInt[0];
		   	 			
		for(my $i = 0 ; $i < @yToProcess ; $i++){
			my $y = $yToProcess[$i][0];
			my $z = $yToProcess[$i][1];
			#interpolate colour for each pixel on scanline
			my $percentDistCovered = ($y-int($yVals[0]+0.5)) / $lineLen;
			my $colourIntAtThisPoint = $pointInt[0]+($difColour*$percentDistCovered);
			$colourIntAtThisPoint = 1 if ($colourIntAtThisPoint > 1);
			my $colour = _getColourString($colourIntAtThisPoint*255,$basecolour,$colourIntAtThisPoint,$self,$obj);
			#write pixel details to zbuffer 
			
			$zbuf->{"$x"."_$y"."z"}=$z;	
			$zbuf->{"$x"."_$y"."c"}=$colour;
			


		} #end for
		} #end lock
    	 	
    	 } #end scanline foreach 
 }
   



sub _getPerspective
{
	#uses focus points
	#focuspoints nearer the screen will shrink an object more
	#if object behind focus point it should not be visible - dealt with in draw
	# just pulls points towards focus point, greater the z the more it pulls
	# so object appears at full defined size at 0 z value - It would probably be more realistic to appear larger at 0

	my $self = shift;
	my $obj = shift;
	my @camVertList;
	my $x;
	my $y;
	my $z;
	my $xd;
	my $yd;
	my $vertexList = $self->{SHAPES}[$obj]->{VERTEXLIST};
	my $focuspoint = $self->{SHAPES}[$obj]->{FOCUSPOINT};
	for (my $i = 0 ; $i < @{$vertexList} ; $i++)
	{
		$x = $$vertexList[$i][0];
		$y = $$vertexList[$i][1];
		$z = $$vertexList[$i][2];
		my $percent = $z/$$focuspoint[2]; # should never have a focus at zero

			$xd = $x - $$focuspoint[0];
			$yd = $y - $$focuspoint[1];
			$x = $x - ($xd*$percent);
			$y = $y - ($yd*$percent);
			$camVertList[$i] = [$x,$y,$z];
	}
	
	return \@camVertList;
}




sub _getTransforms{ 
	#get the set of transformations that get the camera to it's current orientation
	my $self = shift;
		my $tempvec = CanvasObject->new;
		my @vector;
		$vector[0] = [$self->{CAMVEC_F}[0],$self->{CAMVEC_F}[1],$self->{CAMVEC_F}[2]];
		$vector[1] = [$self->{CAMVEC_R}[0],$self->{CAMVEC_R}[1],$self->{CAMVEC_R}[2]];
		$vector[2] = [$self->{CAMVEC_U}[0],$self->{CAMVEC_U}[1],$self->{CAMVEC_U}[2]];
		$tempvec->{VERTEXLIST} = \@vector;
		
		my $xRot = 0;
		my $yRot = 0;
		my $zRot = 0;
		
		
		
			if (${$tempvec->{VERTEXLIST}}[0][2] < 0){$yRot=180 ;}
		
		
			if (${$tempvec->{VERTEXLIST}}[0][2] != 0){
				$yRot += rad2deg(atan(${$tempvec->{VERTEXLIST}}[0][0] / ${$tempvec->{VERTEXLIST}}[0][2]));
			}elsif (${$tempvec->{VERTEXLIST}}[0][0] > 0){
				$yRot = 90;
			}elsif (${$tempvec->{VERTEXLIST}}[0][0] < 0){
				$yRot = -90;
			}
	
	
			$tempvec->rotate('y',-$yRot,0,0);				
	
			if (${$tempvec->{VERTEXLIST}}[0][2] != 0){
				$xRot = rad2deg(atan(${$tempvec->{VERTEXLIST}}[0][1] / ${$tempvec->{VERTEXLIST}}[0][2]))*-1;
			}elsif (${$tempvec->{VERTEXLIST}}[0][1] > 0){
				$xRot = -90;
			}elsif (${$tempvec->{VERTEXLIST}}[0][1] < 0){
				$xRot = 90;
			}
				
			$tempvec->rotate('x',-$xRot,0,0);
	
			if (${$tempvec->{VERTEXLIST}}[2][1] > 0){$zRot=180 ;}
	
			if (${$tempvec->{VERTEXLIST}}[1][0] != 0){
			 	$zRot +=  rad2deg(atan(${$tempvec->{VERTEXLIST}}[1][1] / ${$tempvec->{VERTEXLIST}}[1][0]));
			 }elsif (${$tempvec->{VERTEXLIST}}[1][1] > 0){
			 	$zRot = 90;
			 }elsif (${$tempvec->{VERTEXLIST}}[1][1] < 0){
			 	$zRot = -90;
		 }
			$tempvec->rotate('z',-$zRot,0,0);
			#print "$xRot,$yRot,$zRot\n";
		 return ($xRot,$yRot,$zRot,$tempvec);

}

sub _getFieldView
{

	# similar to getperspective but uses a field of view like an eye would work (from centre of screen)
	#basically we calculate how wide the cone of view is at a given distance and scale accordingly
	my $self = shift;
	my $obj = shift;
	my $hashkey = shift;
	
	my $eyez = $self->{CAMERA}[2];
	my $eyey = $self->{CAMERA}[1];
	my $eyex = $self->{CAMERA}[0]; 
	my @tempvl;
	my $tempobj = CanvasObject->new;

	#get object world coordinates
	for (my $i = 0; $i < @{$self->{$hashkey}[$obj]->{VERTEXLIST}} ; $i++)
	{
		$tempvl[$i] = [${$self->{$hashkey}[$obj]->{VERTEXLIST}}[$i][0],
				${$self->{$hashkey}[$obj]->{VERTEXLIST}}[$i][1],
				${$self->{$hashkey}[$obj]->{VERTEXLIST}}[$i][2]];
	}
	$tempobj->{VERTEXLIST}=\@tempvl;
	#move to camera
	$tempobj->translate(-$eyex,-$eyey,-$eyez);
		#apply camera orientation to object	
		$tempobj->rotate('y',-${$self->{TRANSFORMS}}[1],0,0);
		$tempobj->rotate('x',-${$self->{TRANSFORMS}}[0],0,0);
		$tempobj->rotate('z',-${$self->{TRANSFORMS}}[2],0,0);
		
	#move to original position
	$tempobj->translate($eyex,$eyey,$eyez);
	my @camVertList;

	for (my $i = 0 ; $i < @tempvl ; $i++)
	{
	
	
		#$camVertList[$i] = [0, 0,-1000]; #all points behind camera end up here, I can see this possibly being a problem
		#though in polygon mode as soon as a vertex gets < 0, checkBackFace treats it as a backface and the triangle isn't drawn
		
		#this also currently applies to pixel mode though, it might be nice for that to draw the visible part - would need this to give the actual coord for a point behind the camera
		#but generating the proper coord behind the camera is proving tricky!

		my $ref = _getCameraCoords($self,$tempvl[$i]);
		$camVertList[$i] = [$$ref[0],$$ref[1],$$ref[2]];

	}
	$tempobj=undef;
	return \@camVertList;


}

sub _getCameraCoords{
	my $self = shift;
	my $vl = shift;
	my $eyez = $self->{CAMERA}[2];
	my $eyey = $self->{CAMERA}[1];
	my $eyex = $self->{CAMERA}[0]; 
	
	my $viewangle = $self->{CAMERA_VIEW_ANGLE};
	my $dispheight = ${$self->{DISPLAY}}->Height;
	my $dispwidth = ${$self->{DISPLAY}}->Width;
	my $x = $$vl[0];
	my $y = $$vl[1];
	my $z = $$vl[2];
	my $zed = $z-$eyez;
	my @camVertList = (0,0,-1000);

		#change vertex position depending on where the camera is pointing and how far away it is
		$zed = 1 if ($zed < 1 && $zed >= 0);

		if ($zed < 0 && $self->{PXDRAW} == 1){ #point behind camera in pixel mode
			#get point if it was at z=1, get point if z=z*-1, add the difference to point at z=1
			my @zAt1 = ($x,$y,1);
			my @invZ = ($x,$y,$z*-1);
			my $camZat1 = _getCameraCoords($self,\@zAt1);
			my $camInvZ = _getCameraCoords($self,\@invZ);
			@camVertList = ($$camZat1[0]+($$camZat1[0]-$$camInvZ[0]),$$camZat1[1]+($$camZat1[1]-$$camInvZ[1]),$zed);
			
		}elsif ($zed < 0 && $self->{PXDRAW} == 0){
			#would have to find points where lines crossed z = 0 and use those, likely means building other triangles too
			#until then polygon mode triangles disppear as soon as one point is behind the camera
		}elsif ($zed > 0){
			my @vectortopoint = (($x-$eyex),($y-$eyey),$zed);
			_normalise(\@vectortopoint);
			my $angletopoint = atan($vectortopoint[0]/$vectortopoint[2]); #radians
			my $xunitsAtz = (tan(deg2rad($viewangle/2)) * $zed)*2;
			my $dx = (tan($angletopoint) *$zed);
	
			#y component
			$angletopoint = atan($vectortopoint[1]/$vectortopoint[2]); #radians
			my $dy = (tan($angletopoint) *$zed);
	
			my $scaling = $dispwidth/$xunitsAtz; #make sure using longest axis - it may be Y, though usually not likely
			$scaling = $dispheight/$xunitsAtz if ($dispheight > $dispwidth);
			my $cx = $dispwidth/2;
			my $cy = $dispheight/2;		

	
			@camVertList = ($cx+($dx*$scaling), $cy+($dy*$scaling),$zed);
		}
	return \@camVertList;
}


sub _checkBackFace
{
	my $self = shift;
	#these are transformed camera coords, not world coords
	my $a = shift;
	my $b = shift;
	my $c = shift;
	my $fovflag = shift;
	my $idno = shift;
	my $cvector = _getCameraVector($self);
	my $minz = 0;
	#my $maxz = 0;
	#$maxz = $$a[2] if ($$a[2] > $maxz);
	$minz = $$a[2] if ($$a[2] < $minz);
	#$maxz = $$b[2] if ($$b[2] > $maxz);
	$minz = $$b[2] if ($$b[2] < $minz);
	#$maxz = $$c[2] if ($$c[2] > $maxz);
	$minz = $$c[2] if ($$c[2] < $minz);

	#return 1 if (($minz+(($maxz-$minz)/2)) < -1); #average transformed z value of facet

	return 1 if ($minz < 0 && $self->{PXDRAW} == 0 ); #actually only need minz, if it is less than zero do not draw the facet

	return 1 if ($$a[2] < 1 && $$b[2] < 1 && $$c[2] < 1);
	#pixel mode in perspective mode draws fine, fov mode needs fixing
	#this can make an object disappear in polygon mode when most of it should still be visible, for polygon draw we would have to modify it (and it wouldn't be a triangle anymore
	
	my @normal = _getNormal($a,$b,$c);
	    #assumes camera vector 0,0,1 - dot product not required, return z value
	my $answer = $normal[2];
	if ($fovflag){
		#assumes method - camera will not be 0,0,1
		$$cvector[2]=$$cvector[2]*-1 if ($$cvector[2] < 0);
		$answer = ($normal[2]*$$cvector[2]);
	}

    return $answer;
 }
 
 

 sub _getShade
 {
  	my $self = shift;
	my $a = shift;
	my $b = shift;
	my $c = shift;
	my $obj = shift;
	my $centre = shift;
	my $shade = shift;
	my $numberonly = shift;
	
	my @normal = _getNormal($a,$b,$c);
	my ($colourdec,$percent) = _getColourIntensity($self,$obj,\@normal,$centre);
	
	return ($colourdec,$percent) if ($numberonly);
	
	return _getColourString($colourdec,$shade,$percent,$self,$obj);
 }
 sub _getColourIntensity
 {
 	my $self = shift;
	my $obj = shift;
	my $n = shift;
	my $centre = shift;
	my @normal = @$n;
 	 #get vector to centre of object (simple shading - whole polygon has to shaded the same colour)
 
 	my @lightsource ;
 	if (scalar @{$self->{LIGHTSOURCE}} > 0){
 		@lightsource = @{$self->{LIGHTSOURCE}};
 	}else{
 		#lightsource is the camera
 		@lightsource = @{$self->{CAMERA}};
 	}
 	my @lightvector = ($$centre[0] - $lightsource[0],$$centre[1]-$lightsource[1],$$centre[2]-$lightsource[2]);			
 	#normalise - unit vector
 	_normalise(\@lightvector);
 				
 	
 	#dot product - same as adj/hyp if in ra triangle - angle between vectors - when inverse cos'd 
 	my $answer = ($normal[0]*$lightvector[0])+($normal[1]*$lightvector[1])+($normal[2]*$lightvector[2]);
 	
	my $deg;
	my $percent = 0;
  	my $colourdec = 90;

  	#answer above 0 faces away from light (vectors heading in same direction in z plane)
	if ($answer < 0){
		#acos returns in radians
 		$deg = rad2deg(acos($answer));
 		#at 180 degrees face is directly facing light source
 		#anything below 90 is out of the light (and $answer would have been positive)
 		$percent = ($deg-90)/90;
  		$colourdec = int(90+(165*$percent));
 
  	}
  	return ($colourdec,$percent);
  	
  }
  
  sub _getColourString
  {
  	my $colourdec = shift;
  	my $shade = shift;
  	my $percent=shift;
  	my $self = shift;
	my $obj = shift;

  	if (! $shade){
		$shade =  $self->{SHAPES}[$obj]->{SHADE};
  	}
  	my $colourhex = dec2hex($colourdec);

  	my $colour = "#".$colourhex."2222";
  	if ($shade eq 'green'){
  		$colour = "#22".$colourhex."22";
  	}
  	elsif ($shade eq 'white'){
  		$colour = "#".$colourhex.$colourhex.$colourhex;
  	}
    	elsif ($shade eq 'blue'){
    		$colour = "#2222".$colourhex;
  	}
  	elsif ($shade eq 'yellow'){
		$colour = "#".$colourhex.$colourhex."22";
  	}
  	 elsif ($shade eq 'magenta'){
			$colour = "#".$colourhex."22".$colourhex;
  	}
  	 elsif ($shade eq 'cyan'){
			$colour = "#22".$colourhex.$colourhex;
  	}elsif ($shade =~ m/^\#(.{2})(.{2})(.{2})$/){
  		$percent = 0.15 if ($percent < 0.15);
  		my $r = int(hex($1)*$percent);
  		my $g = int(hex($2)*$percent);
  		my $b = int(hex($3)*$percent);
  		$colour = "#".dec2hex($r).dec2hex($g).dec2hex($b);
  	
  	}
  	
  	return $colour;
 }
 
 
 sub collisionCheck_object
 {
 	my $self=shift;
 	my $obj1 = shift;
 	my $obj2 = shift;
 	my $points = $self->{SHAPES}[$obj1]->{VERTEXLIST}; #possibly don't want to check all points if something where a complex shape with lots of them
 	for (my $i = 0; $i < @$points ; $i++){
 		my @point = ($$points[$i][0],$$points[$i][1],$$points[$i][2]);
 		my $col = $self->{SHAPES}[$obj2]->pointInsideObject(\@point);
 		return $col if ($col > 0);
 	}
 	return 0;
 }
 
 sub collisionCheck_point
 {
  	my $self=shift;
 	my $point = shift;
 	my $obj = shift;
 	my $col = $self->{SHAPES}[$obj]->pointInsideObject($point);
 	return $col;
 }
 
 
 sub _updateWindow{
 	my $self = shift;
 	
 		
 	if ($self->{MW}  != 0 && defined($self->{MW})){
 		${$self->{MW}}->update;
 	}
 	# else client program is reponsible for updating
 }


return 1;




