#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $varpos_coord = 1;
my $varstring_coord = 3;
my $chr_coord = 0;

my $composite_options = {
	'r' => 'regions',
	'f' => 0
};

my $help_messages = {
	'r' => "sets the path to the file holding the regions of interest:\n" .
		"the format assumed is '<chr>(unused) <in_pos> <fin_pos> ...'\n" .
		"[Default: '" . $composite_options->{'r'} . "']",
	'f' => "field of target file required to be in the regions\n" .
		"[Note: field count starts at 0]"
};

opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( !opt_manager::get ( 'h' ) )
{
	my $field = opt_manager::get ( 'f' );
	my $regionfile = opt_manager::get ( 'r' );
	my $regionarray = toolz::read_file ( $regionfile, 1, 2 );
	if ( scalar @inputarr > 0 )
	{
		foreach my $varfile ( @inputarr )
		{
   			open ( my $fh, '<', $varfile ) or die "\n${varfile}: $!\n";
			while ( my $line = <$fh> )
			{
				chomp $line;
				my @varinfo = split ( /[ \t]+/, $line );
				my ( $low, $high ) = toolz::binary_close_field_search ( $varinfo[$field], $regionarray, 0 );
				if ( $low < $high ) # found
				{
					print "$low\t$line\n";
				}
				else
				{
					my $index = $low - 1;
					$index = 0 unless ( $low > 0 );
					if ( $varinfo[$field] >= $regionarray->[$index]->[0]
					and $varinfo[$field] <= $regionarray->[$index]->[1] )
					{
						print "$index\t$line\n";
					}
				}
			}
			close $fh;
		}
	}
}
else
{
	print ( "\n  you may have neglected to provide some input.\n" ) if ( scalar @ARGV == 0 );
	print ( "\n   usage: " . toolz::pathless ( $0 ) . " [options]" . " <target file(s)>\n" );
	print ( "\n   options:\n" . opt_manager::help_message () . "\n" );
}

