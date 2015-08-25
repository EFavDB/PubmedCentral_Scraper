## scrapeArticle.R
## GIVEN THE PUBMED CENTRAL ID OF AN ARTICLE, GO TO THE FULL TEXT
## ARTICLE ON PUBMED CENTRAL AND SEARCH EVERY FIGURE CAPTION FOR 
## MATCHES TO SEARCH TERMS.  CAPTURE METADATA FOR MATCHES.
##==================================================================
## INPUT ARGUMENTS: 
##  -id (integer): an pubmed central article id (pmcid)
##  -topic (string): vector of strings of arbitrary length, 
##    any one of which identifies the drug of interest
##  -plottype (string): vector of strings of arbitrary length, 
##    any one of which identifies the type of figure type to capture
## OUTPUT: dataframe with colnames "img_url","fig_name", "caption" per image, 
##          or returns 0 if there are no matching images in a document
##
## EXAMPLE:
##  scrapeArticle(4204849, 
##                c("trastuzumab","herceptin"),
##                c("tumor growth", "tumor volume",
##                  "tumor size", "tumor inhibition",
##                  "tumor growth inhibition", "tgi",
##                  "tumor response", "tumor regression"))
##==================================================================
library("RCurl")
library("XML")
library("httr")
library("rvest")
library("stringr")

scrapeArticle = function(id, topic, plottype) {
  
  ## go to url of pmc full article for the given pmcid
  ncbiurl.base = "http://www.ncbi.nlm.nih.gov"
  url.article = paste0(ncbiurl.base, "/pmc/articles/PMC", id)
  
  ## check if url is valid
  if(!url_ok(url.article)) {
    write.table(paste(url.article," invalid url", sep=","),
                file="failed_pmcidURL.txt",
                row.names=F, col.names=F, append=T, sep=",")
    return(0)
  }
  
  article = html(url.article)
  
  ## get urls and names of all popup figures in article
  fig_tags = get_fig_urls(article)
  url.figs = fig_tags$url.figs
  fig.names = fig_tags$fig.names
  
  ## create dataframe to hold metadata of figures matching search terms
  figure_text = data.frame(img_url = character(),
                           fig_name = character(),
                           caption = character(),
                           stringsAsFactors = F)
  
  ## track how many (if any) images match search criteria
  foundmatch = 0
  ## loop through all figures, checking if they match keywords
  for (i in seq_along(fig.names)) {
    figure = scrapefigure(url.figs[i], topic, plottype)
    
    if(length(figure) > 1) {
      foundmatch = foundmatch + 1
      
      ##add row(s) of image data to dataframe
      if(length(figure$url.images)>1) {
        imgdata = lapply(figure$url.images,
                         function(x) c(x, fig.names[i], figure$caption))
        imgdata = do.call("rbind", imgdata) 
      } else {
        imgdata = data.frame(figure$url.images, fig.names[i], figure$caption)
      }
      colnames(imgdata) = c("img_url","fig_name","caption")
      figure_text = rbind(figure_text, imgdata)
    }
  }
  if(foundmatch > 0) {
    return(figure_text) 
  } else {
    return(0)
  }
}

get_fig_urls = function(article) {
  ## identify tags corresponding to popups (associated with tables and figures)
  popups.tags = article %>% xml_nodes(".icnblk_cntnt .figpopup")
  ## identify which popups correspond to popups from primary caption links
  ## (and not any other links in the text)
  figs.tags = popups.tags[popups.tags %>% xml_attr("class") == "figpopup"]
  ## identify which popups are figures/plots, not tables
  figs.tags = figs.tags[tolower(figs.tags %>% xml_attr("target")) == "figure"]
  
  ## identify figure link fragments
  figs.linkfrag = figs.tags %>% xml_attr("href")
  ## get urls of figure locations
  url.figs = paste0("http://www.ncbi.nlm.nih.gov", figs.linkfrag)
  
  ## identify figure names
  fig.names = (figs.tags %>% html_text())
  
  ## remove all duplicates of figure links
  url.figs = url.figs[!duplicated(url.figs)]
  fig.names = fig.names[!duplicated(url.figs)]
  
  return(list(url.figs = url.figs, fig.names = fig.names))
}

scrapefigure = function(url.fig, topic, plottype) {
  ## url.fig is the url for a single figure
  if(!url_ok(url.fig)) return(0)
  
  ## grab html content from url of figure
  fig = html(url.fig)
  
  ## get figure caption
  fig.caption = (fig %>% xml_nodes("p"))[[2]] %>% xml_text()
  
  ## check figure caption for matches to search terms
  match.topic = sapply(tolower(topic),
                       function(x) grepl(x, tolower(fig.caption)))
  match.plot = sapply(tolower(plottype),
                      function(x) grepl(x, tolower(fig.caption)))
  
  ## if caption meets search word criteria, capture info about the figure
  if(any(match.topic)==T & any(match.plot)==T) {
    ## get html tag(s) containing location of image(s)
    fig.tags = fig %>% xml_nodes("img")
    
    ## identify tags corresponding to enlarged images
    ## (exclude thumbnails or journal icon)
    figclasses = html_attr(fig.tags, "class")
    fig.isimageclass = (figclasses == "fig-image" | figclasses == "tileshop")
    ## (tileshop images can be further enlarged, but stick with the
    ## intermediate size)
    
    ## keep only tags of images in desired classes
    fig.tags = fig.tags[which(fig.isimageclass == T)]
    
    ## get image source locations (partial path)
    ## (returned in format "/pmc/articles/PMC[pmcid]/bin/[imagename].jpg")
    fig.src = html_attr(fig.tags, "src")
    
    return(list(url.images=fig.src, caption=fig.caption))
  } else {
    return(0)
  }
}