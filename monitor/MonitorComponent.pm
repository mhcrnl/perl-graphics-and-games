package MonitorComponent;
use IO::Socket;
use IO::Handle;
use IO::Select;
use XML::Simple;
use threads;
use threads::shared;
use strict;
use Tk;

$|=1;

=head1 NAME

MonitorComponent

=head1 DESCRIPTION

Manages data retrieval and display of a specific monitor item

=head1 METHODS

The following methods are available:

=over 4

=item B<$monitor-E<gt>new($server, $port, $xmlDefinition)>

Constructor, starts a worker thread to retrieve required data as defined in the xml definition for this item

=cut

sub new
{
	my $self={};
	shift;
		
	$self->{SERVER} = shift;
	$self->{PORT} = shift;
	
	my $node = shift;
	$self->{NAME} = $node->{name};
	$self->{INTERVAL} = $node->{interval};
	$self->{QUERY} = $node->{query};
	$self->{WIDTH} = $node->{width};
	$self->{HEIGHT} = $node->{height};
	$self->{TIMEFIELD} = $node->{timeField};
	$self->{FAILURETHRESHOLD} = $node->{failureThreshold};
	$self->{COMPONENTDEF} = $node->{components}->{component};
	$self->{ROW} = $node->{row};
	$self->{COL} = $node->{col};
	$self->{FRAMEID} = $node->{frame};
	$self->{COMPONENTS};
	$self->{DATA} = undef;
	$self->{CNV} = undef;
	$self->{STATUS} = undef;
	$self->{FRAME} = undef;
	$self->{TIMERCNV} = undef;
	
	$self->{LASTUPDATE} = 0;
	$self->{CONNECTED} = 0;
	$self->{GO} = 1;
	$self->{LASTQUERY} = 0;
	share($self->{DATA});
	share($self->{CONNECTED});
	share($self->{GO});
	share($self->{LASTQUERY});
	$self->{THREAD} = threads->new(\&_getData, $self); 
	#debate - do we start one thread per component (as here), or give info to class level thread pool
	#due to problems using threads with Tk, threads have to be created before Tk used (we can't restart)
	#so if a thread dies here we instantly lose the component
	#a pool of threads waiting for notification may give more resilience (until the pool is exhausted!)
	
	bless $self;
	return $self;
}

=item B<$monitor-E<gt>start($mainWindow, $parentFrame)>

Sets up the monitor item's initial display state

=cut

sub start
{
	my $self = shift;
	my $mw = shift;
	my $parentFrame = shift;
	
	if (defined($self->{FRAME}))
	{
		$self->{FRAME}->destroy;
		$self->{LASTQUERY} = 0;
	}

	$self->{FRAME} = $parentFrame->Frame(-background=>'black', -highlightcolor => 'white', -highlightthickness=>1)->grid(-column=>$self->{COL}, -row=>$self->{ROW});
	my $title = $self->{FRAME}->Label(-text=>$self->{NAME}, -background=>'black',-foreground=>'white', -anchor=>'c', -font=>'{Arial Bold} 16')->pack(-fill=>'x');
	
	my $statusFrame = $self->{FRAME}->Frame(-background=>'black', -highlightthickness=>0)->pack(-fill=>'x');
	$self->{TIMERCNV} = $statusFrame->Canvas(-background=>'black', -highlightthickness => 0, -width=>30, -height=>30)->pack(-side=>'left');
	$self->{TIMERCNV}->createArc(2,2,28,28, -extent=> 0, -fill=>'white', -start=>90, -tags=>'timer');
	$self->{TIMERCNV}->createArc(2,2,28,28, -extent=> 359, -outline=>'yellow', -style=>'arc');
	$self->{STATUS} = $statusFrame->Label(-text=>"", -background=>'black',-foreground=>'white', -anchor=>'c', -font=>'{Arial Bold} 16')->pack( -fill=>'x');
	_setStatus($self, 22);
	$mw->update;
	
	my $height = $self->{HEIGHT};
	if ($height =~ m/^(\d+)\%$/)
	{
		$height = $mw->Height * ($height / 100);
	}
	my $width = $self->{WIDTH};
	if ($width =~ m/^(\d+)\%$/)
	{
		$width = $mw->Width * ($width / 100);
	}
	print "$width\n";
	$height -= $self->{FRAME}->height;
	$self->{CNV} = $self->{FRAME}->Canvas(-background=>'black', -highlightthickness => 0, -width=>$width, -height=>$height)->pack();	
	my @comps = ();
	my $cnt = 0;
	foreach(@{$self->{COMPONENTDEF}})
	{
		eval 'require '.$_->{type}.'; push(@comps, '.$_->{type}.'->new($_, $mw, $self->{CNV}));' ;	
	}
	$self->{COMPONENTS} = \@comps;
	$mw->update;
}

=item B<$monitor-E<gt>stop>

Stop retrieving data for this item (stops data thread)

=cut

sub stop
{
	my $self = shift;
	print "Stopping thread\n";
	$self->{GO} = 0;
	#sleep 2;
	if ($self->{THREAD} != undef)
	{
		$self->{THREAD}->join;
		#$self->{THREAD} = undef; get segv in Unix doing this on shutdown 
	}
}

=item B<$monitor-E<gt>update()>

Update the display for this item based on the available data

=cut

