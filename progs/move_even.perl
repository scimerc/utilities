#!/usr/bin/perl
# pairs consecutive lines in a file
# separates entries with a <tab>
use strict;
use warnings;

exit if ( scalar @ARGV < 1 );

my $cnt = 0;
foreach my $file ( @ARGV )
{
	open ( FH, "<$file" );
	while ( my $line = <FH> )
	{
		if ( $cnt % 2 == 0 )
		{
			chomp $line;
			$line = "$line\t";
		}
		print ( $line );
		$cnt++;
	}
}

