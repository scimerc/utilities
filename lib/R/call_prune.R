library(h5r)

pruneLdPre <- function(logp, threshold=0.0, row.idx = NULL,
            col.idx = NULL, ld.dat = NULL, shape = NULL,
            ref.file = "/Users/yunpeng/Genetic_data/1000GenoRef.hdf5",
                          shlibi = "C_lib/snpprune_pre.so",
                          shlib1 = "C_lib/snpprune_pre1.so") {
    ### prune SNPs by pair-wise LD (r2)

    ##  default reference LD infomation is from Anders, r2 cutoff=0.2.
    ##  the SNPs are pre-aligned with SNPs of the LD information!!!
    ##  New generic LD reference file should be rebuild.
    #
    #   Input:
    #   logp:       vector of numeric values to be pruned
    #   threshold:  a numeric threshold for pruning
    #   row.idx:    a vector of int for the row index of LD CCS sparse mat
    #   col.idx:    a vector of int for the column index of LD CCS sparse mat
    #   ld.dat:     a vector of double for the LD r2 values of LD CCS sparse mat
    #   shape:      a vector of int for the original shape of LD CCS sparse mat
    #   ref.file:   path of the reference file to use.
    #   shlib:      path of share lib for  pruning
    #   shlib1:     path of share lib for  reffile-based pruning

    #   Return:
    #   A vector of bool indicating SNP that shuld be removed
    #
    #   Note:
    #   please use the reference hdf5 file otherwise rebuild one with the same
    #       structure, including group names as the original one
    result <- NULL
    if (length (logp) == 0) {
        cat ("Please provide data vector.\n");
        stop ("Invalide Arguments.\n");
    }
    if (is.null (row.idx) | is.null (col.idx) | is.null (ld.dat) |
                is.null (shape)) {
        if (refFile == "") {
            cat ("Please provide LD information.\n");
            stop ("Invalide Arguments.\n");
        }
        else {
            if (file.exists(ref.file)) {
                dyn.load(shlib1)
                result <- .Call ("SNP_prune_pre1", as.numeric (logp),
                        as.character (ref.file), as.numeric (threshold))
                dyn.unload (shlib1)
                return (result==1)
            }
            else {
                stop (sprintf ("Invalide Arguments: no such file %s.\n",
                              ref.file));
            }
        }
    }
    dyn.load (shlib)
    result <- .Call ("SNP_prune_pre", as.numeric (logp), as.integer (row.idx),
              as.integer (col.idx), as.numeric (ld.dat),
              as.integer (shape), as.numeric (threshold))
    dyn.unload (shlib)
    return (result==1)
}



pruneLdUnpre <- function(logp, snpid, refsnpid=NULL, threshold=0.0,
                        row.idx=NULL, col.idx=NULL, ld.dat=NULL, shape=NULL,
                        ref.file="/Users/yunpeng/Genetic_data/1000GenoRef.hdf5",
                        shlib1 = "C_lib/snpprune_unpre1.so",
                        shlib = "C_lib/snpprune_unpre.so"
                        ) {
    ### prune SNPs by pair-wise LD (r2)

    ##  default reference LD infomation is from Anders, r2 cutoff=0.2.
    ##  New generic LD reference file should be rebuild.
    #
    #   Input:
    #   logp:       vector of numeric values to be pruned
    #   threshold:  a numeric threshold for pruning
    #   row.idx:    a vector of int for the row index of LD CCS sparse mat
    #   col.idx:    a vector of int for the column index of LD CCS sparse mat
    #   ld.dat:     a vector of double for the LD r2 values of LD CCS sparse mat
    #   shape:      a vector of int for the original shape of LD CCS sparse mat
    #   ref.file:   name of the reference file to use.
    #   shlib:      path of share lib for  pruning
    #   shlib1:     path of share lib for reffile-based pruning

    #   Return:
    #   A vector of bool indicating SNP that shuld be removed.
    #
    #   Note:
    #   please use the reference hdf5 file otherwise rebuild one with the same
    #       structure, including same group names as the original one

    result <- NULL
    if (length (logp) == 0)
    {
        cat ("Please provide lgp10P vector.\n");
        stop ("Invalide Arguments.\n");
    }
    if (is.null (row.idx) | is.null (col.idx) | is.null (ld.dat) |
        is.null (shape) | is.null (refsnpid) )
    {
        if (ref.file == "" || ! file.exists (ref.file)) {
            cat ("Please provide LD information.\n");
            stop ("Invalide Arguments.\n");
        }
        else {
            if (! file.exists (shlib1) )
                stop ("miss shared library for unpreprocess data prune.\n");
            dyn.load(shlib1)
            result <- .Call ("SNP_prune_unpre1", as.numeric (logp),
                            as.character (snpid),
                            as.character (ref.file), as.numeric (threshold))
        }
        dyn.unload (shlib1)
        return (result == 1)
    }
    if (! file.exists (shlib) )
        stop ("miss shared library for preprocess data prune.\n");
    dyn.load (shlib)
    len <- length(refsnpid)
    result <- .Call ("SNP_prune_unpre", as.numeric (logp),
                as.character (snpid), as.integer (row.idx),
              as.integer (col.idx), as.character (refsnpid), as.integer (len),
              as.numeric (ld.dat), as.integer (shape),
              as.numeric (threshold))
    dyn.unload (shlib)
    return (result == 1)
}
