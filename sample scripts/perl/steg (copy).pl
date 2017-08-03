#!/bin/perl

use GD;

my $source = GD::Image->new('prime.png');
my $mask = GD::Image->new('2.jpg'); #message to hide
my $steg = GD::Image->new( $source->width, $source->height );

print "Origin Height ".  $source->width . " - Height ". $source->height ."\n";
print "Dup Height ".  $mask->width . " - Height ". $mask->height ."\n";

my $m_idx = $mask->getPixel(100, 100); # get the colour index of the corresponding pixel in the mask
 $r, $g, $b) = $source->rgb($m_idx);
print "\n RGB - ". $r ." " . $g . " " . $b;

for my $x ( 0 .. $source->width - 1 )
{
    for my $y ( 0 .. $source->height - 1 )
    {
        my $m_idx = $mask->getPixel($x, $y); # get the colour index of the corresponding pixel in the mask
        my ( $int ) = $source->rgb( $source->getPixel( $x, $y ) ); # get the intensity of the pixel in the source image
        # if the mask is white, set the least significant bit of the intensity high, otherwise set it low
        $int = ( $m_idx == 0 ) ? $int & 254 : $int | 1;
        my $idx = $steg->colorResolve( $int, $int, $int ); # get the new colour's index in the destination image
        $steg->setPixel( $x, $y, $idx ); # and set the pixel in the destination image
    }
}

open OUT, ">steg.png" || die $!;
binmode OUT;
print OUT $steg->png; # and output the file
close OUT;
