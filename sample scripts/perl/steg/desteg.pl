#!/bin/perl

use GD::Image;

my $source = GD::Image->new('steg.png');
my $desteg = GD::Image->new( $source->width, $source->height );

for my $x ( 0 .. $source->width - 1 ) {
    for my $y ( 0 .. $source->height - 1 ) {
        my $idx = $source->getPixel( $x, $y ); # get the pixel from the source image
        my ( $int ) = $source->rgb( $idx ); # get its intensity
        $int = 255 * ( $int & 1 ); # check its least significant bit - high is with, low is black
        my $d_idx = $desteg->colorResolve( $int, $int, $int ); # get the colour index
        $desteg->setPixel( $x, $y, $d_idx ); #set the pixel
    }
}

open OUT, ">desteg.png" || die $!;
binmode OUT;
print OUT $desteg->png; # output the file
close OUT;
