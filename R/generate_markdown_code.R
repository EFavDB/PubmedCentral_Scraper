## generate_markdown_code.R
## GENERATE R-MARKDOWN CODE (SAVED TO A .RMD FILE) TO BE KNIT TO
## AN HTML FILE THAT DISPLAYS METADATA AND PLOTS STORED IN A
## SQLITE DATABASE

##==================================================================
## INPUT ARGUMENTS:
##  -database.name (string): the name of a sqlite database
##  -topic (string): label in "topic" field of table "figure" in
##   a sqlite database for the drug or keyword associated with 
##   a webscraping search
##  -plot_type (string): label of plot type in "plot_type" field of 
##   table "figure" in a sqlite database for the plot type sought in 
##   a webscraping search
##  -rmd.filename (string): name of file to which the generated markdown code
##   is written
##
## EXAMPLE:
##  generate_markdown_code("myDb.sqlite", "Docetaxel", 
##                          "TGI", "makeHTMLplots.rmd")
##==================================================================
generate_markdown_code = function(database.name, topic, plot_type, rmd.filename) {
  library("DBI")
  library("RSQLite")
  
  ## connect to database
  con = dbConnect(SQLite(), dbname=database.name, flags=SQLITE_RO)
  
  ## get metadata associated with images that match the desired
  ## drug and plot type
  query = sprintf('SELECT *\
                  FROM ((figure JOIN article USING (pmcid))\
                  JOIN figure_text USING (img_url))\
                  WHERE (topic = "%s" AND plot_type = "%s")\
                  ORDER BY pmcid ASC',topic, plot_type)
  images = dbGetQuery(con, query)
  
  ## modify images dataframe so that the img_url contains the full path
  ncbiurl.base = "http://www.ncbi.nlm.nih.gov"
  images$img_url = paste0(ncbiurl.base, images$img_url)
  img_links = images$img_url
  
  ## add a column that flags whether a row is the first in its
  ## particular pmcid group
  images$first = (!duplicated(images$pmcid))
  
  ## name of file to which markdown commands should be written
  outfile = rmd.filename
  ## if file already exists, remove it before writing new rmd commands
  if(file.exists(outfile)) file.remove(outfile)
  
  lineOut = function(text) {
    cat(text, file=outfile, append=T, sep="\n")
  }
  
  ## write out first part of markdown code
  lineOut('---')
  lineOut('title: "Pubmed Central Scraper Results"')
  lineOut('output: html_document')
  lineOut('---')
  lineOut("\n")
  lineOut("```{r, include=FALSE}")
  lineOut('library("DBI")')
  lineOut('library("RSQLite")')
  lineOut("\n")
  lineOut(paste0('con = dbConnect(SQLite(), dbname = "', 
                 database.name,'", flags=SQLITE_RO)'))
  lineOut("query = sprintf('SELECT img_url FROM figure WHERE (topic =\
          \"%s\" AND plot_type = \"%s\") ORDER BY\
          pmcid ASC', topic, plot_type)")
  lineOut('img_urls = dbGetQuery(con, query)')
  lineOut('ncbiurl.base = "http://www.ncbi.nlm.nih.gov"')
  lineOut('img_links = paste0(ncbiurl.base, img_urls$img_url)')
  lineOut('```')
  lineOut('******')
  lineOut("\n")
  lineOut("\n")
  
  ## print out commands per image, including article title, pmcid,
  ## doi linking to full text, and abstract above the first image of each paper
  url.article = paste0(ncbiurl.base, "/pmc/articles/PMC")
  
  for(i in seq_along(img_links)) {
    if(images$first[i]) {
      lineOut(paste0("### ", images$title[i]))
      lineOut(paste0("**pmcid**: [",images$pmcid[i],"](", url.article,
                     images$pmcid[i],")"))
      lineOut("\n")
      lineOut(paste0("**doi**: ",images$doi[i]))
      lineOut("\n")
      lineOut(paste0("**abstract**: ", images$abstract[i]))
      lineOut("\n")
    }
    img_md = paste0("![pmcid: ",images$pmcid[i],"](`r img_links[",i,"]`)")
    lineOut(img_md)
    lineOut("\n")
    lineOut(paste0("**",images$fig_name[i],"**"," - ",images$caption[i]))
    lineOut("\n")
  }
  ## Write end of markdown code
  lineOut('```{r, include=FALSE}')
  lineOut('dbDisconnect(con)')
  lineOut('```')
  
  dbDisconnect(con)
}