use lib '..\perllib';
use Tk;
use Tk::JPEG;
use Ship;
use Bullet;
use Shockwave; 
use Roid;
use Roid3D;
use Alien;
use Drone;
use SoundServer;
use Music;
use HeatMeter;
use Configure;
use GD;
use GamesLib;
use LineEq;
use Math::Trig;
use Whale3D;
use ThreeDCubesTest;
use Special2;
use strict;


our $mainw = MainWindow->new(-background=>'black');
my $g = ($mainw->screenwidth()-5)."x".($mainw->screenheight()-60)."+0+0";
$mainw->geometry($g);
our $cy = $mainw->screenheight()-180;
our $cx = $mainw->screenwidth()-45;
my $f = $mainw->Frame(-background=>'black')->pack(-fill=>'both');
my $mcnv = $f->Canvas(-height=>$cy+20, -background=>'black')->pack(-fill=>'both');
$mcnv->createText($cx/2, $cy/2, -text=>'Loading, Please Wait ...', -font=>'{Arial Bold} 16',-fill=>'white');
_createStars(\$mcnv);
$mainw->update;
our $mw;
our $cnv;
our $cframe;

our $generate3Droids = 1; #will have slow downs if true and depends a lot on PC performance
our $tickTime = 1/40; #40 ticks per second
our $level = 1;
our $maxlevel = 8;
our $heat;
our @bullets;
our $roundType;
our %roids;
keys(%roids) = 50;
our $go =0;
our $score;
our $lastfire;
our $fire;
our $checkroids;
our $bomb;
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
our $adown = 0;
our $ddown = 0;
our @focuspoint = (int($cx/2),int($cy/2),1500);
our $specialtag = 'special';
our $backdropSource = 'horseheadx.jpg';
our $backdropFile = 'backdrop.jpg';
our $backdropTag = 'backdrop';


	#start listeners on ports to listen for sound events
	#sound must come from different separate processes (with Win32::Sound) to play sound in parallel, otherwise it waits for the previous sound to finish
	#can start a new process for each sound, but this has more of an overhead over this method (sound is delayed more)
	#cannot use fork - windows is pseudo-fork, OS treats all forked processes as a single process
	our $sound = SoundServer->new(11);
	our $music = Music->new();
	
	$Special2::tickTime = $tickTime;
	our @specials2 = (Special2->new("STACKABLE", \&_triplefire,sub{},\&_dotriplefire,\&_endtriplefire, "TRIPLE FIRE"),
						Special2->new("STACKABLE", \&_newbomb,sub{},\&_collectbomb,sub{}, "BOMB"),
						Special2->new("STACKABLE", \&_invuln,sub{},\&_doinvuln,\&_endinvuln, "INVULNERABLE"),
						Special2->new("GOOD", \&_incROF,sub{},\&_doincROF,\&_endincROF, "+ ROF", $tickTime), #would like this one to be stackable but has complications
						Special2->new("GOOD", sub{_ammoBox('blue','T','yellow');},sub{},sub{_doAmmo('TRK');},\&_endRounds, "TRACKING ROUNDS"),
						Special2->new("GOOD", sub{_ammoBox('black','X','yellow');},sub{},sub{_doAmmo('EXP');},\&_endRounds, "EXPLOSIVE ROUNDS"),
						Special2->new("GOOD", sub{_ammoBox('red','L','white');},sub{},sub{_doAmmo('BEAM');},\&_endRounds, "LASER"),
						Special2->new("GOOD", sub{_ammoBox('yellow','W','red');},sub{},sub{_doAmmo('WAVE');},\&_endRounds, "SHOCKWAVE"),
						Special2->new("GOOD", sub{_ammoBox('black','P','red');},sub{},sub{_doAmmo('AP');},\&_endRounds, "PIERCING ROUNDS"),
						Special2->new("GOOD", sub{_ammoBox('red','S','blue');},sub{},sub{_doAmmo('SEN');},\&_endRounds, "SENTRY"),
						Special2->new("GOOD", \&_blinky, \&_blinkyOnScreen,\&_doBlinky,sub{},"BLINKY"),
						Special2->new("BAD", sub{}, sub{},\&_doReverse,\&_endReverse, "Reverse Controls"),
						Special2->new("BAD",sub{}, sub{},\&_doSlow,\&_endSpeedMod, "Slow Speed"),
						Special2->new("BAD",sub{}, sub{},\&_doFast,\&_endSpeedMod, "Hyper Speed"),
						Special2->new("BAD",sub{}, sub{},\&_doLoseGun,\&_endLoseGun, "No Gun"),
						Special2->new("BAD",sub{}, sub{},\&_doTurnRate,\&_endTurnRate, "- Turn Rate")
						);
	
	
	our $specialavailable;
	our @specialactive;
	our $specialonscreentime = 0;
	our $tripleFlag = 0;
	our $ship = undef;
	our $dontEnd = 0;
	
	getBackdrop();

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
	$confmenu->checkbutton(-label => "Use 3D roids", -variable => \$generate3Droids, -onvalue => 1, -offvalue => 0);
	$mw->bind('<Control-s>'=>[\&confShip]);
	my $toolmenu = $menuframe->Menubutton(-text=>'Help', -relief=>'raised')->pack(-side=>'left');
	$toolmenu->command(-label=>'Instructions',-command=>[\&dispInstructions]);
	$toolmenu->command(-label=>'High Scores',-command=>[\&highscore]);
	$mw->bind($confmenu,'<Enter>', sub{$confmenu->configure(-relief=>'sunken');});
	$mw->bind($confmenu,'<Leave>', sub{$confmenu->configure(-relief=>'raised');});
	$mw->bind($toolmenu,'<Enter>', sub{$toolmenu->configure(-relief=>'sunken');});
	$mw->bind($toolmenu,'<Leave>', sub{$toolmenu->configure(-relief=>'raised');});
	my $g = ($mw->screenwidth()-5)."x".($mw->screenheight()-60)."+0+2"; #reduce height for windows bar and borders
	$mw->geometry($g);
	$mw->resizable(0,0);
	$cnv = $userframe->Canvas(-width=>$cx, -height =>$cy, -borderwidth=>0, -background=>'black')->pack(-side=>'left');
	$mw->update; #needed for $canvas->Height to work
	$tdc = ThreeDCubesTest->new(\$cnv, \$mw, \@lightsource,0,0);
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
	if (-f $backdropFile && ! defined($mw->imageNames)){
		$mw->Photo($backdropTag, -format => 'jpeg', -file => $backdropFile);
	}
	if (defined($mw->imageNames) && @{$mw->imageNames} > 0){
		$cnv->createImage($cx/2,$cy/2, -image=>$backdropTag, -anchor=>'center', -tags=>'bg');
	}else{
		_createStars(\$cnv);
	}
	my $tempx = int(($cx+30)/2);
	my $ctlf = $mw->Frame(-width=>$tempx, -height=>100, -background => 'black', -borderwidth=>2)->pack;
	$cntl = $ctlf->Canvas(-width=>$tempx, -height =>67, -background => 'black')->grid(-column=>0, -row=>0, -pady=>0);
	$ctlf->Scale(-orient=>'horizontal',-from=>1,-to=>$maxlevel,-tickinterval=>1,-background=>'black', -foreground=>'white', -length=>$tempx-5, -width=>10,
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
	#$mw->bind('<s>'=>[\&skeydown]);
	#$mw->bind('<KeyRelease-s>'=>[\&skeyup]);
	$mw->bind('<b>'=>[\&useBomb]);
	$mw->bind('<c>'=>[\&useCrystal]);
	
	$mw->bind('<P>'=>[\&stop]);
	$mw->bind('<D>'=>[\&dkeydown]);
	$mw->bind('<KeyRelease-D>'=>[\&dkeyup]);
	$mw->bind('<A>'=>[\&akeydown]);
	$mw->bind('<KeyRelease-A>'=>[\&akeyup]);
	$mw->bind('<W>'=>[\&wkeydown]);
	$mw->bind('<KeyRelease-W>'=>[\&wkeyup]);
	#$mw->bind('<S>'=>[\&skeydown]);
	#$mw->bind('<KeyRelease-S>'=>[\&skeyup]);
	$mw->bind('<B>'=>[\&useBomb]);
	$mw->bind('<C>'=>[\&useCrystal]);
	$mw->bind('<FocusOut>'=>[\&focusOut]);
	$mw->bind('<FocusIn>'=>[\&focusIn]);
	
	$cntl->createText(10, 33, -text=>'SCORE:', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white');
	$cntl->createText(75, 33, -text=>$score, -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'scoretext');
	$cntl->createText(150, 33, -text=>'ALIVE', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'green', -tags=>'deadtext');
	$cntl->createText(225, 33, -text=>'NORMAL', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'specialtext');
	$cntl->createText(370, 33, -text=>'0', -anchor=>'w', -font=>'{Arial Bold} 10', -fill=>'white', -tags=>'countdown');

	_resetShip();
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
		push(@lines,'T - Tracking Rounds (Home in on nearest roid. Not with Uber Ray)');
		push(@lines,'L - Beam Rounds');
		push(@lines,'S - Sentry Rounds');
		push(@lines,'W - Shockwave (Asteroid Miners\' best friend. Alien not affected)');
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
		my $sf = $w->Scrolled('Canvas', -width=>450, -height =>400, -highlightbackground=>'black', -background=>'#E7FFC2', -scrollbars=>'e')->pack(-side=>'left');
		
		my $y = 5;
		foreach (@lines)
		{
			$sf->createText(5,$y, -text=>$_, -anchor=>'w');
			$y+=15;
		}
		$y+=20;
		$sf->configure(-scrollregion=>"0 0 450 $y");
	}
}

