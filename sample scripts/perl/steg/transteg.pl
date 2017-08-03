#!/bin/perl

use GD;

my $source = GD::Image->new('1.png');
my $steg = GD::Image->new( $source->width, $source->height );

print "Origin Height ".  $source->width . " - Height ". $source->height ."\n";

$white = $steg->colorAllocateAlpha(0, 0 , 0, 127);

=for my $x ( 0 .. $source->width - 1 )
{
    for my $y ( 0 .. $source->height - 1 )
    {
        my $ct_index = $source->getPixel($x, $y); # get the colour table index of the corresponding pixel from the source
	my ($r, $g, $b) = $source->rgb($ct_index);
        
	my $idx = $steg->colorResolve($$r, $g, $b); # get the new colour's index in the destination image
        $steg->setPixel($x, $y, $idx); # and set the pixel in the destination image
	$steg->transparent($idx); # make the pixel as transparent
    }
}
=cut
open OUT, ">transteg.png" || die $!;
binmode OUT;
print OUT $steg->png; # and output the file
close OUT;
