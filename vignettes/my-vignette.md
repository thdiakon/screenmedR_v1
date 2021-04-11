---
title: "The ScreenmedR package"
#output: rmarkdown::html_vignette
output:
  pdf_document:
    toc: yes
    toc_depth: '3'
    number_sections: true
    bibliography: bibliography.bib
vignette: >
  %\VignetteIndexEntry{The ScreenmedR package}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---


```{r, include = FALSE}
knitr::opts_chunk$set(
  collapse = FALSE,
  comment = "#>"
)
```

# Introduction

screenmedR is a package for screening your choice of publications in order to minimize the manual work choosing the proper publications for your meta-analysis project. It uses unsupervised machine learning algorithms to group your data (abstracts) and calculate the cosine similarity of the groups with a choice of abstracts (4 or 5 initially given) you think they fit to your analysis. The group with the highest cosine similarity can be chosen (in case the difference with the others is big enough) to narrow your search and end up with a much smaller number of abstracts needed for checking. 
It comes also with extra functions that use mesh terms (Descriptor & Qualifier) so as to narrow down your search even more. It uses  RISmed[@RISmed] and rentrez[@rentrez] package to extract the information that needed and tm[] package for the NLP.


# Installation

You can download-install the package from github and load the library:

```{r setup}
#devtools::install_github('thdiakon/screenmedR')
#library(screenmedR)
```

# A case study

This is a simple example of implementation of the code for the screenmed package.
Collecting the Pubmed Ids (PMID) from a PUBMED search the program can provide 3 different services.

*  Find the most relevant publications for our study, by comparing all the abstracts of the search with those of a small group of publications that we are pretty sure that they belong to the meta-analysis.

*  Filter the publications according to the number of common Mesh terms of a small group or a single publication.

* Filter the publications according to a list of specific common Mesh Terms that we are interested in. 


## Using screenmed to screen abstracts for a meta-analysis or a systematic review

Here, an example is provided, from a meta-analysis publication [@] in order to    understand how the program works. One can find more information on the way the program works by reading the above publication.

Initially we apply a search in Pubmed and saved the result in a csv file. We also knew 5 publications that we were quite sure that belong to the study.


```{r}
initial_search <- read.csv("csv-randomized-set.csv")
initialPMID<-initial_search$PMID
knownPMID<-c("25641242","18822428","8276025","16452355","8021760")
```

### The clustering process

Using all that information we apply it to the screenmed function:

```{r}
#a_cluster<-screenmed(initialPMID,knownPMID,0.995,2)
```

The last term is the number of groups. We chose 2 here as the number of abstracts is quite small, 581. There are a lot of ways of choosing the appropriate numbers of clustering but it will not be discussed further here. Usually for less than 1000 abstracts 2-4 groups would by quite ok. 
The number before is something that it is useful for the run and sometimes is quite useful for the clustering. It is the number applied to the removesparseterms() function of tm package. 
It actually removes terms,words that occur very rare (in this case less than 0,5% of the document term matrix). One can play with it between (0,99, 1) to have a better clustering. (Bigger difference in Cosine similarity between the two groups here).

```{r}
#a_cluster$cosine_similarity
```
These two numbers actually tell us the cosine similarity between the groups of abstracts and the initial (knownPMID) group. The bigger the difference between these two numbers the better the clustering. Generally a difference > 0.2 in cosine similarity is quite safe for choosing one group (the first in this case) and discard the other(s). It is obvious that if the difference is very small it is very risky to discard it.

You can see the number of abstracts that are clustered using the following command:

```{r}
#table(a_cluster$clustering)
```
One can notice that the number of abstracts is smaller than 581. This is due to the fact that not all abstracts are extracted from the RISmed package (version 2.2), some of them are missing so in this case we should add them up to the ones that we should check manually.

```{r}
#a_cluster$missing_abstracts  
```
So only 90 are out. Is this good enough? Of course not. We can recluster!!!

