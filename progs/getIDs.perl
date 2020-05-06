#!/usr/bin/perl
use strict;
use warnings;
use lib '/user/france/Lavoro/Tools';
use opt_manager;
use dbconnect;

my $buffer = '';

opt_manager::read ( @ARGV );

dbconnect::start ( opt_manager::get ( 'table' ) );

my $cnt = 0;
my @entries = ();

open ( my $ifh, '<', opt_manager::get ( 'infile' ) ) or die opt_manager::get ( 'infile' ) . ": $!\n";
open ( my $ofh, '>', opt_manager::get ( 'outfile' ) ) or die opt_manager::get ( 'outfile' ) . ": $!\n";

foreach my $line ( <$ifh> )
{
	chomp $line;
	my @data = split ' ', $line;
	if ( scalar @data > 1 )
	{
		if ( opt_manager::get ( 'verbosity' ) > 0 )
		{
			print ( "getting name for domain n. " . $data[1] . "....\n" );
		}
		my $name = dbconnect::getDomainName ( $data[1] );
		push @entries, "$name";
		$cnt++;
	}
}

foreach my $entry ( @entries )
{
	print ( $ofh "$entry\n" );
}

close $ifh;
close $ofh;

dbconnect::finish ( );
