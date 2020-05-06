#!/usr/bin/perl
use strict;
use warnings;

my $fathercoord = 1;
my $mothercoord = 2;
my $personcoord = 0;
my @catalog = ();

sub searchCatalog
{
	my $found = 0;
	my $person = $_[0];
	foreach my $pn ( @catalog )
	{
# 		print "comparing $pn to $person\n";
		if( $pn eq $person )
		{
			$found++;
			last if ( $found > 0 );
		}
	}
	return $found;
}

sub trace_back
{
	my $gh;
	my $flag = 0;
	my $person = $_[0];
	if ( searchCatalog ( $person ) > 0 )
	{
		$flag = 1;
	}
	else
	{
		push @catalog, $person;
		open ( $gh, '<', "$_[1]" ) or die "\n$_[1]: $!\n"; # open genealogy file
		while ( defined ( my $line = <$gh> ) and $flag == 0 )
		{
			if ( $line =~ /^$person[ \t]+/ )
			{
				my @info = split ( /[\t ]/, $line, -1 );
				my $fatherpn = $info[$fathercoord];
				my $motherpn = $info[$mothercoord];
				unless ( $fatherpn eq "0" )
				{
					$flag += trace_back ( $fatherpn, $_[1] );
				}
				unless ( $motherpn eq "0" )
				{
					$flag += trace_back ( $motherpn, $_[1] );
				}
			}
		}
		close $gh;
	}
	return $flag;
}


if ( scalar @ARGV > 0 )
{
	my $gh;
	open ( $gh, '<', "${ARGV[0]}" ) or die "\n$ARGV[0]: $!\n"; # open genealogy file
	while ( my $line = <$gh> )
	{
		chomp $line;
		my @info = split ( /[\t ]/, $line, -1 );
		my $person = $info[0];
		unless ( $person eq "0" )
		{
			@catalog = ();
			print "$person ";
			if ( trace_back ( $person, $ARGV[0] ) == 0 )
			{
				print "normal\n";
			}
			else
			{
				print "recursive\n";
			}
		}
	}
	close $gh;
}
else
{
	print ( "\n checks inconsistencies (recurrent PNs) in a genealogy (e.g. islbok) file.\n" );
	print ( "\n  usage: $0 <genealogy file>\n\n" );
}

