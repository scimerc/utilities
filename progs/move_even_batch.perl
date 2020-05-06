#!/usr/bin/perl
# pairs consecutive lines in a file
# separates entries with a <tab>
use strict;
use warnings;

my $cnt = 0;

while ( my $line = <> ) {
		if ( $cnt % 2 == 0 )
		{
			chomp $line;
			$line = "$line\t";
		}
		print ( $line );
		$cnt++;
}

