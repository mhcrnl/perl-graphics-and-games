use Tk;
use Tk::DialogBox;
use Math::Trig;
use Host;
use Client;
use strict;

$SIG{INT}=\&endit;
$SIG{TERM}=\&endit;
$|=1;
our $mw = MainWindow->new;
$mw->OnDestroy([\&endit]);
our $cx = 800;
our $cy = 600;
our $sealevel = 500;
our $velocity = 20;
our $angle = 0;
our $gravity = 9.8; 
our $drag = 0.2;
our $fire = 0;
our $wind = 0;
our $isHost = 0;
our $isClient = 0;
our $isAlone = 0;
our $comms = undef;
our $parent = $$;
our $tag = 'gun1';
our $yourgo = 1;
our %wall;
our $end = 0;
our $cnv = $mw->Canvas(-width=>$cx, -height =>$cy, -borderwidth=>0, -background=>'black')->pack();

$mw->bind('<space>'=>[\&firepress]);
$mw->bind('<KeyRelease-space>'=>[\&firerelease]);
#$mw->bind('<Return>'=>[\&ready]);
$mw->bind('<d>'=>[\&dkeydown]);
$mw->bind('<a>'=>[\&akeydown]);
$mw->bind('<w>'=>[\&wkeydown]);
$mw->bind('<s>'=>[\&skeydown]);

$mw->bind('<D>'=>[\&dkeydown]);
$mw->bind('<A>'=>[\&akeydown]);
$mw->bind('<W>'=>[\&wkeydown]);
$mw->bind('<S>'=>[\&skeydown]);

$mw->bind('<r>'=>[\&reset]);
$mw->bind('<R>'=>[\&reset]);

$mw->bind('<n>'=>[\&newgame]);
$mw->bind('<N>'=>[\&newgame]);

$mw->update;

_setComms();
_initial();


MainLoop;

sub _setComms
{
	my $dialog = $mw->DialogBox(-title=>'Mode', -buttons=>['Host','Connect','Standalone']);
	$dialog->add('Label', -text=>'Host a game or connect to another?')->pack;
	my $result = $dialog->Show;
	if ($result eq 'Host'){
		$isHost = 1;
		$cnv->createText(50,50,-text=>'Waiting for Challenger', -anchor=>'w', -font=>'{Arial Bold} 14', -fill=>'white', -tags=>'notice');
		$mw->update;
		$comms = Host->new();
		my $pid = fork();
		
		if (! $pid){ #I hate not having ALRM on windows, wouldn't have to do crap like this then
			sleep 20;
			kill("KILL",$parent);
			exit 0;
		}else{
			$comms->accept();
			kill("KILL",$pid);
			print "Connected\n";
			sleep 1;
		}
		$cnv->delete('notice');
		
	}elsif ($result eq 'Connect'){
		$dialog = $mw->DialogBox(-title=>'Mode', -buttons=>['Connect']);
		$dialog->add('Label', -text=>'Enter Server IP or Hostname')->pack;
		my $ip = $dialog->add('Entry', -width=>30)->pack;
		$result = $dialog->Show;
		if ($result eq 'Connect'){
			$isClient = 1;
			$comms = Client->new();
			if ($comms->connect($ip->get))
			{
				print "Connected\n";
			}else{
				print "Not Connected\n";
				$comms = undef;
				$cnv->createText(50,50,-text=>'Could not connect', -anchor=>'w', -font=>'{Arial Bold} 14', -fill=>'white', -tags=>'notice');
			}
		}
		
	}else{
		print "Standalone\n";
		$isAlone = 1;
	}
}

