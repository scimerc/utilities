bioc.locinstall <- function ( mypackage ) {
  install.packages(
    mypackage,
    repos = c(
      "file://tsd/shared/R/cran",
      "file://tsd/shared/R/bioconductor",
      "file://tsd/shared/R/bioconductor/data/experiment",
      "file://tsd/shared/R/bioconductor/data/annotation"
    )
  )
}

cran.locinstall <- function ( mypackage ) {
   install.packages( mypackage, repos = "file://tsd/shared/R/cran" )
}

