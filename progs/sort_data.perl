#!/usr/bin/perl
use strict;
use warnings;

my $verbose = 0;

if ( scalar @ARGV > 0 )
{
	my $label = $ARGV[0];
	open ( LIST, "ls |" ) or die "couldn't list directory content.\n";
	foreach my $file ( <LIST> )
	{
		if ( $file =~ /config.+job-(.+)/ )
		{
			my $jobnum = $1;
			print ( "checking job $jobnum....\n" ) if ( $verbose );
			open ( RLIST, "ls results-* |" ) or die "couldn't list result files.\n";
			my $greplabel = `grep \"${label} \" ${file}`;
			print ( "label found: $greplabel" ) if ( $verbose );
			my @labelcfg = split ( ' ', $greplabel );
			foreach my $rfile ( <RLIST> )
			{
				chomp $rfile;
				print ( "checking file $rfile....\n" ) if ( $verbose );
				if ( $rfile =~ /results-p(.+)-d.+\.csv\.job-$jobnum$/ )
				{
					my $cnt = 0;
					print ( "extracting data from $rfile....\n" ) if ( $verbose );
					open ( FH, "<$rfile" ) or die "couldn't open file $rfile\n";
					foreach my $line ( <FH> )
					{
						chomp $line;
						if ( $cnt > 0 )
						{
							print ( "${labelcfg[1]}\t$1\t$line\t" );
						}
						$cnt++;
					}
					print "\n";
					close ( FH );
				}
			}
		}
	}
}
else
{
	print ( "usage: $0 <label>\n" );
}
