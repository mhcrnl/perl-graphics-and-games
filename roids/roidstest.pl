use lib '..\perllib';
use Tk;
use Tk::JPEG;
use Ship;
use Bullet;
use Shockwave; 
use Roid;
use Alien;
use Drone;
use SoundServer;
use Music;
use HeatMeter;
use Configure;
use Image::Magick;
use GamesLib;
use LineEq;
use Math::Trig;
use Whale3D;
use ThreeDCubesTest;
use strict;

our $mainw = MainWindow->new(-background=>'black');
my $g = ($mainw->screenwidth()-5)."x".($mainw->screenheight()-50)."+0+0";
$mainw->geometry($g);
our $cy = $mainw->screenheight()-175;
our $cx = $mainw->screenwidth()-45;
my $f = $mainw->Frame(-background=>'black')->pack(-fill=>'both');
my $mcnv = $f->Canvas(-height=>$cy+20, -background=>'black')->pack(-fill=>'both');
$mcnv->createText($cx/2, $cy/2, -text=>'Loading, Please Wait ...', -font=>'{Arial Bold} 16',-fill=>'white');
_createStars(\$mcnv);
$mainw->update;
our $mw;
our $cnv;
our $cframe;

our $level = 1;
our $heat;
our @bullets;
our $roundType;
our %roids;
keys(%roids) = 50;
our $rotangle;
our $go =0;
our $score;
our $lastfire;
our $fire;
our $checkroids;
our $bomb;
our $pausetime;
our $alien=undef;
our $drone=undef;
our $momx;
our $momy;
our @bloom;
our @exhaust;
our $cntl;
our $conf=undef;
our $crystal=-1;
our $tdc=undef;
our $spacewhale=undef;
our $shipangle=0;
our $adown = 0;
our $ddown = 0;


	#start listeners on ports to listen for sound events
	#sound must come from different separate processes (with Win32::Sound) to play sound in parallel, otherwise it waits for the previous sound to finish
	#can start a new process for each sound, but this has more of an overhead over this method (sound is delayed more)
	#cannot use fork - windows is pseudo-fork, OS treats all forked processes as a single process
	our $sound = SoundServer->new(11);
	our $music = Music->new();
	our @specials = (\&_invuln, \&_triplefire, \&_newbomb, \&_incROF, \&_apRounds, \&_exRounds, \&_shockwave, \&_blinky);
	our @onScreenActions = (sub{}, sub{},sub{}, sub{},sub{}, sub{},sub{}, \&_blinkyOnScreen);
	our @specialactions = (\&_doinvuln, \&_dotriplefire, \&_collectbomb, \&_doincROF, \&_doapRounds, \&_doexRounds, \&_doshockwave, \&_doBlinky, \&_doReverse, \&_doSlow, \&_doFast, \&_doLoseGun, \&_doTurnRate);
	our @specialends = (\&_endinvuln, sub{}, sub{}, \&_endincROF, \&_endRounds, \&_endRounds, \&_endshockwave,sub{}, \&_endReverse, \&_endSpeedMod, \&_endSpeedMod, \&_endLoseGun, \&_endTurnRate);
	our $specialavailable;
	our $specialactive;
	our $specialstarttime;
	our $ship = undef;
	our $dontEnd = 0;
	
	#resize backdrop image to display size
	if (-f 'horseheadx.jpg'){
		my $img = new Image::Magick;
		$img->Read('horseheadx.jpg');
		my $screenratio = $cx/$cy;
		my $backratio = $img->Get('height') / $img->Get('width');
		if ($backratio <= $screenratio){
			#y is longer in image than screen
			$img->Resize('geometry' => $cx);		
		}elsif($backratio > $screenratio){
			#x / width greater in image
			$img->Resize('geometry' => $cy);
		}
		 #resize keeps original ratios  
		 #this does not
		  # $img->Scale('height' => $cy, 'width'=>$cx);
	  

		$img->Write('backdrop.jpg');
	}else{
		print "Backdrop file missing\n";
	}


_buildTopLevel();
$mainw->withdraw();
$mw->focusForce;
MainLoop;

sub _buildTopLevel
{

	$mw = $mainw->Toplevel(-class=>'Roids');
	$mw->OnDestroy([\&endit]);
	$mw->bind('<Control-c>'=>[\&endit]);
	my @lightsource = (int($cx/2), int($cy/2), -1000);
	
	my $menuframe = $mw->Frame(-borderwidth=>2, -background=>'brown')->pack(-side=>'top', -fill=>'x');
	my $userframe = $mw->Frame(-borderwidth=>2, -background=>'black')->pack(-fill=>'x');
	my $confmenu = $menuframe->Menubutton(-text=>'Configure', -relief=>'raised')->pack(-side=>'left');
	$confmenu->command(-label=>'Ship',-command=>[\&confShip], -accelerator=>'Ctrl-S');
	$mw->bind('<Control-s>'=>[\&confShip]);
	my $toolmenu = $menuframe->Menubutton(-text=>'Help', -relief=>'raised')->pack(-side=>'left');
	$toolmenu->command(-label=>'Instructions',-command=>[\&dispInstructions]);
	$toolmenu->command(-label=>'High Scores',-command=>[\&highscore]);
	$mw->bind($confmenu,'<Enter>', sub{$confmenu->configure(-relief=>'sunken');});
	$mw->bind($confmenu,'<Leave>', sub{$confmenu->configure(-relief=>'raised');});
	$mw->bind($toolmenu,'<Enter>', sub{$toolmenu->configure(-relief=>'sunken');});
	$mw->bind($toolmenu,'<Leave>', sub{$toolmenu->configure(-relief=>'raised');});
	my $g = ($mw->screenwidth()-5)."x".($mw->screenheight()-50)."+0+2"; #reduce height for windows bar and borders
	$mw->geometry($g);
	$mw->resizable(0,0);
	$cnv = $userframe->Canvas(-width=>$cx, -height =>$cy, -borderwidth=>0, -background=>'black')->pack(-side=>'left');
	$mw->update; #needed for $canvas->Height to work
	$tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource);
	if (! defined($ship)){
		$ship = Ship->new(\$cnv, 3, 1, 0.3, 8, 5, 0, 0);
		$ship->setColour('red');

	}
	
	
	my $sideframe = $userframe->Frame(-borderwidth=>0, -background=>'black')->pack(-side=>'right', -anchor=>'s');
	$cframe = $sideframe->Frame(-borderwidth=>0, -background=>'black', -height=>30)->pack(-fill=>'x', -pady=>20);
	my $bombframe = $sideframe->Frame(-borderwidth=>1, -background=>'white')->pack;
	$bombframe->Label(-text=>"Bomb", -background=>'black',-foreground=>'white', -anchor=>'w',-borderwidth=>0)->pack(-fill=>'x');
	$bombframe->Label(-textvariable=>\$ship->{bomb}, -background=>'black',-foreground=>'white', -anchor=>'w', -borderwidth=>0, -padx=>5)->pack(-fill=>'x');
	$sideframe->Label(-text=>"", -background=>'black', -borderwidth=>0, -pady=>10)->pack;
	my $hcnv = $sideframe->Canvas(-width=>30, -height =>300, -borderwidth=>0, -background=>'black')->pack;
	$heat = HeatMeter->new(\$hcnv,0.97);
	if (-f 'backdrop.jpg' && ! defined($mw->imageNames)){
		$mw->Photo('backdrop', -format => 'jpeg', -file => 'backdrop.jpg');
	}
	if (defined($mw->imageNames) && @{$mw->imageNames} > 0){
		$cnv->createImage($cx/2,$cy/2, -image=>'backdrop', -anchor=>'center');
	}
	my $tempx = int(($cx+30)/2);
	my $ctlf = $mw->Frame(-width=>$tempx, -height=>100, -background => 'black', -borderwidth=>2)->pack;
	$cntl = $ctlf->Canvas(-width=>$tempx, -height =>67, -background => 'black')->grid(-column=>0, -row=>0, -pady=>0);
	$ctlf->Scale(-orient=>'horizontal',-from=>1,-to=>8,-tickinterval=>1,-background=>'black', -foreground=>'white', -length=>$tempx-5, -width=>10,
			-label=>'Level',-variable=>\$level)->grid(-column=>1, -row=>0, -pady=>0);
	$mw->bind('<Return>'=>[\&go]);
	$mw->bind('<space>'=>[\&firepress]);
	$mw->bind('<KeyRelease-space>'=>[\&firerelease]);
	$mw->bind('<p>'=>[\&stop]);
	$mw->bind('<d>'=>[\&dkeydown]);
	$mw->bind('<KeyRelease-d>'=>[\&dkeyup]);
	$mw->bind('<a>'=>[\&akeydown]);
	$mw->bind('<KeyRelease-a>'=>[\&akeyup]);
	$mw->bind('<w>'=>[\&wkeydown]);
	$mw->bind('<KeyRelease-w>'=>[\&wkeyup]);
	$mw->bind('<s>'=>[\&skeydown]);
	$mw->bind('<KeyRelease-s>'=>[\&skeyup]);
	$mw->bind('<b>'=>[\&useBomb]);
	$mw->bind('<c>'=>[\&useCrystal]);
	
	$mw->bind('<P>'=>[\&stop]);
	$mw->bind('<D>'=>[\&dkeydown]);
	$mw->bind('<KeyRelease-D>'=>[\&dkeyup]);
	$mw->bind('<A>'=>[\&akeydown]);
	$mw->bind('<KeyRelease-A>'=>[\&akeyup]);
	$mw->bind('<W>'=>[\&wkeydown]);
	$mw->bind('<KeyRelease-W>'=>[\&wkeyup]);
	$mw->bind('<S>'=>[\&skeydown]);
	$mw->bind('<KeyRelease-S>'=>[\&skeyup]);
	$mw->bind('<B>'=>[\&useBomb]);
	$mw->bind('<C>'=>[\&useCrystal]);
	$mw->bind('<FocusOut>'=>[\&focusOut]);
	$mw->bind('<FocusIn>'=>[\&focusIn]);
	
	$cntl->createText(10, 33, -text=>'SCORE:', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white');
	$cntl->createText(75, 33, -text=>$score, -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'scoretext');
	$cntl->createText(150, 33, -text=>'ALIVE', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'green', -tags=>'deadtext');
	$cntl->createText(225, 33, -text=>'NORMAL', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'specialtext');
	$cntl->createText(350, 33, -text=>'0', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'countdown');


	_resetShip();
	#_draw('ship',$ship);
}

