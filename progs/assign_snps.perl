#!/usr/bin/perl
# this shuld make lists of comma-separated SNPs for every given gene.
# it was used to set up the pathway analysis protocol.
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " assign SNPs to the correct genes according to their position.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " -gm <gene map> <SNP map file(s)>\n\n" . 
                    "  the gene map records have format: <gene_ID1>  <gene_ID2>  <start>  <end>\n" . 
                    "  the SNP map is expected to have: <SNP_ID>  <unused>  <position>...\n";
my $snp_coord = 0;
my $pos_coord = 2;
my $lower_coord = 2;
my $higher_coord = 3;
my $upstream_offset = 0;
my $downstream_offset = 0;
my $extra_coord = 4;

my $composite_options = {
	'gm' => ''
};

my $help_messages = {
	'gm' => "path to the gene map file\n"
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );
my $genemap_file = opt_manager::get ( 'gm' );
unless ( scalar @inputarr == 0 or ${genemap_file} eq '' )
{
	my $genes = toolz::read_file ( $genemap_file );
	foreach my $snpfile ( @inputarr )
	{
		open ( my $fh, '<', $snpfile ) or die "\n${snpfile}: $!\n";
		{
			my $snp = '';
			while ( defined ( $snp = <$fh> ) )
			{
				my @snpdata = split ( /[\t ]+/, $snp );
				my $pos = $snpdata[$pos_coord];
				my ( $p, $q ) = toolz::binary_close_field_search ( $pos, $genes, $lower_coord );
				if ( $pos > $genes->[$p]->[$lower_coord] - $upstream_offset )
				{
					$genes->[$p]->[$extra_coord] .= ',' if ( defined ( $genes->[$p]->[$extra_coord] ) );
					$genes->[$p]->[$extra_coord] .= $snpdata[$snp_coord];
				}
				if ( $p > 0 and $pos < $genes->[$p-1]->[$higher_coord] + $downstream_offset )
				{
					if ( defined ( $genes->[$p-1]->[$extra_coord] ) )
					{
						$genes->[$p-1]->[$extra_coord] .= ',' . $snpdata[$snp_coord];
					}
					else
					{
						$genes->[$p-1]->[$extra_coord] = $snpdata[$snp_coord];
					}
				}
			}
		}
		close $fh;
	}
	foreach my $gene ( @$genes )
	{
		print "@{$gene}\n";
	}
}
else
{
	print ( "\n missing input.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " -gm <gene map> <snp map file(s)>\n\n" );
}

