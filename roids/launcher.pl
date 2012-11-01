
use Win32::Process;
#use Win32::TieRegistry; #updated to AP 5.10.1 build 1007 and TieRegistry no longer appears to pick up reg entry (on vista) have to go to older module



use Win32::Registry;
    my $key;
    $::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\Perl\\", $key);
    my ($type, $path);
    $key->QueryValueEx("BinDir", $type, $path);


#my $key= $Registry->{"HKEY_LOCAL_MACHINE\\SOFTWARE\\Perl"};
#print "$key\n";
#my $path= $key->{"\\BinDir"};

Win32::Process::Create($p,
$path,
"perl roidstest.pl",
0,
HIGH_PRIORITY_CLASS,
 ".");