sub dispInstructions
{
	my $class = 'Instructions';
	if (_checkChildren($class)){
		my $w=$mw->Toplevel(-class=>$class);
		my $g = "450x400+100+100";
		$w->geometry($g);
		$w->resizable(0,0);
		my @lines;
		push(@lines,'');
		push(@lines,"Written by: Paul Brandon (Rights Doubtful!)");
		push(@lines,'');
		push(@lines,"Version 0.5 - 31/10/2012");
		push(@lines,'');
		push(@lines,"A mining accident has disturbed the Asteroid belt, and roids are being");
		push(@lines,"thrown all over the place. Unlucky for you, you\'re stuck in the middle of it");
		push(@lines,"Destroy the Asteroids before they destroy you!");
		push(@lines,'');
		push(@lines,"Return\t - Start/Unpause/Reset Game");
		push(@lines,"P\t - Pause Game");
		push(@lines,"W\t - Move Forward");
		#push(@lines,"S\t - Move Back"); not implemented
		push(@lines,"A\t - Rotate Left");
		push(@lines,"D\t - Rotate Right");
		push(@lines,"Space\t - Fire");
		push(@lines,"B\t - Drop Bomb (Start with 2, can\'t use when invulnerable!)");
		push(@lines,'');
		push(@lines,'Bomb scores 1 point*level on each roid no matter what it is.');
		push(@lines,'Larger roids are not split (as they are vapourised by the bomb');
		push(@lines,'');
		push(@lines,"Level selector can be changed any time using the mouse");
		push(@lines,"The effect is instant even if in the middle of a game.");
		push(@lines,'');
		push(@lines,"Giant Asteroid  = 1pt (Splits to 2 Large Asteroids)");
		push(@lines,"Large Asteroid  = 1pt (Splits to 2 Small Asteroids)");
		push(@lines,"Small Asteroid = 2pts");
		push(@lines,"Dark Roid = 10pts (Tougher to destroy, does not split)");
		push(@lines,"Level Acts as a multiplier on points");
		push(@lines,'');
		push(@lines,'Nearby aliens with a warped sense of humour may also turn up, to make your');
		push(@lines,'predicament a little more interesting with a missile barrage.');
		push(@lines,'Wipe the smile off their tentacles for 150 pts.');
		push(@lines,' N.B. Bomb does not affect them and requires several hits to destroy');
		push(@lines,' N.B.2 Different colour missiles have different effects e.g. Red = Death');
		push(@lines,'');
		push(@lines,'Beware Berserker Drones!');
		push(@lines,'');
		push(@lines,'And! Don\'t hurt Space Whales, or much pain will ensue!');
		push(@lines,'(They can only be hurt once travelling across the screen)');
		push(@lines,'');
		push(@lines,'Special Pickups stay onscreen for 10 seconds, effects last 20');
		push(@lines,'3 - Three Way Firing');
		push(@lines,'I - Invulnerability');
		push(@lines,'R - Increase rate of fire');
		push(@lines,'P - Piercing Rounds (Keeps going, makes shorter work of dark roids. Not with Uber Ray)');
		push(@lines,'X - Explosive Rounds (Explodes near asteroids. Not with Uber Ray)');
		push(@lines,'S - Shockwave (Asteroid Miners\' best friend. Alien not affected)');
		push(@lines,'B - Replenish bomb (can\'t have more than 2 - does not appear if you have 2)');
		push(@lines,'');
		push(@lines,'Heat Meter:');
		push(@lines,'Every time you fire you produce heat, if the next shot takes you over 100% it will not fire');
		push(@lines,'Heat dissipates over time');
		push(@lines,'Heat production is affected by what you have fitted to your ship');
		push(@lines,'N.B. Bomb uses 33% of capacity');
		push(@lines,'');
		push(@lines,'Thanks to author planetjazzbass on Looperman.com for the Ambient loops');
		push(@lines,'Sound effects from Worms 2');
		push(@lines,'Music for gates side game from the X2/X3 games by Egosoft');
		#require Tk::Pane;
		#my $sf = $w->Scrolled('Frame', -width=>420, -height =>400, -highlightbackground=>'black',-scrollbars=>'e')->pack(-side=>'left');
		#scrolled frame on vista plus activeperl 5.10, but not on XP activeperl 5.6, safer to use canvas
		my $sf = $w->Scrolled('Canvas', -width=>450, -height =>400, -highlightbackground=>'black', -background=>'#E7FFC2', -scrollbars=>'e')->pack(-side=>'left');
		
		my $y = 5;
		foreach (@lines)
		{
			#$sf->Label(-text=>$_, -width=>70, -background=>'#E7FFC2', -anchor=>'w', -padx=>5)->pack(-anchor=>'w');
			$sf->createText(5,$y, -text=>$_, -anchor=>'w');
			$y+=15;
		}
		$y+=20;
		$sf->configure(-scrollregion=>"0 0 450 $y");
	}
}

sub focusIn
{
	if ($go == -1){
		go();
	}
}

sub focusOut
{
	#pause if game playing
	if ($go == 1){
		stop();
		$go = -1; #override to -1 to indicate pause on lost focus for when focus is regained, go function treats it the same as 0
	}
	
}


sub confShip
{
	my $class = 'Configure';
	if (_checkChildren($class)){
		$go = 2 if ($go == 1);
		my $w=$mw->Toplevel(-class=>$class);
		my $g = "680x450+100+100";
		$w->geometry($g);
		$w->resizable(0,0);
		if (! defined($conf)){
			$conf = Configure->new(\$w);
		}else{
			$conf->renew(\$w);
		}
		$w->waitWindow;
		$ship->setStats($conf);

		clear(0);
	}
}

