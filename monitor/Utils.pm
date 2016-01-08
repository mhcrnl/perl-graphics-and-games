package Utils;
use Time::Piece;
use GD;
use Tk::PNG;
use MIME::Base64;

#takes a decimal number and changes it to hexidecimal
#this was added with putting together colours in mind, therefore it will prefix a 0 if the length is 1
sub dec2hex
{
	my $code = shift;
	my $hex = sprintf ("%lx",$code);
	$hex = "0$hex" if (length($hex)%2==1);
	return $hex;
}

#modifies the value returned from the database, modifications can be chained together using double pipe (||)
# $val is the value to be modified, $mod is the modification object
sub checkModification
{
	my $val = shift;
	my $mod = shift;
	return $val if (!defined($mod) || !defined($mod->{type}));
	
	my @mods = split('\|\|', $mod->{type});
	my @vals = split('\|\|', $mod->{value});
	for ($i = 0 ; $i < @mods ; $i++)
	{
		if ($mods[$i] eq "regex")
		{
			eval '$val =~ '.$vals[$i];
		}
		elsif ($mods[$i] eq "date")
		{
			$val = localtime($val)->strftime($vals[$i]);
		}
		elsif ($mods[$i] eq "percent")
		{
			$val = int(($val / $vals[$i]) * 100);
		}
	}
	return $val;
}

#Gets a label using the GD library, which allows rotation and to find the size of the string
sub getGDLabel
{
	my $mw = shift;
	my $text = shift;
	my $tag = shift;
	my $fontSize = shift;
	my $rotation = shift;
	my $im = new GD::Image(1000,1000);
	my $black=$im->colorAllocate(0,0,0);
	my $white=$im->colorAllocate(255,255,255);
	my @bounds = $im->stringFT($white, getFontFolder()."arialbd.ttf",$fontSize,$rotation,500,500,$text);
	
	my ($maxX, $maxY, $minX, $minY) = (0,0,99999999,999999999);
	for(my $i = 0 ; $i < @bounds ; $i++)
	{
		if ($i % 2 == 0) #x
		{
			$maxX = $bounds[$i] if ($bounds[$i] > $maxX);
			$minX = $bounds[$i] if ($bounds[$i] < $minX);
		}
		else #y
		{
			$maxY = $bounds[$i] if ($bounds[$i] > $maxY);
			$minY = $bounds[$i] if ($bounds[$i] < $minY);
		}
	} 
	my $width = $maxX - $minX;
	my $height = $maxY - $minY;
	
	my $im2 = new GD::Image($width, $height);
	$im2->copy($im,0,0,$minX,$minY,$width, $height);
	
	my $id = $text.rand(1000000).$tag;
	$mw->Photo($id, -format => 'png', -data => encode_base64($im2->png));	
	
	return ($width, $height, $id);
}


sub getGDWrappedLabel
{
	my $mw = shift;
	my $text = shift;
	my $tag = shift;
	my $fontSize = shift;
	my $maxWidth = shift;
	my $bgcolour = shift;
	my $textcolour = shift;
	my $bgtransparent = shift;
	my ($bgred, $bggreen, $bgblue) = getGDColour($bgcolour);
	my ($txred, $txgreen, $txblue) = getGDColour($textcolour);
	my @im = ();
	$im[0] = new GD::Image(3000,100);
	if ($bgtransparent){
		$im[0]->colorAllocateAlpha($bgred, $bggreen, $bgblue,127);	
	}else{
		$im[0]->colorAllocate($bgred, $bggreen, $bgblue);
	}
	
	my $txColour=$im[0]->colorAllocate($txred, $txgreen, $txblue);
	
	my @bounds = $im[0]->stringFT($txColour, getFontFolder()."arialbd.ttf",$fontSize,0,0,90,$text);
	my $minY = $bounds[7];
	my $maxY = $bounds[1];
	my $width = $bounds[4];
	
	if ($maxWidth > 0 && $width > $maxWidth)
	{
		@im = ();
		$width = $maxWidth;
		my @string = split(" ", $text);
		my $curString;
		my $image = undef;
		my $lastReset = -1;
		for	(my $i = 0 ; $i < @string ; $i++) #doubt this is the most efficient way, but it'll do it, wil need to think on the algorithm more
		{
			my $prevString = $curString;
			my $temp = new GD::Image($maxWidth,100);
			if ($bgtransparent){
				$temp->colorAllocateAlpha($bgred, $bggreen, $bgblue,127);
			}else{
				$temp->colorAllocate($bgred, $bggreen, $bgblue);
			}
			$txColour=$temp->colorAllocate($txred, $txgreen, $txblue);
			$curString .= " " if (defined($image));
			$curString .= $string[$i];
			@bounds = $temp->stringFT($txColour, getFontFolder()."arialbd.ttf",$fontSize,0,0,90,$curString);
			
			if ($bounds[4] > $maxWidth)
			{
				push(@im, $image) if (defined($image));
				$curString = "";
				$i--;
				last if ($lastReset == $i); #word longer than available space (just dump out gracefully for now to avoid infinite loop)
				$lastReset = $i;
				$image = undef;
			}
			elsif($i == @string - 1)
			{
				push(@im, $temp);
			}
			else
			{
				$image = $temp;
			}
		}
	}
	
	my $height = $maxY - $minY;
	my $im2 = new GD::Image($width, $height * scalar @im);
	my $y = 0;
	foreach(@im){
		$im2->copy($_, 0, $y, 0, $minY ,$width, $height);
		$y += $height;
	}
	
	my $id = $text.rand(1000000).$tag;
	$mw->Photo($id, -format => 'png', -data => encode_base64($im2->png));	
	
	return ($width, $height  * scalar @im, $id);
}

sub getGDColour
{
	my $colour = shift;
	return (hex(substr($colour, 1, 2)), hex(substr($colour, 3, 2)), hex(substr($colour, 5, 2)));
}

#get the true type font folder, mostly for use by GD
sub getFontFolder
{
	if ($^O eq "MSWin32")
	{
		return "C:\\Windows\\Fonts\\";
	}
	else
	{
		return "/usr/share/fonts/truetype/msttcorefonts/";
	}
}

1;