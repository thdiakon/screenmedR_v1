#' @title Cleaning not relevant publications in terms of number of mesh terms.
#'
#'
#' @description It provides the PMID numbers of a set of publications x which have at least
#'  d descriptors and q qualifiers in common with a small default set y. Should be used for
#'  x > = 300 abstracts.
#'
#' @param x,y,d,q
#'
#' @return NULL
#'
#' @examples
#'
#' @export mesh_clean_bq

mesh_clean_bq<-function(x,y,d,q){

    bigqueryindex <-
        split(seq(1,length(x)), ceiling(seq_along(seq(1,length(x)))/100))


    extractedData <- c()

    for (i in bigqueryindex) {

        extractedData = c(extractedData,mesh_clean(x[unlist(i)],y,d,q))
    }
    uextracteddata<-unique(extractedData)

    return(uextracteddata)
}
