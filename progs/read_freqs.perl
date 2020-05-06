#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $varpos_coord = 1;
my $varstring_coord = 3;
my $chr_coord = 0;

my $program_description = " read variant frequencies for the variants given.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <variant file(s)>\n";

my $composite_options = {
	'f' => 'freqs'
};

my $help_messages = {
	'f' => "sets the path to the file holding the variant frequencies.\n" .
		"[Default: '" . $composite_options->{'f'} . "']\n"
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
	my $freqfile = opt_manager::get ( 'f' );
	my $freqarray = toolz::read_file ( $freqfile );
	foreach my $varfile ( @inputarr )
	{
		open ( my $fh, '<', $varfile ) or die "\n${varfile}: $!\n";
		while ( my $variant = <$fh> )
		{
			my $cnt = 0;
			chomp $variant;
			my @varinfo = split ( /[ \t]/, $variant );
			my $chromosome = $varinfo[$chr_coord];
			my $chrpos = $varinfo[$varpos_coord];
			my $varstring = $varinfo[$varstring_coord];
			if ( "$chrpos" =~ /^[0-9]+$/ )
			{
				printf ( "$chromosome\t$chrpos\t$varstring" );
				my $index = toolz::binary_field_search ( $chrpos, $freqarray, 1 );
				if ( $index < 0 )
				{
					print "\t0\n";
				}
				else
				{
					my $freq = 0.;
					my $var = $freqarray->[$index];
					for ( my $i = 2; $i < scalar @$var; $i += 2 )
					{
						$freq = $var->[$i + 1] if ( $var->[$i] eq $varstring );
					}
					print "\t${freq}\n";
				}
			}
			else
			{
				print "\twarning: non-numeric position [${chrpos}] in variant file ${varfile}\n";
			}
		}
		close $fh;
	}
}
else
{
	print ( "\n missing input.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <variant file(s)>\n\n" );
}

