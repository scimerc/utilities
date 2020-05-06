## myEAtests.R - version 0.31 (february 2014)
## a package of functions to perform enrichment analysis.

source( "/home/checco/lib/R/gc.R" )
source( "/home/checco/lib/R/figure.colors.R" )

qlabel <- "quantile"
get_qlabel <- function () { return( qlabel ) }
set_qlabel <- function ( myqlabel ) { qlabel <- myqlabel }

# compute FDRs
# parameters:
# - data.file: root name for various output files
# - mydata: data array with the stuff of interest
# - pheno: name of the phenotype to be looked at (mydata's p-value column)
# - annot_name: name of the annotation to use for stratification (also one of mydata's column names)
# - my.breaks: annotation intervals breaking points
# - numof.breaks: number of annotation intervals
# - filter.name: data.file field to use as filter
# - fdr.level: FDR significance level
# returns a table with values for each quantile and quantile-cumulative
compute_fdr <- function (
	data.file="",
	mydata=NULL,
	pheno="P_value",
	annot_name="",
	my.breaks="auto",
	numof.breaks=4,
	figure.colors=NULL,
	filter.name="",
	fdr.level=0.01,
	draw_plots=FALSE
) {

	if ( is.null( attr( compute_fdr, "function_calls" ) ) ) attr( compute_fdr, "function_calls" ) <<- 0
	attr( compute_fdr, "function_calls" ) <<- attr( compute_fdr, "function_calls" ) + 1

    if ( !is.null( mydata ) && annot_name != "" ) {

        ###############  set genome-wide significance level  ################
        cat( "p-value genome-wide significance level is set to: " )
        gws.level <- max( 5.E-8, fdr.level / sum( !is.na( mydata[, pheno ] ) ) )
        cat( gws.level, "\n" )
        #####################################################################

        filename.spec <- paste( pheno, annot_name, "FDR", sep = "_" )

        if ( filter.name != "" ) {
			mydata <- mydata[ mydata[, filter.name ] == TRUE, ]
			filter.str <- paste( "replica", attr( compute_fdr, "function_calls" ), sep = "_" )
			filename.spec <- paste( filename.spec, filter.str, sep = "_" )
		}
        mydata <- mydata[ !is.na( mydata[, pheno ] ), ] # just SNPs that have a p-value *and* annotation
        mydata <- mydata[ order( mydata[, pheno ] ), ]  # sort the data according to the p-values
		my.plot.filename <- paste( data.file, filename.spec, "plot.pdf", sep = "_" )
		my.data.filename <- paste( data.file, filename.spec, "data.txt", sep = "_" )

        annot_name_q <- paste( annot_name, "quant", sep = "_" )  # quantile column name
        mydata[, annot_name_q ] <- factorize_annotation( mydata[, annot_name ], my.breaks, numof.breaks )
        annot_levels <- levels( as.factor( mydata[, annot_name_q ] ) )  # extract quantile intervals

        my.colors <- array( dim = length( annot_levels ) )
        for ( k in 1 : length( annot_levels ) )
            my.colors[ k ] <-  my.color.function( k, length( annot_levels ), figure.colors )

        ##################################################  return table  ##################################################
        my.summary.fdr <- matrix( nrow = 2 * length( annot_levels ) + 2, ncol = 6 )
        colnames( my.summary.fdr ) <- c( "[=]", "[=]*", "[<]", "[<]*", "[>]", "[>]*" )
        rownames( my.summary.fdr ) <- c(
			paste( rep( c( "FDR", "GWS" ), each = length( annot_levels ) ), get_qlabel(), 1 : length( annot_levels ), sep = "_" ),
			c( "FDR_all", "GWS_all" )
		)
        ####################################################################################################################

        ###################  number of p-values below gws.level in the complete set  ###################
        my.summary.fdr[ "GWS_all", ] <- c( sum( mydata[, pheno ] < gws.level ), NA, NA, NA, NA, NA )
        ################################################################################################

        #####################  number of FDR below fdr.level in the complete set  ######################
        # NOTE: this does not exactly p/q, but a running cumulative minimum of p/q (see ?p.adjust)
        temp.fdr <- p.adjust( mydata[, pheno ], method = "fdr" )
        my.summary.fdr[ "FDR_all", ] <- c(
			sum( temp.fdr < fdr.level ),
			sum( temp.fdr < fdr.level & mydata[, pheno ] >= gws.level ),
			NA, NA, NA, NA
		)
        my.table <- mydata[, c( "MarkerName", pheno ) ]
        my.table$all <- temp.fdr  # store FDR
        if ( draw_plots ) {
			pdf( filename = my.plot.filename )
			my.key <- c( 16 )
			my.key.color <- c( "#777777" )
			my.key.text <- c( "all SNPs" )
			plot.filter <- runif( length( mydata[, pheno ] ) ) > 1000 / length( mydata[, pheno ] )
			plot(
				-log10( mydata[ plot.filter, pheno ] ),
				temp.fdr[ plot.filter ],
				col = "#777777",
				pch = 16,
				xlab = "-Log10(p)",
				ylab = "FDR",
				xlim = c(0,12),
                type = "b"
			)
		}
        ################################################################################################

        for ( k in 1 : length( annot_levels ) ) {

            annot_level_name <- paste( get_qlabel(), k, sep = "_" )
            cat( " ", get_qlabel(), k, "[", annot_name_q, "]..\n" )

            ##############################################################################
            ###################  compute FDR in the current quantile  ####################
            temp.strat.fdr <- array( dim = length( mydata$MarkerName ) )
            logtemp_k <- mydata[, annot_name_q ] == annot_levels[ k ]  # logical vector to extract current SNPs
            cat( "   ", sum( logtemp_k, na.rm=T ) , " [", sum( is.na( logtemp_k ) ), " dropped because NA] SNPs in quantile..\n", sep="" )
            logtemp_k[ is.na( logtemp_k ) ] <- FALSE
			temp.strat.fdr[ logtemp_k ] <- p.adjust( mydata[ logtemp_k, pheno ], method = "fdr" )  # compute FDR (see NOTE above)
            my.table[, paste( "FDR", annot_level_name, sep = "_" ) ] <- temp.strat.fdr  # store FDR
            if ( draw_plots ) {
				my.key <- append( my.key, 16 )
				my.key.color <- append( my.key.color, my.colors[ k ] )
				my.key.text <- append( my.key.text, annot_level_name )
				points(
					-log10( mydata[ logtemp_k & plot.filter, pheno ] ),
					temp.strat.fdr[ logtemp_k & plot.filter ],
					col = my.colors[ k ],
					pch = 16,
					type = "b"
				)
			}
            ################  number of FDR below fdr.level in the current quantile  #################
            fdrlogtemp <- temp.strat.fdr[ logtemp_k ] < fdr.level
            gwslogtemp <- mydata[ logtemp_k, pheno ] < fdr.level / sum( logtemp_k )
			my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[=]" ] <- sum( fdrlogtemp, na.rm = T )
			my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[=]" ] <- sum( gwslogtemp, na.rm = T )
            ##########  number of FDR below fdr.level in the current quantile *and not* genome-wide significant  ###########
            temp.count <- sum( fdrlogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
            my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[=]*" ] <- temp.count
            temp.count <- sum( gwslogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
            my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[=]*" ] <- temp.count
            ############################################################################
            ############################################################################

            if ( k > 2 ) {

				############################################################################
				#################  compute FDR below the current quantile  #################
				temp.strat.fdr <- array( dim = length( mydata$MarkerName ) )
				logtemp_k <- as.numeric( mydata[, annot_name_q ] ) < k  # logical vector to extract current SNPs
				logtemp_k[ is.na( logtemp_k ) ] <- FALSE
				temp.strat.fdr[ logtemp_k ] <- p.adjust( mydata[ logtemp_k, pheno ], method = "fdr" )  # compute FDR (see NOTE above)
				my.table[, paste( "lt", annot_level_name, sep = "_" ) ] <- temp.strat.fdr  # store FDR
				if ( draw_plots && k > 2 ) {
					my.key <- append( my.key, 25 )
					my.key.color <- append( my.key.color, my.colors[ k ] )
					my.key.text <- append( my.key.text, paste( "[<]", annot_level_name ) )
					points(
						-log10( mydata[ logtemp_k & plot.filter, pheno ] ),
						temp.strat.fdr[ logtemp_k & plot.filter ],
						col = my.colors[ k ],
						pch = 25,
						type = "b"
					)
				}
				##################  number of FDR below fdr.level below the current quantile  ###################
				fdrlogtemp <- temp.strat.fdr[ logtemp_k ] < fdr.level
				gwslogtemp <- mydata[ logtemp_k, pheno ] < fdr.level / sum( logtemp_k )
				my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[<]" ] <- ifelse( k == 1, NA, sum( fdrlogtemp, na.rm = T ) )
				my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[<]" ] <- ifelse( k == 1, NA, sum( gwslogtemp, na.rm = T ) )
				###########  number of FDR below fdr.level below the current quantile *and not* genome-wide significant  ############
				temp.count <- sum( fdrlogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
				my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[<]*" ] <- ifelse( k == 1, NA, temp.count )
				temp.count <- sum( gwslogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
				my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[<]*" ] <- ifelse( k == 1, NA, temp.count )
				############################################################################
				############################################################################

			}

			if ( k < length( annot_levels ) - 1 ) {

				############################################################################
				#################  compute FDR above the current quantile  #################
				temp.strat.fdr <- array( dim = length( mydata$MarkerName ) )
				logtemp_k <- as.numeric( mydata[, annot_name_q ] ) > k  # logical vector to extract current SNPs
				logtemp_k[ is.na( logtemp_k ) ] <- FALSE
				temp.strat.fdr[ logtemp_k ] <- p.adjust( mydata[ logtemp_k, pheno ], method = "fdr" )  # compute FDR (see NOTE above)
				my.table[, paste( "gt", annot_level_name, sep = "_" ) ] <- temp.strat.fdr  # store FDR
				if ( draw_plots && k < length( annot_levels ) - 1 ) {
					my.key <- append( my.key, 24 )
					my.key.color <- append( my.key.color, my.colors[ k ] )
					my.key.text <- append( my.key.text, paste( "[>]", annot_level_name ) )
					points(
						-log10( mydata[ logtemp_k & plot.filter, pheno ] ),
						temp.strat.fdr[ logtemp_k & plot.filter ],
						col = my.colors[ k ],
						pch = 24,
						type = "b"
					)
				}
				##################  number of FDR below fdr.level above the current quantile  ###################
				fdrlogtemp <- temp.strat.fdr[ logtemp_k ] < fdr.level
				gwslogtemp <- mydata[ logtemp_k, pheno ] < fdr.level / sum( logtemp_k )
				my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[>]" ] <- ifelse( k == length( annot_levels ), NA, sum( fdrlogtemp, na.rm = T ) )
				my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[>]" ] <- ifelse( k == length( annot_levels ), NA, sum( gwslogtemp, na.rm = T ) )
				###########  number of FDR below fdr.level above the current quantile *and not* genome-wide significant  ############
				temp.count <- sum( fdrlogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
				my.summary.fdr[ paste( "FDR", annot_level_name, sep = "_" ), "[>]*" ] <- ifelse( k == length( annot_levels ), NA, temp.count )
				temp.count <- sum( gwslogtemp & mydata[ logtemp_k, pheno ] >= gws.level, na.rm = T )
				my.summary.fdr[ paste( "GWS", annot_level_name, sep = "_" ), "[>]*" ] <- ifelse( k == length( annot_levels ), NA, temp.count )
				############################################################################
				############################################################################

			}

        }

        if ( draw_plots ) {

			legend( "topright", my.key.text, col = my.key.color, pch = my.key )
			dev.off()

		}

		write.table( my.table, file = my.data.filename, quote = F, row.names = F )

        return( my.summary.fdr )

    }

}


# draw stratified QQ-plots
# parameters:
# - mydata: data array with the stuff of interest
# - pheno: name of the phenotype to be looked at(mydata's p-value column)
# - annot_name: name of the annotation to use for stratification(also one of mydata's column names)
# - my.breaks: annotation intervals breaking points
# - numof.breaks: number of annotation intervals
# - filter.name: data.file field to use as filter
# - P_prct: percentile of Top SNPs to be highlighted in the plots
# returns a table with qq-plot data for all quantiles
draw_qq_plots <- function (
	mydata=NULL,
	pheno="P_value",
	annot_name="",
	my.breaks="auto",
	numof.breaks=4,
	ci=FALSE,
	figure.colors=NULL,
	filter.name="",
	P_prct=0.01,
	verbose=F
) {

	plottype = "l"
	my.devices <- dev.list()
	N.devices <- length( my.devices )
	if ( N.devices <= 1 ) par( ask = TRUE )
	i <- 0

    library( Hmisc, quietly = T, warn.conflicts = F )

    if ( !is.null( mydata ) && annot_name != "" ) {

		neglog10_P_threshold <- 24  # set minimum p-value for the plots
		tiny <- 1.E-72

        ###############  set genome-wide significance level  ################
        cat( "p-value genome-wide significance level is set to: " )
        gws.level <- max( 5.E-8, 0.05 / sum( !is.na( mydata[, pheno ] ) ) )
        cat( gws.level, "\n" )
        #####################################################################

        if( verbose ) cat( "setting temporary data storage tables..\n" )
        if ( filter.name != "" ) mydata <- mydata[ mydata[, filter.name ] == TRUE, ]
        mydata <- mydata[ !is.na( mydata[, pheno ] ), ]  # just take SNPs that have a p-value
        mydata <- mydata[ order( mydata[, pheno ] ), ]  # sort SNPs according to their p-value
		return.table <- data.frame( MarkerName = mydata$MarkerName )

        ################### draw master plot ####################
        neglog10_P_all <- -log10( mydata[, pheno ] )

        if ( verbose ) {
			print( "draw_qq_plots() neglog10_P_all:" )
			print( summary( neglog10_P_all ) )
		}

		n_all = length( neglog10_P_all )
		histobreaks = seq(
			min( 0, floor( min( neglog10_P_all, na.rm=TRUE ) ) ),
			ceiling( max( neglog10_P_all, na.rm=TRUE ) ),
			length.out = 1000
		)
		histotemp_all <- hist( neglog10_P_all, breaks = histobreaks, plot = FALSE )
		cdftemp_all <- cumsum( histotemp_all$counts )
		datafilter <- histotemp_all$mids < -log10( gws.level ) | histotemp_all$counts > 1
		datapoints <- histotemp_all$mids[ datafilter ]
		binconftemp_all <- binconf( cdftemp_all, n_all, method = 'exact' )
		binconftemp_all <- binconftemp_all[ datafilter, ]

        cat( "plotting masters..\n" )
		if ( N.devices > 1 ) {
			dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
			i = i + 1
		}
		qqplot(
            -log10( 1 - binconftemp_all[, 1 ] ), datapoints, type = plottype, lwd = 2, pch = 16, cex = 0.5, col = "#777777",
			xlab = "Empirical -log10(p)", ylab = "Nominal -log10(p)", xlim = c( 0, 6 ), ylim = c( 0, 8 )
        )
        if ( ci ) {
			points( -log10( 1 - binconftemp_all[, 2 ] ), datapoints, type = plottype, lty = 2 )
			points( -log10( 1 - binconftemp_all[, 3 ] ), datapoints, type = plottype, lty = 2 )
		}
		if ( N.devices > 1 ) {
			dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
			i = i + 1
		}
        plot(
            datapoints, rep( 1, length( datapoints ) ),
            type = plottype, lty = 2, lwd = 1.5, pch = 16, cex = 0.5, col = "#777777",
			xlab = "Nominal -log10(p)", ylab = "Fold enrichment", xlim = c( 0, 8 )
        )
        return.table[, "All" ] <- mydata[, pheno ]

        #########################################################

        ################### draw strata plot ####################
        i = 0
        cat( "plotting additional points..\n" )
        annot_name_q <- paste( annot_name, "quant", sep = "_" )  # quantile column name
        mydata[, annot_name_q ] <- factorize_annotation( mydata[, annot_name ], my.breaks, numof.breaks )
        annot_levels <- levels( as.factor( mydata[, annot_name_q ] ) )  # extract quantile intervals
        my.colors <- array( dim = length( annot_levels ) )
        for ( k in 1 : length( annot_levels ) )
            my.colors[ k ] <-  my.color.function( k, length( annot_levels ), figure.colors )
        for ( k in 1 : length( annot_levels ) ) {
            cat( "plotting ", get_qlabel(), k, " [", annot_name_q, "] -- color=", my.colors[ k ], "..\n", sep="" )
            return.table[, paste( get_qlabel(), k, sep = "_" ) ] <- ifelse(
			  mydata[, annot_name_q ] == annot_levels[ k ],
			  mydata[, pheno ], NA
			)
            neglog10_P <- -log10( mydata[ mydata[, annot_name_q ] == annot_levels[ k ], pheno ] )
            neglog10_P <- neglog10_P[ !is.na( neglog10_P ) ]
            n = length( neglog10_P )
			histotemp <- hist( neglog10_P, breaks = histobreaks, plot = FALSE )
			cdftemp <- cumsum( histotemp$counts )
			binconftemp <- binconf( cdftemp, n, method = 'exact' )
			binconftemp <- binconftemp[ datafilter, ]
            if (
				length( -log10( 1 - binconftemp[, 1 ] ) ) > 0 && length( datapoints ) > 0
				&& length( -log10( 1 - binconftemp[, 1 ] ) ) == length( datapoints )
			) {
				if ( N.devices > 1 ) {
					dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
					i = i + 1
				}
				points(
					-log10( 1 - binconftemp[, 1 ] ), datapoints,
					type = plottype, lwd = 2, col = my.colors[ k ], pch = 16
				)
				if ( ci ) {
					points(
						-log10( 1 - binconftemp[, 2 ] ), datapoints,
						type = plottype, col = my.colors[ k ], lty = 2
					)
					points(
						-log10( 1 - binconftemp[, 3 ] ), datapoints,
						type = plottype, col = my.colors[ k ], lty = 2
					)
				}
				if ( N.devices > 1 ) {
					dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
					i = i + 1
				}
				foldtemp <- ( 1 - binconftemp[, 1 ] ) / ( 1 - binconftemp_all[, 1 ] + tiny )
				points(
					datapoints, foldtemp,
					type = plottype, lwd = 2, col = my.colors[ k ], pch = 16
				)
				if ( ci ) {
					foldtemp_2 <- ( 1 - binconftemp[, 2 ] ) / ( 1 - binconftemp_all[, 2 ] + tiny )
					foldtemp_3 <- ( 1 - binconftemp[, 3 ] ) / ( 1 - binconftemp_all[, 3 ] + tiny )
	# 				foldtemp_2 <-
	# 					foldtemp * ( 1 + exp( 10 ) * (
	# 						log10( ( 1 - binconftemp_all[, 1 ] + tiny ) * ( 1 - binconftemp[, 2 ] ) + tiny ) -
	# 						log10( ( 1 - binconftemp_all[, 2 ] + tiny ) * ( 1 - binconftemp[, 1 ] ) + tiny )
	# 					) )
	# 				foldtemp_3 <-
	# 					foldtemp * ( 1 + exp( 10 ) * (
	# 						log10( ( 1 - binconftemp_all[, 1 ] + tiny ) * ( 1 - binconftemp[, 3 ] ) + tiny ) -
	# 						log10( ( 1 - binconftemp_all[, 3 ] + tiny ) * ( 1 - binconftemp[, 1 ] ) + tiny )
	# 					) )
					points(
						datapoints, foldtemp_2,
						type = plottype, col = my.colors[ k ], lty = 2
					)
					points(
						datapoints, foldtemp_3,
						type = plottype, col = my.colors[ k ], lty = 2
					)
				}
			} else
				cat( "warning: degenerate", get_qlabel(), k, "\n" )
        }

        ###################################### write legend #######################################
        cat( "writing legends..\n" )
        if ( N.devices > 1 ) {
			dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
			i = i + 1
		}
		abline(a = 0, b = 1, col = 'lightgray', lwd = 2, lty = 2)  # null line
		abline(a = -log10(gws.level), b = 0, col = 'lightblue', lwd = 2, lty = 3)  # GWS line
        legend(
            "topleft", c(
                'all SNPs', levels( as.factor( mydata[, annot_name_q ] ) )
            ),
            col = c(
                '#777777', my.colors[ 1 : length( levels( as.factor( mydata[, annot_name_q ] ) ) ) ]
            ),
#             pch = c(
#                 rep( 16, length( levels( as.factor( mydata[, annot_name_q ] ) ) ) + 1 )
#             ),
            lwd = c(
                rep( 2, length( levels( as.factor( mydata[, annot_name_q ] ) ) ) + 1 )
            )
        )
        legend(
            "bottomright", c( 'Expected under null', paste( 'p = ', format( gws.level ) ) ),
            lty = c( 2, 3 ), col = c( 'lightgray', 'lightblue' ), lwd = 2
        )
        if ( N.devices > 1 ) {
			dev.set( my.devices[ i %% length( my.devices ) + 1 ] )
			i = i + 1
		}
        legend(
            "topleft", c(
                'all SNPs', levels( as.factor( mydata[, annot_name_q ] ) )
            ),
            col = c(
                '#777777', my.colors[ 1 : length( levels( as.factor( mydata[, annot_name_q ] ) ) ) ]
            ),
#             pch = c(
#                 rep( 16, length( levels( as.factor( mydata[, annot_name_q ] ) ) ) + 1 )
#             ),
            lwd = c(
                rep( 2, length( levels( as.factor( mydata[, annot_name_q ] ) ) ) + 1 )
            )
        )
        ###########################################################################################

        return( return.table )

    } else {

		return( NULL )

	}

}


# estimate enrichment
# parameters:
# - mydata: data array with the stuff of interest
# - pheno: name of the phenotype to be looked at (mydata's p-value column)
# - annot_names: covariate annotation names to control for
# - annot_name: name of the annotation to use for stratification (also one of mydata's column names)
# - my.breaks: annotation intervals breaking points
# - numof.breaks: number of annotation intervals
# - filter.name: data.file field to use as filter
# returns a table with values for each quantile and quantile-cumulative
estimate_enrichment <- function (
	mydata=NULL,
	pheno="P_value",
	annot_names=NULL,
	annot_name="",
	my.breaks="auto",
	numof.breaks=4,
	filter.name=""
) {

	library( lmtest, quietly = T, warn.conflicts = F )

    if ( !is.null( mydata ) && annot_name != "" ) {

        if ( filter.name != "" ) mydata <- mydata[ mydata[, filter.name ] == TRUE, ]

        cat( "removing NAs..\n" )
        mydata <- mydata[ !is.na( mydata[, pheno ] ) & !is.na( mydata[, annot_name ] ), ]  # just take SNPs that have p-value *and* annotation

        annot_name_q <- paste( annot_name, "quant", sep = "_" )  # quantile column name
        mydata[, annot_name_q ] <- factorize_annotation( mydata[, annot_name ], my.breaks, numof.breaks )
        cat( "computing annotation factor levels..\n" )
        annot_levels <- levels( as.factor( mydata[, annot_name_q ] ) )  # extract quantile intervals

        ############################# return tables #############################
		reg_annot_names <- c()
        cat( "removing uninformative covariates..\n" )
		for ( tmp_annot_name in annot_names )
			if ( any( !is.na( mydata[, tmp_annot_name ] ) ) )
				reg_annot_names <- c( reg_annot_names, tmp_annot_name )
        N.testq <- 7 * length( reg_annot_names ) + 5
        my.enrichment <- matrix(
			NA,
            nrow = length( annot_levels ) + 1,
            ncol = 3 * N.testq
        )
        regression.entries <- paste0( rep( c( "intercept", reg_annot_names ), each = 5 ), c( "", "(se)", "(p)", "(ci_a)", "(ci_b)" ) )
        if ( length( reg_annot_names ) > 1 )
			regression.entries <- c( regression.entries, paste0( rep( reg_annot_names[ reg_annot_names != annot_name ], each = 2 ), c( "(pLR+)", "(pLR-)" ) ) )
		table.entries = paste0( rep( "[=]", 7 * length( reg_annot_names ) + 3 ), regression.entries )
        print( "list of table entries:" )
        print( table.entries )
		results.colnames <- paste0( rep( c( "[=]", "[<]", "[>]" ), each = N.testq ), c( "", "(pT)", regression.entries ) )
        colnames( my.enrichment ) <- results.colnames
        results.rownames <- c( paste( get_qlabel(), 1 : length( annot_levels ), sep = "_" ), "all" )
        rownames( my.enrichment ) <- results.rownames
        #########################################################################

        ###################################### enrichment in the complete set ######################################
        cat( "enrichment in the complete set:\n" )
        tempz <- qnorm( .5 * mydata[, pheno ] ) * ( rbinom( length( mydata[, pheno ] ), 1, .5 ) - .5 ) * 2
        my.enrichment[ "all", "[=]" ] <- mean( tempz^2 ) - 1
        if( length( reg_annot_names > 0 ) && length( tempz ) > 10 * length( reg_annot_names ) ) {
			regression.coeff <- regress_enrichment( tempz, mydata, annot_name, reg_annot_names )
			my.enrichment[ "all", table.entries ] <- regression.coeff
		} else cat( "insufficient data (", length( tempz ), ")\n", sep = "" )
        ############################################################################################################

        for ( k in 1 : length( annot_levels ) ) {

            annot_level_name <- paste( get_qlabel(), k, sep = "_" )
            cat( " ", get_qlabel(), k, "[", annot_name_q, "]..\n" )

            ################### compute enrichment in the current quantile ####################
            cat( "enrichment at level ", k, ":\n" )
            logtemp_k <- mydata[, annot_name_q ] == annot_levels[ k ]  # logical vector to extract current SNPs
            my.enrichment[ annot_level_name, "[=]" ] <- mean( tempz[ logtemp_k ]^2 ) - 1
            zT <- t.test( tempz[ logtemp_k ], tempz )
            my.enrichment[ annot_level_name, "[=](pT)" ] <- zT$p.value
            reg_annot_names <- c()
			for ( tmp_annot_name in annot_names )
				if ( any( !is.na( mydata[ logtemp_k, tmp_annot_name ] ) ) )
					reg_annot_names <- c( reg_annot_names, tmp_annot_name )
			regression.entries <- paste0( rep( c( "intercept", reg_annot_names ), each = 5 ), c( "", "(se)", "(p)", "(ci_a)", "(ci_b)" ) )
			if ( length( reg_annot_names ) > 1 )
				regression.entries <- c( regression.entries, paste0( rep( reg_annot_names[ reg_annot_names != annot_name ], each = 2 ), c( "(pLR+)", "(pLR-)" ) ) )
			table.entries = paste0( rep( "[=]", 7 * length( reg_annot_names ) + 1 ), regression.entries )
            if( length( reg_annot_names > 0 ) && length( tempz ) > 10 * length( reg_annot_names ) ) {
				regression.coeff <- regress_enrichment( tempz[ logtemp_k ], mydata[ logtemp_k, ], annot_name, reg_annot_names )
				my.enrichment[ annot_level_name, table.entries ] <- regression.coeff
			} else cat( "insufficient data (", sum( logtemp_k ), ")\n", sep = "" )
            ###################################################################################

            ################### compute enrichment below the current quantile ####################
            if ( k > 2 ) {
				cat( "enrichment below level ", k, ":\n" )
				logtemp_k <- as.numeric( mydata[, annot_name_q ] ) < k  # logical vector to extract current SNPs
				my.enrichment[ annot_level_name, "[<]" ] <- mean( tempz[ logtemp_k ]^2 ) - 1
				zT <- t.test( tempz[ logtemp_k ], tempz )
				my.enrichment[ annot_level_name, "[<](pT)" ] <- zT$p.value
				reg_annot_names <- c()
				for ( tmp_annot_name in annot_names )
					if ( any( !is.na( mydata[ logtemp_k, tmp_annot_name ] ) ) )
						reg_annot_names <- c( reg_annot_names, tmp_annot_name )
				regression.entries <- paste0( rep( c( "intercept", reg_annot_names ), each = 5 ), c( "", "(se)", "(p)", "(ci_a)", "(ci_b)" ) )
				if ( length( reg_annot_names ) > 1 )
					regression.entries <- c( regression.entries, paste0( rep( reg_annot_names[ reg_annot_names != annot_name ], each = 2 ), c( "(pLR+)", "(pLR-)" ) ) )
				table.entries = paste0( rep( "[<]", 7 * length( reg_annot_names ) + 1 ), regression.entries )
				if( length( reg_annot_names > 0 ) && length( tempz ) > 10 * length( reg_annot_names ) ) {
					regression.coeff <- regress_enrichment( tempz[ logtemp_k ], mydata[ logtemp_k, ], annot_name, reg_annot_names )
					my.enrichment[ annot_level_name, table.entries ] <- regression.coeff
				} else cat( "insufficient data (", sum( logtemp_k ), ")\n", sep = "" )
			}
            ######################################################################################

            ################### compute enrichment above the current quantile ####################
            if ( k < length( annot_levels ) - 1 ) {
				cat( "enrichment above level ", k, ":\n" )
				logtemp_k <- as.numeric( mydata[, annot_name_q ] ) > k  # logical vector to extract current SNPs
				my.enrichment[ annot_level_name, "[>]" ] <- mean( tempz[ logtemp_k ]^2 ) - 1
				zT <- t.test( tempz[ logtemp_k ], tempz )
				my.enrichment[ annot_level_name, "[>](pT)" ] <- zT$p.value
				reg_annot_names <- c()
				for ( tmp_annot_name in annot_names )
					if ( any( !is.na( mydata[ logtemp_k, tmp_annot_name ] ) ) )
						reg_annot_names <- c( reg_annot_names, tmp_annot_name )
				regression.entries <- paste0( rep( c( "intercept", reg_annot_names ), each = 5 ), c( "", "(se)", "(p)", "(ci_a)", "(ci_b)" ) )
				if ( length( reg_annot_names ) > 1 )
					regression.entries <- c( regression.entries, paste0( rep( reg_annot_names[ reg_annot_names != annot_name ], each = 2 ), c( "(pLR+)", "(pLR-)" ) ) )
				table.entries = paste0( rep( "[>]", 7 * length( reg_annot_names ) + 1 ), regression.entries )
				if( length( reg_annot_names > 0 ) && length( tempz ) > 10 * length( reg_annot_names ) ) {
					regression.coeff <- regress_enrichment( tempz[ logtemp_k ], mydata[ logtemp_k, ], annot_name, reg_annot_names )
					my.enrichment[ annot_level_name, table.entries ] <- regression.coeff
				} else cat( "insufficient data (", sum( logtemp_k ), ")\n", sep = "" )
			}
            ######################################################################################

        }

        return( my.enrichment )

    }

    return( NULL )

}


# stratify annotation and compute ensuing annotation factors
# - annotation: annotation array
# - my.breaks: annotation intervals breaking points
# - numof.breaks: number of annotation intervals
# returns an array of annotation factors
factorize_annotation <- function ( annotation, my.breaks = "auto", numof.breaks = 4 ) {

	cat( "factorizing annotation..\n", sep = "" )

	if ( my.breaks != "auto" ) {

		if ( my.breaks == "std" ) {
			my.qdata <- annotation
			my.current.breaks <- quantile( my.qdata, probs = seq( 0, 1, by = 1 / numof.breaks ), na.rm=T )
			cat( "using standard breaks: ", my.current.breaks, "\n" )
		} else if ( my.breaks == "unq" ) {
			my.qdata <- unique( annotation )
			my.current.breaks <- quantile( my.qdata, probs = seq( 0, 1, by = 1 / numof.breaks ), na.rm=T )
			cat( "using unique breaks: ", my.current.breaks, "\n" )
		} else {
			my.current.breaks <- sort( c(
				as.numeric( unlist( strsplit( as.character( my.breaks ), "," ) ) ),
				min( annotation, na.rm = T ), max( annotation, na.rm=T )
			) )
			cat( "using custom breaks: ", my.current.breaks, "\n" )
		}

		if ( length( my.current.breaks ) > length( unique( my.current.breaks ) ) ) {
			cat( "warning: non-unique breaking points collapsed.\n", sep = "" )
			my.current.breaks = sort( unique( my.current.breaks ) )
		}

		cat( "generating factors..\n" )
		annotation_quant <- cut( annotation, my.current.breaks, include.lowest=T )

		return( annotation_quant )

	} else {

		cat( "using auto breaks.\n" )
		return( annotation )

	}
}


# compute binomial proportion tests
# - mydata.org: data array with the stuff of interest
# - pheno: name of the phenotype to be looked at (mydata's p-value column)
# - annot_name: name of the annotation to use for stratification (also one of mydata's column names)
# - annot_name_ctrl: name of the annotation to use as control (also one of mydata's column names); defaults to everything
# - my.breaks: annotation intervals breaking points
# - numof.breaks: number of annotation intervals
# - P_prct: percentile of Top SNPs to be used in the tests
# - filter.names: data.file fields to use as filters
# - indices: set of indices for bootstraping permutations
# - reweighting: sample reweighting factors
# returns a table with p-values for each quantile and quantile-cumulative
perform_bpt <- function (
	mydata.org=NULL,
	pheno="P_value",
	annot_name="",
	annot_name_ctrl="",
	my.breaks="auto",
	numof.breaks=4,
	P_prct=0.01,
	filter.names="",
	indices=NULL,
	reweighting=NULL
) {

    if ( !is.null( mydata.org ) && annot_name != "" ) {

		do_cumulative = FALSE  # no cumulative intervals by default (e.g.: categorical annotations)

#         if ( !is.null( indices ) ) {
# 			if ( length( indices ) != length( mydata.org[, pheno ] ) )
# 				cat( "BPT subset ", length( indices ), "(", length( mydata.org[, pheno ] ), ")\n" )
# 			mydata.org[, pheno ] <- mydata.org[ indices, pheno ]
# 		}

        mydata.org <- mydata.org[ !is.na( mydata.org[, pheno ] ) & !is.na( mydata.org[, annot_name ] ), ]  # just take SNPs that have a p-value *and* annotation

        my.filter.list <- list()
        if ( any( filter.names == "" ) ) {
			my.filter <- rep( TRUE, length( mydata.org[, pheno ] ) )
			my.filter.list <- list( my.filter )
		} else {
			for ( filter.name in filter.names )
				my.filter.list[[ length( my.filter.list ) + 1 ]] <- mydata.org[, filter.name ] == TRUE
		}

        annot_name_q <- paste( annot_name, "quant", sep = "_" )  # quantile column name
        mydata.org[, annot_name_q ] <- factorize_annotation( mydata.org[, annot_name ], my.breaks, numof.breaks )
        annot_levels <- levels( as.factor( mydata.org[, annot_name_q ] ) )  # extract quantile intervals

        if ( any( mydata.org[, annot_name_q ] != mydata.org[, annot_name ] ) ) do_cumulative = TRUE

        P_thresh = quantile( mydata.org[, pheno ], P_prct )

        #################### return table ####################
        if( do_cumulative ) {
			BPT_test <- array( dim = c( 3, length( annot_levels ), length( my.filter.list ) ) )
			my.summary.bpt <- matrix( nrow = length( annot_levels ), ncol = 3 )
			colnames( my.summary.bpt ) <- c( "[=]", "[<]", "[>]" )
		} else {
			BPT_test <- array( dim = c( 1, length( annot_levels ), length( my.filter.list ) ) )
			my.summary.bpt <- matrix( nrow = length( annot_levels ), ncol = 1 )
			colnames( my.summary.bpt ) <- c( "[=]" )
		}
        rownames( my.summary.bpt ) <- annot_levels
#         rownames( my.summary.bpt ) <- c( paste( get_qlabel(), 1 : length( annot_levels ), sep = "_" ) )
        ######################################################

		filter.counter = 1

		for ( my.filter in my.filter.list ) {

			mydata <- mydata.org[ my.filter, ]

			if ( annot_name_ctrl != "" ) {
				myctrl <- mydata[ mydata[, annot_name_ctrl ] >= 1, ]
				BPT_ctrl <- sum( myctrl[, reweighting ], na.rm = T )
				BPT_ctrl_signif <- sum( ( myctrl[, pheno ] < P_thresh ) * myctrl[, reweighting ], na.rm = T )
				remove( myctrl )
			} else {
				BPT_ctrl <- sum( mydata[, reweighting ], na.rm = T )
				BPT_ctrl_signif <- sum( ( mydata[, pheno ] < P_thresh ) * mydata[, reweighting ], na.rm = T )
			}

			compute_test_statistic <- function ( mytemp ) {
				BPT_positive <- sum( mytemp[, reweighting ], na.rm = T )
				BPT_positive_signif <- sum( ( mytemp[, pheno ] < P_thresh ) * mytemp[, reweighting ], na.rm = T )
				n_a <- BPT_ctrl
				n_b <- BPT_positive
				f_a <- BPT_ctrl_signif / ( n_a + 0.01 )
				f_b <- BPT_positive_signif / ( n_b + 0.01 )
				f_ab <- ( f_a * n_a + f_b * n_b ) / ( n_a + n_b + 0.01 )
				return( ( f_a - f_b ) / sqrt( f_ab * ( 1 - f_ab ) * ( 1 / ( n_a + 0.01 ) + 1 / ( n_b + 0.01 ) ) ) )
			}

			for ( k in 1 : length( annot_levels ) ) {

				annot_level_name <- paste( get_qlabel(), k, sep = "_" )

				################### perform BPT for SNPs in the current quantile ####################
				logtemp_k <- mydata[, annot_name_q ] == annot_levels[ k ]  # logical vector to extract current SNPs
				BPT_test[ 1, k, filter.counter ] <- compute_test_statistic( mydata[ logtemp_k, ] )
				#####################################################################################

				if( do_cumulative ) {

					################### perform BPT for SNPs below the current quantile ####################
					if ( k > 2 ) {
						logtemp_k <- as.numeric( mydata[, annot_name_q ] ) < k  # logical vector to extract current SNPs
						BPT_test[ 2, k, filter.counter ] <- compute_test_statistic( mydata[ logtemp_k, ] )
					}
					########################################################################################

					################### perform BPT for SNPs above the current quantile ####################
					if ( k < length( annot_levels ) - 1 ) {
						logtemp_k <- as.numeric( mydata[, annot_name_q ] ) > k  # logical vector to extract current SNPs
						BPT_test[ 3, k, filter.counter ] <- compute_test_statistic( mydata[ logtemp_k, ] )
					}
					########################################################################################

				}

			}

			filter.counter = filter.counter + 1

		}

		for ( k in 1 : length( annot_levels ) ) {

			annot_level_name <- annot_levels[ k ]
# 			annot_level_name <- paste( get_qlabel(), k, sep = "_" )

			my.summary.bpt[ annot_level_name, "[=]" ] <- 2 * pnorm( median( abs( BPT_test[ 1, k, ] ) ), lower.tail = F )
			if( do_cumulative ) {
				my.summary.bpt[ annot_level_name, "[<]" ] <- 2 * pnorm( median( abs( BPT_test[ 2, k, ] ) ), lower.tail = F )
				my.summary.bpt[ annot_level_name, "[>]" ] <- 2 * pnorm( median( abs( BPT_test[ 3, k, ] ) ), lower.tail = F )
			}

		}

        return( my.summary.bpt )

    }

}


# regress enrichment estimate on covariates
# - z: Z-score to compute enrichment estimate (z^2) from
# - mydata: container data arrray including the covariates of interest
# - annot_name: name of the annotation to use for stratification (also one of mydata's column names)
# - cov_names: names of the covariates of interest
# returns regression coefficients and p-values
regress_enrichment <- function ( z, mydata, annot_name, cov_names, scaleX = FALSE, verbose = FALSE ) {

	zz <- z[ !is.na( z ) ]

# 	library( locfdr )
#
# 	zz.locfdr <- locfdr( zz, plot = FALSE )
# 	sigma0 <- zz.locfdr$fp0[ 5, 2 ]

	sigma0 <- sd( zz )

	tiny = 1.E-72

	if ( !is.na( sigma0 ) ) {

		z.adj = z / sigma0

		cat( "regressing on covariates: ", cov_names, "\n" )
		reg.coeff <- array( NA, dim = c( length( cov_names ) + 1, 3 ) )
		cov.array <- array( unlist( mydata[, cov_names ] ), dim = c( length( mydata$MarkerName ), length( cov_names ) ) )
		if( scaleX && is.numeric( cov.array ) ) cov.array <- scale( cov.array )
		colnames( cov.array ) <- cov_names

		ivar = log( z.adj^2 + tiny )

		if( sum( !is.na( ivar ) ) > 0 ) {

			formula.text <- paste0( "ivar~", paste0( "cov.array[,\"", cov_names, "\"]", collapse = "+" ) )
			cat( "enrichment regression: ", formula.text, "\n" )
			ivar.lm = lm( as.formula( formula.text ) )
			pLRs <- c()
			cat( "performing likelihood ratio tests..\n" )
			for( cov_name in cov_names[ cov_names != annot_name ] ) {
				formula.text <- paste0( "ivar~cov.array[,\"", annot_name, "\"]+cov.array[,\"", cov_name, "\"]" )
				ivar.single.cov.lm = lm( as.formula( formula.text ) )
				LRT <- drop1( ivar.single.cov.lm, test="Chisq" )
				pLRs <- c( pLRs, LRT$'Pr(>Chi)'[ -1 ] )
			}
			reg.coeff[ !is.na( ivar.lm$coefficients ), ] <- summary( ivar.lm )$coefficients[, c( 1, 2, 4 ) ]
			return( c( t( cbind( reg.coeff, confint( ivar.lm ) ) ), pLRs ) )

		} else return( NA )

	} else return( NA )

}
