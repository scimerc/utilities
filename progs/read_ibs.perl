#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " extract the IBS factor for the given PN pairs from the output of 'ibs'.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . "[-t <thresh>] -pns <file> " . " <ibs output>\n";

my $composite_options = {
	'pns' => '',
	't' => 0.01
};

my $help_messages = {
	'pns' => "pn pairs file",
	't' => "threshold(0.01)"
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );
my $PNfile = opt_manager::get ( 'pns' );
my $thresh = opt_manager::get ( 't' );

unless ( scalar @inputarr == 0 or $PNfile eq '' )
{
	open ( my $ph, '<', "${PNfile}" ) or die "\n${PNfile}: $!\n";
	my @pns = <$ph>;
	chomp ( @pns );
	close $ph;
	foreach my $ibsfile ( @inputarr )
	{
		open ( my $fh, '<', "${ibsfile}" ) or die "\n${ibsfile}: $!\n";
		while ( my $line = <$fh> )
		{
			my @ibsinfo = split ( /[ \t]+/, $line );
			my $pair = $ibsinfo[1] . "\t" . $ibsinfo[2];
			my $index = toolz::binary_text_search ( $pair, \@pns );
			if ( $index < 0 )
			{
				$pair = $ibsinfo[2] . "\t" . $ibsinfo[1];
				$index = toolz::binary_text_search ( $pair, \@pns );
			}
			unless ( $index < 0 )
			{
				my @pairpns = split ( "\t", $pair );
				print ( $pairpns[0] . "\n" ) if ( $ibsinfo[8] < $thresh );
			}
		}
		close $fh;
	}
}
else
{
	print ( "\n missing input.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . "[-t <thresh>] -pns <file> " . " <ibs output file>\n\n" );
}

