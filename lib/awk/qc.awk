BEGIN{
    if ( maf_field == "" ) maf_field = 5;
    if ( maf_filter == "" ) maf_filter = 0.01;
    if ( info_field == "" ) info_field = 7;
    if ( info_filter == "" ) info_filter = 0.1;
} ( NR > header && NR == FNR && $( maf_field ) >= maf_filter && $( info_field ) >= info_filter ) {
    snplist[ NR ] = $1;
    next; \
} ( NR > FNR && FNR in snplist ) {
    print;
}

