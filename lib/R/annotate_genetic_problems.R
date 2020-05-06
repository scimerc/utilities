annotate.genetic.problems <- function( t_data, uid='X000UID', pihat=0.125 ) {
  cnames = c(
    uid,
    'SID',
    'FID',
    'IID',
    'MISMIX',
    'SNPSEX',
    'RELSHIP',
    'has_better_relative',
    'F_MISS',
    'SEX'
  )
  cnames_new = c(
    uid,
    'subjid',
    'genetics_fid',
    'genetics_iid',
    'genetics_mismix',
    'genetics_snpsex',
    'genetics_relship',
    'has_better_relative',
    'genetics_f_miss',
    'sex'
  )
  mynames = names( t_data )
  for ( k in 1:length(cnames) ) {
    if ( any( mynames == cnames[k] ) )
      mynames[ mynames == cnames[k] ] = cnames_new[k]
  }
  names( t_data ) = mynames
  t_data[, uid] = as.character( t_data[, uid] )
  t_data$genetics_mismix = as.character( t_data$genetics_mismix )
  t_data$genetics_relship = as.character( t_data$genetics_relship )
  tis_data = t_data[ order( t_data$genetics_f_miss, decreasing=F ), ]
  tis_data$genetics_alphasex = NA
  if ( !is.null( tis_data$genetics_snpsex ) && !is.null( tis_data$sex ) ) {
    tis_data$genetics_alphasex = ifelse(
      tis_data$genetics_snpsex == 1, 'male', ifelse(
        tis_data$genetics_snpsex == 2, 'female', NA
      )
    )
  } else {
    if ( is.null( tis_data$sex ) ) tis_data$sex = NA
  }
  cat( 'sex confusion matrix\n' )
  print( table( tis_data[, c('sex', 'genetics_alphasex')] ) )
  # find individuals with relatives genotyped with higher coverage
  tis_data$has_better_relative = FALSE
  ecnames_new = cnames_new[ cnames_new %in% names( tis_data ) ]
  # remove pihat values from the lists of related individuals
  tis_data$genetics_relship_clean = gsub( '[(][^,]+[)]', '', tis_data$genetics_relship )
  # extract pihat values from the lists of related individuals
  tis_data$genetics_relship_pihat = gsub( '[^,]+[(]|[)]', '', tis_data$genetics_relship )
  # run algorithm
  tis_data_r = as.data.frame( matrix(
    unlist( lapply( tis_data[, uid], function(x, td, cn) {
      tdr = data.frame( matrix( NA, ncol=length(cn), nrow=1 ) )
      names(tdr) = cn
      k = which( td[, uid] == x )
      tdr = td[ k, cn ]
      rellist = unlist( strsplit( td$genetics_relship_clean[k], ',' ) )
      relpihat = unlist( strsplit( td$genetics_relship_pihat[k], ',' ) )
      rellist = as.character( rellist[ !grepl( '^[^[:alnum:]]*NA[^[:alnum:]]*$', rellist ) ] )
      relpihat = as.numeric( relpihat[ !grepl( '^[^[:alnum:]]*NA[^[:alnum:]]*$', relpihat ) ] )
      rellist = rellist[ relpihat >= pihat ]
      relpihat = relpihat[ relpihat >= pihat ]
      if ( length( rellist ) > 0 && length( relpihat ) > 0 ) {
        # better coverage sample (all those preceding k, as td is sorted increasingly on f_miss)
        better.covered = 1:dim(td)[1] %in% 1:k & td$genetics_mismix == 'OK'
        tdr$genetics_relship = paste( sprintf( '%s(%.3f)', rellist, relpihat ), collapse=',' )
        tdr$has_better_relative = any( rellist %in% td[better.covered, uid] )
      }
      return( tdr )
    }, td=tis_data, cn=ecnames_new ) ),
    dimnames=list( NULL, ecnames_new ),
    nrow=dim(tis_data)[1],
    byrow=T
  ) )
  tsel_r = tis_data_r$genetics_mismix != 'OK' | tis_data_r$has_better_relative == 'TRUE'
  # find potential sex mislabelings
  tsel =
    !is.na( tis_data$sex ) &
    !is.na( tis_data$genetics_alphasex ) &
    tis_data$genetics_alphasex != tis_data$sex
  # combine filters
  tsel = tsel | tsel_r
  return( tis_data_r[ tsel, ] )
}

annotate.problems <- function( idlist, pihat=0.125 ) {
  # requires the "httr" library!
  if ("httr" %in% rownames(installed.packages())) {
    # define query parameters
    body <- list(NULL
      ,participants_project = "1"
      ,participants_sex = "1"
      ,genetics_batch = "1"
      ,genetics_uid = "1"
      ,genetics_f_miss = "1"
      ,genetics_mismix = "1"
      ,genetics_relship = "1"
      ,genetics_snpsex = "1"
      ,include_genetics = "1"
      ,options_format = "tsv"
      ,options_join = "intersect"
    )
    # authenticate and download
    rx <- httr::GET( "http://p33-rhel7-hpc:8088/login",query=list(userid=Sys.info()[["user"]]))
    rx <- httr::POST("http://p33-rhel7-hpc:8088/dbres",body=body)
    # convert to table
    con <- textConnection(httr::content(rx, "text"))
    t_data <- read.table(con, header=T, sep="\t", na.strings="None")
    write("your data is available in \"t_data\"", "")
    close(con)
  } else {
    write("please install the \"httr\" library", "")
    return( NULL )
  }
  idlist = as.character( idlist )
  t_data$subjid = as.character( t_data$subjid )
  ti_data = t_data[ t_data$subjid %in% idlist, ]
  return( annotate.genetic.problems( ti_data, uid='genetics_uid', pihat ) )
}

