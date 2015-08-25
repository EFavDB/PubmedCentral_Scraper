## pubmedcentral_scraper.R
## SCRAPE PUBMED CENTRAL FULL TEXT ARTICLES FOR FIGURES MATCHING 
## USER-SPECIFIED KEYWORDS (TOPIC AND PLOT TYPE), THEN STORE 
## MATCHES INTO SQLITE DATABASE

## FILE DEPENDENCIES:
## eSearch.R
## eFetch.R
## scrapeArticle.R
## myDb.sqlite (a sqlite database)

##==================================================================
## <---------USER INPUT STARTS HERE--------->

## name of database where scraper results are stored
database.name = "myDb.sqlite"

## maximum number of results to retrieve from query
retmax = 10

## topic terms to be queried via the pubmed search engine
#query.topic = c("Docetaxel", "Docetaxol")
query.topic = c("Paclitaxel")

## topic/drug label for database
#topic = "Docetaxel"
topic = "Paclitaxel"

## keywords to identify plot type to be captured
query.plottype = c("tumor growth", "tumor volume",
                   "tumor size", "tumor inhibition",
                   "tumor growth inhibition", "tgi",
                   "tumor response", "tumor regression")

## plot type label for database
plot_type = "TGI"

## <---------USER INPUT ENDS HERE----------->

##==================================================================
library("RSQLite")
library("DBI")

source("eSearch.R")
source("scrapeArticle.R")
source("eFetch.R")
##==================================================================
## connect to sqlite database for storing webscraped results
con = dbConnect(SQLite(), dbname = database.name)

## check if tables exist in database
if(!dbExistsTable(con, "article")) stop("table 'article' does not exist")
if(!dbExistsTable(con, "figure")) stop("table 'figure' does not exist")
if(!dbExistsTable(con, "figure_text")) stop("table 'figure_text' does not exist")

##==================================================================
## PERFORM SIMPLE SEARCH (eSearch) ON PUBMED CENTRAL AND
## RETRIEVE UID'S OUTPUT BY QUERY
uids = eSearch(list(query.topic, query.plottype), retmax)
print(paste0("Retrieved ", length(uids), " pmcids from query results."))

##==================================================================
## CHECK IF UIDS FOR THE PARTICULAR TOPIC AND PLOT TYPE ALREADY
## EXIST IN THE DATABASE.  DO NOT PASS ALONG EXISTING UIDS TO BE SCRAPED.
checkexistence = function(uid) {
  query = sprintf('SELECT EXISTS(SELECT 1 FROM figure WHERE\
                  pmcid=%i AND topic="%s" AND plot_type="%s"LIMIT 1)',
                  uid, topic, plot_type)
  rowexists = dbGetQuery(con, query)
}
rowexists = unlist(sapply(as.integer(uids), checkexistence))

## only keep uid's that havent already been scraped for the same 
## topic and plot_type
uids = uids[!rowexists]

if(sum(rowexists)>0) {print(paste0(sum(rowexists)," records already exist in the database and will not be scraped."))}

##==================================================================
## FOR EACH UID, SCRAPE EACH FULL TEXT ARTICLE AND SAVE IMAGE
## URLS AND METADATA FOR RELEVANT ARTICLES

## define database fields and queries for data insertion
fields.article = "$pmcid, $doi, $title, $journal, $year, $authors, $abstract, $keywords"
query.article = paste0("INSERT OR IGNORE INTO article VALUES (", fields.article, ")")

fields.figure = "$topic, $plot_type, $img_url, $pmcid"
query.figure = paste0("INSERT OR IGNORE INTO figure VALUES (", fields.figure, ")")

fields.figure_text = "$img_url, $fig_name, $caption"
query.figure_text = paste0("INSERT OR IGNORE INTO figure_text VALUES (", fields.figure_text, ")")

## set counter ot track how many articles match the search criteria
match = 0
## set counter to track progress of article scraping
id_num = 0

for (id in uids) {
  id_num = id_num + 1
  print(paste0("scraping article ", id_num, " of ", length(uids)))
  
  ## scrapeArticle() returns a dataframe of "img_url","fig_name","caption"
  figure_text = scrapeArticle(id, query.topic, query.plottype)
  nimgs = nrow(figure_text) # the number of images returned
  
  ## get additional article metadata if image matches exist, then 
  ## write to database
  if(length(figure_text) > 1) {
    match = match + 1
    
    article_meta = eFetch(id)
    ## returns a list of (doi, title, journal, year, authors, abstract, keywords)
    
    ## WRITE RESULTS TO DATABASE
    ## tables:
    ## "article": pmcid | doi | title | journal | year | authors | abstract | keywords
    dbSendPreparedQuery(con, query.article, 
                        bind.data=data.frame(pmcid=id, article_meta))
    ## "figure": topic | plot_type | img_url | pmcid
    df.figure = data.frame(topic = rep(topic, nimgs),
                           plot_type = rep(plot_type, nimgs),
                           img_url = figure_text$img_url,
                           pmcid = rep(id, nimgs))
    dbSendPreparedQuery(con, query.figure, bind.data = df.figure)
    ## "figure_text": img_url | fig_name | caption
    dbSendPreparedQuery(con, query.figure_text, bind.data = figure_text)
  }
}

print(paste0(match, " article matches out of ",length(uids)," scraped articles."))

## disconnect from database
dbDisconnect(con)