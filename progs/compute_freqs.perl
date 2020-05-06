#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " compute frequencies of variants in PN files in the given directory.\n" . 
                        " the program was thought for use with variant files from sequencing.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " [options] <file(s)>\n";

my $varpos_coord = 1;
my $varstring_coord = 3;

my $composite_options = {
	'nucleus' => '/nfs_mount/chromosomes',
	'path' => '/nfs_mount/pns',
};

my $help_messages = {
	'nucleus' => 'path to the directory containing the data ordered per chromosomes',
	'path' => 'path to the directory containing the sequenced people information'
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
	foreach my $chromosome ( @inputarr )
	{
		my @index = ();
		my @lastindex = ();
		my @string = ();
		my $PNdir = opt_manager::get ( 'path' );
		opendir ( my $dh, $PNdir ) || die "\n${PNdir}: $!\n";
		my @PNs = grep ( ( !/^\./ and -f "${PNdir}/$_" ), readdir ( $dh ) );
		my @PNfh = ();
		my $PNcnt = 0;
		foreach my $person ( @PNs )
		{
			open ( my $tmpfh, '<', "${PNdir}/${person}" ) or die "\n${person}: $!\n";
			push @PNfh, $tmpfh;
			push @index, 0;
			push @lastindex, 0;
			push @string, '';
			$PNcnt++;
		}
		my $fh;
		my $chrfile = opt_manager::get ( 'nucleus' ) . '/' . $chromosome;
		open ( $fh, '<', "${chrfile}" ) or die "\n${chrfile}: $!\n";
		while ( my $chrpos = <$fh> )
		{
			chomp $chrpos;
			if ( "$chrpos" =~ /^[0-9]+$/ )
			{
				my %variant = ();
				printf ( "$chromosome\t$chrpos" );
				for ( my $i = 0; $i < $PNcnt; $i++ )
				{
					my $PNline = '';
					my @PNinfo = ();
					my $tmpPNfh = $PNfh[$i];
					if ( defined $tmpPNfh and defined $chrpos )
					{
						while ( $index[$i] < $chrpos and defined ( $PNline = <$tmpPNfh> ) )
						{
							if ( $PNline =~ /^${chromosome}[[:space:]]/ )
							{
								chomp $PNline;
								@PNinfo = split ( "\t", $PNline, -1 );
								$index[$i] = $PNinfo[$varpos_coord];
								$string[$i] = $PNinfo[$varstring_coord];
							}
						}
						if ( $index[$i] == $chrpos && $index[$i] != $lastindex[$i] )
						{
							if ( defined $variant{$string[$i]} )
							{
								$variant{$string[$i]}++;
							}
							else
							{
								$variant{$string[$i]} = 1;
							}
							$lastindex[$i] = $index[$i];
						}
					}
				}
				if ( scalar keys %variant > 0 )
				{
					while ( my ( $key, $value ) = each %variant )
					{
						printf ( "\t" );
						printf ( "$key (%.4f)", $value / $PNcnt );
					}
				}
				printf ( "\n" );
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
	print ( "\n compute frequencies of variants in PN files in the given directory.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " <file(s)>\n\n" );
}