sub getBackdrop{
	#resize backdrop image to display size
	if (! -f $backdropSource){
		print "No backdrop file\n";
		return;
	}
	
	my $myImage = new GD::Image($cx,$cy);
	my $image = GD::Image->new($backdropSource);
	
	my $sx = $image->width / $cx;
	my $sy = $image->height / $cy;
	
	my $scale = $sx;
	if ($sy < $sx){
		$scale = $sy;
	}
	
	my $sourcew = $cx * $scale;
	my $sourceh = $cy * $scale;
	
	
	$myImage->copyResized($image,0,0, int(($image->width - $sourcew)/2), int(($image->height - $sourceh)/2), $cx,$cy,$sourcew ,$sourceh);
	
	open (OUT, ">$backdropFile") || die "Could not create backdrop file\n";
	binmode OUT;
	print OUT $myImage->jpeg;
	close OUT;
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
	
	$tdc->removeObject($ship->{ID}) if ($ship->{ID} > -1);
	$ship->resetStats();
	$score = 0;
	$lastfire = 0;
	$fire = 0;
	$checkroids = 1;
	$bomb = 0;
	$tripleFlag = 0;
	$alien=undef;
	$drone=undef;
	$specialavailable = undef;
	@specialactive = ();
	$specialonscreentime = 0;
	$roundType = 'STD';
	$roundType = 'BEAM' if ($ship->{guntype} == 2);
	@bloom = ();
	@exhaust = ();
	$heat->reset();
	$momx = 0;
	$momy = 0;
	#$ship->delete('ship');
	$ship->setDimensions($width, $height);
	#$ship->translate(($cx/2)-($width/2),($cy/2)-($height/2),0);
	$ship->shieldOff();
	$ship->shieldOn() if ($ship->{shield} > 0);	
	$ship->{ID} = $tdc->registerObject($ship,\@focuspoint,$ship->{SHADE},($cx/2)-($width/2),($cy/2)-($height/2),0, 0);
	#ship now notionally a 3d element
	
}




