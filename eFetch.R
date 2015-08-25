## eFetch.R
## FETCH ARTICLE SUMMARY FOR A GIVEN ID

##==================================================================
## INPUT ARGUMENTS: 
##  -id (integer): an article id, e.g. pmcid, in the ncbi database
##  -database (string): abbreviation for ncbi database to search (see ncbi
##    eutils documentation)
## OUTPUT: article metadata as a list containing:
##  (doi (string), title (string), journal (string), year (integer), 
##    authors (string), abstract (string), keywords (string))
##
## EXAMPLE:
##  eFetch(4204849)
##==================================================================
library("RCurl")
library("XML")
library("httr")
library("rvest")
library("stringr")

eFetch = function(id, database="pmc") {
  
  ## NCBI DATABASE - DEFINE BASE URL OF API AND GENERAL API OPTIONS
  ## base eutils url
  url.base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
  ## eFetch utility
  efetch = "efetch.fcgi?"
  
  ## database to search
  db = paste0("db=",database)
  
  ## retrieval mode: data format of record to be returned
  retmode = "retmode=xml"
  
  ## compose url for eFetch
  url.efetch = paste0(url.base, efetch, db, "&", "id=", id, "&", retmode)
  
  data.efetch = getURL(url.efetch)
  data.xml = xmlParse(data.efetch)
  
  title = data.xml %>% xml_nodes("title-group") %>% xml_text()
  
  authors.surname = data.xml %>% xml_nodes("contrib-group") %>%
    xml_nodes("contrib") %>% xml_nodes("name") %>%
    xml_nodes("surname") %>% xml_text()
  authors.firstname = data.xml %>% xml_nodes("contrib-group") %>%
    xml_nodes("contrib") %>% xml_nodes("name") %>%
    xml_nodes("given-names") %>% xml_text()
  authors = paste(authors.surname, authors.firstname, sep=",")
  
  ## combine authors vector into one single string
  authors = paste(authors, collapse="; ")
  
  abstract = paste((data.xml %>% xml_nodes("abstract") %>% xml_text()),
                   collapse="; ")
  
  keywords = paste((data.xml %>% xml_nodes("kwd") %>% xml_text()), 
                   collapse="; ")
  
  doi = (data.xml %>% xml_nodes("article-id") 
         %>% xml_text()) [(data.xml %>% xml_nodes("article-id") %>%
                             xml_attr("pub-id-type")) == "doi"]
  
  ## some articles lack a doi
  if (length(doi)==0) doi = ""
  
  journal = data.xml %>% xml_nodes("journal-title") %>% xml_text()
  
  ## dates available are not uniform, so just grab the year 
  ## from the first date
  year = (data.xml %>% xml_nodes("pub-date") %>% 
            xml_nodes("year") %>% xml_text())[1]
  
  article_meta = list(doi=doi, title=title, journal=journal, year=year,
                      authors=authors, abstract=abstract, keywords=keywords)
  return(article_meta)
}