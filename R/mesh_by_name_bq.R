#' @title Screens Pubmed PMID numbers in terms of the names of Descriptors & Qualifiers
#'
#' @description It can provide all the PMIDS of publications with specific Descriptors
#' and Qualifiers. It is used for x > = 300 PMIDS
#'
#' @param x,Descriptor,Qualifier
#'
#' @return NULL
#'
#' @examples
#'
#' @export mesh_by_name_bq
mesh_by_name_bq<-function(x,d,q){

    bigqueryindex <-
        split(seq(1,length(x)), ceiling(seq_along(seq(1,length(x)))/100))


    extractedData <- c()

    for (i in bigqueryindex) {

        extractedData = c(extractedData,mesh_by_name(x[unlist(i)],d,q))
    }


    return(extractedData)
}