sub _checkChildren
{
	my $class = shift;
	my $del = shift;
	#is sub-window already open, if so focus it
	my @c = grep{$_->class eq $class}$mw->children;
	if (@c > 0){
		if (! $del){
			$c[0]->deiconify if ($c[0]->state ne "normal");
			$c[0]->focus;
			
		}else{
			$c[0]->destroy;
		}
		return 0;
	}
	return 1;
}

sub _resetShip
{
	my $height = 60;
	my $width = 40;
	my @focuspoint = (int($cx/2),int($cy/2),1500);
	$tdc->removeObject($ship->{ID}) if ($ship->{ID} > -1);
	$ship->resetStats();
	$rotangle = 0;
	$ship->{thrust} = 0;
	$score = 0;
	$lastfire = 0;
	$fire = 0;
	$checkroids = 1;
	$bomb = 0;
	$alien=undef;
	$drone=undef;
	$specialavailable = -1;
	$specialactive = 0;
	$specialstarttime = 0;
	$pausetime = 0;
	$roundType = 'STD';
	#$roundType = 5;
	$roundType = 'BEAM' if ($ship->{guntype} == 2);
	@bloom = ();
	@exhaust = ();
	$heat->reset();
	$momx = 0;
	$momy = 0;
	$shipangle=0;
	#$ship->delete('ship');
	$ship->setDimensions($width, $height);
	#$ship->translate(($cx/2)-($width/2),($cy/2)-($height/2),0);
	$ship->shieldOff();
	$ship->shieldOn() if ($ship->{shield} > 0);	
	$ship->{ID} = $tdc->registerObject($ship,\@focuspoint,$ship->{SHADE},($cx/2)-($width/2),($cy/2)-($height/2),0, 0);
	#ship now notionally a 3d element
	
}


#sub _draw{
#	my $tag = shift;
#	my $obj = shift;
#	$obj->draw('ship');
#	
#	$mw->update;
#
#}
#
#
#sub _rotate
#{
#	#around object centre point
#
#	my $tag= shift;
#	my $obj=shift;
#	my $angle = shift;
#	my $centre = $obj->getCentre();
#	my @c = ($$centre[0],$$centre[1]);
#	my @trans = (-$$centre[0],-$$centre[1],0);
#	#negative rate will move object in anti-clockwise direction
#	$obj->translate($trans[0], $trans[1], $trans[2]);
#	$obj->rotate('z',$angle,$c[0],$c[1]);
#	_draw($tag,$obj);
#	_momentumData();
#	
#}


sub go
{
	
	return if ($go == 1 || _checkChildren("Configure")==0);
	if ($go == 2){
		clear(1);
		return;
	}
	$music->play('main');
	$go = 1;
	$specialstarttime = time() - $pausetime if ($pausetime > 0);
	$pausetime = 0;
	my $cycle = 0;
	my $coolingcycle = 0;
	my $nextroid = 1;
	while ($go == 1){

		my $then = getTime();
		$coolingcycle++;
		if ($coolingcycle == 20){
			$coolingcycle = 0;
			if ($ship->{thrust} != 0){ #adds engine heat - heat dissipates more slowly while moving
				$heat->cool(0.4); #0.4 is heat to add back in after cooling cycle
			}else{
				$heat->cool();
			}
		}
		$drone = new Drone(1,1,1,\$cnv,'STD') if (int(rand(12000)) ==1 && ! defined($drone) && ! defined($alien)); #for testing
		$drone->plotDeflectionShot($ship,$cx,$cy) if (defined($drone));
		$drone->move() if ($coolingcycle%3 == 1 && defined($drone)); 
		_handleWhale() if ($coolingcycle%3 == 1);
		$cycle++;
		if ($cycle == $nextroid){
			_generateRoid();
			$cycle = 0;
			$nextroid = 10+int(rand(120-(15*$level)));
			#print "$nextroid\n";
		}
		_handlespecials();
		_handleAlien() if ($coolingcycle%2 == 1); #less critical events every second cycle, hopefully aids performance
		_fire() if ($fire == 1);
		#_rotate('ship',$ship,$rotangle) if ($rotangle != 0);
		if ($rotangle != 0){
			$tdc->rotate($ship->{ID},'z',$rotangle,$rotangle,1);
			$shipangle+=$rotangle;
			if ($shipangle > 360){
				$shipangle-=360;
			}
			if ($shipangle < -360){
				$shipangle+=360;
			}
		}
		_handleMovement(); 
		_handleBomb() if ($bomb == 1);
		_handleBullets();
		_handleRoids(scalar $cnv->find('withtag','shockwave'));
		_handleBlooms() if ($coolingcycle%2 == 1);
		_handleExhaust() if ($coolingcycle%2 == 0); #slows just a bit too much - rejigged checkRoidsCollisions (exhaust particles inside ship boundary triggered full collision checking) - seems better! - though alien seems to slow it down somewhat now
		_checkRoidCollisions() if ($checkroids == 1);
		$cntl->itemconfigure('scoretext', -text=>$score);
		#$mw->update;
		$tdc->_updateAll(); #will do $mw->update in here anyway
		_breakship() if ($go == 2);
		my $now = getTime();
		my $tdif = 0.02 - ($now-$then);
		my $wait = sprintf "%.3f", $tdif;
		if ($wait > 0){
			select (undef, undef, undef, $wait);
		}
		
	}
}

sub _handleWhale
{
	if (! defined($spacewhale) && int(rand(10000)) ==1){
		$spacewhale = Whale3D->new();
		my @focuspoint = (int($cx/2),int($cy/2),1500);
		$spacewhale->{ID} = $tdc->registerObject($spacewhale,\@focuspoint,'#99BBFF',50,int($cy/(1+rand(9))),800, 0);
	} elsif (defined($spacewhale)){
		my $centre = $spacewhale->getCentre();
		#print join(":",@$centre)."\n";
		if ($$centre[2] > 300){
			$tdc->rotate($spacewhale->{ID},'z',-2.6,2.6,1);
			$tdc->translate($spacewhale->{ID},0,0,-20,1);
			$cnv->raise($ship->{TAG},$spacewhale->{TAG});
		}elsif ($$centre[2] > 200){
			$tdc->rotate($spacewhale->{ID},'y',-5,5,1);
			$tdc->translate($spacewhale->{ID},0,0,-5,1);
			$cnv->raise($ship->{TAG},$spacewhale->{TAG});
		}elsif ($$centre[0] < $cx+200 && $$centre[2] < 200){
			$spacewhale->{STATE} = 1;
			$tdc->translate($spacewhale->{ID},8,0,0,1);
			$cnv->raise($ship->{TAG},$spacewhale->{TAG});
		}else {
			
			$tdc->removeObject($spacewhale->{ID});
			$spacewhale=undef;
		}
	}
}


sub _handleAlien
{
	my $rand = -1;
	if (! defined($alien) && ! defined($drone)){
		$rand = int(rand(5300-(300*$level)));
		#$rand = 0;
	}
	if ($rand ==0){
		my $ax = $cx-15;
		my $ay = $cy-15;
		$ax-- if($ax%2 == 1);
		$ay-- if($ay%2 == 1);
		$alien = Alien->new($ax, $ay, \$cnv);
	}
	if (defined($alien)){
		if ($alien->{Y} < 0 || $alien->{X} < 0 || $alien->{OFFSCREEN} == 1){
			if ($alien->delete() == 0)
			{
				$alien = undef;
			}
		}else{
			$alien->draw();
		}
	}
}

#sub _handleMovement
#{
#	my ($x, $y, $addx, $addy) = $ship->getFireLine($thrust);
#	my $centre = $ship->getCentre();
#	if ($$centre[0]+$addx >= 0 &&
#		$$centre[0]+$addx <= $cx &&
#		$$centre[1]+$addy >= 0 &&
#		$$centre[1]+$addy <= $cy){
#	
#		$ship->translate($addx, $addy, 0);
#		_draw('ship',$ship);
#	}
#}

