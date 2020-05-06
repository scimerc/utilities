#!/usr/bin/perl
# sum up the single allele probabilities into pseudo counts
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " sum up single allele probabilities into pseudo counts.\n" . 
                        " the input file is expected to have a tag followed by the probabilities\n" . 
                        " as in: <tag>  <SNP1_prob1>  <SNP1_prob2>  <SNP2_prob1>  <SNP2_prob2>...\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " <input file>\n";

opt_manager::init_help_message ( $program_description . $program_usage );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
	foreach my $ifile ( @inputarr )
	{
		open ( my $fh, '<', "${ifile}" ) or die "\n${ifile}: $!\n";
		my $header = <$fh>;
		while ( my $line = <$fh> )
		{
			chomp $line;
			my $index = 1;
			my @info = split ( /[ \t]/, $line, -1 );
			print ( $info[$index] . "\t" );
			while ( $index + 1 < scalar ( @info ) )
			{
				my $pseudo_probability = 0.;
				for ( my $subindex = 0; $subindex < 2; $subindex++ )
				{
					$pseudo_probability += $info [ $index + $subindex ];
				}
				$index += 2;
				$pseudo_probability = -9. if ( $pseudo_probability < 0. );
				print ( $pseudo_probability . "\t" );
			}
			print "\n";
		}
		close $fh;
	}
}
else
{
	print ( "\n you may have neglected to provide some input.\n\n " );
	print ( toolz::pathless ( $0 ) . " sums up the single allele probabilities into pseudo counts.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " <input file>\n\n" );
}