```{r}
#secondPMID<-abstractsofgroup(a_cluster$clustering,1,initialPMID)  
```

The abstractsofgroup() function filters the PMIDS of the abstracts that belong to the first group (the one with the bigger cosine similarity). What is left is a second clustering, using the rules of the first: 

```{r}
#b_cluster<-screenmed(secondPMID,knownPMID,0.995,2)
#b_cluster$cosine_similarity
#table(b_cluster$clustering)
```
```{r}
#table(b_cluster$clustering)
```
### Cross check and results

So we ended up with 118+63=181 possible abstracts to check out manually. Not bad. We have started from 581. Our colleagues did the job for us. The did the whole check manually and found that the rest are:
```{r}
#rest_relevant_pubs<-c("17329276","8835086","23904065","11023168","10356137","9175947"
#                      ,"8215566","15930210","8346957","33627329")
```

The cosine similarity result shows that the second group should hold our rest_relevant_pubs. Let's check it out:

```{r}
#lastPMID<-abstractsofgroup(b_cluster$clustering,2,initialPMID)
#intersect(rest_relevant_pubs,lastPMID)
```
That's correct. Everything is included. Not even needed to check the ones that RISmed could not provide us with abstracts (RISmed is the program that runs behind). The program succeeded to achieve more or less reduction of the manual abstract check to 118/581= 0.2. Some advice to end up. The process here was a small test. There are meta-analyses that include tens of thousands abstracts. In that case, would be a good idea, to split the initial PMID vector to chunks of 1000 abstract PMIDS and to repeat the process as shown above. One could end up saving a lot of time using the program.


## The mesh functions

Before we proceed let's give some useful information. Let's take one publication from our first group of knownPMID the one with PMID 25641242. If one could check its webpage in pubmed:

<https://pubmed.ncbi.nlm.nih.gov/25641242/>

he could see that on the left end of the page there is a column with all the mesh terms. If no slash (/) is included the terms are called Descriptors. In case there is a slash the first term is a Descriptor and the second is called Qualifier. The two sets of functions that this package includes are filtering our results, each one in a different way by using those terms that mentioned here. So for example "Blood Pressure / drug effects*" first term has a Descriptor = Blood Pressure and a Qualifier drug effects. It has more than 20 Descriptors and a lot of Qualifiers too.

### The clean_mesh() and clean_mesh_bq() functions

Let's say that we would like from our initial check (initialPMID) to restrict more our search. For example we would like to include publications which have at least some Descriptors and Qualifiers in common with our knownPMID publications. In case of a query that includes less than 300 publications one can use clean_mesh(). If there are more, then we must choose clean_mesh_bq(). Here we have 581, so we use the second:



```{r}
#initialPMID<-initial_search$PMID
#knownPMID<-c("25641242","18822428","8276025","16452355","8021760")
#mesh_clean_bq(initialPMID,knownPMID,11,2)
```

We provide with our initial search and the small group of PMID's of the publications the first two terms of the function and ask for 11 Descriptors in common and 2 Qualifiers.  

Another example, checking the common mesh terms of two publications:

```{r}
#a<-c("8276025")
#b<-c("8021760")
#mesh_clean(a,b,7,2)
```

So the function succeeded in filtering the publications according to what we asked for.
TO have at least 11 common Descriptors and two Qualifiers with the group of knownPMID.

### The mesh_by_name() and mesh_by_name_bq() functions

These functions are used in order to find publications with specific Mesh terms, Descriptors, Qualifiers, or both. We can use the mesh_by_name() or mesh_by_name_bq() for bigger queries. Eg:

```{r}
#Descriptor<-c("Blood Pressure","Dobutamine","Humans","Infant, Newborn")
#Qualifier<-c("administration & dosage")
#mesh_by_name_bq(initialPMID,Descriptor,Qualifier)
```

The first term of the function inputs the PMIDS of the initial search. The other two are including the exact names of Descriptors and Qualifiers our publications need to have.

The filtering works!!!

Enjoy!

# References