sub _handleMovement
{
	my $x = 0;
	my $y = 0;
	my $addx = 0;
	my $addy = 0;

	if ($ship->{thrust} != 0){
		($x, $y, $addx, $addy) = $ship->getFireLine($ship->{thrust});
			my ($ex, $ey) = $ship->getEnginePosition();
			my $rand = 2.5-rand(5);
			my $exhaustx = ($addx*-1)+$rand;
			$rand = 2.5-rand(5);
			my $exhausty = ($addy*-1)+$rand;
			my $debris = $cnv->createOval($ex, $ey, $ex+2, $ey+2, -fill=>'orange', -outline=>'orange', -tags=>'exhaust');
			push(@exhaust, [$debris,$ex,$ey,$exhaustx,$exhausty]);
			

	}
	#factor momentum into movement vector
	$momx = 0 if ($momx < 0.1 && $momx > -0.1);
	$momy = 0 if ($momy < 0.1 && $momy > -0.1);
	
	if ($momx != 0 || $momy != 0){
		$momx = $momx/1.024;
		$momy = $momy/1.024;
		$addx += $momx;
		$addy += $momy;
		my $sq = ($addx*$addx)+($addy*$addy);
		my $mag = sqrt($sq);
		if ($mag > $ship->{mspeed}){
			my $pc = $mag/$ship->{mspeed};
			$addy=$addy/$pc;
			$addx=$addx/$pc;
		}
	}
	#move ship	
	if ($addx != 0 || $addy != 0){
		my $centre = $ship->getCentre();
	
		if ($$centre[0] < 0){
			$ship->translate(-$$centre[0],0, 0);
		}
		if ($$centre[1] < 0){
			$ship->translate(0,-$$centre[1], 0);
		}
		
		if ($$centre[0]+$addx >= 0 &&
			$$centre[0]+$addx <= $cx &&
			$$centre[1]+$addy >= 0 &&
			$$centre[1]+$addy <= $cy){
		
			#$ship->translate($addx, $addy, 0);
			#_draw('ship',$ship);
			$tdc->translate($ship->{ID},$addx, $addy,0,1);
		}
	}
}

sub _handleBomb
{
	my ($x, $y, $x1, $y1) = $cnv->coords('blastwave');
	if (($x1 - $x) > ($cx*0.66)){
		#does not blast whole screen (2/3 distance of x)
		$bomb = 0;
		$cnv->delete('blastwave');
	}else{
		$cnv->coords('blastwave',$x-10, $y-10, $x1+10, $y1+10);
	}
}

sub _handleRoids
{
	my $shockwave = shift;
	foreach (keys %roids){
		if ($roids{$_}->offScreen($cx,$cy)){
			removeRoid($_);
		}else{
			$roids{$_}->draw();
			_checkBombCollision($_,'blastwave') if($bomb == 1);
			_checkBombCollision($_,'shockwave') if($shockwave>0); 
		}
	}
}

sub _handleBullets
{
	my @btemp = ();
	foreach my $bul (@bullets){
		$bul->draw($cx,$cy);
		if ($bul->offScreen($cx,$cy)){
			$bul->delete();
			$bul=undef;
		}else{
			
			my $col = 0;
			$col = _checkBulletCollision($bul) if ($bul->{ROUND} ne 'WAVE');
			if ($col == 1){
				if($bul->{ROUND} eq 'STD' || $bul->{ROUND} eq 'CLU'){
					$bul->delete() ;
					$bul=undef;
				}
				else{
					push(@btemp, $bul);
				}
			}else{
				push(@btemp, $bul);
			}
		}
	}
	@bullets = @btemp;
}


sub _handlespecials
{

	if (time() - $specialstarttime > 10 && $specialavailable > -1 && $specialactive == 0){
		$specialavailable = -1;
		$cnv->delete('special');
	}
	elsif ($specialavailable == -1){
		my $rand = int(rand(300));
		#my $rand = 1;
		if ($rand == 1){
			my $temp = @specials;
			$specialavailable = int(rand($temp-0.01));
			#$specialavailable = 7;
			$specialstarttime = time();
			&{$specials[$specialavailable]};
		}
	}
	elsif ($specialactive ==1){
		my $t = 20 - (time()-$specialstarttime);
		&{$specialactions[$specialavailable]};
		$t = 0 if ($t < 0);
		$cntl->itemconfigure('countdown', -text=>"$t");
		if ($t <= 0){
			&{$specialends[$specialavailable]};
			$specialavailable = -1;
			$specialactive = 0;
			$cntl->itemconfigure('specialtext', -text=>'NORMAL');
		}
	}
	elsif ($specialavailable > -1 && $specialactive == 0){
		&{$onScreenActions[$specialavailable]};
		my ($x, $y, $x1, $y1) = $cnv->coords('special');
		my @obj = $cnv->find('overlapping', $x, $y, $x1, $y1);
		my $del = 0;
		foreach my $id (@obj){
			if (${$cnv->itemcget($id, -tags)}[0] eq $ship->{TAG} && $del == 0){
				$specialstarttime = time();
				$specialactive = &{$specialactions[$specialavailable]};
				$sound->play('special');
				$del = 1;
				last;
			}
		}
		$cnv->delete('special') if ($del == 1);
	}
}

sub _breakship
{	
	_newbloom($ship, 'yellow',2);
	while (@bloom > 0){
		_handleBlooms();
		$ship->flyapart();
		#_draw('ship', $ship);
		$tdc->translate($ship->{ID},0, 0,0,0);
		#$mw->update;
		select (undef, undef, undef, 0.016);
	}
	
	$music->stop();
	highscore($score);
}

sub clear
{
	my $fullReload = shift;
	$_=undef foreach(@bullets);
	@bullets=();
	foreach(keys %roids){
		$roids{$_}=undef;
		delete $roids{$_};
	}
	if ($fullReload == 1){
		print "reloading...\n";
		$mainw->deiconify();
		$mainw->focusForce;
		$mainw->update;
		$cnv=undef;
		$dontEnd = 1;
		$mw->destroy();
		$mw=undef;
		$dontEnd = 0;
		$go = 0;
		$tdc=undef;
		$spacewhale=undef;
		_buildTopLevel(); #complete rebuild of top level, should reset canvas ids to 0, will eventually run out otherwise
				#hopefully enough for one game, don't know limit, but will generate over 0.5 million ids
				#possible performance hit on large ids, probably good to clear anyway
				#can't find way to clear contents and repopulate an existing window which would be better
				#UnmapWindow would seem to be useful, but can't get it to work how I want
		$mw->focusForce;
		$mainw->withdraw();
	}else{
		$cnv->delete('all');
		#my $f = $cnv->parent;
		#$cnv->UnmapWindow;
		#$cnv = $f->Canvas(-width=>$cx, -height =>$cy, -borderwidth=>0, -background=>'black')->pack(-side=>'left');
		if (defined($mw->imageNames) && @{$mw->imageNames} > 0){ #backdrop is loaded
			$cnv->createImage($cx/2,$cy/2, -image=>'backdrop', -anchor=>'center');
		}
		$spacewhale=undef;
		$cntl->itemconfigure('specialtext', -text=>'NORMAL');
		$cntl->itemconfigure('countdown', -text=>'0');
		_resetShip();
		#_draw('ship',$ship);
		$cntl->itemconfigure('scoretext', -text=>$score);
		$cntl->itemconfigure('deadtext', -text=>'ALIVE', -fill=>'green');
	}
	$mw->update;
}


