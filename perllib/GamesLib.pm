package GamesLib;
use Time::HiRes qw(gettimeofday);
use Math::Trig;

BEGIN{
	use Exporter();
	@ISA = qw(Exporter);
	@EXPORT = qw(&distanceBetween &getTime &getLine &dec2hex &_normalise &_getNormal);
}


sub distanceBetween
{
	my $source = shift;
	my $dest = shift;
	
	my $dx = $$dest[0] - $$source[0];
	my $dy = $$dest[1] - $$source[1];
	my $dz = $$dest[2] - $$source[2];
	
	
	my $adj = sqrt(($dx*$dx)+($dz*$dz));
	return sqrt(($dy*$dy)+($adj*$adj));

}


sub getTime
{
	my ($sec, $micro) = gettimeofday;
	$micro = sprintf "%06d", $micro;
	my $now = sprintf "%.3f", "$sec.$micro";
	return $now;

}


sub getLine
{
	my $incr = shift;
	my $x1 = shift;
	my $y1 = shift;
	my $x = shift;
	my $y = shift;
	my $addx = 0;
	my $addy = 0;
	
	#get gradient mid base to point
	my $dx = $x1 - $x;
	if ($dx == 0){
		#equation is x = $x (vertical line)
		$addx = 0;
		$addy = $incr;
		$addy=$addy*-1 if ($y1 < $y);
	}else{
		my $dy = $y1 - $y;
		if ($dy == 0){
			#equation is y = $y (horizontal)
			$addx = $incr;
			$addy = 0;
			$addx=$addx*-1 if ($x1 < $x);
		}else{
			my $grad = $dy/$dx;
			#my $c = $y - ($grad*$x);
			#equation is y=$grad(x) + $c
			my $theta = atan($grad); 
			$addx = cos($theta) * $incr;
			$addy = sin($theta) * $incr;
			if ($x1 < $x)
			{
				$addx=$addx*-1;
				$addy=$addy*-1;
			}
		}
	} 
	return ($addx, $addy);
}


sub dec2hex
{
	my $code = shift;
	my $hex = sprintf ("%lx",$code);
	$hex = "0$hex" if (length($hex)%2==1);
	return $hex;
}

 sub _normalise
 {
 	my $ref = shift;
 	#normalise - unit vector
	my $squareadd = ($$ref[0]*$$ref[0])+($$ref[1]*$$ref[1])+($$ref[2]*$$ref[2]);
	my $divider = sqrt($squareadd);
	if ($divider == 0){
		@$ref = (0,0,0);
	}else{
		$$ref[0] = $$ref[0]/$divider;
		$$ref[1] = $$ref[1]/$divider;
        	$$ref[2] = $$ref[2]/$divider;
        }
 }

 sub _getNormal
 {
 	my $a = shift;
	my $b = shift;
	my $c = shift;
	my $no_normalise = shift;
	my @vector1 = (0,0,0);
    	my @vector2 = (0,0,0);
	my @normal;
    	$vector1[0] = $$b[0] - $$a[0];
    	$vector1[1] = $$b[1] - $$a[1];
    	$vector1[2] = $$b[2] - $$a[2];
    	$vector2[0] = $$c[0] - $$a[0];
    	$vector2[1] = $$c[1] - $$a[1];
    	$vector2[2] = $$c[2] - $$a[2];
    
    	#cross product - perpendicular vector to 2 existing ones
    	$normal[0] = (($vector1[1]*$vector2[2])-($vector2[1]*$vector1[2]));
    	$normal[1] = (-($vector1[0]*$vector2[2])+($vector2[0]*$vector1[2]));
    	$normal[2] = (($vector1[0]*$vector2[1])-($vector2[0]*$vector1[1]));
    	
    	if (! $no_normalise){
    	#unit vector
    	my $squareadd = ($normal[0]*$normal[0])+($normal[1]*$normal[1])+($normal[2]*$normal[2]);
    	#if zero points make a point
    	if ($squareadd > 0){ 
    		my $divider = sqrt($squareadd);
    		$normal[0] = $normal[0]/$divider;
    		$normal[1] = $normal[1]/$divider;
    		$normal[2] = $normal[2]/$divider;
    	}else{
    	#return as if back face
    		@normal = (0,0,1);
    	}
    	}
    	return @normal;
 }


return 1;

END{}