sub go
{
	
	return if ($go == 1 || _checkChildren("Configure")==0);
	if ($go == 2){
		clear(1);
		return;
	}
	$music->play('main');
	$go = 1;
	
	my $cycle = 0;
	my $coolingcycle = 0;
	my $nextroid = 1;
	while ($go == 1){
		$lastfire++;
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
			$nextroid = _nextRoidDelay();
		}
		_handlespecials();
		_handleAlien() if ($coolingcycle%2 == 1); #less critical events every second cycle, hopefully aids performance
		_fire() if ($fire == 1);
		my $rotangle = $ship->turn();
		if ($rotangle != 0){
			$tdc->rotate($ship->{ID},'z',$rotangle,$rotangle,1);
		}
		_bank();
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
		my $tdif = $tickTime - ($now-$then);
		my $wait = sprintf "%.3f", $tdif;
		if ($wait > 0){
			select (undef, undef, undef, $wait);
		}
		
	}
}

sub _nextRoidDelay
{
	#get number of cycles before next roid is generated
	#increase generation chance when less than 10 roids, higher level can increase generation too
	my $interval = 15;
	my $maxWait = $interval*$maxlevel;
	my $cnt = scalar keys(%roids);
	if ($cnt < 10)
	{
		$maxWait = ($maxWait / 10) * $cnt;
		$interval = $maxWait/$maxlevel;
	}
	return 10+int(rand($maxWait-($interval*$level)));
}