sub _checkRoidCollisions
{
	my ($x, $y, $x1, $y1, $no_triangles) = $ship->getBoundingBox(); #should reduce number of checks to do
	my @keys = $cnv->find('overlapping', $x, $y, $x1, $y1);
	return if (@keys <= (1+$no_triangles)); #minimum 3 objects will be found, background and the 2 ship halves (may need to take into account if background is missing)
	@keys = grep{${$cnv->itemcget($_, -tags)}[0] =~ m/roid|missile|whale/;}@keys;
	return if (@keys == 0);
	foreach my $k (@keys){
	
	#fixed collision detection, I hope, ship checks points on it's border for overlap
	#can now use irregular roids
	my $id = 0;
	my $doneRoidCheck = 0;
	if (${$cnv->itemcget($k, -tags)}[0] eq 'roid' && $doneRoidCheck == 0){
		$id =$ship->checkCollision('roid');
		$go = 2 if ($id > 0);
		$doneRoidCheck = 1;
		#checkCollision will find any roids collision, don't need to check more than once
	}elsif(${$cnv->itemcget($k, -tags)}[0] eq 'missile'){
		my ($mid, $tid) = $alien->checkMissileCollision($ship->{TAG},${$cnv->itemcget($k, -tags)}[2]);
		if($mid > 0){
			my $effect = ${$cnv->itemcget($k, -tags)}[1];
			$cnv->delete($mid);
			$cnv->delete($tid);
			$effect =~ s/^eff:(\d+)$/$1/;
			if ($effect > 0){
				_processEffect($effect);
			}else{
				#die
				$go = 2;
			}
		}
		
	}elsif (${$cnv->itemcget($k, -tags)}[0] eq 'whale' && $spacewhale->{STATE} == 1){
		$id =$ship->checkCollision('whale');
		$go = 2 if ($id > 0);
	}
	if ($go == 2){
		if ($id > 0){
			if ($roids{$id}){
   				$ship->{shield} -= $roids{$id}->{SIZE};
   			}else{
   				#probably drone
   				$ship->{shield}--;
   			}
   			if ($ship->{shield} > -1){
    				if ($ship->{shield} == 0){
     					$ship->shieldOff();
     					$sound->play("shieldoff");
    				}
    				removeRoid($id);
    				$go = 1;
   			}else{
    				#else you still die
    				$ship->shieldOff();
   			}
  		} #id 0 will be a missile strike, still kills outright
  		if ($go == 2){
   			$sound->play("die");
   			$cntl->itemconfigure('deadtext', -text=>'!!DEAD!!', -fill=>'red');
  		}
  		last;
 	}
 	}
}

sub _processEffect
{
	my $effect = shift;
	return if ($effect == 0); #effect 0 is death, should have been dealt with elsewhere, would activate last good special if let through
	if ($specialactive == 1 || $specialavailable > -1){
		#remove any existing special
		$specialstarttime -= 20;
		_handlespecials();
	}
	#replace with the bad special
	$cnv->delete('special'); #remove any special icon on screen
	$specialstarttime = time();
	$specialavailable = scalar @specials + $effect - 1;
	$specialactive = &{$specialactions[$specialavailable]};
	
}


sub _checkBombCollision
{
	#currently does not affect whales
	my $key = shift;
	my $tag = shift;
	my $obj = $roids{$key};
	my @t = $cnv->find('overlapping', $obj->{X}+(10*$obj->{SIZE}), $obj->{Y}+(10*$obj->{SIZE}),
					$obj->{X}+((10*$obj->{SIZE})*2), $obj->{Y}+((10*$obj->{SIZE})*2));
					#middle square of roid - not perfect, but meh!
					
	foreach my $id (@t)
	{
		if (${$cnv->itemcget($id, -tags)}[0] eq $tag)
		{
			removeRoid($key);
			$score+=(1*$level);
			last;
		}
		
	}
}

sub _handleExhaust
{
	my @temp = @exhaust;
 	@exhaust = ();
 		for (my $i = 0; $i < @temp ; $i++){
 			$temp[$i][3] = $temp[$i][3] * 0.7;
  			$temp[$i][4] = $temp[$i][4] * 0.7;
  			if (sqrt($temp[$i][3]*$temp[$i][3]) > 0.2 && sqrt($temp[$i][4]*$temp[$i][4]) > 0.2){ #use positive value for this check - square root of value squared ensures this
  				$temp[$i][1] += $temp[$i][3];
  				$temp[$i][2] += $temp[$i][4];
  				$cnv->coords($temp[$i][0], $temp[$i][1], $temp[$i][2],$temp[$i][1]+2, $temp[$i][2]+2);
  				push(@exhaust,$temp[$i]);
  			}
  			else
  			{
  				$cnv->delete($temp[$i][0]);
  			}
 		}
}

sub _handleBlooms
{
	my @temp = @bloom;
 	@bloom = ();
 		for (my $i = 0; $i < @temp ; $i++){
 			$temp[$i][3] = $temp[$i][3] * 0.85;
  			$temp[$i][4] = $temp[$i][4] * 0.85;
  			if (sqrt($temp[$i][3]*$temp[$i][3]) > 0.4 && sqrt($temp[$i][4]*$temp[$i][4]) > 0.4){ #use positive value for this check - square root of value squared ensures this
  				$temp[$i][1] += $temp[$i][3];
  				$temp[$i][2] += $temp[$i][4];
  				$cnv->coords($temp[$i][0], $temp[$i][1], $temp[$i][2],$temp[$i][1]+$temp[$i][5], $temp[$i][2]+$temp[$i][5]);
  				push(@bloom,$temp[$i]);
  			}
  			else
  			{
  				$cnv->delete($temp[$i][0]);
  			}
 		}
}
 
sub _newbloom{
 	my $obj = shift;
 	my $bloomColour = shift;
 	my $particle_size = shift;
 	my ($x, $y, $x1, $y1) = $obj->getBoundingBox(); # add function to roid
 	foreach (1..12){
 		my $randx = int($x + rand($x1-$x));
 		my $randy = int($y + rand($y1-$y));
 		my $addx = 2+rand(7);
 		my $addy = 2+rand(7);
 		$addx=$addx*-1 if (int(rand(2)%2 == 0));
 		$addy=$addy*-1 if (int(rand(2)%2 == 0));
 		my $debris = $cnv->createOval($randx, $randy, $randx+$particle_size, $randy+$particle_size, -fill=>$bloomColour, -outline=>$bloomColour, -tags=>'debris');
 		push(@bloom, [$debris,$randx,$randy,$addx,$addy,$particle_size]);
  	}
}


sub _checkBulletCollision
{
	my $obj = shift;
	#my @tags = $cnv->find('overlapping', $obj->{X}-1, $obj->{Y}-1, $obj->{X}+1, $obj->{Y}+1); 
 	my @tags;
 	#some bullet travel distances may be to long and skip the would be impacted object, check small chunks along bullet line
 	#	my $addx = $obj->{ADDX}/3;
 	#	my $addy = $obj->{ADDY}/3;
 	if ($obj->{ROUND} eq 'EXP'){
 		#proximity/explosive round
		return _checkExplosiveRound($obj);
 	}
 	elsif ($obj->{ROUND}  eq 'BEAM'){
 		#beam weapon
		_checkBeamRound($obj,\@tags); 		
		 		
 	}else{
 	 	#some bullet travel distances may be to long and skip the would be impacted object, check small chunks along bullet line
	 	my $addx = $obj->{ADDX}/3;
 		my $addy = $obj->{ADDY}/3;
 		for (my $i = 4 ; $i--;){
 			my @temp = $cnv->find('overlapping', $obj->{X}-($addx*$i), $obj->{Y}-($addy*$i), $obj->{X}-($addx*$i), $obj->{Y}-($addy*$i));
 			if (@temp > 0){
 				#splice (@tags,@tags,0,@temp); 
 				push (@tags,@temp); 
 				$i=0;
 			}
 		}
 	}
	my $ret = 0;
	my $prev = -1;
	@tags = sort @tags;
	foreach my $t (@tags){
		next if ($t == $prev || $t == 1);
		$prev = $t;
		if (defined($alien) && $t == $alien->{ID}){
			my $kill = $alien->hit();
			if ($kill==1){
				$score+=150 ;
				$sound->play('aliendie');
			}
			$ret = 1;
			last if ($obj->{ROUND} eq 'STD' || $obj->{ROUND} eq 'CLU');
		}
		elsif (defined($drone) && $t == $drone->{ID}){
			$score+=250 ;
			$cnv->delete($drone->{ID});
			$cnv->delete($drone->{BULLET}->{ID}) if (defined($drone->{BULLET}));
			$drone = undef;
			$sound->play('aliendie');
			$ret = 1;
			last if ($obj->{ROUND} eq 'STD' || $obj->{ROUND} eq 'CLU');
		}elsif (defined($spacewhale) && $spacewhale->{STATE} == 1 && (scalar grep{$_==$t}@{$tdc->getItemIds($spacewhale->{ID})}) > 0){
			#my $ids = $tdc->getItemIds($spacewhale->{ID});
			#my @temp = grep{$_==$t}@$ids;
			#if (scalar @temp > 0){
				#you killed the whale! arrrrgh!
				#badness will happen here! - will bring in a drone
				#could do with a whale sound
				$drone = new Drone(1,1,1,\$cnv,'BEAM'); #laser armed! ehehehe!
				$score-=300;
				$tdc->removeObject($spacewhale->{ID});
				_newbloom($spacewhale, 'red',10);
				$spacewhale=undef;
				last if ($obj->{ROUND}eq 'STD' || $obj->{ROUND} eq 'CLU');
			#}
		}
		elsif ($roids{$t}){
			if ($roids{$t}->{COL} eq 'black'){
				#darkroid
				$ret = 1;
				$roids{$t}->{HP}-=1;
				if ($roids{$t}->{HP} == 0){
					$score+=(10*$level);
					$sound->play('hit1');
					_newbloom($roids{$t}, 'white',2);
					removeRoid($t);
				}else{
					$sound->play('hit2') if ($obj->{ROUND} ne 'BEAM'); #beam will destroy in one hit usually, don't bother playing this sound
				}
			}else{
			if ($roids{$t}->{SIZE} > 1){
				#split into 2 smaller ones and modify trajectories
				
				my ($argx, $argy,$size, $movex, $movey) = $roids{$t}->split();
				my $r1 = Roid->new($argx, $argy, $size, $movex, $movey, 1, '#AAAAAA', \$cnv);
				($argx, $argy,$size, $movex, $movey) = $roids{$t}->split();
				my $r2 = Roid->new($argx, $argy, $size, $movex, $movey, 1, '#AAAAAA', \$cnv);
				
				$r1->draw();
				$roids{$r1->{ID}} = $r1;
				$r2->draw();
				$roids{$r2->{ID}} = $r2;
				$score+=(1*$level);
			}else{
				$score+=(2*$level);
				_newbloom($roids{$t}, 'white',2);
			}
			$ret=1;
			$sound->play('hit1');
			removeRoid($t);
			}
			last if ($obj->{ROUND} eq 'STD' || $obj->{ROUND} eq 'CLU');
		}
	}
	return $ret;
}


