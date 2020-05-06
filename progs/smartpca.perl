#!/usr/bin/perl

use Getopt::Std ;
use File::Basename ;

### process flags
my @flaglist = ("i","a","b","k","o","p","e","l","m","t","s");
$x = @ARGV;
for($n=0; $n<$x; $n++)
{
  foreach $flag (@flaglist) 
  {
    if($ARGV[$n] eq "-$flag") { $specified{$flag} = 1; }
  }
}
foreach $flag ("i","a","b","o","p","e","l")
{
  unless($specified{$flag}) { die("OOPS -$flag flag not specified"); }
}
get_opts('i:a:b:k:o:p:e:l:m:t:s:',\%opts);
$i = $opts{"i"}; 
$a = $opts{"a"}; 
$b = $opts{"b"}; 
$k = 10; if($specified{"k"}) { $k = $opts{"k"}; }
$o = $opts{"o"}; 
$p = $opts{"p"}; 
$e = $opts{"e"}; 
$l = $opts{"l"}; 
$m = 5; if($specified{"m"}) { $m = $opts{"m"}; }
$t = 10; if($specified{"t"}) { $t = $opts{"t"}; }
$s = 6.0; if($specified{"s"}) { $s = $opts{"s"}; }

### run smartpca
$parfile = "$o.par"; 
$evec = "$o.evec";
open(PARFILE,">$parfile") || die("OOPS couldn't open file $parfile for writing");
print PARFILE ("genotypename: $i\n");
print PARFILE ("snpname: $a\n");
print PARFILE ("indivname: $b\n");
print PARFILE ("evecoutname: $evec\n");
print PARFILE ("evaloutname: $e\n");
print PARFILE ("altnormstyle: NO\n");
print PARFILE ("numoutevec: $k\n");
print PARFILE ("numoutlieriter: $m\n");
print PARFILE ("numoutlierevec: $t\n");
print PARFILE ("outliersigmathresh: $s\n");
close(PARFILE);
$command = "smartpca";          # MUST put bin directory in path
$command .= " -p $parfile >$l";
print("$command\n");
system("$command");

### make string of populations for ploteig
$popstring = "";
open(EVEC,$evec) || die("OOPS couldn't open file $evec for reading");
while($line = <EVEC>)
{
  chomp($line);
  @array = split(/[\t ]+/,$line);
  $x = @array;
  if($array[1] =~ /eigvals/) { next; } # eigvals header line
  $pop = $array[$x-1];
  if($popfound{$pop}) { next; }
  $popstring = $popstring . "$pop:";
  $popfound{$pop} = 1;
}
close(EVEC);
chop($popstring); # remove last ":"

### cax ploteig
$command = "ploteig";           # MUST put bin directory in path
$command .= " -i $evec";
$command .= " -c 1:2 ";
$command .= " -p $popstring ";
$command .= " -x ";
$command .= " -o $p.xtxt "; # must end in .xtxt
print("$command\n");
system("$command");

### translate .evec file to .pca file expected by eigenstrat program
### Note: .evec file does not contain entries for outliers 
###       .pca  file does contain entries (set to ax 0.0) for outliers
open(EVEC,$evec) || die("OOPS couldn't open file $evec for reading");
open(IND,$b) || die("OOPS couldn't open indiv file $b for reading");
open(OUT,">$o") || die("OOPS couldn't open file $o for writing");

print OUT ("$k\n"); # number of output eigenvectors/eigenvalues
$line = <EVEC>; chomp($line); # eigvals line
my @array = split(/[\t ]+/,$line);
for($x=0; $x<$k; $x++) { printf OUT ("%.04f\n",$array[$x+2]); } # x-th eval
while($line = <EVEC>)
{
  chomp($line);
  my @array = split(/[\t ]+/,$line);
  $sample = $array[1];
  for($x=0; $x<$k; $x++) { $evecarray{$sample}[$x] = $array[$x+2]; }
  $found{$sample} = 1;
}
while($line = <IND>)
{
  chomp($line);
  my @array = split(/[\t ]+/,$line);
  $sample = $array[0];
  if($sample eq "") { $sample = $array[1]; }
  unless($found{$sample}) 
  {
    for($x=0; $x<$k; $x++) { $evecarray{$sample}[$x] = 0.0; }
  }
  for($x=0; $x<$k; $x++)
  {
    printf OUT (" ");
    if($evecarray{$sample}[$x] > 0) { printf OUT (" "); }
    printf OUT ("%.04f",$evecarray{$sample}[$x]);
  }
  printf OUT ("\n");
}

close(EVEC);
close(IND);
close(OUT);

### If labels are Case and Control only, compute correlations between
### Case/Control status and each eigenvector.  Append to logfile.
if(($popstring eq "Case:Control") || ($popstring eq "Control:Case"))
{
  open(LOG,">>$l") || die("OOPS couldn't open file $l for appending");
  print LOG ("\n");
  for($x=0; $x<$k; $x++) # compute correlation for evec $x
  {
    open(EVEC,$evec) || die("OOPS couldn't open file $evec for reading");
    $sum1=0; $sumx=0; $sumxx=0; $sumy=0; $sumyy=0; $sumxy=0;
    $line = <EVEC>; chomp($line); # eigvals line
    while($line = <EVEC>)
    {
      chomp($line);
      @array = split(/[\t ]+/,$line);
      $this = $array[2+$x];
      $sumy += $this;
      $sumyy += $this*$this;
      $sum1 += 1;
      if($line =~ /Case/) # Case is 1, Control is 0
      {
        $sumx += 1;
        $sumxx += 1;
        $sumxy += $this;
      }
    }
    close(EVEC);
    $meanx = $sumx/$sum1;
    $meany = $sumy/$sum1;
    if($sum1 == 0) { next; }
    $sdevx = sqrt($sumxx/$sum1 - $meanx*$meanx);
    $sdevy = sqrt($sumyy/$sum1 - $meany*$meany);
    if($sdevx * $sdevy == 0) { next; }
    $corr = ($sumxy/$sum1) / ($sdevx*$sdevy);
    $x1 = $x+1;
    printf LOG ("Correlation between eigenvector $x1 (of $k) and Case/Control status is %.03f\n",$corr);
  }
  close(LOG);
}