sub _initial
{
	$fire = 0;
	$cnv->createRectangle(0,$sealevel,$cx,$cy, -fill=>'brown', -outline=>'brown',, -tags=>'ground');
	$cnv->createArc(50,$sealevel-20,90,$sealevel+20, -extent=>-270, -fill=>'yellow', -tags=>'gun1');
	$cnv->createLine($cx/2, 40, $cx/2, 60, -fill=>'red');
	#$cnv->createRectangle(($cx/2)-5, $sealevel-150, ($cx/2)+5, $sealevel, -fill=>'gray', -tags=>'wall');
	_pixelwall();
	$cnv->createArc($cx-90,$sealevel-20,$cx-50,$sealevel+20, -start=>180, -extent=>270, -fill=>'orange', -tags=>'gun2');
	$cnv->createText(50,550,-text=>'POWER: 0', -anchor=>'w', -font=>'{Arial Bold} 14', -fill=>'white', -tags=>'power');
	$angle=89;
	if ($isClient){
		$tag = 'gun2';
		$yourgo = 0;
		#$yourgo = 1; #for test
		$mw->update;
		_waitForMessages();
	}elsif($isHost){
		_generateWind();
		$mw->update;
		_heartbeat();
		#$mw->update;
	}else{
		$tag = 'gun1';
		_generateWind();
		$mw->update;
	}
	
}

sub _pixelwall
{
	$cnv->delete('wall');
	for (my $y = $sealevel ; $y > $sealevel-151 ; $y-=2){
		for (my $j = 0 ; $j <10 ; $j+=2){
			my $x=$cx/2-5+$j;
			my $id = "wall$x:$y";
			$wall{$y}{$x}=$cnv->createRectangle($x,$y,$x,$y, -fill=>'gray', -outline=>'gray', -width=>0, -tags=>$id);
			#annoyingly a pixel is 4 pixels as I cannot get it to draw without an outline
		}
		
	}
}

sub _waitForMessages
{
	return if (! defined($comms));

	while(1){
		my $message = $comms->getMessage();
		chomp($message);
		if ($message eq "NoCon"){
			#lost connection, deal with it
			reset();
			last;
		}elsif ($message eq "EndTurn"){
			$yourgo = 1;
			ready();
			last;
		}elsif ($message =~ m/right:(.+)/){
			my ($x, $y, $x1, $y1) = $cnv->coords($1);
			$cnv->coords($1,$x+1, $y, $x1+1, $y1);
		}elsif ($message =~ m/left:(.+)/){
			my ($x, $y, $x1, $y1) = $cnv->coords($1);
			$cnv->coords($1,$x-1, $y, $x1-1, $y1);
		}elsif ($message =~ m/up:(.+)/){
			my $ext = $cnv->itemcget($1,-extent);
			$cnv->itemconfigure($1,-extent=>$ext+1) if ($1 eq "gun1");
			$cnv->itemconfigure($1,-extent=>$ext-1) if ($1 eq "gun2");
		}elsif ($message =~ m/down:(.+)/){
			my $ext = $cnv->itemcget($1,-extent);
			$cnv->itemconfigure($1,-extent=>$ext-1) if ($1 eq "gun1");
			$cnv->itemconfigure($1,-extent=>$ext+1) if ($1 eq "gun2");
		}elsif ($message =~ m/wind:(.+)/){
			_generateWind($1);
		}elsif ($message =~ m/fire:(.+):(\d+):(\d+)/){
			my $ret = _fire($1,$2,$3);
			if ($ret == 1){
				$message = $comms->getMessage();
				chomp($message);
				if ($message eq "newgame"){
					newgame();
				}else{
					reset();
				}
				last;
			}
		}
		$mw->update();
	}

}


sub _heartbeat
{
	#periodically send heartbeat signal, allows client to update itself
	#and respond to any user events as it can't whilst listening to socket
	#and can't free itself as can't use ALRM
	
	#update - could use canRead/canWrite functions
	my $t = time();
	while ($yourgo == 1){
		if ((time() - $t) == 2){
		$t = time();
		$comms->sendMessage("hb") if ($end == 0 && defined($comms));
		}
		$mw->update if($end == 0);
		select (undef, undef, undef, 0.01);
	}
}

sub dkeydown
{
	return if ($yourgo == 0);
	#go right
	my ($x, $y, $x1, $y1) = $cnv->coords($tag);
	if (($tag eq "gun1" && $x1 < $cx/2) || ($tag eq "gun2" && $x1 < $cx)){
		$x++;
		$x1++;
		$cnv->coords($tag,$x, $y, $x1, $y1);
		$comms->sendMessage("right:$tag") if (! $isAlone);
	}
	$mw->update;

}