sub _checkExplosiveRound
{
	my $obj = shift;
	my @temp = $cnv->find('overlapping', $obj->{X}-30, $obj->{Y}-30, $obj->{X}+30, $obj->{Y}+30);
	@temp = grep{${$cnv->itemcget($_, -tags)}[0] =~ m/roid|drone|alien|whale/;}@temp;
	if (@temp > 0){
		#burst
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 6, 0, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -6, 0, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 0, 6, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 0, -6, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 4.24, 4.24, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 4.24, -4.24, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -4.24, 4.24, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -4.24, -4.24, \$cnv, 'CLU'));
		
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 3, 5.2, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 5.2, 3, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 3, -5.2, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, 5.2, -3, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -3, 5.2, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -5.2, 3, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -3, -5.2, \$cnv, 'CLU'));
		push(@bullets, Bullet->new($obj->{X}, $obj->{Y}, -5.2, -3, \$cnv, 'CLU'));
		$obj->{ROUND}='STD';
		return 1;
	}
	return 0;
}

sub _checkBeamRound
{
	my $obj = shift;
	my $tags = shift;

 	my $x = $obj->{X};
 	my $y = $obj->{Y};

 	#get equation of fire line, get x value of fline at y of point, if roids crosses then there will be x values higher and lower than roid point
 	my $x1 = $x + $obj->{ADDX};
 	my $y1 = $y + $obj->{ADDY};
 	my $fline = LineEq->new($x1, $y1, $x, $y);
 	my @fv = ($obj->{ADDX}, $obj->{ADDY}, 0);
 	_normalise(\@fv);
 	foreach my $rkey (keys %roids){
		push(@$tags, $rkey) if (_checkObjectAcrossLine ($rkey, $fline, \@fv, $x, $y) == 1);
 	}
 	if (defined($alien)){
 		push(@$tags, $alien->{ID}) if (_checkObjectAcrossLine ($alien->{ID}, $fline, \@fv, $x, $y) == 1); 
 	}
 	if (defined($drone)){
 		push(@$tags, $drone->{ID}) if (_checkObjectAcrossLine ($drone->{ID}, $fline, \@fv, $x, $y) == 1);
 	}
}

sub _checkObjectAcrossLine
{
	my $rkey = shift; #object canvas ID
	my $fline = shift; #LineEq object representing line
	my $fv = shift; #unit vector representing line
	my $x = shift; #line originating point
	my $y = shift;
	my @coords = $cnv->coords($rkey);
	my $flag = -1;
	my @v = ($coords[0] - $x, $coords[1] - $y, 0);
	_normalise(\@v);
	return 0 if (rad2deg(acos(($$fv[0]*$v[0])+($$fv[1]*$v[1]))) > 135); #stops roids on line behind ship being picked up
	for (my $i = 0 ; $i < @coords ; $i+=2){
		my $f = -1;
		my $tx = $fline->xAty($coords[$i+1]);
		if ($tx ne 'n'){
			$f = 0 if ($tx > $coords[$i]);
			$f = 1 if ($tx < $coords[$i]);
		}else{ #special case horizontal line
			$f = 0 if ($fline->{Y} > $coords[$i+1]);
			$f = 1 if ($fline->{Y} < $coords[$i+1]);
		}
		
		if ($f != -1){
			if ($flag == -1){
				$flag = $f;
			}elsif ($flag != $f){
				#we have a candidate
				return 1;
			}
		}	
 	}
 	return 0;
}

sub removeRoid
{
	my $key = shift;
	$cnv->delete($key);
	$roids{$key}=undef;
	delete $roids{$key};
	
}

sub _generateRoid
{
	my @temp = keys(%roids);
	my $cnt = @temp;
	return if ($cnt>30); #do not generate if more than 30 roids, may tweak this
	my $a = int(rand(100)) % 2;
	my $argx = 0;
	my $argy = 0;
	if ($a == 1){
		$argx = int(rand($cx));
		my $a = int(rand(100)) % 2;
		if ($a == 1){
			$argy = $cy;
		}
	}else{
		$argy = int(rand($cy));
		my $a = int(rand(100)) % 2;
		if ($a == 1){
			$argx = $cx;
		}
	}
	my $movex = 0.5+rand($level);
	my $movey = 0.5+rand($level);
	$movex=$movex*-1 if ($argx > ($cx/2));
	$movey=$movey*-1 if ($argy > ($cy/2));
	my $darkroid = int(rand(100))%15;
	my $largeroid = int(rand(100))%17;
	my $r;
	if ($darkroid == 0){
		$r = Roid->new($argx, $argy, 2, $movex, $movey, 7, 'black', \$cnv);
	}else{
		my $size = 2;
		$size = 4 if ($largeroid == 0);
		$r = Roid->new($argx, $argy, $size, $movex, $movey, 1, '#CCCCCC', \$cnv);
	}
	$r->draw();
	$roids{$r->{ID}} = $r;
	#print $r->{ID}."\n";
}

sub stop
{
	#should rename as pause
	$go = 0;
	$pausetime = 0;
	if ($specialactive > 0){
		$pausetime = time()-$specialstarttime;
	}
}

sub _fire
{	
	if ($go){
		my $time = getTime();
		my $dif = $time - $lastfire;
		if ($dif > $ship->{rof}){
			$lastfire = $time;
			if ($roundType eq 'WAVE' && $heat->heat($ship->{heat}))
			{
				#shockwave
				my ($x, $y, $addx, $addy, $addx1, $addy1, $addx2, $addy2) = 0;
				($x, $y, $addx, $addy) = $ship->getFireLine($ship->{pspeed}-1,3);
				($x, $y, $addx1, $addy1) = $ship->getFireLine($ship->{pspeed},0);
				($x, $y, $addx2, $addy2) = $ship->getFireLine($ship->{pspeed}-1,4);
				push(@bullets, Shockwave->new($x, $y, $addx, $addy,$addx1, $addy1,$addx2, $addy2, \$cnv));
				$sound->play("bomb");
				
			}elsif ($heat->heat($ship->{heat})){
				for (my $i = $ship->{guns} ; $i-- ;){
					_generateBullet($ship->{pspeed},$i);
				}
			}
		}
	}
}

