#!/usr/bin/perl
use strict;

my $PSIPREDpath = system( 'which psipred' );
my $myEXTENSION = 'pred.adj';

sub getStructure
{
  my $tdb = $_[0];
#   if ($tdb eq 'H')
#   {
#     return 'H';
#   }
#   elsif ($tdb eq 'E')
#   {
#     return 'E';
#   }
#   else
#   {
#     return 'C';
#   }
  if ($tdb eq 'H' || $tdb eq 'G' || $tdb eq 'I')
  {
    return 'H';
  }
  elsif ($tdb eq 'E' || $tdb eq 'B')
  {
    return 'E';
  }
  else
  {
    return 'C';
  }
}

sub getIndex
{
  my $str = $_[0];
  
  if ($str eq 'H')
  {
    return 0;
  }
  elsif ($str eq 'E')
  {
    return 1;
  }
  elsif ($str eq 'C')
  {
    return 2;
  }
  else
  {
    die ("Unknown SSE type: \"$str\"\n");
  }
}

sub computeCorrelationCoefficient
{
	my @confusionMatrix = @{$_[0]} ;
	my $numerator = 0. ;
	my $denominator = 0. ;
	my $sum_over_k_A = 0. ;
	my $sum_over_k_B = 0. ;
	my $catalogSize = 3. ;
	for(my $k = 0; $k<$catalogSize; $k++)
	{
		my $sum_over_i_A = 0. ;
		my $sum_over_i_B = 0. ;
		my $sum_over_ij_A = 0. ;
		my $sum_over_ij_B = 0. ;
		for(my $i = 0; $i<$catalogSize; $i++)
		{
			for(my $j = 0; $j<$catalogSize; $j++)
			{
# 				print ">>>>>> assembling GCC-numerator step[$i][$j]:" ;
# 				print "GCC += ${confusionMatrix[$k][$k]}*${confusionMatrix[$i][$j]}" ;
# 				print " - ${confusionMatrix[$k][$i]}*${confusionMatrix[$j][$k]}\n" ;
				$numerator += $confusionMatrix[$k][$k]*$confusionMatrix[$i][$j] - $confusionMatrix[$k][$i]*$confusionMatrix[$j][$k] ;
				if($j!=$k)
				{
					$sum_over_ij_A += $confusionMatrix[$j][$i] ;
					$sum_over_ij_B += $confusionMatrix[$i][$j] ;
				}
			}
			$sum_over_i_A += $confusionMatrix[$k][$i] ;
			$sum_over_i_B += $confusionMatrix[$i][$k] ;
		}
		$sum_over_k_A += $sum_over_i_A*$sum_over_ij_A ;
		$sum_over_k_B += $sum_over_i_B*$sum_over_ij_B ;
	}
	$denominator = sqrt($sum_over_k_A*$sum_over_k_B+1e-20) ;
	my $myGCC = $numerator / $denominator ;
# 	print ">>>>>> GCC inside subroutine: $myGCC ( = $numerator / $denominator )\n" ;
	return $numerator / $denominator ;
}


my $argnum = $#ARGV + 1;

($argnum >= 1) or die ("Filter file is missing!\n");

my $inDir = '/scratch/scratch/rasinski/profiles/input.dssp';
my $inDir2 = '/scratch/scratch/rasinski/datasets/dssp';

open(IN, "<$ARGV[0]") or die("Could not open file $ARGV[0] for reading!\n");

#undecided = more than one score above the threshold
#uncertain = all scores below threshold
my $protcnt = 0;
my $tinynumber = 1.E-12;
my $threshold = 0.4;
my $undecided1 = 0;
my $undecided2 = 0;
my $uncertain1 = 0;
my $uncertain2 = 0;
my $total = 0;
my $undecidedHelices1 = 0;
my $undecidedHelices2 = 0;
my $uncertainHelices1 = 0;
my $uncertainHelices2 = 0;
my $totalHelices = 0;
my $undecidedStrands1 = 0;
my $undecidedStrands2 = 0;
my $uncertainStrands1 = 0;
my $uncertainStrands2 = 0;
my $totalStrands = 0;
my $undecidedCoils1 = 0;
my $undecidedCoils2 = 0;
my $uncertainCoils1 = 0;
my $uncertainCoils2 = 0;
my $totalCoils = 0;
my $stage1correct = 0;
my $stage2correct = 0;
my $totalCorrect = 0;
my $correctHelices1 = 0;
my $correctHelices2 = 0;
my $totalCorrectHelices = 0;
my $correctStrands1 = 0;
my $correctStrands2 = 0;
my $totalCorrectStrands = 0;
my $correctCoils1 = 0;
my $correctCoils2 = 0;
my $totalCorrectCoils = 0;
my $nonconflict2nonconflict = 0;
my $nonconflict2nonconflictHelices = 0;
my $nonconflict2nonconflictStrands = 0;
my $nonconflict2nonconflictCoils = 0;
my $nonconflict2undecided = 0;
my $nonconflict2undecidedHelices = 0;
my $nonconflict2undecidedStrands = 0;
my $nonconflict2undecidedCoils = 0;
my $nonconflict2uncertain = 0;
my $nonconflict2uncertainHelices = 0;
my $nonconflict2uncertainStrands = 0;
my $nonconflict2uncertainCoils = 0;
my $undecided2nonconflict = 0;
my $undecided2nonconflictHelices = 0;
my $undecided2nonconflictStrands = 0;
my $undecided2nonconflictCoils = 0;
my $undecided2undecided = 0;
my $undecided2undecidedHelices = 0;
my $undecided2undecidedStrands = 0;
my $undecided2undecidedCoils = 0;
my $undecided2uncertain = 0;
my $undecided2uncertainHelices = 0;
my $undecided2uncertainStrands = 0;
my $undecided2uncertainCoils = 0;
my $uncertain2nonconflict = 0;
my $uncertain2nonconflictHelices = 0;
my $uncertain2nonconflictStrands = 0;
my $uncertain2nonconflictCoils = 0;
my $uncertain2undecided = 0;
my $uncertain2undecidedHelices = 0;
my $uncertain2undecidedStrands = 0;
my $uncertain2undecidedCoils = 0;
my $uncertain2uncertain = 0;
my $uncertain2uncertainHelices = 0;
my $uncertain2uncertainStrands = 0;
my $uncertain2uncertainCoils = 0;
my $controlTotal = 0;
my @globalConfusionMatrix = ([0, 0, 0],[0, 0, 0],[0, 0, 0]);

