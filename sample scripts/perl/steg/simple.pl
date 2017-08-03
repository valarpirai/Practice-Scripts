#!/usr/local/bin/perl

        use GD;

        # create a new image
        $im = new GD::Image(1000,1000);

        # Creating background color with transparency
        $white = $im->colorAllocateAlpha(255,255,255,127);
        
	$black = $im->colorAllocate(0,0,0);       
        $red = $im->colorAllocate(255,0,0);      
        $blue = $im->colorAllocate(0,0,255);

        # make the background transparent and interlaced
        #$im->transparent($black);
        #$im->interlaced('true');
	$im->setThickness(10);
        # Put a black frame around the picture
        $im->rectangle(0,0,999,999,$black);

        # Draw a blue oval
        $im->arc(500,500,95,75,0,360,$blue);

#	$im->setThickness(100);
        # And fill it with red
#        $im->fill(900,900,$red);


# Writing the created image in to a image file using Binary Stream
open OUT, ">simple.png" || die $!;
binmode OUT;
print OUT $im->png; # output the file is simple.png
close OUT;
