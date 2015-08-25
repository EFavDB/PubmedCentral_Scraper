## markdown_and_plot.R
## GENERATE MARKDOWN FOR DISPLAYING ALL PLOTS SCRAPED FROM
## PUBMED CENTRAL MATCHING THE USER-SPECIFIED "topic" AND "plot_type"

## FILE DEPENDENCIES:
## generate_markdown_code.R
## myDb.sqlite (a sqlite database)


##==================================================================
## <---------USER INPUT STARTS HERE--------->

## name of database where scraper results are stored
db = "myDb.sqlite"

## topic/drug label for database
topic = "Docetaxel"

## plot type label for database
plot_type = "TGI"

## filename of generated markdown code
md.filename = "makeHTMLplots.rmd"

## <---------USER INPUT ENDS HERE----------->
##==================================================================
library("knitr")

source('generate_markdown_code.R')
generate_markdown_code(database.name = db,
                       topic = topic,
                       plot_type = plot_type,
                       md.filename = md.filename)

## GENERATE HTML FILE CONTAINING SCRAPED PLOTS AND METADATA
html.filename = sprintf("scraper_%s_plots_for_%s.html", 
                        plot_type, topic)
knit2html(md.filename, output=html.filename)