sub _handleWhale
{
	if (! defined($spacewhale) && int(rand(10000)) ==1){
		$spacewhale = Whale3D->new();
		my @focuspoint = (int($cx/2),int($cy/2),1500);
		$spacewhale->{ID} = $tdc->registerObject($spacewhale,\@focuspoint,'#99BBFF',50,int($cy/(1+rand(9))),800, 0);
	} elsif (defined($spacewhale)){
		my $centre = $spacewhale->getCentre();
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
		$ship->{thrust}+=0.1 if ($ship->{thrust} < $ship->{mspeed});
		($x, $y, $addx, $addy) = $ship->getFireLine($ship->{thrust},0);
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
	
	#if ($ship->{thrust} < $ship->{mspeed}){
		$momx = $momx/1.01;
		$momy = $momy/1.01;
		$addx += $momx;
		$addy += $momy;
		my $sq = ($addx*$addx)+($addy*$addy);
		my $mag = sqrt($sq);
		if ($mag > $ship->{mspeed}){
			my $pc = $mag/$ship->{mspeed};
			$addy=$addy/$pc;
			$addx=$addx/$pc;
		}

	#}
	#else{
	#	$momx=$addx;
	#	$momy=$addy;
	#}
	#move ship	
	if ($addx != 0 || $addy != 0){
		my $centre = $ship->getCentre();
	
		my $movex = $$centre[0]+$addx;
		$movex += $cx if ($movex < 0);
		$movex -= $cx if ($movex > $cx);
		
		my $movey = $$centre[1]+$addy;
		$movey += $cy if ($movey < 0);
		$movey -= $cy if ($movey > $cy);
		
		$tdc->translate($ship->{ID},$movex-$$centre[0], $movey-$$centre[1],0,1);
	
	}
}

sub _handleBomb
{
	my ($x, $y, $x1, $y1) = $cnv->coords('blastwave');
	if (($x1 - $x) > ($cx*0.5)){
		#does not blast whole screen (1/2 distance of x)
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
			$roids{$_}->update();
			_checkBombCollision($_,'blastwave') if($bomb == 1);
			_checkBombCollision($_,'shockwave') if($shockwave && $shockwave>0); 
		}
	}
}

sub _handleBullets
{
	my @btemp = ();
	foreach my $bul (@bullets){
		$bul->draw($cx,$cy,\@bullets,'bullet');
		if ($bul->offScreen($cx,$cy)){
			$bul->delete();
			$bul=undef;
		}else{
			
			my $col = 0;
			$col = _checkBulletCollision($bul) if ($bul->{ROUND} ne 'WAVE');
			if ($col == 1){
				if($bul->removeAfterHit() == 1){
					$bul->delete() ;
					$bul=undef;
				}
				else{
					push(@btemp, $bul);
				}
			}else{
				if ($bul->{ROUND} eq 'TRK' && ($bul->{CNT} == 15 || ($bul->{TRACKING} != 0 && $bul->{TRACKING}->{DEAD}==1)))
				{
					$bul->{TRACKING} = _getNearestRoid($bul->{X}, $bul->{Y});
				}
				push(@btemp, $bul);
			}
		}
	}
	@bullets = @btemp;
}


sub _handlespecials
{
	if (defined($specialavailable)){
		$specialonscreentime++;
	}
	if ($specialonscreentime * $tickTime > 10 && defined($specialavailable) > -1 && @specialactive == 0){
		$specialavailable = undef;
		$specialonscreentime = 0;
		$cnv->delete($specialtag);
	}
	elsif (!defined($specialavailable)){
		my $rand = int(rand(300)); #may make generation rate dependant on level
		#my $rand = 1;
		if ($rand == 1){
			my @temp = grep{$_->{TYPE} ne 'STACKABLE'} @specialactive;
			if (@temp == 0)
			{
				@temp = grep{$_->{TYPE} eq 'GOOD' || $_->{TYPE} eq 'STACKABLE'} @specials2;
			}
			else
			{
				@temp = grep{$_->{TYPE} eq 'STACKABLE'} @specials2;
			}
			#if (@temp >=4){
			#	$specialavailable = $temp[4];
			#}else
			#{
				$specialavailable = $temp[int(rand(scalar @temp-0.01))];
			#}
			
			$specialonscreentime = 0;
			$specialavailable->display;
		}
	}
	
	foreach (@specialactive){
		$_->tick;
		if ($_->hasExpired){
			$_->end;
			shift @specialactive;
		}
	}
	
	if (@specialactive > 0)
	{
		$cntl->itemconfigure('specialtext', -text=>$specialactive[0]->{LABEL});
		$cntl->itemconfigure('countdown', -text=>$specialactive[0]->timeLeft());
	}
	else
	{
		$cntl->itemconfigure('countdown', -text=>"0");
		$cntl->itemconfigure('specialtext', -text=>"NORMAL");
	}
	
	if (defined($specialavailable)){
		$specialavailable->whileDisplaying;
		my ($x, $y, $x1, $y1) = $cnv->coords($specialtag);
		my @obj = $cnv->find('overlapping', $x, $y, $x1, $y1);
		my $del = 0;
		foreach my $id (@obj){
			if (${$cnv->itemcget($id, -tags)}[0] eq $ship->{TAG} && $del == 0){
				my $cnt = scalar @specialactive;
				@specialactive = grep{$_->{LABEL} ne $specialavailable->{LABEL}} @specialactive;
				if ($cnt == scalar @specialactive){
					$specialavailable->start;
				}else{
					$specialavailable->resetTimer;
				}
				push(@specialactive, $specialavailable);
				$specialavailable = undef;
				$sound->play($specialtag);
				$del = 1;
				last;
			}
		}
		$cnv->delete($specialtag) if ($del == 1);
	}
}

