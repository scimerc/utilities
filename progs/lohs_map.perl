#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description =  " write a LOH map file out of a LOH string file (see 'findLOHs').\n";
my $program_usage =  "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <LOH string file(s)>\n";

my $composite_options = {
  'b' => 0,
  'd' => 0,
  'bmax' => 0,
  'dmax' => 0,
  'map' => ''
};

my $help_messages = {
  'b' => "non-LOHS tolerance buffer (to be combined with 'd');\n",
  'd' => "non-LOHS distance tolerance buffer (to be combined with 'b');\n",
  'bmax' => "non-LOHS tolerance buffer: LOHs this far apart get different tags;\n",
  'dmax' => "non-LOHS distance tolerance buffer: LOHs this far apart get different tags;\n",
  'map' => "snp map file.\n"
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );
my $buffer = opt_manager::get ( 'b' );
my $distbuffer = opt_manager::get ( 'd' );
my $maxbuffer = opt_manager::get ( 'bmax' );
my $maxdistbuffer = opt_manager::get ( 'dmax' );
my $snpmap = opt_manager::get ( 'map' );

unless ( scalar @inputarr == 0 or $snpmap eq '' )
{
  my $cnt = 0;
  my $cnt_start = 0;
  my $oldcnt = -$buffer-1;
  my $oldcnt_start = -$buffer-1;
  my $pos = 0;
  my $pos_start = 0;
  my $oldpos = -$distbuffer-1;
  my $oldpos_start = -$distbuffer-1;
  my $tagcnt = 0;
  open ( my $fhmap, '<', "${snpmap}" ) or die "\n${snpmap}: $!\n";
  my @snplist = <$fhmap>;
  close $fhmap;
  foreach my $outfile ( @inputarr )
  {
    open ( my $fh, '<', "${outfile}" ) or die "\n${outfile}: $!\n";
    while ( my $line = <$fh> )
    {
      chomp $line;
      my $last = '';
      my @data = split ( /[\t ]+/, $line );
      my @LOHdata = split ( '', $data[3] );
      my $allele = 'Q';
      my $oldallele = 'Q';
      $cnt = $cnt_start;
      $oldcnt = $oldcnt_start;
      $oldpos = $oldpos_start;
      $tagcnt = $cnt;
      foreach my $char ( @LOHdata )
      {
        chomp $char;
        if ( $char eq 'x' or $char eq 'y' )
        {
            chomp $snplist[$cnt];
            my @snpdata = split ( /[\t ]+/, $snplist[$cnt] );
            my $current = $data[0] . "_" . $snpdata[1];
            my $message = '';
            $allele = 'M' if ( $char eq 'x' );
            $allele = 'P' if ( $char eq 'y' );
            # change tag if conditions met:
            #   a. allele is changing;
            unless ( $allele eq $oldallele )
            {
                $tagcnt = $cnt;
                $message = "changing tag to LOH${cnt} due to allele change.\n";
                print ( $message ) if ( opt_manager::get ( 'v' ) );
            }
            #             OR
            #   b. both the following:
            #     i) SNP counter more than $buffer apart;
            #     ii) SNP position more than $distbuffer apart.
            $message = "[" . $cnt . " <> " . $oldcnt . " --- " . $snpdata[1] . " <> " . $oldpos . "]\n";
            print ( $message ) if ( opt_manager::get ( 'v' ) );
            if ( $cnt > $oldcnt+$buffer+1 and $snpdata[1] > $oldpos+$distbuffer )
            {
                $tagcnt = $cnt;
                $message = "changing tag to LOH${cnt} due to combined genomic/physical distance.\n";
                print ( $message ) if ( opt_manager::get ( 'v' ) );
            }
            #             OR
            #   c. either of the following:
            #     i) SNP counter more than $maxbuffer apart;
            #     ii) SNP position more than $maxdistbuffer apart.
            $message = "[" . $cnt . " <> " . $oldcnt . " --- " . $snpdata[1] . " <> " . $oldpos . "]\n";
            print ( $message ) if ( opt_manager::get ( 'v' ) );
            if ( $cnt > $oldcnt+$maxbuffer+1 or $snpdata[1] > $oldpos+$maxdistbuffer )
            {
                $tagcnt = $cnt;
                $message = "changing tag to LOH${cnt} due to either genomic or physical distance.\n";
                print ( $message ) if ( opt_manager::get ( 'v' ) );
            }
            # write down LOH entry
            unless ( $current eq $last )
            {
                my $output_line = $data[0] . "\tLOH$tagcnt\t$allele\t" . $snplist[$cnt];
                print ( "$output_line\n" );
            }
            $last = $current;
            $oldallele = $allele;
            $oldpos = $snpdata[1];
            $oldcnt = $cnt;
        }
        $cnt++;
      }
    }
    $cnt_start = $cnt;
    $oldcnt_start = $oldcnt;
    $oldpos_start = $oldpos;
  }
}
else
{
  print ( "\n missing input.\n" );
  print ( "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <LOH string file(s)>\n\n" );
}

