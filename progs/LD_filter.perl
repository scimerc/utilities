#!/usr/bin/perl
# this was supposed to work with LD files from an older version of the pipeline
# it seems this was changed later on so this script may be obsolete.
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " filter markers from an LD list."; 
my $program_usage = "\n\n  usage: " . toolz::pathless( $0 ) . " [options] <LD list(s)>\n";

my $composite_options = {
	't' => 0.9
};

my $help_messages = {
	't' => 'correlation threshold [default = ' . $composite_options->{'t'} . ']'
};

opt_manager::init_help_message( $program_description . $program_usage );
opt_manager::set_composite_options( $composite_options, $help_messages );

my @inputarr = opt_manager::read( @ARGV );
my $thresh = opt_manager::get( 't' );

if ( scalar @inputarr > 0 )
{
	foreach my $LDfile ( @inputarr )
	{
		my $catalog = {};
		my $LDcatalog = {};
		open( my $fh, '<', "${LDfile}" ) or die "\n${LDfile}: $!\n";
		while ( my $LDline = <$fh> )
		{
			chomp $LDline;
			my @LDinfo = split( /[ \t]+/, $LDline, -1 );
			if ( $LDinfo[3] > $thresh )
			{
				$LDcatalog->{$LDinfo[1]} = [] unless exists ( $LDcatalog->{$LDinfo[1]} );
				$catalog->{$LDinfo[1]} = 0 unless exists ( $catalog->{$LDinfo[1]} );
				push( @{$LDcatalog->{$LDinfo[1]}}, $LDinfo[2] );
				$catalog->{$LDinfo[1]}++;
			}
		}
		my @tagkeys = ();
		foreach my $key ( sort { $catalog->{$b} <=> $catalog->{$a} } keys %$catalog )
		{
			if ( exists $catalog->{$key} )
			{
				push( @tagkeys, $key );
				delete( @{$catalog}{@{$LDcatalog->{$key}}} );
			}
		}
		foreach my $key ( @tagkeys )
		{
			print( "$key\n" );
		}
		close $fh;
	}
}
else
{
	print( "\n  usage: " . toolz::pathless( $0 ) . " <LD list(s)> [try '-h' for help]\n\n" );
}