sub update
{
	my $self = shift;
	my $flashMod = shift;
	
	if (!defined($self->{THREAD}) || !$self->{THREAD}->is_running() )
	{
		#if (defined($self->{THREAD})){
		#	$self->{THREAD}->detach();
		#}
		#$self->{THREAD} = threads->new(\&_getData, $self);
		#can't restart threads here as they will now have Tk references, and they play badly with threads! (All threads must be started before Tk used)
		$self->{CONNECTED} = 6;
	}
	
	if ($self->{LASTQUERY} > $self->{LASTUPDATE})
	{
		$self->{LASTUPDATE} = time;		
		my $ref = XMLin($self->{DATA}, ForceArray => [ 'Row' ]);
		
		if (defined($ref->{Rows}->{Row}))
		{
			my @entries = @{$ref->{Rows}->{Row}};
			@entries = sort {$b->{$self->{TIMEFIELD}} <=> $a->{$self->{TIMEFIELD}}} @entries if (defined($self->{TIMEFIELD}));
			
			if (scalar @entries > 0)
			{
				foreach(@{$self->{COMPONENTS}})
				{
					$_->update(\@entries);
				}
				$self->{CONNECTED} = 3 if ($self->{FAILURETHRESHOLD} > 0 && time - @entries[0]->{$self->{TIMEFIELD}} > $self->{FAILURETHRESHOLD} * 60);
			}
			else
			{
				$self->{CONNECTED} = 4;
			}
		}
		#_setStatus($self, $flashMod);
	}
	_setStatus($self, $flashMod);

	my $flash = $self->{CNV}->find('withtag','flash');
	if ($flash != undef)
	{
		foreach(@$flash)
		{
			my $item = $_;
			my $curColour = $self->{CNV}->itemcget($item, -fill);
			my $newcolour = substr($curColour,0,5).$flashMod;
			$self->{CNV}->itemconfigure($item,-fill=>$newcolour);
			$self->{CNV}->itemconfigure($item,-outline=>$newcolour);
		}
	}		
}

#Set the status label according to the current status
sub _setStatus
{
	my $self = shift;
	my $flashMod = shift;
	if ($self->{CONNECTED} < 0){
		$self->{STATUS}->configure(-background=>'#22EE22', -text=>'Connecting');
	}
	elsif ($self->{CONNECTED} == 0){
		$self->{STATUS}->configure(-background=>'#EE22'.$flashMod, -text=>'Not connected');
	}elsif ($self->{CONNECTED} == 1){
		$self->{STATUS}->configure(-background=>'#22EE22', -text=>'Connected');
	}elsif ($self->{CONNECTED} == 2){
		$self->{STATUS}->configure(-background=>'#000000', -text=>'Fetching');
	}elsif ($self->{CONNECTED} == 3){
		$self->{STATUS}->configure(-background=>'#EE22'.$flashMod, -text=>'Sensor Failure');
	}elsif ($self->{CONNECTED} == 4){
		$self->{STATUS}->configure(-background=>'orange', -text=>'No Data');
	}elsif ($self->{CONNECTED} == 5){
		$self->{STATUS}->configure(-background=>'magenta', -text=>'Timed Out');
	}elsif ($self->{CONNECTED} == 6){
		$self->{STATUS}->configure(-background=>'#EE'.$flashMod.'EE', -text=>'Monitor Failure');
	}
	
	my $timerDegrees = ((time - $self->{LASTUPDATE}) / ($self->{INTERVAL} *60)) * 360;
	$timerDegrees = 360 if ($timerDegrees > 360);
	$self->{TIMERCNV}->itemconfigure(1, -extent => -$timerDegrees);
	
}

#Used by worker thread to periodically retrieve data
sub _getData
{
	my $self = shift;
	
	if (!defined($self->{QUERY}))
	{
		print "No query defined for: ".(defined($self->{NAME}) ? $self->{NAME} : "")."\n";
		return;
	}
	
	while($self->{GO})
	{
		if (time - $self->{LASTQUERY} < $self->{INTERVAL} * 60)
		{
			sleep 1;
			next;
		}

		my ($sock, $handle) = _getConnection($self, 0);
		
		my $xml = _queryServer($self, $sock, $handle);
		
		if ($self->{CONNECTED} > 1)
		{
			$self->{CONNECTED} = 5;
		} 
		close $handle if ($handle != undef); 
		
		$self->{DATA} = $xml;
		$self->{LASTQUERY} = time;
		sleep 1;
	} #end while
}

#Get connection to the server
sub _getConnection
{
	my $self = shift;
	my $retry = shift;
	
	$self->{CONNECTED} = -1;

	my $sock = IO::Select->new();
	my $handle = IO::Socket::INET->new(Proto     => "tcp",
	                                    PeerAddr  => $self->{SERVER},
	                                    PeerPort  => $self->{PORT},
	                                    Blocking => 0,
	                                    Timeout => 10)
	           or $self->{CONNECTED} = -2;
	
	if ($self->{CONNECTED} == -2)
	{
		print "Problem connecting to: ".$self->{SERVER}.":".$self->{SERVER}.": $!\n";
		if ($retry == 2){
			$self->{CONNECTED} = 0;
			return (undef, undef);
		}
		
		sleep 5;
		return _getConnection($self, ++$retry);
	}	
	
	return ($sock, $handle);
}

#Send query as defined in the XML defintion and get response
sub _queryServer
{
	my $self = shift;
	my $sock = shift;
	my $handle = shift;
	
	my $xml;
	if ($self->{CONNECTED} == -1 && defined($handle))
	{
		$self->{CONNECTED} = 2;
    	$handle->autoflush(1);
		$sock->add($handle);
		print $handle $self->{QUERY}."\r\n";
		
		
		if ($sock->can_read(10))
		{
			while(<$handle>)
			{
				chomp($_);
				 $xml .= "$_";
			}
			$self->{CONNECTED} = 1;
		}
	}
	#print "$xml\n";
	return $xml;
}

1;
=back