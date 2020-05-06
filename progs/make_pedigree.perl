#!/usr/bin/perl
use strict;
use warnings;

my $sexcoord = 6;
my $numcoord = 0;
my $fathercoord = 2;
my $mothercoord = 3;
my $personcoord = 1;
my $familycoord = 0;
my $diagcoord = 2;
my $defaultdiag = 1;

sub searchFamilyFile
{
	my $fh;
	my $pn = $_[1];
	my $returnline = "";
	open ( $fh, '<', "${_[0]}" ) or die "\n$!\n";
	while ( my $line = <$fh> )
	{
		chomp $line;
		$returnline = $line if ( $line =~ /^[0-9]*\t${pn}\t/ );
	}
	return $returnline;
}

sub searchInfoFile
{
	my $fh;
	my $pn = $_[1];
	my $returnline = "";
	open ( $fh, '<', "${_[0]}" ) or die "\n$!\n";
	while ( my $line = <$fh> )
	{
		chomp $line;
		$returnline = $line if ( $line =~ /^${pn}\t/ );
	}
	return $returnline;
}


if ( scalar @ARGV > 1 )
{
	my $fh;
	my $ph;
	open ( $fh, '<', "${ARGV[0]}" ) or die "\n$!\n"; # open family file
	open ( $ph, '<', "${ARGV[1]}" ) or die "\n$!\n"; # open person file
	my $count = 0;
	my @oinfo = (); # initialize orphanhood array
	my @plist = (); # initialize person list
	while ( my $line = <$ph> )
	{
		chomp $line;
		push @plist, $line; # add person from person file to person list
		$oinfo[$count] = 1; # assume orphanhood
		$count++;
	}
	seek ( $ph, 0, 0 ); # rewind person file
	while ( my $fline = <$fh> )
	{
		chomp $fline;
		my @finfo = split ( /[\t ]/, $fline, -1 );
		my $found = 0; # reset flag
		unless ( $finfo[$personcoord] eq "0" ) # person id is available
		{
			$count = 0; # reset counter
			my $sex = 0;
			if ( defined $finfo[$sexcoord] )
			{
				$sex = $finfo[$sexcoord];
			}
			while ( my $pline = <$ph> ) # scan person file to see if person is there
			{
				chomp $pline;
				my @pinfo = split ( /[\t ]/, $pline, -1 );
				if ( $pline =~ /^${finfo[$personcoord]}[\t ]*/ ) # person id matches that in person file
				{
					if ( scalar @pinfo > 1 )
					{
						$sex = 1 if ( $pinfo[$sexcoord] == 1 );
						$sex = 2 if ( $pinfo[$sexcoord] == 0 );
					}
					# write down known information
					print "${finfo[$personcoord]}\t";
					print "${finfo[$fathercoord]}\t";
					print "${finfo[$mothercoord]}\t";
					print "0\t0\t${sex}\n";
					$oinfo[$count] = 0; # no orphan
					$found = 1; # set flag
				}
				$count++;
			}
			seek ( $ph, 0, 0 ); # rewind person file
			if ( $found == 0 ) # the person was not found in person file
			{
				my $ffh;
				open ( $ffh, '<', "${ARGV[0]}" ) or die "\n$!\n";
				while ( my $ffline = <$ffh> ) # scan family file to see if the person is a parent
				{
					chomp $ffline;
					my @ffinfo = split ( /[\t ]/, $ffline, -1 );
					my $entrycount = 0; # reset counter
					foreach my $entry ( @ffinfo ) # scan family information entries
					{
						# sex is male if person is father
						$sex = 1 if ( $entry eq $finfo[$personcoord] && $entrycount == $fathercoord );
						# sex is female if person is mother
						$sex = 2 if ( $entry eq $finfo[$personcoord] && $entrycount == $mothercoord );
						$entrycount++;
					}
				}
				close $ffh;
				print "${fline}\t$sex\t$defaultdiag\n";
			}
		}
	}
	$count = 0; # reset counter
	# write down the ones that remained orphans
	foreach my $oline ( @plist )
	{
		if ( $oinfo[$count] == 1 )
		{
			chomp $oline;
			my $sex = 0;
			my $diag = $defaultdiag;
			my @pinfo = split ( /[\t ]/, $oline, -1 );
			if ( scalar @pinfo > $sexcoord )
			{
				$sex = $pinfo[$sexcoord];
			}
			if ( scalar @pinfo > $diagcoord )
			{
				$diag = $pinfo[$diagcoord];
			}
			# write down known information
			print "${pinfo[$numcoord]}\t${pinfo[$numcoord]}\t0\t0\t";
			print "${sex}\t${diag}\n";
		}
		$count++;
	}
	close $fh;
	close $ph;
}
else
{
	print ( "\n similar to the genealogy generating script, but includes diagnosis information.\n" );
	print ( "\n  usage: $0 <family file> <person file>\n" );
	print ( "\n  [note: make sure your family file is complete before you run this.]\n\n" );
}
