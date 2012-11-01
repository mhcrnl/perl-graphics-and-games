use lib '..\perllib';
use ThreeDCubesTest;
use Cross;
use Torus;
use Tk;
use Tk::DialogBox;
use strict;




		my $w = MainWindow->new(-background=>'black');
		$w->OnDestroy([\&endit]);
		my $ctrlcnv = $w->Canvas(-height=>310, -width=>150)->grid(-column=>0, -row=>0, -rowspan=>3, -pady=>2, -padx=>2, -sticky=>'nsew');
		my @lightsource = (200, 200, -800); 
		my $threeDobj = ThreeDCubesTest->new(\$ctrlcnv, \$w, \@lightsource,0);
		my @focuspoint = (0); #length less than 3 should use default
		my $torusobj = Torus->new(25, 25);
		my $torus = $threeDobj->registerObject($torusobj,\@focuspoint,'green',75,80,80);
		$threeDobj->rotate($torus,'y',50,50);
		$w->update;
		$threeDobj->rotate($torus,'y',15,360);
		my $crossobj = Cross->new(150, 30, 30);
		my $cross = $threeDobj->registerObject($crossobj,\@focuspoint,'red',75,225,75);
		$threeDobj->rotate($cross,'y',-40,40);
		$w->update;
		$threeDobj->rotate($cross,'y',2,360);
		our $nextxo = 'o';
		my @slaves;
		for (my $i = 0; $i<3 ; $i++){
			for (my $j = 1; $j<4 ; $j++){
				push(@slaves,$w->Canvas(-height=>100, -width=>100, -background=>'white')->grid(-column=>$j, -row=>$i, -pady=>2, -padx=>2));
				$w->bind($slaves[@slaves-1], '<Button-1>', [\&drawxo, \$w,\$slaves[@slaves-1]]);
			}
		}
		
		MainLoop;


sub drawxo
{
	shift;
	my $w = shift;
	my $cnv=shift;
	my @diag1;
	my @diag2;
	my $flag = 0;
	if ($nextxo ne 'w'){
	if (! $$cnv->gettags('x') && ! $$cnv->gettags('o')){
	$flag = 1;
	($nextxo eq 'o') ? drawo($cnv) : drawx($cnv);
	}
	for (my $i = 0 ; $i < 3 ; $i++){
		my @slaves = $$w->gridSlaves(-row=>$i);
		highlight($w,$i,-1) if ($slaves[0]->find('withtag','o') && $slaves[1]->find('withtag','o') && $slaves[2]->find('withtag','o'));
		highlight($w,$i,-1) if ($slaves[0]->find('withtag','x') && $slaves[1]->find('withtag','x') && $slaves[2]->find('withtag','x'));
		$diag1[$i] = $slaves[$i]->gettags('all');
		$diag2[$i] = $slaves[2-$i]->gettags('all');
	}
	
	highlight($w,1,1) if ($diag1[0][0] eq $diag1[1][0] && $diag1[1][0] eq $diag1[2][0] && $diag1[0][0] ne '');
	highlight($w,2,2) if ($diag2[0][0] eq $diag2[1][0] && $diag2[1][0] eq $diag2[2][0] && $diag2[0][0] ne '');
	
	for (my $i = 0 ; $i < 3 ; $i++){
		my @slaves = $$w->gridSlaves(-column=>$i);
		highlight($w,-1,$i) if ($slaves[0]->find('withtag','o') && $slaves[1]->find('withtag','o') && $slaves[2]->find('withtag','o'));
		highlight($w,-1,$i) if ($slaves[0]->find('withtag','x') && $slaves[1]->find('withtag','x') && $slaves[2]->find('withtag','x'));
	}
	my $cnt = 0;
	for (my $i = 1 ; $i < 4 ; $i++){
		for (my $j = 0 ; $j < 3 ; $j++){
			$cnt++ if(${$$w->gridSlaves(-column=>$i, -row=>$j)}[0]->find('withtag','o') || ${$$w->gridSlaves(-column=>$i, -row=>$j)}[0]->find('withtag','x'));	
		}
	}
	$nextxo = ($nextxo eq 'o') ? 'x' : 'o' if ($flag==1);
	if ($cnt == 9){
		$nextxo = 'w';
		my $dialog = $$w->DialogBox(-title=>'Losers', -buttons=>['Again','Exit']);
		$dialog->add('Label', -text=>'You\'re all losers, play again?')->pack;
		my $result = $dialog->Show;
		if ($result eq 'Again'){
			clearxo($w);
		}else{
			$$w->destroy;
		}		
	}
	}
}

sub highlight
{
	my $w = shift;
	my $row = shift;
	my $col = shift;
	my @slaves;
	if ($col == -1){
		@slaves = $$w->gridSlaves(-row=>$row);
	}elsif ($row == -1){
		@slaves = $$w->gridSlaves(-column=>$col);
	}elsif ($row == 2){
		$slaves[0] = ${$$w->gridSlaves(-column=>1, -row=>0)}[0];
		$slaves[1] = ${$$w->gridSlaves(-column=>2, -row=>1)}[0];
		$slaves[2] = ${$$w->gridSlaves(-column=>3, -row=>2)}[0];
	}elsif($row == 1){
		$slaves[0] = ${$$w->gridSlaves(-column=>3, -row=>0)}[0];
		$slaves[1] = ${$$w->gridSlaves(-column=>2, -row=>1)}[0];
		$slaves[2] = ${$$w->gridSlaves(-column=>1, -row=>2)}[0];
	}
	for (0..2){
		$slaves[$_]->configure(-background=>'blue');
	}
	my $winxo = $nextxo;
	$nextxo = 'w';
	my $dialog = $$w->DialogBox(-title=>'Winner', -buttons=>['Again','Exit']);
	$dialog->add('Label', -text=>$winxo.' wins, play again?')->pack;
	my $result = $dialog->Show;
	if ($result eq 'Again'){
		clearxo($w);
	}else{
		$$w->destroy;
	}
	
}

sub clearxo
{
	my $w = shift;
	for (my $i = 1 ; $i < 4 ; $i++){
		for (my $j = 0 ; $j < 3 ; $j++){
		${$$w->gridSlaves(-column=>$i, -row=>$j)}[0]->delete('all');
		${$$w->gridSlaves(-column=>$i, -row=>$j)}[0]->configure(-background=>'white');;
		}
	}
	$nextxo = 'o'
}

sub drawx
{
	my $cnv = shift;
	$$cnv->createLine(10,10,90,90, -fill=>'red', -width=>5, -tags=>'x');
	$$cnv->createLine(90,10,10,90, -fill=>'red', -width=>5);
}

sub drawo
{
	my $cnv = shift;
	$$cnv->createOval(10,10,90,90, -outline=>'green', -width=>5, -tags=>'o');
}

sub endit
{
print "Bye Bye\n";
exit 0;
}