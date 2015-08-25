## eSearch.R
## PERFORM SIMPLE SEARCH (ESearch) ON PUBMED CENTRAL AND 
## RETRIEVE UID'S OUTPUT BY QUERY

##==================================================================
## INPUT ARGUMENTS: 
##  -searchterms (list): a list of length 2, containing sets of strings
##    to be searched, where there should exist at least one match to each
##    set of strings.  The order of the sets does not matter.
##  -nreturns (integer): maximum number of query records to retrieve,
##    up to a maximum of 10,000
##  -database (string): abbreviation for ncbi database to search (see ncbi
##    eutils documentation)
##  -sortby (string): method used to sort id's in the esearch output (see
##    ncbi eutils documentation)
## OUTPUT: a vector of uid's/pmcid's (pubmed central id's)
##
## EXAMPLE:
##  eSearch(list(topic=c("trastuzumab","herceptin"),
##                plottype=c("tumor growth", "tumor volume",
##                          "tumor size", "tumor inhibition",
##                          "tumor growth inhibition", "tgi",
##                          "tumor response", "tumor regression")), 
##          nreturns=10, database="pmc", sortby="relevance")

##==================================================================
library("RCurl")
library("XML")
library("httr")
library("rvest")
library("stringr")

eSearch = function(searchterms, nreturns=10, database="pmc", sortby="relevance") {
  
  ## STRING TOGETHER SEARCH TERMS TO FORM QUERY
  stringTerms = function(x) {
    ## x is a vector of strings
    ## paste quotation marks around each string element
    x = paste0("\"",x,"\"")
    longstring = paste(x, collapse="+OR+")
    ## substitute '+' for spaces
    longstring = gsub("\\s+", "\\+", longstring)
    ## wrap entire long string in parentheses
    longstring = paste0("(",longstring,")")
    return(longstring)
  }
  query = paste(sapply(searchterms, stringTerms), collapse="+AND+")
  query = paste0("term=",query)
  
  ##==================================================================
  
  ## NCBI DATABASE - BASE URL OF API AND GENERAL API OPTIONS
  ## base eutils url
  url.base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
  ## eSearch utility
  esearch =  "esearch.fcgi?"
  
  ## database to search (default is pubmed central to use with article scraper)
  db = paste0("db=",database)
  
  ## maximum number of uid's to be retrieved (max=100k)
  retmax = paste0("retmax=",nreturns)
  
  ## method used to sort uid's output by eSearch
  sortmethod = paste0("sort=",sortby)
  
  ## compose url for eSearch
  url.esearch = paste0(url.base, esearch, db, "&", retmax,
                       "&", sortmethod, "&", query)
  
  ## get and parse xml data returned by eSearch
  data.esearch = getURL(url.esearch)
  data.xml = xmlParse(data.esearch)
  
  ## get uid's/pmcid's
  uids = data.xml %>% xml_nodes("Id") %>% xml_text()
  return(uids)
}