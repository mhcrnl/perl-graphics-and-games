use strict;
use Win32::Sound;                                 

Win32::Sound::Volume('100%');
opendir(DIR, "music\\$ARGV[0]");
my @files = readdir(DIR);
closedir (DIR);

my @tracks = grep{/^.*\.wav$/}@files;

while (1){
	my $rand = int(rand(@tracks-0.1));
	print($tracks[$rand]."\n");
	for (1..5){
		Win32::Sound::Play("music\\$ARGV[0]\\".$tracks[$rand]); #is a limited API, doesn't play the full track, repeats after about a minute on the longer ones
	}


}



