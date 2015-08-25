pubmedcentral_scraper.R
=========================

pubmedcentral_scraper.R is an R script that retrieves a list of Pubmed Central article ID's returned by a query to the Pubmed Central database at the National Center for Biotechnology Information (NCBI) via the Entrez Programming Utilities interface http://www.ncbi.nlm.nih.gov/books/NBK25499/.  For each article ID, the scraper scans the captions of every figure in the online versions of the full-text articles for matches to the user-specified query topics.  Metadata for matching figures are stored in a SQLite database.


Prerequisite to running pubmedcentral_scraper.R
--------------------------
The scraper works with a SQLite database adhering to the schema specified in createSQLiteDatabase.R


Order of steps in pubmedcentral_scraper.R
--------------------------
- User defines search terms (one set defining the topic, another set defining the plot type to capture) in pubmedcentral_scraper.R
- Retrieve Pubmed Central Id's (pmcid) from a query to Pubmed Central via eSearch.R
- Send each pmcid to scrapeArticle.R, which returns metadata for images matching the search terms.
- If an article contains at least one matching image, also capture the article metadata (e.g. title, journal, year, etc) via a call to eFetch.R
- Save results of scraping to SQLite database.


To visualize results of scraping
--------------------------
markdown_and_plot.R queries the SQLite database where the scraping results are stored for the user-specified topic and plot type, then generates Rmarkdown code that is knitted to html displaying the matching plots and their associated captions and article information.  For an example outputted html file, go to the subdirectory files_generated_by_code/ and download "scraper_TGI_plots_for_trastuzumab.html" or simply click on makeHTMLplots.md in github, which will render the same html file.  Note that the plots are generated via href's to their Pubmed Central full-text articles and are not stored locally on the user's harddisk.


Generic functions for accessing Entrez utilities
---------------------------
eFetch.R and eSearch.R are not constrained to searches on Pubmed Central (e.g., Pubmed is equally valid).  However, pubmedcentral_scraper.R will only work with id's from a query to the Pubmed Central database, since those articles are guaranteed to have full-text online versions.