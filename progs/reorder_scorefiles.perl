#!/usr/bin/perl
use strict;
use warnings;

my $verbose = 0;

if ( scalar @ARGV > 0 )
{
	open ( LIST, "ls |" ) or die "couldn't list directory content\n";
	foreach my $file ( @ARGV )
	{
		my $cnt = 0;
		my $scnt = 0;
		my $tcnt = 0;
		open ( FH, "<${file}" ) or die "couldn't open file ${file}\n";
		open ( NFH, ">${file}.new" ) or die "couldn't open file ${file}.new\n";
		foreach my $line ( <FH> )
		{
			if ( $line =~ /#.*/ )
			{
				$scnt++;
				if ( $scnt % 2 == 0 && $tcnt > 1)
				{
					print ( NFH "#\n" );
				}
			}
			else
			{
				$cnt++;
				chomp $line;
				my @data = split ( "\t", $line );
				print ( NFH "${data[0]}\t" );
				if ( $cnt % 3 == 0 )
				{
					print ( NFH "${data[1]}\n" );
				}
			}
			$tcnt++;
		}
	}
}
else
{
	print ( "usage: $0 <files>\n" );
}
