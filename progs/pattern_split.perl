#!/usr/bin/perl
# split a file in multiple files at every occurrence of some pattern;
# the files generated are formed from the original filename and a suffix '.<n>'
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;

my @inputarr = ();
@inputarr = opt_manager::read ( @ARGV );
push ( @inputarr, opt_manager::get ( 'infile' ) ) if ( length ( @inputarr ) == 0 );
if ( scalar @inputarr > 0 )
{
	foreach my $inputfile ( @inputarr )
	{
		open ( my $ifh, '<', $inputfile ) or die "${inputfile}: $!\n";
		my $filestring = '';
		while ( my $line = <$ifh> )
		{
			$filestring .= $line;
		}
		my $pattern = opt_manager::get ( 'pattern' );
		my @fpart = split ( $pattern, $filestring);
		my $count = 0;
		foreach my $part ( @fpart )
		{
			open ( my $ofh, '>', "${inputfile}.${count}" ) or die ": $!\n";
			printf ( $ofh $part );
			close $ofh;
			$count++;
		}
		close $ifh;
	}
}
else
{
	print ( "\n split <files> at every occurrence of the pattern specified by <regex>.\n" );
	print ( "\n  usage:  pattern_split.perl -pattern[ |=]<regex> <files>\n\n" );
}

