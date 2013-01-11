package Configure;

use strict;
use Tk;
use ThreeDCubesTest;
use Ship3D;
use ColourPicker;



sub new{
	my $self={};
	shift;
	my $mw = shift;
	$self->{MW} = $mw;

	my $slots = 5;
	my @equipment;
	my @stats;
	my $confheat = 3;
	my $confrof = 0.3;
	my $confpspeed = 8;
	my $confmspeed = 5;
	my $confshield = 0;
	my $confguns = 1;
	my $equipheat = 0;
	my $equiprof = 0;
	my $equippspeed = 0;
	my $equipmspeed = 0;
	my $selectedSlot = 0;
	my @selections = (0) x $slots;
	$equipment[0] = ['Mining Charge','Combat Driver', 'Uber Ray']; #main gun
	$stats[0][0] = [3,0,0,0]; #heat, rof mod, projectile speed mod, movement, speed mod - i.e. changes from standard, 
	$stats[0][1] = [4,-0.07,2,-0.5];
	$stats[0][2] = [10,0.2,0,-1];
	$equipment[1] = ['Nothing','Deflector Screen','Impact Barrier','Heat Sink']; 
	$stats[1][0] = [0,0,0,0,0];
	$stats[1][1] = [1,0,0,-0.5,0];
	$stats[1][2] = [1,0.1,-1,-0.5];
	$stats[1][3] = [-4,0,0,-1];
	$equipment[2] = ['Nothing','Gun','Heat Sink','Booster'];
	$stats[2][0] = [0,0,0,0];
	$stats[2][1] = ['+gun',0,0,0];
	$stats[2][2] = [-1,0,0,0];
	$stats[2][3] = [1,0,0,1];
	$equipment[3] = ['Nothing','Gun','Heat Sink','Booster']; 
	$stats[3][0] = [0,0,0,0];
	$stats[3][1] = ['+gun',0,0,0];
	$stats[3][2] = [-1,0,0,0];
	$stats[3][3] = [1,0,0,1];
	$equipment[4] = ['Standard Engine','Pursuit Engine','Cold Gas Engine']; 
	$stats[4][0] = [0,0,0,0];
	$stats[4][1] = [1,0,0,1];
	$stats[4][2] = [-1,0,0,-1];

	$selectedSlot = 1;

	$self->{slots} = \$slots;
	$self->{equipment} = \@equipment;
	$self->{stats} = \@stats;
	$self->{heat} = \$confheat;
	$self->{rof} = \$confrof;
	$self->{pspeed} = \$confpspeed;
	$self->{mspeed} = \$confmspeed;
	$self->{shield} = \$confshield;
	$self->{guns} = \$confguns;
	$self->{equipheat} = \$equipheat;
	$self->{equiprof} = \$equiprof;
	$self->{equippspeed} = \$equippspeed;
	$self->{equipmspeed} = \$equipmspeed;
	$self->{selectedSlot} = \$selectedSlot;
	$self->{selections} = \@selections; 
	$self->{guntype} = 0;
	$self->{colour} = '#ff0000';


	buildScreen($self);
	bless $self;
	_fillSelection($self);
	_fillStats($self);
	$$mw->update;
	return $self;

}

sub renew
{
	my $self=shift;
	my $mw = shift;
	$self->{MW} = $mw;
	${$self->{selectedSlot}} = 1;
	buildScreen($self);
	_fillSelection($self);
	_fillStats($self);
	$$mw->update;
}

