<style>
.small-code pre code {
  font-size: 1em;
}

.section .reveal .state-background {
  background: #66CCFF;
}

.section .reveal h1,
.section .reveal p {
  color: black;
}

</style>

Pubmed Central web scraper quick start
========================================================
author: Cathy Yeh
**Scrape articles on Pubmed Central** (PMC) for figures, e.g. plots of tumor
growth inhibition for a particular drug, and store scraped results in a SQLite
database.  

Query the database for a particular drug and plot-type to **generate 
html reports** displaying links to the source articles, along with article abstracts,
captured figures, and captions.


Depends on R Packages
========================================================
* `RSQLite`
* `DBI`
* `RCurl`
* `XML`
* `httr`
* `rvest`
* `stringr`
* `knitr`


First time using scraper: create a SQLite database
========================================================
class: small-code

<small>**createSQLiteDatabase.R** creates a SQLite database 
with the schema below that is used to store the scraped results</small>

table: **article**
```
pmcid | doi | title | journal | year | authors | abstract | keywords
```

table: **figure**
```
topic | plot_type | img_url | pmcid
```

table: **figure_text**
```
img_url | fig_name | caption
```


Scripts to scrape PMC and generate html reports
========================================================

**pubmedcentral_scraper.R** calls on
- `eSearch.R`
- `eFetch.R`
- `scrapeArticle.R`
- `myDb.sqlite` (created by `createSQLiteDatabase.R`)

**markdown_and_plot.R** calls on
- `generate_markdown_code.R`
- `myDb.sqlite`


Running the webscraper
========================================================
class: small-code

<small>set scraper settings in **pubmedcentral_scraper.R**</small>
```
## <---------USER INPUT STARTS HERE--------->

database.name = "myDb.sqlite"
retmax = 10
query.topic = c("Docetaxel", "Docetaxol")
topic = "Docetaxel"
query.plottype = c("tumor growth", "tumor volume",
                   "tumor size", "tumor inhibition",
                   "tumor growth inhibition", "tgi",
                   "tumor response", "tumor regression")
plot_type = "TGI"

## <---------USER INPUT ENDS HERE----------->
```

<small>Run the scraper:</small>
```
source("pubmedcentral_scraper.R")
```


Visualize web scraping results
========================================================
class: small-code

edit top of **markdown_and_plot.R**
```
## <---------USER INPUT STARTS HERE--------->

## name of database where scraper results are stored
db = "myDb.sqlite"

## topic/drug label for database
topic = "Docetaxel"

## plot type label for database
plot_type = "TGI"

## filename of generated markdown code
rmd.filename = "makeHTMLplots.rmd"

## <---------USER INPUT ENDS HERE----------->
```

**generate html report for scraper results**
```
source("markdown_and_plot.R")
```


Excerpt of sample report
========================================================
class: small-code

<small>topic: "Docetaxel"; plot_type: "TGI"</small>
![sample report](PubmedCentralSlides-figure/reportSnippet.PNG)
