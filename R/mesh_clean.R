#' @title Cleaning not relevant publications in terms of number of mesh terms.
#'
#'
#' @description It provides the PMID numbers of a set of publications x which have at least
#'  d descriptors and q qualifiers in common with a small default set y. Should be used for
#'  x < 300 abstracts.
#'
#' @param x,y,d,q
#'
#' @return result_final
#'
#' @examples
#'
#' @export mesh_clean

mesh_clean<-function(x,y,d,q){

    merge<-unique(c(x,y))

    rec <- rentrez::entrez_fetch(db="pubmed", id=merge, rettype = "xml", parsed=TRUE)

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

    # for purrr
    `%>%` <- purrr::`%>%`

    #they have no DescriptorNameUI or QualifierNAmeUI
    mesh0<-unlist(dplyr::filter(t, DescriptorNameUI=="NA")
                  %>% dplyr::pull("PMID"))


    Descriptor_small<-unique(unlist(dplyr::filter(t,PMID %in% y)
                                    %>% dplyr::pull("DescriptorNameUI")))


    Qualifier_small<-unique(unlist(dplyr::filter(t,PMID %in% y)
                                   %>% dplyr::pull("QualifierNAmeUI")))


    inter_descriptor<-lapply(m1,intersect,Descriptor_small)

    inter_qualifier<-lapply(m2,intersect,Qualifier_small)


    common_n_discriptor<-lapply(inter_descriptor,length)

    common_n_qualifier<-lapply(inter_qualifier,length)

    result<-dplyr::tibble(common_n_discriptor,common_n_qualifier,m3)

    filter_final <- result %>% dplyr::filter(common_n_discriptor >=d & common_n_qualifier >=q)

    res<-unlist(filter_final$m3)

    result_final<-intersect(res,x)

    return(result_final)
}
