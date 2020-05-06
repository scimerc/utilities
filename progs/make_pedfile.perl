#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $composite_options = {
	'p' => '',
	'g' => '',
};

my $help_messages = {
	'p' => 'sets the file containing the list of PNs.',
	'g' => 'sets the four column file containing the genotypes.'
};

opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
}
else
{
}