sub buildScreen
{
	my $self = shift;
	my $mw = $self->{MW};
	my $userframe = $$mw->Frame(-borderwidth=>2, -width=>230)->pack(-fill=>'y', -side=>'left');
	my $cnv = $$mw->Canvas(-width=>450,-background=>'white')->pack(-side=>'right', -fill=>'both');
	my @lightsource = (225, 250, -50); 
	$$mw->update; #must do this so we get the canvas size (as it is dynamically filled)
	my $tdc = ThreeDCubesTest->new(\$cnv, $mw, \@lightsource);
	
	my $ship = Ship3D->new();
	my @focus = (225,225,1000);
	my $shipobj = $tdc->registerObject($ship,\@focus,$self->{colour},25,25,50,0,0);
	my @rotation = ('x',1.5,90);

	$tdc->rotate($shipobj,'x',100,100);
	$cnv->createOval(215,325,235,345, -width=>2, -outline=>'black', -tags=>'marker');
	$cnv->createLine(0,45,50,45, -width=>2, -fill=>'black', -tags=>'marker');
	$cnv->createLine(50,45,50,335, -width=>2, -fill=>'black', -tags=>'marker');
	$cnv->createLine(50,335,215,335, -width=>2, -fill=>'black', -tags=>'marker');
	
	$userframe->Label(-text=>'Slots',-font=>'{Arial Bold} 10')->pack(-fill=>'x');
	my $buttons = $userframe->Frame()->pack(-fill=>'x');
		
	for my $i (1..${$self->{slots}}){
		$buttons->Button(-text => $i, -padx=>13, -command=>[sub{${$self->{selectedSlot}}=$i;_updateView($self);_fillSelection($self);_fillStats($self);}], -background=>'#cccccc')->grid(-column=>($i-1), -row=>0);
	}
	$userframe->Label(-text=>' ')->pack(-fill=>'x');
	$userframe->Label(-text=>'Equipment',-font=>'{Arial Bold} 10')->pack(-fill=>'x');
	my $equipFrame = $userframe->Frame()->pack();
	my $selector=$equipFrame->Scrolled('Listbox', -width=>35, -height=>4, -selectmode=>'single', -scrollbars=>'e')->pack(-side=>'right');
	$selector->bind('<Button-1>',sub{_fillStats($self);});
	
	$userframe->Button(-text=>'Fit Part', -command=>[sub{_fitpart($self);}], -background=>'#cccccc')->pack(-fill=>'x');
	$userframe->Label(-text=>' ')->pack(-fill=>'x');
	$userframe->Label(-text=>'Equipment Stats',-font=>'{Arial Bold} 10')->pack(-fill=>'x');
	my $equipStats = $userframe->Frame(-background=>'black')->pack(-ipady=>1,-ipadx=>1);
	
	$equipStats->Label(-text=>'Heat',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>0, -row=>0, -padx=>1, -pady=>1);
	$equipStats->Label(-text=>'Rof',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>1, -row=>0,-padx=>1, -pady=>1);
	$equipStats->Label(-text=>'P Speed',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>2, -row=>0,-padx=>1, -pady=>1);
	$equipStats->Label(-text=>'M Speed',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>3, -row=>0,-padx=>1, -pady=>1);
		
	$equipStats->Label(-textvariable=>$self->{equipheat},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>0, -row=>1, -pady=>1);
	$equipStats->Label(-textvariable=>$self->{equiprof},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>1, -row=>1, -pady=>1);
	$equipStats->Label(-textvariable=>$self->{equippspeed},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>2, -row=>1, -pady=>1);
	$equipStats->Label(-textvariable=>$self->{equipmspeed},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>3, -row=>1, -pady=>1);
		
	$userframe->Label(-text=>' ')->pack( -fill=>'x');
	$userframe->Label(-text=>'Ship Stats',-font=>'{Arial Bold} 10')->pack(-fill=>'x');
	my $shipStats = $userframe->Frame(-background=>'black')->pack(-ipady=>1,-ipadx=>1);
	
	$shipStats->Label(-text=>'Heat',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>0, -row=>0, -padx=>1, -pady=>1);
	$shipStats->Label(-text=>'Rof',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>1, -row=>0,-padx=>1, -pady=>1);
	$shipStats->Label(-text=>'P Speed',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>2, -row=>0,-padx=>1, -pady=>1);
	$shipStats->Label(-text=>'M Speed',-font=>'{Arial Bold} 9', -width=>'7')->grid(-column=>3, -row=>0,-padx=>1, -pady=>1);
	
	$shipStats->Label(-textvariable=>$self->{heat},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>0, -row=>1, -pady=>1);
	$shipStats->Label(-textvariable=>$self->{rof},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>1, -row=>1, -pady=>1);
	$shipStats->Label(-textvariable=>$self->{pspeed},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>2, -row=>1, -pady=>1);
	$shipStats->Label(-textvariable=>$self->{mspeed},-font=>'{Arial Bold} 9',-width=>'7')->grid(-column=>3, -row=>1, -pady=>1);
		
	my $sshield = $userframe->Label(-text=>'Shield: '.${$self->{shield}},-font=>'{Arial Bold} 9',-width=>'31', -anchor=>'w')->pack(-fill=>'x', -pady=>1);
	$userframe->Button(-text=>'Done', -command=>[sub{_done($self);}], -background=>'#cccccc')->pack(-fill=>'x');
	$userframe->Button(-text=>'Colour', -command=>[sub{_pickColour($self);}], -background=>'#cccccc')->pack(-fill=>'x');
	
	$self->{CNV} = \$cnv;
	$self->{TDC} = \$tdc;
	$self->{sshield} = \$sshield;
	$self->{selector} = \$selector;
	$self->{shipobj} = \$shipobj;
	$self->{rotation} = \@rotation;

	
}