sub _generateBullet
{
	my $magnitude = shift;
	my $line = shift;
	my ($x, $y, $addx, $addy) = $ship->getFireLine($magnitude,$line);
	my $b = Bullet->new($x, $y, $addx, $addy, \$cnv, $roundType);
	push(@bullets, $b);
	if ($line==0){
		$sound->play("bullet$roundType");
	}
}

sub _invuln
{
	_specialbox('yellow','black','I','black');
}

sub _triplefire
{
	_specialbox('green','black','3','black');
}

sub _doinvuln
{
	if ($specialactive == 0){
		$checkroids = 0;
		#$cnv->itemconfigure('ship', -fill=>'yellow');
		$ship->setColour('yellow');
		$cntl->itemconfigure('specialtext', -text=>'INVULNERABLE');
		return 1;
	}
	return 0;
}

sub _endinvuln
{
	$checkroids = 1;
	#$cnv->itemconfigure('ship', -fill=>$ship->{SHADE});
	$ship->setColour($ship->{basecol});
}

sub _dotriplefire
{
	$cntl->itemconfigure('specialtext', -text=>'TRIPLE FIRE');
	if ($fire == 1){
		my $time = getTime();
		my $dif = $time - $lastfire;
		if ($dif > $ship->{rof}){
			_generateBullet($ship->{pspeed},3);
			_generateBullet($ship->{pspeed},4);
		}
	}
	return 1;
}

sub _newbomb
{
	if ($ship->{bomb} < $ship->{basebomb}){ 
		_specialbox('black','white','B','white');
	}else{
		$specialavailable = -1;
	}
}

sub _collectbomb
{
	#not a timed effect reset flags
	$ship->{bomb}+=1;
	#$specialactive = 0;
	$specialavailable = -1;
	$cntl->itemconfigure('countdown', -text=>'0');
	return 0;
	
}

sub _incROF
{
	_specialbox('purple','yellow','R','yellow');
}

sub _doincROF
{
	if($specialactive == 0){
		$ship->{rof} = $ship->{rof}/2;
		$ship->{heat} = $ship->{heat}/3; #let them have fun
		$cntl->itemconfigure('specialtext', -text=>'+ ROF');
		return 1;
	}
	return 0;
}

sub _endincROF
{
	$ship->{rof} = $ship->{rof}*2;
	$ship->{heat} = $ship->{heat}*3;
}


sub _apRounds
{
	if ($roundType eq 'STD'){
	 	_specialbox('black','red','P','red') ;
	}else{
		$specialavailable = -1;
	}
}

sub _doapRounds
{
	if($specialactive == 0){
		$roundType = 'AP';
		$cntl->itemconfigure('specialtext', -text=>'Piercing Rounds');
		return 1;
	}
	return 0;
}

sub _exRounds
{
	if ($roundType eq 'STD'){
	 	_specialbox('black','yellow','X','yellow');
	}else{
		$specialavailable = -1;
	}
	
}

sub _doexRounds
{
	if($specialactive == 0){
		$roundType = 'EXP';
		$cntl->itemconfigure('specialtext', -text=>'Explosive Rounds');
		return 1;
	}
	return 0;
}

sub _endRounds
{
	$roundType = 'STD';
}


sub _shockwave
{
	if ($roundType eq 'STD' || $roundType eq 'BEAM'){
	 	_specialbox('yellow','red','S','red');
	}else{
		$specialavailable = -1;
	}
	
}

sub _doshockwave
{
	if($specialactive == 0){
		$roundType = 'WAVE';
		$ship->{rof} = 1;
		$ship->{pspeed} = 10;
		$cntl->itemconfigure('specialtext', -text=>'Shockwave');
		return 1;
	}
	return 0;
}

sub _endshockwave
{
	$roundType = 'STD';
	$roundType = 'BEAM' if ($ship->{guntype} == 2);
	$ship->{pspeed} = $ship->{basepspeed};
	$ship->{rof} = $ship->{baserof};
}

sub _blinky
{
	#may want to reduce frequency on this one
	if ($crystal == -1 && time() % 3 == 0){
		my $x = int(rand($cx-20));
		my $y = int(rand($cy-20));
		$cnv->createOval($x, $y, $x+30, $y+30, -fill=>'#FF0000', -outline=>'red', -tags=>["special","plus"]);
	}else{
		$specialavailable = -1;
	}
	
}

sub _blinkyOnScreen
{
	my $colour = $cnv->itemcget('special',-fill);
	$colour = hex(substr($colour,3,2));
	my $dir = ${$cnv->itemcget('special',-tags)}[1];
	if ($dir eq "plus"){
		$colour+=15;
		if ($colour > 255){
			$colour=255;
			$cnv->itemconfigure('special',-tags=>["special","minus"]);
		}
	}else{
		$colour-=15;
		if ($colour < 0){
			$colour=0;
			$cnv->itemconfigure('special',-tags=>["special","plus"]);
		}	
	}
	my $newcolour="#FF".dec2hex($colour)."00";
	$cnv->itemconfigure('special',-fill=>$newcolour);
}

sub _doBlinky
{
	#do side game
	$specialavailable = -1;
	$cntl->itemconfigure('countdown', -text=>'0');
	$cnv->delete('special');
	$cnv->update;
	#stop(); #don't think I need to do this, this is being called from within the go loop, will block until prog finishes, and don't need to handle timings for a special effect, there shouldn't be another one in play
	#end music and start new one for side game?
	$music->end();
	my $ret = 0;
	#my $pid = open(PROG, "perl ../gates/gatetest.pl |");
	$mw->iconify;
	my $pid = open(PROG, "launchgates.bat |");
	if ($pid != 0){
	
		while (defined (my $p = <PROG>))
		{
			chomp($p);
			#print "$p\n";
			#do stuff depending on messages
			#plan to award crystal for complete course, will correspond to a special that can be activated at any time
			if ($p eq "start"){
				$music->play('side');
			}else{
				$music->end();
				if ($p eq "Complete"){
					#award crystal
					$crystal = int(rand(scalar @specials - 1.01)); #don't include last special element, is another blinky 
					#print "Crytsal: $crystal\n";
					#will need to update a marker
					my $c = _getColour($crystal);
					$cframe->configure(-background=>$c);
				}elsif ($p eq "Hit Gate"){
					#activate bad special
					my $badspecs = scalar @specialactions - scalar @specials - 0.01;
					my $effect = int(rand($badspecs));
					$specialavailable = scalar @specials + $effect;
					$specialstarttime = time();
					&{$specialactions[$specialavailable]};
					$ret = 1;
				}
				#incomplete course does nothing
			}
		}
	}
	close PROG;
	$mw->deiconify;
	$mw->focusForce;
	#sleep 2;
	my $w=$mw->Toplevel(-class=>'Countdown');
	my $posx=int($cx/2 - 100);
	my $posy=int($cy/2 - 50);
	my $g = "200x100+$posx+$posy";
	$w->geometry($g);
	$w->resizable(0,0);
	my $fr = $w->Frame()->pack(-fill=>'x');
	my $count = 3;
	$fr->Label(-text=>"Restarting in ...", -font=>'{Arial Bold} 12')->pack(-fill=>'x');
	$fr->Label(-textvariable=>\$count, -font=>'{Arial Bold} 12')->pack(-fill=>'x');
	$w->focus;
	$w->update;
	while ($count > 0){
		$count--;
		$w->update;
		sleep 1;
	}
	$w->destroy;
	$mw->focusForce;
	wkeyup();
	$music->play('main');
	#print "done\n";
	return $ret;
	#go(); # see stop
}

sub _getColour{
	my $no = shift;
	return 'yellow' if ($no == 0);
	return 'red' if ($no == 1);
	return 'blue' if ($no == 2);
	return 'green' if ($no == 3);
	return 'cyan' if ($no == 4);
	return 'magenta' if ($no == 5);
	return 'purple' if ($no == 6);
	return 'black'
}