MAINLOOP: while(<IN>)
{
  my $prot = $_;
  chop($prot);
  my @localConfusionMatrix = ([0, 0, 0],[0, 0, 0],[0, 0, 0]);

  my $command = '';
  
  # Read the sequence and save it in a file
  my $copyCommand = "cp $inDir/$prot.in $prot.fasta";
  (system ($copyCommand) == 0) or die("Error executing command: $copyCommand\nError: $?");

#   $command = "${PSIPREDpath}/runpsipred $prot.fasta\n";
#   (system ($command) == 0) or die("Error executing command: $command\nError: $?");
  my @sequence = ();
  my $sequenceSubstring = '';
  my @structure = ();
  my $structureSubstring = '';
  my $breakCount = 0;
  open(SRC, "<$inDir2/$prot.dssp") or die("Could not open file $inDir2/$prot.dssp for reading!\n");
  while(<SRC>)
  {
    my $src_line = $_;
    chop($src_line);
    if ($src_line =~ /....[0-9] ...[0-9]...([AaVvMmLlIiFfWwPpGgEeDdKkRrHhCcQqNnSsTtYy])  (.).*/)
    {
      my $aaChar = $1;
      my $sseChar = $2;
      $sequenceSubstring .= $aaChar;
      if ($sseChar eq ' ')
      {
        $structureSubstring .= 'C';
      }
      else
      {
        $structureSubstring .= getStructure($sseChar);
      }
    }
    if ($src_line =~ /....[0-9] ...[0-9]...([Xx])  (.).*/ || $src_line =~ /[.]* ! [.]*/)
    {
#       print ("adding substring \"$sequenceSubstring\" to the sequence string....\n");
      push @sequence, $sequenceSubstring;
      push @structure, $structureSubstring;
      $sequenceSubstring = '';
      $structureSubstring = '';
      $breakCount++;
    }
  }
#   print ("adding substring \"$sequenceSubstring\" to the sequence string....\n");
  push @sequence, $sequenceSubstring;
  push @structure, $structureSubstring;
  $sequenceSubstring = '';
  $structureSubstring = '';
  close(SRC);

  my $jumpflag = 0 ;
  
  # Read the predicted structure
  open(PRED, "<$prot.${myEXTENSION}") or $jumpflag = 1;
  
  if ( $jumpflag == 0 )
  {
	my $residue = 0;
	my $offset = 0;
	my $lengthdiff = 0;
	my $firstSequence = '';
	my $firstPrediction = '';
	while(<PRED>)
	{
		my $line = $_;
		chop($line);
		if ($line =~/\s*\d+\s+([AVMLIFWPGEDKRHCQNSTYX])\s+([HEC])\s+.*/)
		{
			$firstSequence .= "$1";
			$firstPrediction .= "$2";
		}
	}
	close(PRED);
	$lengthdiff = (length $firstSequence) - (length $firstPrediction);
	if ( $lengthdiff != 0 )
	{
		die ("length mismatch (${lengthdiff}) between first predicted sequence and structure:\n${firstSequence}\n${firstPrediction}\n");
	}
	my $subcorrect = 0;
	my $subtotal = 0;
	my $cnt = 0;
	foreach $sequenceSubstring ( @sequence )
	{
		my $strIndex = 0;
		my $breakPosition = 0;
		my $sublength = length $sequenceSubstring;
		$breakPosition = index $firstSequence, $sequenceSubstring;
		if ( $breakPosition >= 0 )
		{
			my $prediction = substr $firstPrediction, $breakPosition, $sublength;
			
			for (my $i = 0; $i < $sublength; $i++)
			{
				my $str_char = substr $structure[$cnt], $i, 1;
				my $pred_char = substr $prediction, $i, 1;
				$total++;
				$subtotal++;
				$subcorrect++ if ( $str_char eq $pred_char );
				$globalConfusionMatrix[getIndex($pred_char)][getIndex($str_char)]++;
				$localConfusionMatrix[getIndex($pred_char)][getIndex($str_char)]++;
			}
		}
		$cnt++;
	}
# 	if ($subtotal != 0)
	{
		my $protAcc = 100.0 * $subcorrect / ( $subtotal + $tinynumber );
		my $gmcc = computeCorrelationCoefficient ( \@localConfusionMatrix );
		print "percentage of correct residues stage 1 for $prot: $protAcc ($subcorrect/$subtotal)\n";
		print "GMCC for stage 1 for $prot: $gmcc\n";
	}
  }
  else
  {
  	print "percentage of correct residues stage 1 for $prot: 0 (0/0)\n";
  	print "GMCC for stage 1 for $prot: 0\n";
  }
}

close(IN);