sub akeydown
{
	return if ($yourgo == 0);
	#go left
	my ($x, $y, $x1, $y1) = $cnv->coords($tag);
	if (($tag eq "gun1" && $x > 0) || ($tag eq "gun2" && $x > $cx/2)){
		$x--;
		$x1--;
		$cnv->coords($tag,$x, $y, $x1, $y1);
		$comms->sendMessage("left:$tag") if (! $isAlone);
	}
	$mw->update;
}
sub wkeydown
{
	return if ($yourgo == 0);
	#increase firing angle
	if ($angle < 89){
		$angle++;
		my $a = $angle - 360;
		$a=$a*-1 if ($tag eq "gun2");
		$cnv->itemconfigure($tag,-extent=>$a);
		$comms->sendMessage("up:$tag") if (! $isAlone);
	}
	$mw->update;
}
sub skeydown
{
	return if ($yourgo == 0);
	#decrease firing angle
	if ($angle > 1){
		$angle--;
		my $a = $angle - 360;
		$a=$a*-1 if ($tag eq "gun2");
		$cnv->itemconfigure($tag,-extent=>$a);
		$comms->sendMessage("down:$tag") if (! $isAlone);
	}
	$mw->update;
}


sub newgame
{
	$cnv->delete('all');
	$comms->sendMessage("newgame") if($isHost);
	_initial();
}

sub reset
{
	$cnv->delete('all');
	$comms->closecon() if (defined($comms));
	$comms=undef;
	_setComms();
	_initial();
}

sub ready
{
	$fire = 0 if ($fire == 2);
 	_generateWind();
 	_heartbeat() if (! $isAlone);
 	$mw->update;
}

sub firepress
{
	return if ($yourgo == 0);
	#build power while pressed
	$mw->update;
	if ($fire == 0){
		if ($velocity < 120){
		select (undef, undef, undef, 0.01);
		$velocity++;
		my $text = "POWER: $velocity";
		$cnv->itemconfigure('power',-text=>$text);
		_showPara();
		$mw->update;
		}
	}
}

sub firerelease
{
	return if ($yourgo == 0);
	if ($fire == 0){
		$fire = 1;
		$yourgo = 0 if (! $isAlone);
		my $ret = _fire();
		$fire = 2;
		$velocity = 20;
		$cnv->itemconfigure('power',-text=>"POWER: 0");
		$cnv->delete('para');
		$mw->update;
		if (! $isAlone) {
		if ($ret == 0){
			$comms->sendMessage("EndTurn");
			_waitForMessages();
		}
		}else{
			$tag = ($tag eq "gun1") ? "gun2" : "gun1";
			ready();
		}
	}
}


sub _generateWind
{
	$wind = shift;
	$wind = rand(4)-2 if (! $wind);
	$drag = 0.2;
	#$drag = 0;
	#$wind = 0;
	$cnv->delete('windsock');
	$cnv->createLine($cx/2,50, $cx/2+($wind*40), 50, -width=>5, -fill=>'blue', -arrow=>'last', -tags=>'windsock');
	$comms->sendMessage("wind:$wind") if ($yourgo == 1 && $isAlone == 0);
}


sub _showPara{
	#show parabolic projection of shot, can be used as an aiming aid
	#does not include wind and drag
	$cnv->delete('para');
	my $vx = cos(deg2rad($angle))*$velocity; #horizontal start velocity
	my $vy = sin(deg2rad($angle))*$velocity; #vertical start velocity
	my $time = 0;
	my ($x, $y, $x1, $y1) = $cnv->coords($tag);
	$x = $x+20;
	$y = $sealevel;
	my $startx = $x;
	while ($y < $sealevel+1){ 
		$cnv->createRectangle($x-1,$y-1,$x+1,$y+1, -fill=>'magenta', -outline=>'magenta', -tags=>'para');
		
		$x = ($vx*$time);
		 $x+=$startx if ($tag eq "gun1");
		 $x = $startx-$x if ($tag eq "gun2");
		$y = $sealevel - (($vy*$time) - ($gravity*($time*$time))/2);
		$time+=0.5;
	}
	$mw->update;
	
	#my $paraheight = ($vy*$vy)/(2*$gravity);
	#my $range = (2*$vx*$vy)/$gravity;
	#$range=$range*-1 if ($tag eq "gun2");
	#$cnv->createOval($x, $sealevel-$paraheight, $x+$range, $sealevel+$paraheight, -outline=>'magenta', tags=>'para');
	#though this curve isn't actually parabolic - has steeper curves as it starts at 90 degree angle
	
	#$cnv->lower('para','ground');
	
	
}

