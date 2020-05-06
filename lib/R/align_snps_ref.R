AlignSNPWithRef <- function (dat, snpid, refsnpid,
                    shlib = "C_lib/snp_align_ref.so") {
    ## Align the values of a list of SNPs with a list of reference SNPs
    #
    #   return a list of values with the number equal to the number of reference SNPs
    #
    #   Input:
    #   dat:        vector of double, logp or zval, etc
    #   snpid:      vector of SNPs IDs
    #   refsnpid:   vector SNPs IDs
    #
    #   Return:
    #   a list of values with the number equal to the number of reference SNPs.
    #
    #   Note:
    #   if number of snpid < number refsnpid, missing SNPs filled with NaN values
    #   if number of snpid > number refsnpid, extra values removed
    #
    if (!file.exists (shlib))
        stop ("miss shared library.\n")
    nref <- length (refsnpid)
    dyn.load (shlib)
    result <- .Call ("SNP_align_with_ref", as.numeric (dat),
                     as.character (snpid), as.character (refsnpid),
                     as.integer (nref))
    dyn.unload (shlib)
    return (result)
}