sub _doReverse{
	return 0 if ($specialactive > 0);
	$ship->{turnrate} = $ship->{turnrate}*-1;
	$cntl->itemconfigure('specialtext', -text=>'Reversed Controls');
	return 1;
}

sub _doSlow{
	return 0 if ($specialactive > 0);
	$ship->{mspeed} = $ship->{mspeed}/3;
	$cntl->itemconfigure('specialtext', -text=>'Slow Speed');
	return 1;
}

sub _doFast{
	return 0 if ($specialactive > 0);
	$ship->{mspeed} += 7;
	$cntl->itemconfigure('specialtext', -text=>'Hyper Speed');
	return 1;
}

sub _doLoseGun{
	return 0 if ($specialactive > 0);
	$fire = -1;
	$cntl->itemconfigure('specialtext', -text=>'No Gun');
	return 1;
}

sub _doTurnRate{
	return 0 if ($specialactive > 0);
	$ship->{turnrate} -= 2;
	$cntl->itemconfigure('specialtext', -text=>'Reduced Turn Rate');
	return 1;
}

sub _endReverse{
	$ship->{turnrate} = $ship->{baseturnrate};
}

sub _endSpeedMod{
	$ship->{mspeed} = $ship->{basemspeed};
}

sub _endLoseGun{
	$fire = 0;
}

sub _endTurnRate{
	$ship->{turnrate} = $ship->{baseturnrate}; ;
}


sub _specialbox
{
	my $colour = shift;
	my $outline = shift;
	my $text = shift;
	my $textcolour = shift;
	my $x = int(rand($cx-20));
	my $y = int(rand($cy-20));
	$cnv->createRectangle($x, $y, $x+20, $y+20, -fill=>$colour, -outline=>$outline, -tags=>'special');
	$cnv->createText($x+10, $y+10, -text=>$text, -anchor=>'c', -font=>'{Arial Bold} 10', -fill=>$textcolour, -tags=>'special');
}

sub _createStars
{
	my $canvas = shift;
	for (1..60){
		my $x = int(rand($cx));
		my $y = int(rand($cy));
		my $size = int(rand(2));
		$$canvas->createOval($x-1-$size, $y-1-$size, $x+1, $y+1, -fill=>'white');
	}
}

sub highscore
{
	my $newscore = shift;
	my $class = 'Scores';
	if (! $newscore){
		return if (_checkChildren($class)==0); #refocuses existing window
	}
	my $display = 0;
	my @newlist;
	my $newscorepos = -1;
	my @scores = ();
	if (-f "scores"){
		open(SCORES, "<scores");
		@scores = <SCORES>;
		close SCORES;
	}
	$display = 1 if (! $newscore);
	$scores[0] = "AAA,0" if (@scores == 0);
	for (my $i = 0 ; $i < 10 ; $i++){
		chomp($scores[$i]);
		my @split = split(',',$scores[$i]);
		if ($newscore > $split[1] && $display == 0){
			push(@newlist, "TEMP,$newscore");
			$newscorepos = $i;
			push (@newlist,$scores[$i]) if ($i < 9);
			$display = 1;
		}else{
			push (@newlist,$scores[$i]) if (@newlist < 10);
		}
		
	}
	if ($display){
		#remove any existing window
		_checkChildren($class,1);
			
		my $w=$mw->Toplevel(-class=>$class);
		$w->resizable(0,0);
		my $f1 = $w->Frame(-borderwidth=>2, -background=>'gray')->pack(-side=>'left');
		my $f2 = $w->Frame(-borderwidth=>2, -background=>'gray')->pack(-side=>'right');
		my $name = "<Type Name Here>";
		for (my $i = 0 ; $i < @newlist ; $i++){
			my @split = split(',',$newlist[$i]);
			if ($i == $newscorepos){
			my $e = $f1->Entry(-textvariable => \$name, -width=>30, -takefocus=>1)->pack(-pady=>1, -ipady=>2);
			$f1->bind($e,'<Return>', [\&recordscore, $i, \$name, \@newlist, \$w]);
			}else{
			my $text = ($i+1)."\. $split[0]";
			$f1->Label(-text=>$text, -width=>30, -background=>'#E7FFC2', -anchor=>'w', -padx=>5)->pack(-pady=>1, -ipady=>2);
			}
			$f2->Label(-text=>$split[1], -width=>30, -background=>'#E7FFC2', -anchor=>'w', -padx=>5)->pack(-pady=>1, -ipady=>2);
		}
	}
}


sub recordscore
{
	shift;
	my $pos = shift;
	my $name = shift;
	my $scorelist = shift;
	my $w = shift;
	$$scorelist[$pos] =~ s/TEMP/$$name/;
	open(SCORES, ">scores");
	print SCORES join("\n",@$scorelist);
	close SCORES;
	$$w->destroy();
	highscore();
	
}


sub _momentumData
{

	if ($ship->{thrust} != 0){
		my ($x, $y, $addx, $addy) = $ship->getFireLine($ship->{thrust});
		$momx += $addx;
		$momy += $addy;
		my $sq = ($momx*$momx)+($momy*$momy);
		my $mag = sqrt($sq);
		if ($mag > $ship->{thrust}){
			my $pc = $mag/$ship->{thrust};
			$momy=$momy/$pc;
			$momx=$momx/$pc;
		}
	}
}

sub firepress
{
	$fire = 1 if ($fire != -1);
}

sub firerelease
{	
	$fire = 0 if ($fire != -1);
}


sub dkeydown
{
	if ($adown==0){
	$ddown = 1;
	_bank(-30) if ($rotangle == 0);
	$rotangle = $ship->{turnrate}; 
	}
}

sub dkeyup
{
	if ($ddown==1){
	$ddown = 0;
	_bank(30);
	$rotangle = 0;
	}
}

sub akeydown
{	
	if ($ddown==0){
	$adown = 1;
	_bank(30) if ($rotangle == 0);
	$rotangle = -($ship->{turnrate}) ;
	}
}

sub akeyup
{
	if ($adown==1){
	$adown=0;
	_bank(-30);
	$rotangle = 0;
	}
}

sub _bank
{
	my $bankangle = shift; 
	#hopefully gives some impression of banking - though this switch to 30 degree banking isn't gradual, it is instant
	$tdc->rotate($ship->{ID},'z',-$shipangle,-$shipangle,1) if ($shipangle != 0);
	$tdc->rotate($ship->{ID},'y',$bankangle,$bankangle,1);
	$tdc->rotate($ship->{ID},'z',$shipangle,$shipangle,1) if ($shipangle != 0);
}

sub wkeydown
{
	$ship->{thrust} = $ship->{mspeed};
}

sub wkeyup
{
	_momentumData();
	$ship->{thrust} = 0;
}

sub skeydown
{
	#$thrust = -1; not good with momentum as currently coded
	$ship->{thrust} = 0; 
}

sub skeyup
{
	_momentumData();
	$ship->{thrust} = 0;
}

sub useBomb
{
	if ($ship->{bomb} > 0 && $bomb == 0 && $checkroids == 1 && $heat->heat(33)){
		$bomb = 1;
		$ship->{bomb}--;
		my $centre = $ship->getCentre();
		$sound->play('bomb');
		$cnv->createOval($$centre[0]-10,$$centre[1]-10,$$centre[0]+10,$$centre[1]+10, -outline=>'white', -tags=>'blastwave', -width=>6);
	}
}

sub useCrystal
{
	if ($specialactive == 0 && $crystal > -1){ #do not activate if a special is active
		#print "$crystal\n";
		$cnv->delete('special'); #remove any special icon on screen
		$specialstarttime = time();
		$specialavailable = $crystal; 
		$specialactive = &{$specialactions[$specialavailable]};
		#reset
		$cframe->configure(-background=>'black');
		$crystal = -1;
	}
}

sub endit
{
	$go = 0;
	if ($dontEnd == 0){
	$mw->withdraw();
	print "Thanks for playing - Goodbye\n";
	$music->end();
	$sound->end();
	$mw->withdraw();
	$mainw->destroy(); #if not reset
	sleep 2;
	exit 0;
	}
}