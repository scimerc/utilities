#!/usr/bin/perl
use strict;
use warnings;

if ( scalar @ARGV > 0 )
{
	foreach my $arg ( @ARGV )
	{
		my $fh;
		open ( $fh, '<', "${arg}" ) or die "\n$!\n";
		# get header information
		my $header = <$fh>;
		chomp $header;
		print "${header}\n";
		my @headerinfo = split ( /[\t ]+/, $header, -1 );
		my $index = 0;
		while ( my $line = <$fh> )
		{
			$index = 0;
			my $pn = '';
			chomp $line;
			my @info = split ( /[\t ]+/, $line, -1 );
			foreach my $field ( @info )
			{
				if ( $index == 0 )
				{
					$pn = $field;
					print "${pn}\t";
				}
				elsif ( $index % 2 == 0 )
				{
					print "${field}\n";
				}
				elsif ( $index % 2 == 1 )
				{
					print "${pn}\t" if ( $index > 1 );
					print "${headerinfo[$index]}\t${field}\t";
				}
				$index++;
			}
		}
		close $fh;
	}
}
else
{
	print ( "\n generate a four-column genotype file from (I think) one of those files\n" );
	print ( " with all the people's genotypes in one line; just feed such files as arguments.\n\n" );
}

