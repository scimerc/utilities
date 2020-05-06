#! /usr/bin/perl
use strict ;
use warnings ;

my $verbose = 0 ;

if ( scalar @ARGV > 0 )
{
	foreach my $file ( @ARGV )
	{
		my $cnt = 0 ;
		my $scnt = 0 ;
		my $tcnt = 0 ;
		my $chainID = '-1' ;
		open ( FH, "<${file}" ) or die "couldn't open file ${file}\n" ;
		open ( NFH, ">${file}.data" ) or die "couldn't open file ${file}.data\n" ;
		foreach my $line ( <FH> )
		{
			chomp $line ;
			if ( $line =~ /^#.*/ )
			{
				$scnt++ ;
				my @cdata = split ' ', $line ;
				if ( $chainID eq $cdata[2] )
				{
					$cnt++ ;
				}
				else
				{
					$cnt = 0 ;
					$chainID = $cdata[2] ;
				}
			}
			else
			{
				print NFH "$tcnt $chainID $cnt\n" ;
				$tcnt++ ;
				$cnt++ ;
			}
		}
		close FH ;
		close NFH ;
	}
}
else
{
	print ( "usage: $0 <files>\n" ) ;
}
