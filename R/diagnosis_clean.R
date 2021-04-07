#' @title Clean and manipilate the abstracts
#'
#' @description Using a lot of tm functions works for cleaning and stemming removing
#' special words etc.
#'
#' @param x
#'
#' @return NULL
#'
#' @examples
#'
#' @export diagnosis_clean
#'
#'
diagnosis_clean<-function(x){
    x<-tolower(x)
    x<-tm::removeNumbers(x)
    x<-gsub("[[:punct:]]", " ", x)
    x<-tm::removeWords(x,tm::stopwords("SMART"))
    x<-stringr::str_squish(x)
    x<-tm::stemDocument(x)
    return(x)
}

