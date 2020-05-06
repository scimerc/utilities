#!/usr/bin/perl
use strict;
use warnings;

# transpose.perl - Transpose matrix.
#
# usage: transpose.perl < file
#
# file should contain an nxm matrix.
# The program returns the transposed matrix.
#
# Author: Oli Thor Atlason (2002)
# modified by Francesco Bettella (2011)

my $n = 0;
my $maxcol = 0;
my @infile = ();

while ( <STDIN> )
{
  chomp;
  my @line = split ( /[\t]/ );
  push ( @infile, [@line] );
  $maxcol = ( $maxcol > $#line ) ? $maxcol : $#line;
  $n++;
}

for ( my $j = 0; $j <= $maxcol; $j++ )
{
  for ( my $i = 0; $i < $n; $i++ )
  {
    $infile[$i][$j] = 'x' if ( ! defined ( $infile[$i][$j] ) );
    print $infile[$i][$j] . "\t";
  }
  $infile[$n][$n] = 'x' if ( ! defined ( $infile[$n][$n] ) );
  print $infile[$n][$n] . "\n";
}

