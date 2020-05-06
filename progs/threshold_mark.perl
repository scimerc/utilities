#!/usr/bin/perl
use strict;
use warnings;

my @table;
my @filter;
my $ncolumns = 0;
my $nrows = 0;
my $offset = 2;
my $thresh = 1.29;

for (my $k = 0; $k < $offset ; $k++)
{
	push @filter, 1;
}

while ( my $line = <> )
{
	chomp $line;
	if ( $line !~ /#/ )
	{
		$nrows++;
		my @data = split ( ' ', $line );
		if ( scalar @data > $ncolumns )
		{
			$ncolumns = scalar @data;
		}
		push @table, \@data;
	}
	print "$line\n";
}

for ( my $i = $offset; $i < $ncolumns; $i++ )
{
	my $sum = 0;
	for ( my $j = 0; $j < $nrows; $j++ )
	{
		$sum += $table[$j][$i];
	}
	push @filter, 0;
	if ( $sum >= $thresh )
	{
		$filter[$i] = '+';
	}
	else
	{
		$filter[$i] = '-';
	}
}

for ( my $i = 0; $i < $ncolumns; $i++ )
{
	print "$filter[$i]\t";
}

print "\n";