sub _breakship
{	
	_newbloom($ship, 'yellow',2);
	while (@bloom > 0){
		_handleBlooms();
		$ship->flyapart();
		$tdc->translate($ship->{ID},0, 0,0,0);
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
		removeRoid($_);

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
			$cnv->createImage($cx/2,$cy/2, -image=>$backdropTag, -anchor=>'center');
		}else{
			_createStars(\$cnv);
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
		my $effect = $alien->checkMissileCollision($ship->{TAG},$k);
			
		_processEffect($effect) if ($effect > -1);
				

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
	if ($effect == 0){ #red missile - die
		$go = 2;
		return;
	}

		_expireSpecials();
	
	#replace with the bad special

	my @temp = grep{$_->{TYPE} eq 'BAD'} @specials2;
	$effect--;
	if ($effect > 0 && $effect < @temp)
	{
		push (@specialactive, $temp[$effect-1]);
	}
}

sub _expireSpecials
{
	$cnv->delete($specialtag); #remove any special icon on screen
	if (@specialactive > 0 || defined($specialavailable)){
	#remove any existing special
		foreach(@specialactive)
		{
			#$_->{STARTTIME}-=20;
			$_->end;
		}
		#$specialavailable = -1;
		@specialactive = ();
		$specialavailable = undef;
	}
}


sub _checkBombCollision
{
	#currently does not affect whales
	my $key = shift;
	my $tag = shift;
	my $obj = $roids{$key};
	my $centre = $obj->getCentre();
	my @t = $cnv->find('overlapping', $$centre[0]-10, $$centre[1]-10, $$centre[0]+10, $$centre[1]+10);
	#is a 20x20 square at the centred on roid, should suffice for now
					
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
 	my @ids; # ID numbers of polygons on screen
 	if ($obj->{ROUND} eq 'EXP'){
 		#proximity/explosive round
		return _checkExplosiveRound($obj);
 	}
 	elsif ($obj->{ROUND}  eq 'BEAM'){
 		#beam weapon
		_checkBeamRound($obj,\@ids); 		
		 		
 	}else{
 	 	#some bullet travel distances may be too long and skip the would be impacted object, check small chunks along bullet line
 	 	#this would currently return tags on the first point where an overlap is found (may be detrimental to piercing rounds)
	 	my $addx = $obj->{ADDX}/3;
 		my $addy = $obj->{ADDY}/3;
 		for (my $i = 4 ; $i--;){
 			my @temp = $cnv->find('overlapping', $obj->{X}-($addx*$i), $obj->{Y}-($addy*$i), $obj->{X}-($addx*$i), $obj->{Y}-($addy*$i));
 			@temp = grep{${$cnv->itemcget($_, -tags)}[0] =~ m/roid|drone|alien|whale/}@temp;
 			if (@temp > 0){
 				push (@ids,@temp); 
 				$i=0;
 			}
 		}
 	}
	my $ret = 0;
	my $prev = -1;
	@ids = sort @ids;
	foreach my $t (@ids){
		next if ($t == $prev || $t == 1);
		$prev = $t;
		if (defined($alien) && $t == $alien->{ID}){
			my $kill = $alien->hit();
			if ($kill==1){
				$score+=150 ;
				$sound->play('aliendie');
			}
			$ret = 1;
			last if ($obj->removeAfterHit() == 1);
		}
		elsif (defined($drone) && $t == $drone->{ID}){
			$score+=250 ;
			$cnv->delete($drone->{ID});
			$cnv->delete($drone->{BULLET}->{ID}) if (defined($drone->{BULLET}));
			$drone = undef;
			$sound->play('aliendie');
			$ret = 1;
			last if ($obj->removeAfterHit() == 1);
		}elsif (defined($spacewhale) && $spacewhale->{STATE} == 1 && (scalar grep{$_==$t}@{$tdc->getItemIds($spacewhale->{ID})}) > 0){
				#you killed the whale! arrrrgh!
				#badness will happen here! - will bring in a drone
				#could do with a whale sound
				$drone = new Drone(1,1,1,\$cnv,'BEAM'); #laser armed! ehehehe!
				$score-=300;
				$tdc->removeObject($spacewhale->{ID});
				_newbloom($spacewhale, 'red',10);
				$spacewhale=undef;
				last if ($obj->removeAfterHit() == 1);
		}
		else
		{
			$ret = _checkBulletRoidCollision($obj, $t);
			last if ($ret == 1 && $obj->removeAfterHit() == 1);
		}
	}
	return $ret;
}

sub _checkBulletRoidCollision
{
	my $obj = shift;
	my $t = shift;
	my $tag = ${$cnv->itemcget($t, -tags)}[1];
	my $ret = 0;
	if ($tag =~ m/roid:(\d+)/){
		$t = $1;
	} 
	return 0 if (!$roids{$t});
	if ($roids{$t}->{SHADE} eq '#999999' || $roids{$t}->{SHADE} eq 'black'){ #should use a proper marker
		#darkroid
		$ret = 1;
		$roids{$t}->{HP}-=1;
		if ($roids{$t}->{HP} == 0){
			$score+=(15*$level);
			$sound->play('hit1');
			_newbloom($roids{$t}, 'white',2);
			removeRoid($t);
		}else{
			$sound->play('hit2') if ($obj->{ROUND} ne 'BEAM'); #beam will destroy in one hit usually, don't bother playing this sound
		}
	}else{
		if ($roids{$t}->{SIZE} > 1){
			foreach(0..1)
			{
				my ($argx, $argy,$size, $movex, $movey) = _splitRoid($roids{$t});
				my $r;
				if ($generate3Droids){
					$r = Roid3D->new($movex, $movey,  $size, 1);
					$r->{ID} = $tdc->registerObject($r,\@focuspoint,$roids{$t}->{SHADE},$argx, $argy,80,0,1);
					$r->{TAG} = "roid roid:".$r->{ID};
				}else{
					$r = Roid->new($argx, $argy, $size, $movex, $movey, 1, $roids{$t}->{SHADE}, \$cnv);
					$r->update();
				}
				$roids{$r->{ID}} = $r;
			}
		}else{
			$score+=(2*$level);
			_newbloom($roids{$t}, 'white',2);
		}
		$ret=1;
		$sound->play('hit1');
		removeRoid($t);
	}
	return $ret;
}

sub _splitRoid
{
	my $obj = shift;
	my $size = int($obj->{SIZE}/2);
	my $rand = 50+int(rand(100)); 
	my $mx = ($obj->{MX}/100)*$rand; #new x vector between 50% and 150% of original
	$mx = $mx*-1 if ($rand % 4 == 0); #25% change to reverse direction
	$rand = 50+int(rand(100));
	my $my = ($obj->{MY}/100)*$rand;
	$my = $my*-1 if ($rand % 4 == 0);
	my $centre = $obj->getCentre;
	return ($$centre[0], $$centre[1], $size, $mx, $my);

}


sub _checkExplosiveRound
{
	my $obj = shift;
	my @temp = $cnv->find('overlapping', $obj->{X}-30, $obj->{Y}-30, $obj->{X}+30, $obj->{Y}+30);
	@temp = grep{${$cnv->itemcget($_, -tags)}[0] =~ m/roid|drone|alien|whale/;}@temp;
	if (@temp > 0){
		#burst
		$obj->doExplosion(\@bullets);
		
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

sub _getNearestRoid
{
	my ($x, $y) = @_;
	my $roid = 0;
	my $dist = -1;
	
	foreach my $rkey (keys %roids){
		my $centre = $roids{$rkey}->getCentre();
		my $dx = $x - $$centre[0];
		my $dy = $y - $$centre[1];
		my $distToRoid = sqrt(($dx*$dx)+($dy*$dy));
		if ($distToRoid < $dist || $dist < 0){
			$dist = $distToRoid;
			$roid = $roids{$rkey};
		}
	}
	return $roid;
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
	if ($generate3Droids){
		$tdc->removeObject($roids{$key}->{ID});
	}else{
		$roids{$key}->delete;
	}
	$roids{$key}=undef;
	delete $roids{$key};
}

sub _generateRoid
{
	return if (scalar keys(%roids) > ($cx*$cy) / 30000); #should maintain same roid density across different sized screens
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
	my $size = 2;
	my $hp = 1;
	my $colour = "#DDDDDD";
	$size = 4 if ($largeroid == 0 && $darkroid > 0);
	$hp = 7 if ($darkroid == 0);
	$colour = 'black' if ($darkroid == 0 && $generate3Droids == 0);
	$colour = '#999999' if ($darkroid == 0 && $generate3Droids);
	$colour = '#FFFFFF' if ($darkroid > 0 && $generate3Droids);
	if ($generate3Droids)
	{
		$r = Roid3D->new($movex, $movey, $size, $hp);
		$r->{ID} = $tdc->registerObject($r,\@focuspoint,$colour,$argx, $argy,80,0,1);
		$r->{TAG} = "roid roid:".$r->{ID};
	}
	else
	{
		$r = Roid->new($argx, $argy, $size, $movex, $movey, $hp, $colour, \$cnv);
		$r->update;
	}
	$roids{$r->{ID}} = $r;
}

sub stop
{
	#should rename as pause
	$go = 0;
}

sub _fire
{	
	if ($go){

		if ($lastfire * $tickTime > $ship->{rof}){
			$lastfire = 0;
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
				if ($tripleFlag == 1){
					_generateBullet($ship->{pspeed},3);
					_generateBullet($ship->{pspeed},4);
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
	my ($xs, $ys, $addxs, $addys) = $ship->getFireLine($ship->{thrust},0);
	#momentum of ship now imparted to bullets
	my $b = Bullet->new($x, $y, $addx+$addxs+$momx, $addy+$addys+$momy, \$cnv, $roundType);
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
	#if (@specialactive == 0){
		$checkroids = 0;
		$ship->setColour('yellow');
		return 1;
	#}
	#return 0;
}

sub _endinvuln
{
	$checkroids = 1;
	#$cnv->itemconfigure('ship', -fill=>$ship->{SHADE});
	$ship->setColour($ship->{basecol});
}

sub _dotriplefire
{
	$tripleFlag = 1;
	return 1;
}

sub _endtriplefire
{
	$tripleFlag = 0;
}

sub _newbomb
{
	if ($ship->{bomb} < $ship->{basebomb}){ 
		_specialbox('black','white','B','white');
	}else{
		$specialavailable = undef;
	}
}

sub _collectbomb
{
	#not a timed effect reset flags
	$ship->{bomb}+=1;

	$specialavailable = undef;
	$cntl->itemconfigure('countdown', -text=>'0');
	return 0;
}

sub _incROF
{
	_specialbox('purple','yellow','R','yellow');
}

sub _doincROF
{
		$ship->{rof} = $ship->{rof}/2;
		$ship->{heat} = $ship->{heat}/3; #let them have fun
		return 1;
}

sub _endincROF
{
	$ship->{rof} = $ship->{rof}*2;
	$ship->{heat} = $ship->{heat}*3;
}


sub _ammoBox
{
	my $bgcolour = shift;
	my $text = shift;
	my $txtcolour = shift;
	if ($roundType eq 'STD'){
		 _specialbox($bgcolour,$txtcolour,$text,$txtcolour) ;
	}else{
		#$specialavailable = -1;
		$specialavailable = undef;
	}
}

sub _doAmmo{
	my $type = shift;
	#if(@specialactive == 0){
		$roundType = $type;
		my $text;
		if ($type eq 'WAVE'){$ship->{rof} = 1;$ship->{pspeed} = 10;}
		if ($type eq 'SEN') {$ship->{rof} = 2.5;$ship->{pspeed} = 2;}
		return 1;
	#}
	#return 0;
}




sub _endRounds
{
	$roundType = 'STD';
	$ship->{pspeed} = $ship->{basepspeed};
	$ship->{rof} = $ship->{baserof};
}




sub _blinky
{
	#may want to reduce frequency on this one
	if ($crystal == -1 && time() % 3 == 0){
		my $x = int(rand($cx-20));
		my $y = int(rand($cy-20));
		$cnv->createOval($x, $y, $x+30, $y+30, -fill=>'#FF0000', -outline=>'red', -tags=>[$specialtag,"plus"]);
	}else{
		#$specialavailable = -1;
		$specialavailable = undef;
	}
	
}

sub _blinkyOnScreen
{
	my $colour = $cnv->itemcget($specialtag,-fill);
	$colour = hex(substr($colour,3,2));
	my $dir = ${$cnv->itemcget($specialtag,-tags)}[1];
	if ($dir eq "plus"){
		$colour+=15;
		if ($colour > 255){
			$colour=255;
			$cnv->itemconfigure($specialtag,-tags=>[$specialtag,"minus"]);
		}
	}else{
		$colour-=15;
		if ($colour < 0){
			$colour=0;
			$cnv->itemconfigure($specialtag,-tags=>[$specialtag,"plus"]);
		}	
	}
	my $newcolour="#FF".dec2hex($colour)."00";
	$cnv->itemconfigure($specialtag,-fill=>$newcolour);
}

sub _doBlinky
{
	#do side game
	$specialavailable = undef;
	$cntl->itemconfigure('countdown', -text=>'0');
	$cnv->delete($specialtag);
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
					my @temp = grep{$_->{TYPE} ne 'BAD' && $_->{LABEL} ne 'BLINKY'} @specials2;
					$crystal = $temp[int(rand(scalar @temp - 0.01))];
					#will need to update a marker
					my $c = _getCrystalColour($crystal);
					$cframe->configure(-background=>$c);
				}elsif ($p eq "Hit Gate"){
					#activate bad special
					_expireSpecials();
					my @temp = grep{$_->{TYPE} eq 'BAD'} @specials2;
					push (@specialactive, $temp[int(rand(scalar @temp - 0.01))]);
					$ret = 1;
				}
				#incomplete course does nothing
			}
		}
	}
	close PROG;
	$mw->deiconify;
	$mw->focusForce;
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
	return $ret;
}

sub _getCrystalColour{
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
	$ship->{turnrate} = $ship->{turnrate}*-1;
	return 1;
}

sub _doSlow{
	$ship->{mspeed} = $ship->{mspeed}/3;
	return 1;
}

sub _doFast{
	$ship->{mspeed} += 7;
	return 1;
}

sub _doLoseGun{
	$fire = -1;
	return 1;
}

sub _doTurnRate{
	$ship->{turnrate} -= 2;
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
	$cnv->createRectangle($x, $y, $x+20, $y+20, -fill=>$colour, -outline=>$outline, -tags=>$specialtag);
	$cnv->createText($x+10, $y+10, -text=>$text, -anchor=>'c', -font=>'{Arial Bold} 10', -fill=>$textcolour, -tags=>$specialtag);
}

sub _createStars
{
	my $canvas = shift;
	for (1..80){
		my $x = int(rand($cx));
		my $y = int(rand($cy));
		my $size = int(rand(3));
		my $colour = 'white';
		my $randcolour = int(rand(3));
		if ($randcolour < 1){
			$colour = '#FFFFAA';
		}elsif ($randcolour < 2){
			$colour = '#FFAAAA';
		}
		$$canvas->createOval($x-1-$size, $y-1-$size, $x+1, $y+1, -fill=>$colour, -tags=>'star');
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
	$ship->{targetbanking} = -30;
	$ship->{turning} = 1;
	}
}

sub dkeyup
{
	if ($ddown==1){
	$ddown = 0;
	$ship->{targetbanking} = 0;
	$ship->{turning} = 0;
	}
}

sub akeydown
{	
	if ($ddown==0){
	$adown = 1;
	$ship->{targetbanking} = 30;
	$ship->{turning} = -1;
	}
}

sub akeyup
{
	if ($adown==1){
	$adown=0;
	$ship->{targetbanking} = 0;
	$ship->{turning} = 0;
	}
}

sub _bank
{
	#hopefully gives some impression of banking in a turn
	return if ($ship->{currentbanking} == $ship->{targetbanking});
	
	my $bankangle = 2;
	$bankangle = -2 if ($ship->{currentbanking} > $ship->{targetbanking}); 
	
	$ship->{currentbanking} += $bankangle;
	
	$tdc->rotate($ship->{ID},'z',-$ship->{shipangle},-$ship->{shipangle},1) if ($ship->{shipangle} != 0);
	$tdc->rotate($ship->{ID},'y',$bankangle,$bankangle,1);
	$tdc->rotate($ship->{ID},'z',$ship->{shipangle},$ship->{shipangle},1) if ($ship->{shipangle} != 0);
}

sub wkeydown
{
	#$ship->{thrust} = $ship->{mspeed};
	$ship->{thrust} = 1 if ($ship->{thrust} == 0);

}

sub wkeyup
{
	my ($x, $y, $addx, $addy) = $ship->getFireLine($ship->{thrust},0);
	$momx = $addx+$momx;
	$momy = $addy+$momy;
	$ship->{thrust} = 0;
}

#sub skeydown
#{
#	#$thrust = -1; not good with momentum as currently coded
#	$ship->{thrust} = 0; 
#}

#sub skeyup
#{
#	$ship->{thrust} = 0;
#}

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
	if (@specialactive == 0 && $crystal > -1){ #do not activate if a special is active
		#print "$crystal\n";
		$cnv->delete($specialtag); #remove any special icon on screen
		push (@specialactive, $crystal);
		$crystal->start;
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