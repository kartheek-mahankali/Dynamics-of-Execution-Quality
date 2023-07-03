#---
# This script is used to automatically download the available Rule 605 filings
# for the market centers provided in config.yml
# The files will be saved under f605_data directory
# title: download_rule605_filings.R
# author: Sai Kartheek Mahankali
#---

###############################################
# Source functions.R to load get_input_from_config_file function
# Load the market_center_table that thas ID, NAME, URL for various market centers
###############################################

source("C:/new_DEQ/functions.R")

config_file_path <- "C:/new_DEQ/config.yml"

get_input_from_config_file(config_file_path)

mctable_file_path <- paste0(project_dir, "/data/constituent_data/mcid.csv")

market_center_table <- fread(mctable_file_path)

###############################################
# Define individual functions for market centers
###############################################

DownloadRule605FilingsCDRG <- function(mc) {
  file_download_dir <- paste0(project_dir, "/data/zip_files/")
  file_dir <- paste0(project_dir, "/data/f605_data/")
  mc_dir <- "CDRG_Rule605Files"
  mc_dir_path <- file.path(file_dir, mc_dir)
  if (!dir.exists(mc_dir_path)) {
    dir.create(mc_dir_path)
  }
  mc_dir_path <- paste0(mc_dir_path, "/")
  current_date <- Sys.Date()
  month_year <- vector("character", 50)

  for (i in 1:50) {
    iteration_date <- current_date %m-% months(i)
    month <- format(iteration_date, "%B")
    year <- format(iteration_date, "%Y")
    month_year[i] <- paste(month, year, sep = " ")
  }

  month_year_list <- as.list(month_year)


  rule605_status <- data.frame(
    month = unlist(month_year_list),
    downloaded = character(length(month_year_list)),
    stringsAsFactors = FALSE
  )

  url <- market_center_table$mc_url[mc == market_center_table$mc_id]
  response <- GET(url)
  content <- content(response, as = "text")
  parsed_html <- read_html(content)
  counter <- 1

  for (i in 1:length(month_year_list)) {
    search_date <- rule605_status$month[i]
    xpath_expr <- paste0("//*[contains(text(), '", search_date, "')]")
    target_element <- html_node(parsed_html, xpath = xpath_expr)
    base_url <- "https://www.citadelsecurities.com"
    href <- target_element %>%
      html_node("a") %>%
      html_attr("href")

    if (is.na(href)) {
      rule605_status$downloaded[i] <- "No"
      next
    } else if (startsWith(href, "/wp-content/")) {
      href <- paste0(base_url, href)
    }

    file_name <- basename(href)
    full_file_path <- paste0(mc_dir_path, file_name)
    download.file(href, destfile = full_file_path, method = "auto", extra = "overwrite")
    rule605_status$downloaded[i] <- "Yes"
    counter <- counter + 1
  }
  cat("Downloaded CDRG Rule 605 filings","\n")
}

DownloadRule605FilingsNITE <- function(mc) {
  file_download_dir <- paste0(project_dir, "/data/zip_files/")
  file_dir <- paste0(project_dir, "/data/f605_data/")
  mc_dir <- "NITE_Rule605Files"
  mc_dir_path <- file.path(file_dir, mc_dir)
  if (!dir.exists(mc_dir_path)) {
    dir.create(mc_dir_path)
  }
  mc_dir_path <- paste0(mc_dir_path, "/")
  current_date <- Sys.Date()
  month_year <- vector("character", 50)

  for (i in 1:50) {
    iteration_date <- current_date %m-% months(i)
    month <- format(iteration_date, "%B")
    year <- format(iteration_date, "%Y")
    month_year[i] <- paste(month, year, sep = " ")
  }

  month_year_list <- as.list(month_year)

  rule605_status <- data.frame(
    month = unlist(month_year_list),
    downloaded = character(length(month_year_list)),
    stringsAsFactors = FALSE
  )


  url <- market_center_table$mc_url[mc == market_center_table$mc_id]
  response <- GET(url)
  content <- content(response, as = "text")
  parsed_html <- read_html(content)
  counter <- 1

  for (i in 1:length(month_year_list)) {
    search_date <- rule605_status$month[i]
    xpath_expr <- paste0("//*[contains(text(), '", search_date, "')]")
    target_element <- html_node(parsed_html, xpath = xpath_expr)

    href <- html_attr(target_element, "href")
    if (is.na(href)) {
      rule605_status$downloaded[i] <- "No"
      next
    }
    file_name <- paste0(mc, sprintf("%02d", counter), ".zip")
    full_file_path <- paste0(file_download_dir, file_name)
    downloaded_file <- GET(href, write_disk(full_file_path, overwrite = TRUE))
    counter <- counter + 1
    if (status_code(downloaded_file) == 200) {
      rule605_status$downloaded[i] <- "Yes"
    } else {
      rule605_status$downloaded[i] <- "No"
    }
    file_list <- list.files(file_download_dir, full.names = TRUE)
    for (file in file_list) {
      unzip(file, exdir = mc_dir_path)
    }
  }
  cat("Downloaded NITE Rule 605 filings","\n")
}

DownloadRule605FilingsJNST <- function(mc) {
  file_download_dir <- paste0(project_dir, "/data/zip_files/")
  file_dir <- paste0(project_dir, "/data/f605_data/")
  mc_dir <- "JNST_Rule605Files"
  mc_dir_path <- file.path(file_dir, mc_dir)
  if (!dir.exists(mc_dir_path)) {
    dir.create(mc_dir_path)
  }
  mc_dir_path <- paste0(mc_dir_path, "/")
  current_date <- Sys.Date()
  month_year <- vector("character", 50)

  for (i in 1:50) {
    iteration_date <- current_date %m-% months(i)
    month <- format(iteration_date, "%m")
    year <- format(iteration_date, "%Y")
    month_year[i] <- paste0(year, month)
  }
  month_year_list <- as.list(month_year)

  rule605_status <- data.frame(
    month = unlist(month_year_list),
    downloaded = character(length(month_year_list)),
    stringsAsFactors = FALSE
  )

  counter <- 1

  for (i in 1:length(month_year_list)) {
    url <- "https://www.janestreet.com/static/execution-quality-reports/"
    url <- paste0(url, rule605_status$month[i], "_JNST.txt")
    file_name <- basename(url)
    full_file_path <- paste0(mc_dir_path, file_name)
    response <- tryCatch(
      {
        GET(url)
      },
      error = function(e) {
        stop(e)
      }
    )
    if (status_code(response) == 404) {
      rule605_status$downloaded[i] <- "No"
      next
    }
    download.file(url, destfile = full_file_path, method = "auto", extra = "overwrite")
    counter <- counter + 1
  }
  cat("Downloaded JNST Rule 605 filings","\n")
}

###############################################
# Define DownloadRule605Filings that calls
# individual functions to download rule 605 files
###############################################

DownloadRule605Filings <- function(mcid_list) {
  for (mc in mcid_list) {
    if (mc == "CDRG") {
      DownloadRule605FilingsCDRG("CDRG")
    } else if (mc == "NITE") {
      DownloadRule605FilingsNITE("NITE")
    } else if (mc == "JNST") {
      DownloadRule605FilingsJNST("JNST")
    }
  }
}


###############################################
# Function call
###############################################

if (length(mcid_list) == 0) {
  cat("Market Center IDs provided in configuration file : ",mcid_list,"\n")
  cat("User must manually download the Rule 605 filings")
} else {
  cat("Market Center IDs provided in configuration file : ",mcid_list,"\n")
  cat("Initiating automatic download of Rule 605 filings...","\n")
  DownloadRule605Filings(mcid_list)
}
