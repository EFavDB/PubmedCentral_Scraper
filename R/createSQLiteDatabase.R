## createSQLiteDatabase.R
## CREATE A SQLITE DATABASE TO STORE RESULTS OF PUBMED CENTRAL
## WEBSCRAPER RESULTS IN THREE TABLES

##==================================================================
## DATABASE SCHEMA

## table: article
## key: pmcid
## fields: pmcid | doi | title | journal | year | authors | abstract | keywords

## table: figure
## composite key: topic + plot_type + img_url
## fields: topic | plot_type | img_url | pmcid

## table: figure_text
## key: img_url
## fields: img_url | fig_name | caption
##==================================================================
library(DBI)
library(RSQLite)

## Create a database "myDb.sqlite"
con = dbConnect(SQLite(), dbname = "myDb.sqlite")

## create TABLE figure_text
query = 'CREATE TABLE figure_text(img_url TEXT, fig_name TEXT,\
        caption TEXT, PRIMARY KEY(img_url))'
dbGetQuery(con, query)

## create TABLE figure
query = 'CREATE TABLE figure(topic TEXT, plot_type TEXT, img_url TEXT,\
        pmcid INTEGER, PRIMARY KEY(topic, plot_type, img_url))'
dbGetQuery(con, query)

## create TABLE article
query = 'CREATE TABLE article(pmcid INTEGER, doi TEXT, title TEXT,\
        journal TEXT, year INTEGER, authors TEXT, abstract TEXT,\
        keywords TEXT, PRIMARY KEY(pmcid))'
dbGetQuery(con, query)

## Disconnect from database
dbDisconnect(con)