sub _pickColour
{
	my $self=shift;
	my $w=${$self->{MW}}->Toplevel(-class=>'Colour Picker');
	$w->resizable(0,0);
	my $cp = ColourPicker->new(\$w);
	$w->waitWindow;
	${$self->{TDC}}->setColour(${$self->{shipobj}}, $cp->{COLOUR});
	$self->{colour} = $cp->{COLOUR};
}

sub _done
{
	my $self=shift;
	${$self->{MW}}->destroy;
}

sub getStats
{
	print "Mooo\n";
}

sub _fillSelection{
	my $self = shift;
	my $slot = ${$self->{selectedSlot}};
	my $equipment = $self->{equipment};
	$slot--;
	${$self->{selector}}->delete(0,'end') if (${$self->{selector}}->size > 0);
	for (my $i = 0 ; $i < @{$$equipment[$slot]} ; $i++){
		${$self->{selector}}->insert('end',$$equipment[$slot][$i]);
	}
	${$self->{selector}}->activate(0);
	${$self->{selector}}->selectionSet(${$self->{selections}}[$slot]);
	${$self->{MW}}->update;
}


sub _fillStats{
	my $self = shift;
	my $slot = ${$self->{selectedSlot}};
	$slot--;
	my @selection = ${$self->{selector}}->curselection;
	${$self->{equipheat}} = ${$self->{stats}}[$slot][$selection[0]][0];
	${$self->{equiprof}} = ${$self->{stats}}[$slot][$selection[0]][1];
	${$self->{equippspeed}} = ${$self->{stats}}[$slot][$selection[0]][2];
	${$self->{equipmspeed}} = ${$self->{stats}}[$slot][$selection[0]][3];
	${$self->{MW}}->update;
}


sub _fitpart{
	my $self = shift;
	my $slot = ${$self->{selectedSlot}};
	$slot--;
	
	if ($slot == 0 ){ #main gun slot, may need to alter any slave gun slots
		${$self->{heat}} -= ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0]*${$self->{guns}};
	}else{
	
	if (${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0] eq '+gun'){
		${$self->{heat}} -= ${$self->{stats}}[0][${$self->{selections}}[0]][0];
		${$self->{guns}}--;
	}else{
		${$self->{heat}} -= ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0];
	}
	}
	
	${$self->{rof}} -= ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][1];
	${$self->{pspeed}} -= ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][2];
	${$self->{mspeed}} -= ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][3];
	
	
	my @selection = ${$self->{selector}}->curselection;
	${$self->{selections}}[$slot] = $selection[0];

	if ($slot == 0 ){ #main gun slot, may need to alter any slave gun slots
		${$self->{heat}} += ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0]*${$self->{guns}};
		$self->{guntype} = $selection[0];
	}else{
	
	if (${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0] eq '+gun'){
		${$self->{heat}} += ${$self->{stats}}[0][${$self->{selections}}[0]][0];
		${$self->{guns}}++;
	}else{
		${$self->{heat}} += ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][0];
	}
	}
	${$self->{rof}} += ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][1];
	${$self->{pspeed}} += ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][2];
	${$self->{mspeed}} += ${$self->{stats}}[$slot][${$self->{selections}}[$slot]][3];
	
	if ($slot == 1){
		if (${$self->{selections}}[1] == 1 || ${$self->{selections}}[1] == 2){
			${$self->{shield}} = ${$self->{selections}}[1];
			
		}else{
			${$self->{shield}} = 0;
		}
		${$self->{sshield}}->configure(-text=>"Shield: ".${$self->{shield}});
	}
	${$self->{MW}}->update;
}

