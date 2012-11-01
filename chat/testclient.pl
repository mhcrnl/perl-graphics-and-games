use Tk;
use IO::Socket;
use IO::Handle;
use IO::Select;
use strict;
 

$|=1;

our $s = IO::Select->new();
our $h = IO::Socket::INET->new(Proto     => "tcp",
	                                    PeerAddr  => '127.0.0.1',
	                                    PeerPort  => 7000,
	                                    Blocking => 0,
	                                    Timeout => 10)
	           or die "Could not connect";
	
	
    	$h->autoflush(1);

$s->add($h);

#server sends back an initial hello message
if (scalar $s->can_read(5) == 0){
	print "Could not connect\n";
	exit 0;
}
<$h>;

our $name = "Anon";
our $mw = undef;
$mw = MainWindow->new;
$mw->OnDestroy([\&endit]);
$mw->resizable(0,0);
our $send = "";

my $menuframe = $mw->Frame(-borderwidth=>2)->pack(-side=>'top', -fill=>'x');
my $usermenu = $menuframe->Menubutton(-text=>'Edit', -relief=>'raised')->pack(-side=>'left');
$usermenu->command(-label=>'Change Name',-command=>[\&changeName], -accelerator=>'Ctrl-N');
$mw->bind('<Control-s>'=>[\&changeName]);
$mw->bind($usermenu,'<Enter>', sub{$usermenu->configure(-relief=>'sunken');});
$mw->bind($usermenu,'<Leave>', sub{$usermenu->configure(-relief=>'raised');});

my $f1 = $mw->Frame()->pack();
my $f2 = $mw->Frame()->pack();
my $entry = $f2->Entry(-textvariable=>\$send, -width=>50)->pack(-side=>'left');
$f2->bind($entry, '<Return>'=>[\&sendmes]);
my $but = $f2->Button(-text => 'Send', -command => [\&sendmes])->pack(-side=>'right');
our $cnv1 = $f1->Scrolled('Canvas',-width=>400, -height =>300, -borderwidth=>0, -background=>'blue',-scrollregion=>"0 0 400 300",-scrollbars=>'e')->pack();

our $go = 1;
our ($x, $y) = (20,20);
my $linesize = 40;
	$mw->OnDestroy([\&endit]);
	while(1){
		my @ready = $s->can_read(0.1);
		foreach (@ready){
			my $returnmessage = <$_>;
			chomp $returnmessage;
			#print "$returnmessage\n";
			my @mes = split("\0",$returnmessage);
			foreach my $m (@mes){
				if ($m ne ""){
				my $message;
				do{
					if (length($m) > $linesize){
						$message = substr($m,0,$linesize);
						$m = substr($m,$linesize);
					}else{
						$message = $m;
						$m = "";
					}
					$cnv1->createText($x,$y,-text=>$message, -anchor=>'w', -font=>'{Arial Bold} 12', -fill=>'white', -tags=>'text');
					$y+=20;
					$cnv1->configure(-scrollregion=>"0 0 400 $y");
					$cnv1->yviewMoveto(1);
				} until (length($m) == 0);
				}
			}
		}
		if ($go==1){
			$mw->update ;
		}else{
			last;
		}

	}

MainLoop;




sub endit
{
$go = 0;
close $h;
exit 0;
}

sub sendmes
{
	my @go = $s->can_write(5); #doesn't appear to work
	if (@go > 0){
		print $h "~mes~:$name: $send\n"; 
		$send = "";
		$mw->update;
		return;
	}
	
	$cnv1->createText($x,$y,-text=>'Connection Lost', -anchor=>'w', -font=>'{Arial Bold} 12', -fill=>'white', -tags=>'text');
	

}

sub changeName
{
	my $class = 'Name';
	return if (_checkChildren($class) == 0);	
	my $w=$mw->Toplevel(-class=>$class);
	my $g = "+100+100";
	$w->geometry($g);
	$w->resizable(0,0);
	my $entry = $w->Entry(-textvariable=>\$name, -width=>50)->pack(-side=>'left');
	$w->bind($entry, '<Return>'=>sub {$w->withdraw();});
	my $but = $w->Button(-text => 'Change', -command => sub{$w->withdraw();})->pack(-side=>'right');
	$w->update;
	
	
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