sub _fire
{
		my $mytag = shift;
		my $myangle = shift;
		my $myvelocity = shift;
		if (! $mytag){
			$mytag = $tag;
			$myangle = $angle;
			$myvelocity = $velocity;
			$comms->sendMessage("fire:$tag:$angle:$velocity") if(! $isAlone);
		}
		my ($x, $y, $x1, $y1) = $cnv->coords($mytag);
		$x = $x+20;
		$y = $sealevel;
		my $startx = $x;
		my $ret = 0;
		#print "$x,$y\n";
		my $shell = $cnv->createRectangle($x-1,$y-1,$x+1,$y+1, -fill=>'white', -outline=>'white');
		my $vx = cos(deg2rad($myangle))*$myvelocity; #horizontal start velocity
		my $vy = sin(deg2rad($myangle))*$myvelocity; #vertical start velocity
		my $time = 0;
		my $lx=0;
		$lx = $startx if ($mytag eq "gun2");
		my $maxh = 0;
		my $ttime = 0;
		my $dlock = 0;
		my $comingdown = 0;
		my $paraheight = ($vy*$vy)/(2*$gravity);
		$wind=$wind*-1 if ($mytag eq "gun2");
		$drag=$drag*-1 if ($mytag eq "gun2");
		while ($y < $sealevel+1){ 
			my $d=($drag*($time*$time))/2;
			$x = (($vx+($wind*$time))*$time);
			$x+=$startx if ($mytag eq "gun1");
			$x = $startx - $x if ($mytag eq "gun2");
			if (($mytag eq "gun1" && $x - $d > $lx) || ($mytag eq "gun2" && $x + $d < $lx)){		
				$x = $x - $d if($mytag eq "gun1");
				$x = $x + $d if($mytag eq "gun2");
			}elsif(($mytag eq "gun1" && $x - $d <= $lx) || ($mytag eq "gun2" && $x + $d >= $lx)){
				$x = $lx + $wind if($mytag eq "gun1");
				$x = $lx - $wind if($mytag eq "gun2");
			}
			$lx = $x;
			my $height = (($vy*$time) - ($gravity*($time*$time))/2);
			my $fraction = -1;
			if ($paraheight-$height < 50){
				$fraction = (50+($paraheight-$height))/100;
				$d=$d*$fraction
			}
			if ($height-$d >= $maxh){ #act with gravity
				$maxh = $height-$d;
				$height = $maxh;
				$dlock = $d;
			}else{
				#act against gravity
				$d=($drag*($ttime*$ttime))/2;
				$d=$d*$fraction if ($fraction>-1);
				$height=$height-$dlock+$d;
				$comingdown = 1;
				$ttime+=0.1;
			}
			$y = $sealevel - $height;
			$time+=0.1;
			#print "$x,$y\n";
			$cnv->coords($shell, $x-1,$y-1,$x+1,$y+1);
			$mw->update;
			select (undef, undef, undef, 0.001); #accelerated draw rate not true time (cut boredom)
			#select (undef, undef, undef, 0.01);
			my @keys = $cnv->find('overlapping', $x-1, $y-1, $x+1, $y+1); 
			my $exit = 0;
			foreach(@keys){
				if(${$cnv->itemcget($_, -tags)}[0] =~ m/gun\d/ && $comingdown == 1){
					#DEAD!!
					$cnv->delete($_);
					$ret = 1;
					$exit = 1;
				}elsif(${$cnv->itemcget($_, -tags)}[0] =~ m/wall(\d+):(\d+)/){
					#hit wall
					$cnv->delete($_);
					$wall{$2}{$1} = undef;
					delete $wall{$2}{$1};
					$exit = 1;
				}
			}
			last if ($exit == 1);
		}
		$cnv->delete($shell);
		return $ret;
		
		

}

sub endit
{
	print "Escaping\n";
		$end = 1;
		$comms->closecon() if (defined($comms));
		$comms=undef;
		exit 0;
		
}