sub _updateView{
	my $self = shift;	
	${$self->{CNV}}->delete('marker');
	#rotate ship and mark hardpoint
	
	#first reverse current rotation
	${$self->{TDC}}->rotate(${$self->{shipobj}},'x',-2,15);
	${$self->{TDC}}->rotate(${$self->{shipobj}},${$self->{rotation}}[0],${$self->{rotation}}[1]*-1,${$self->{rotation}}[2]);
	
	if (${$self->{selectedSlot}} == 1){
		@{$self->{rotation}} = ('x',2,90);
	}
	elsif (${$self->{selectedSlot}} == 2){
		@{$self->{rotation}}  = ('x',-2,90);
	}
	elsif (${$self->{selectedSlot}} == 3){
		@{$self->{rotation}}  = ('y',2,50);
	}
	elsif (${$self->{selectedSlot}} == 4){
		@{$self->{rotation}}  = ('y',-2,50);
	}
	elsif (${$self->{selectedSlot}} == 5){
		@{$self->{rotation}}  = ('y',3,180);
	}
	
	${$self->{TDC}}->rotate(${$self->{shipobj}},${$self->{rotation}}[0],${$self->{rotation}}[1],${$self->{rotation}}[2]);
	${$self->{TDC}}->rotate(${$self->{shipobj}},'x',2,15);
	
	${$self->{CNV}}->createLine(0,45,50,45, -width=>2, -fill=>'black', -tags=>'marker');
	if (${$self->{selectedSlot}} == 1){
		${$self->{CNV}}->createOval(215,325,235,345, -width=>2, -outline=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,45,50,335, -width=>2, -fill=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,335,215,335, -width=>2, -fill=>'black', -tags=>'marker');
	}
	elsif (${$self->{selectedSlot}} == 2){
		${$self->{CNV}}->createOval(215,215,235,235, -width=>2, -outline=>'yellow',-tags=>'marker');
		${$self->{CNV}}->createLine(50,45,50,225, -width=>2, -fill=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,225,215,225, -width=>2, -fill=>'black', -tags=>'marker');
	}
	elsif (${$self->{selectedSlot}} == 3){
		${$self->{CNV}}->createOval(255,200,275,220, -width=>2, -outline=>'yellow',-tags=>'marker');
		${$self->{CNV}}->createLine(50,45,50,210, -width=>2, -fill=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,210,255,210, -width=>2, -fill=>'black', -tags=>'marker');
	}
	elsif (${$self->{selectedSlot}} == 4){
		${$self->{CNV}}->createOval(175,200,195,220, -width=>2, -outline=>'yellow',-tags=>'marker');
		${$self->{CNV}}->createLine(50,45,50,210, -width=>2, -fill=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,210,175,210, -width=>2, -fill=>'black', -tags=>'marker');
	}
	elsif (${$self->{selectedSlot}} == 5){
		${$self->{CNV}}->createOval(215,225,235,245, -width=>2, -outline=>'yellow',-tags=>'marker');
		${$self->{CNV}}->createLine(50,45,50,235, -width=>2, -fill=>'black', -tags=>'marker');
		${$self->{CNV}}->createLine(50,235,215,235, -width=>2, -fill=>'black', -tags=>'marker');
	}
	${$self->{MW}}->update;
}

1;
