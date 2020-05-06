#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $varpos_coord = 1;
my $varstring_coord = 3;
my $chr_coord = 0;

my $program_description = " count variants in the PNs.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <variant file(s)>\n";

my $composite_options = {
	'path' => 'sequencing'
};

my $help_messages = {
	'path' => "path to the directory containing the sequenced samples information.\n" . 
		"[Note: at the time of writing this is a directory with a subdirectory\n" . 
        "for each PN.]\n" . "[Default: '" . $composite_options->{'path'} . "']\n"
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
	foreach my $varfile ( @inputarr )
	{
		my @PNchrpos = ();
		my @PNchrlastpos = ();
		my @string = ();
		my $PNdir = opt_manager::get ( 'path' );
		opendir ( my $dh, $PNdir ) || die "\n${PNdir}: $!\n";
		my @PNs = grep ( !/^[.]/, readdir ( $dh ) );
		my @PNfh = ();
		my $PNcnt = 0;
		foreach my $person ( @PNs )
		{
			my $PNfile = "${PNdir}/${person}/${person}.snpcalls.final";
			if ( open ( my $tmpfh, '<', $PNfile ) )
			{
				push @PNfh, $tmpfh;
				push @PNchrpos, 0;
				push @PNchrlastpos, 0;
				push @string, '';
				$PNcnt++;
			}
		}
		open ( my $fh, '<', "${varfile}" ) or die "\n${varfile}: $!\n";
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
				for ( my $i = 0; $i < $PNcnt; $i++ )
				{
					my $PNline = '';
					my @PNinfo = ();
					my $tmpPNfh = $PNfh[$i];
					if ( defined $tmpPNfh and defined $chrpos )
					{
						while ( $PNchrpos[$i] < $chrpos and defined ( $PNline = <$tmpPNfh> ) )
						{
							if ( $PNline =~ /^${chromosome}[[:space:]]/ )
							{
								chomp $PNline;
								@PNinfo = split ( "\t", $PNline, -1 );
								$PNchrpos[$i] = $PNinfo[$varpos_coord];
								$string[$i] = $PNinfo[$varstring_coord];
							}
						}
						if ( $PNchrpos[$i] == $chrpos && $PNchrpos[$i] != $PNchrlastpos[$i] )
						{
							if ( $string[$i] eq $varstring )
							{
								$cnt++;
							}
							$PNchrlastpos[$i] = $PNchrpos[$i];
						}
					}
				}
				printf ( "\t$cnt\n" );
			}
			else
			{
				print "\twarning: non-numeric position [${chrpos}] in variant file ${varfile}\n";
			}
		}
		for ( my $i = 0; $i < $PNcnt; $i++ )
		{
			close $PNfh[$i];
		}
		close $fh;
		closedir $dh;
	}
}
else
{
	print ( "\n missing input.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <variant file(s)>\n\n" );
}

