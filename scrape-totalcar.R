# Scrape https://totalcar.hu/
# When checking the robots.txt I found that they provide xml sitemaps to easily find content on the website

# Load libraries
library(XML)
library(tidyverse)
library(data.table)
library(rvest)

# The sitemap can be found here: https://totalcar.hu/sitemap/sitemapindex.xml
# It contains all articles (and some other stuff too) ordered by months between 2009 and 2019

# Read in the sitemap
url <- "https://totalcar.hu/sitemap/sitemapindex.xml"
inputxml <- read_xml(url)
# Parse xml
inputxml <- xmlParse(inputxml)
# Convert to df
sitemap_df <- xmlToDataFrame(inputxml)
View(sitemap_df)

# Check the articles in November, 2019
# Find the xml for the related time:
nov_url <- "https://totalcar.hu/sitemap/cikkek_201911.xml"
nov_xml <- read_xml(nov_url)
nov_xml <- xmlParse(nov_xml)
nov_df <- xmlToDataFrame(nov_xml)
View(nov_df)

# We have now the links to the articles in a dataframe
# Let's iterate over the dataframe, scraping the title of the articles

# First let's try out on one example
# Extract URL of the first article in df
first_try <- nov_df[1, 'loc']
t <- read_html(as.character(first_try))
title <- t %>% html_node('.cim span') %>% 
  html_text()

# It seems working fine, now make a function
get_title <- function(df) {
  for (row in 1:nrow(df)) {
  
  article_url <- df[row, 'loc']
  t <- read_html(as.character(article_url))
  title <- t %>% html_node('.cim span') %>% 
    html_text()
  # Assign in to cell in df
  df[row, 'title'] <- title
  print(row)
  }
  names(df) <- c('url', 'lastmod')
  
  return(df)
}

# Create small table to try out function
trydf <- nov_df[1:10,]
df <- get_title(df = trydf)

# Scrape data for November and December of 2019
# First define a function to get the df for december
get_month  <- function(year_month) {
  month_url <- paste0("https://totalcar.hu/sitemap/cikkek_",year_month, ".xml")
  month_xml <- read_xml(month_url)
  month_xml <- xmlParse(month_xml)
  month_df <- xmlToDataFrame(month_xml)
  return(month_df)
}

dec_df <- get_month(201912)
nov_df <- get_month(201911)

# Make november df smaller to reduce runtime
nov_df <- nov_df[1:10, ]

months_list <- list(nov_df, dec_df)

# Get dataframe for nov and dec
res <- lapply(months_list, get_title)

# Append dfs together
res <- rbindlist(res)

saveRDS(res, 'totalcar_nov-dec.rds')
