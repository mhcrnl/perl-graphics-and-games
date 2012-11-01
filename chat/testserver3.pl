use strict;
use threads;
use threads::shared;
use IO::Socket;
use IO::Handle;
use IO::Select;

$SIG{INT} = \&endit;
$|=1;
our (@messages) :shared;
our (%shash, %notify);
my %thrd;
#my %workers;
our $threads = 3;
my $currentThread = 1;
my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                  LocalPort => 7000,
                                  Listen    => 0,
                                  Reuse     => 1);

die "can't setup server: $!" unless $server;


#share ($server); #can't put $server and client variables in share, might have been useful

foreach (1..$threads){
 share ($shash{$_}{'go'});
 share ($shash{$_}{'pid'});
 share ($shash{$_}{'die'});
 share ($shash{$_}{'busy'});
 share ($shash{$_}{'notifynum'});
 share (@{$notify{$_}{'notify'}});
 
 $shash{$_}{'go'} = 0;
 $shash{$_}{'pid'} = -1;
 $shash{$_}{'die'} = 0;
 $shash{$_}{'busy'} = 0;
 @{$notify{$_}{'notify'}} =();
 $shash{$_}{'notifynum'} = 0;
 
 $thrd{$_} = threads->new(\&work,$_);
}


$shash{$currentThread}{'go'} = 1;

		#{
		#lock(@messages); #just to test it does lock - it works
		#sleep 15;
		#}


while(1){
	my $cnt=0;
	if ($shash{$currentThread}{'busy'} == 1 ){
		#print "here\n";
		while ($cnt < $threads){
			$cnt++;
			$currentThread++;
			$currentThread = 1 if ($currentThread == $threads+1);
			if ($shash{$currentThread}{'go'} == 0){
				$shash{$currentThread}{'go'} == 1;
				last;
			}
			#else we are too busy
		}
		
	}elsif($shash{$currentThread}{'go'} == 0){
		#print "here2\n";
		$shash{$currentThread}{'go'} = 1;
	}
	
	if (@messages > 0){
		my @temp;
		{
		lock(@messages);
		@temp = @messages;
		@messages = ();
		}
		
		foreach my $t (1..$threads){
			if ($shash{$t}{'busy'} == 1){

				{
				lock(@{$notify{$t}{'notify'}});
				#splice(@{$notify{1}{'notify'.$which}}, @{$notify{1}{'notify'.$which}}, 0, @temp);
				#bah splice not allowed on shared arrays
				foreach (@temp){
					push (@{$notify{$t}{'notify'}}, $_);
				}
				
				}
			}
		}
		
		#foreach (@temp){
		#	print "$_\n";
		#}
	
	}
	select (undef, undef, undef, 0.1);
}


sub work{
  my $dthread = shift;
  my $client = undef;
  my $clientaddr = 0;
  $SIG{KILL} = sub{if (defined($client)){print $client "Connection Closed\n"; close $client;} threads->exit(0);};
    while(1){
       if($shash{$dthread}{'die'} == 1){ goto END }; 
       if ( $shash{$dthread}{'go'} == 1 ){
       		print "HI - $dthread\n";
       		($client,$clientaddr) = $server->accept();
       		print $client "hi\n";
       		$shash{$dthread}{'busy'} = 1;
       		my $s = IO::Select->new();
       		$s->add($client);
       		while ($s->exists($client)){
       		#print "loop\n"; # go check for notifications etc.
       			if ( @{$notify{$dthread}{'notify'}} > 0){
       				#print "~~~~~\n";
       				my $return = "";
       				{
       				lock( @{$notify{$dthread}{'notify'}});
       				foreach (@{$notify{$dthread}{'notify'}}){
       				$return.="\0".$_;
       				#print "$_\n";
       				#print $client "$_\n"; #may be better as one reply
       				}
       				@{$notify{$dthread}{'notify'}} = ();
       				print $client "$return\n";
       				}
       			}
       			my @ready = $s->can_read(0.2);
				foreach (@ready){
					my $m = <$_>;
					chomp $m;
					if ($m =~ m/^~mes~:(.*)$/){
						{
						lock (@messages);
						push (@messages, $1);
						}
					}
					elsif ($m eq ""){$s->remove($client);}  #conn closed
			}
  
       		}
       		print "close\n";
		close $client;
		$shash{$dthread}{'busy'} = 0;
    	$shash{$dthread}{'go'} = 0;    
       }else
         { sleep 1 }
    }
END:
}


sub endit{
	print "Bye\n";
	close $server;
	#no point doing this as there will always something waiting on accept so it won't die, can't use alarm to interrupt
	#can join what I can
	foreach (1..$threads){
		if ($shash{$_}{'go'} == 0){
		$shash{$_}{'die'} = 1;
		$thrd{$_}->join;}
		else{
		$thrd{$_}->kill('KILL')->detach;	
		}
	}
	exit 0;
}