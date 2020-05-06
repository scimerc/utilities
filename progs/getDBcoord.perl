#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use dbconnect;

my $buffer = '';

if ( scalar @ARGV > 0 )
{
	opt_manager::read ( @ARGV );

	open ( my $ifh, '<', opt_manager::get ( 'infile' ) ) or die opt_manager::get ( 'infile' ) . ": $!\n";
	open ( my $ofh, '>', opt_manager::get ( 'outfile' ) ) or die opt_manager::get ( 'outfile' ) . ": $!\n";

	dbconnect::start ( opt_manager::get ( 'table' ) );

	my $cnt = 0;
	my @entries = ();

	foreach my $line ( <$ifh> )
	{
		chomp $line;
		my $ID = dbconnect::getDomainID ( $line );
		if ( defined $ID )
		{
			push @entries, "$cnt $ID 0";
		}
		else
		{
			print "warning: domain $line not found.\n";
		}
		$cnt++;
	}

	print ( $ofh "$cnt 0 0\n" );
	foreach my $entry ( @entries )
	{
		print ( $ofh "$entry\n" );
	}

	close $ifh;
	close $ofh;

	dbconnect::finish ( );
}
else
{
	print ( "\nThis program fetches the database coordinates for a given list of protein domanin names.\nUsage: $0 " );
	print ( "[-infile=<domain names list file {default is 'infile.dat'}>] " );
	print ( "[-outfile=<database coordinates output file {default is 'outfile.dat'}> " );
	print ( "[-table=<database reference table {default is 'Proteins'}>\n" );
}
