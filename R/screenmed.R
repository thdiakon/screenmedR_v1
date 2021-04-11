#' @title Screens Pubmed PMID numbers in accordance of a small group of relevant publications
#'
#' @description It provides us results for the cosine similarity of the group_number clusters
#' as well as a list of the clustered abstracts and in which cluster they belong. Finally it
#' also provides the PMIDS of the publications that no abstract was found.
#'
#'
#' @param initial_search,filtered,sparcity,group_number
#'
#' @return group_number,cosine_similarity,clustering,missing_abstracts
#'
#' @examples
#'
#' @export screenmed
#'
#'
screenmed <- function(initial_search,filtered,sparcity,group_number){


    # The abstracts from the big query
    #*************************************
    e <- RISmed::EUtilsGet(initial_search)
    Abstracts_Big<-RISmed::AbstractText(e)
    Abstracts_Big_PMID<-RISmed::PMID(e)
    Big<-cbind(Abstracts_Big,Abstracts_Big_PMID)

    #The abstracts from the small query
    #*************************************
    e <- RISmed::EUtilsGet(filtered)
    Abstracts_Small<-RISmed::AbstractText(e)
    Abstracts_Small_PMID<-filtered
    Small<-cbind(Abstracts_Small,Abstracts_Small_PMID)

    #make them tibbles
    Big<-tidyr::as_tibble(Big)
    Small<-tidyr::as_tibble(Small)

    # for purrr
    `%>%` <- purrr::`%>%`

    #rename columns of Small to antijoin with Big
    Small_Antijoin <- Small %>%
        dplyr::rename(Abstracts_Big = Abstracts_Small, Abstracts_Big_PMID = Abstracts_Small_PMID)

    Big <- dplyr::anti_join(Big,Small_Antijoin,by="Abstracts_Big_PMID")

    #cleaning and removing numbers and stemming
    Big$Abstracts_Big<-diagnosis_clean(Big$Abstracts_Big)
    Small$Abstracts_Small<-diagnosis_clean(Small$Abstracts_Small)

    #count the blanks
    #sum(Big$Abstracts_Big != "")

    #removing blanks (From RISMED)
    Big<-Big[! Big$Abstracts_Big=="", ]
    Small<-Small[! Small$Abstracts_Small=="", ]

    #Create the big dtm matrix with tm for clustering (Loop begin)
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    docs <- data.frame(doc_id = Big$Abstracts_Big_PMID,
                       text = Big$Abstracts_Big,
                       stringsAsFactors = FALSE)
    (ds <- tm::DataframeSource(docs))
    x <- tm::Corpus(ds)

    dtm = tm::DocumentTermMatrix(x,list(wordLengths=c(3, 15),stripWhitespace=T))

    #  tm::inspect(dtm)
    ifelse( sparcity == 1, dtm , dtm<-tm::removeSparseTerms(dtm,sparcity))

    sparse_words<-dtm$dimnames$Terms
    #  tm::inspect(dtm)
    Big_number<-length(Big$Abstracts_Big)

    tfidf.matrix_before <- as.matrix(dtm)

    #**********************Hierarchical clustering**********************************
    #library('proxy')
    d1 <- proxy::dist(tfidf.matrix_before, method = "cosine")
    set.seed(12)
    cluster1 <- hclust(d1, method = "ward.D2")
    # Cut tree into groups
    clustering <- cutree(cluster1, k = group_number)
    small_unlist<-paste(unlist(Small$Abstracts_Small), collapse =" ")
    Big_alone<-dplyr::as_tibble(Big$Abstracts_Big)
    Big_cleaned_merged<- vector(mode="character", length=as.integer(group_number+1))

    for(i in 1:group_number){
        Big_cleaned_merged[i]<-Big_alone %>%
            dplyr::mutate(clustering) %>%dplyr::filter(clustering==i) %>% dplyr::select(-clustering)
        Big_cleaned_merged[i]<-paste(unlist(Big_cleaned_merged[i]), collapse =" ")
    }

    Big_cleaned_merged[as.integer(group_number+1)]<-small_unlist
    Big_cleaned_merged<-unlist(Big_cleaned_merged)

    v<-(1:(group_number+1))
    v<-as.character(v)

    Big_cleaned_merged_1<-as.data.frame(cbind(v,Big_cleaned_merged))

    docs <- data.frame(doc_id =Big_cleaned_merged_1$v ,
                       text = Big_cleaned_merged_1$Big_cleaned_merged,
                       stringsAsFactors = FALSE)
    (ds <- tm::DataframeSource(docs))
    x <- tm::Corpus(ds)

    my_words<-unique(c(sparse_words,unlist(strsplit(small_unlist," "))))

    dtm = tm::DocumentTermMatrix(x,list(wordLengths=c(3, 15),
                                        stripWhitespace=T,
                                        dictionary = my_words))

    dtm_dist<-as.matrix(dtm)

    cosine_similarity<-c()

    for(i in 1:group_number){
        cosine_similarity<-c(cosine_similarity,lsa::cosine(as.vector(dtm_dist[group_number+1,]), as.vector(dtm_dist[i,])))
    }

    missing_abstracts=setdiff(as.character(initial_search),unname(unlist(attributes(clustering))))

    list(group_number = group_number,
         cosine_similarity = cosine_similarity,
         clustering=clustering,
         missing_abstracts=missing_abstracts)


}
