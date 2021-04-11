#' @title Screens Pubmed PMID numbers in terms of the names of Descriptors & Qualifiers
#'
#' @description It can provide all the PMIDS of publications with specific Descriptors
#' and Qualifiers. It is used for x < 300 PMIDS
#'
#' @param x,Descriptor,Qualifier
#'
#' @return NULL
#'
#' @examples
#'
#' @export mesh_by_name
mesh_by_name<-function(x,Descriptor,Qualifier){

    rec <- rentrez::entrez_fetch(db="pubmed", id=x, rettype = "xml", parsed=TRUE)

    mesh <- XML::getNodeSet(rec, "//PubmedArticle")

    xpath2 <-function(x, ...){
        y <- XML::xpathSApply(x, ...)
        ifelse(length(y) == 0, NA,  list(y, collapse=" "))
    }

    m1 <- sapply(mesh, xpath2, ".//DescriptorName", XML::xmlValue, "UI")
    m2 <- sapply(mesh, xpath2, ".//QualifierName", XML::xmlValue, "UI")
    m2 <- sapply(m2,unique)
    m3 <- sapply(mesh, xpath2, ".//MedlineCitation/PMID", XML::xmlValue)

    t<-dplyr::tibble(DescriptorNameUI = m1,
                     QualifierNAmeUI = m2, PMID = m3)


    inter_descriptor<-lapply(m1,intersect,Descriptor)

    inter_qualifier<-lapply(m2,intersect,Qualifier)


    common_n_discriptor<-lapply(inter_descriptor,length)

    common_n_qualifier<-lapply(inter_qualifier,length)

    result<-dplyr::tibble(common_n_discriptor,common_n_qualifier,m3)

    # for purrr
    `%>%` <- purrr::`%>%`

    filter_final <- result %>%
        dplyr::filter(common_n_discriptor >=length(Descriptor) & common_n_qualifier >=length(Qualifier))

    res<-unlist(filter_final$m3)

    return(res)
}
