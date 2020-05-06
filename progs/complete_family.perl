#!/usr/bin/perl
use strict;
use warnings;

my $fathercoord = 2;
my $mothercoord = 3;
my $familycoord = 0;

if ( scalar @ARGV > 0 )
{
	my $fh;
	open ( $fh, '<', "${ARGV[0]}" ) or die "\n$!\n";
	while ( my $fline = <$fh> )
	{
		chomp $fline;
		print "$fline\n";
		my @finfo = split ( /[\t ]/, $fline, -1 );
		foreach my $pncoord ( $fathercoord, $mothercoord )
		{
			my $found = 0;
			unless ( $finfo[$pncoord] eq "0" )
			{
				my $ffh;
				open ( $ffh, '<', "${ARGV[0]}" ) or die "\n$!\n";
				while ( my $ffline = <$ffh> )
				{
					chomp $ffline;
					$found = 1 if ( $ffline =~ /^[^\t ]*[\t ]${finfo[$pncoord]}[\t ]/ );
				}
				if ( $found == 0 )
				{
					print "${finfo[$familycoord]}\t${finfo[$pncoord]}";
					for ( my $i = 2; $i < scalar @finfo; $i++ )
					{
						print "\t0";
					}
					print "\n";
				}
				close $ffh;
			}
		}
	}
}
else
{
	print ( "\n complete a family relationship file (missing information is set to 0).\n" );
	print ( "\n the family relationship file is expected to have the format:\n" );
	print ( "\n <family_ID>  <PN_ID>  <father_ID>  <mother_ID>...\n" );
	print ( "\n  usage: $0 <family file>\n\n" );
}

