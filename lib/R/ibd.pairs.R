ibd.pairs <- function(id.pairs)
{
  ddir <- "/nfs/gpfs/data/statbox/dfg/phasing_ibs/GWPhase/"
  idir <- "/nfs/gpfs/data/statbox/frigge/GeneDrop/R7/IBD/"
  mdir <- "/nfs/gpfs/data/statbox/frigge/Data/HM3r2/hapmap3_r2_plus_1000g_jun2010_b36_ceu/"

  chrs <- paste("chr",c(1:22),sep="")

  cmd <- paste("/home/francesb/progs/lrpsharing",
               " --binlrp ",ddir,chrs,
               " --map ",ddir,chrs,".fullmap",
               " --Igenmap ",mdir,"genetic_map_",chrs,"_combined_b36.txt",
               " --chr ",c(1:22),
               " --pairs",
               " --findshr pairs.",id.pairs,
               " --mingendst 1",
               " --minsnpshared 20",
               " -o ",chrs,".ibd.pairs.",id.pairs,
               sep="")
  write(cmd,paste("cmd.ibd.pairs.",id.pairs,sep=""),ncol=1)
}
