#---
# title: "Functions"
# author: "Sai Kartheek Mahankali"
#---

###############################################
# Install Required Packages
###############################################

required_lib <- c(
  "kableExtra", "tidytext", "yaml", "config", "knitr",
  "formatR", "tibble", "dplyr", "tidyr", "lubridate",
  "ggplot2", "ggfortify", "caret", "tsibble", "fable",
  "fabletools", "feasts", "tsibbledata", "data.table",
  "xtable", "data.table", "rvest", "httr"
)


to_be_installed_lib <- required_lib[!required_lib %in% installed.packages()]

for (lib in to_be_installed_lib) {
  install.packages(lib, dependencies = TRUE)
}

sapply(required_lib, require, character = TRUE)


###############################################
# Function to read user input from config.yml
###############################################

get_input_from_config_file <- function(config_file_path) {
  config <- yaml::yaml.load_file(config_file_path)

  project_dir <- config$default$project_dir

  order_size_ip <- config$default$order_size
  if (order_size_ip != "") {
    order_size_ip <- gsub("\"", "", order_size_ip)
    order_size_ip <- strsplit(order_size_ip, ",")[[1]]
    order_size_ip <- as.numeric(order_size_ip)
  } else {
    order_size_ip <- 21
  }

  order_type_ip <- config$default$order_type
  if (order_type_ip != "") {
    order_type_ip <- gsub("\"", "", order_type_ip)
    order_type_ip <- strsplit(order_type_ip, ",")[[1]]
    order_type_ip <- as.numeric(order_type_ip)
  } else {
    order_type_ip <- 11
  }

  ticker_ip <- config$default$tickers
  if (ticker_ip != "") {
    ticker_list <- strsplit(ticker_ip, ",")[[1]]
  } else {
    ticker_list <- character(0)
  }

  mcid_ip <- config$default$market_center_ids
  if (mcid_ip != "") {
    mcid_list <- strsplit(mcid_ip, ",")[[1]]
  } else {
    mcid_list <- character(0)
  }
  assign("project_dir", project_dir, envir = .GlobalEnv)
  assign("order_type_ip", order_type_ip, envir = .GlobalEnv)
  assign("order_size_ip", order_size_ip, envir = .GlobalEnv)
  assign("ticker_list", ticker_list, envir = .GlobalEnv)
  assign("mcid_list", mcid_list, envir = .GlobalEnv)
}

###############################################
# Function to create rule605_all dataframe from the downloaded files
###############################################

process_rule605_files <- function(rule605_files, rule605_col_names, rule605_col_types) {
  rule605_df_list <- lapply(rule605_files, read.table,
    header = FALSE,
    sep = "|",
    fill = TRUE,
    col.names = rule605_col_names,
    colClasses = rule605_col_types
  )

  rule605_all <- dplyr::bind_rows(rule605_df_list)

  return(rule605_all)
}

###############################################
# Function to look at the constituent files and add listing related columns
###############################################

add_listing_data <- function(data, file_name, column_name) {
  file_data <- read.table(file_name, header = FALSE)
  data[[column_name]] <- data[, 4] %in% file_data[, 1]
  return(data)
}


###############################################
# Function to update order_type and order_size values in rule605_df
###############################################

update_rule605_df <- function(df) {
  df <- df %>%
    mutate(order_type = case_when(
      order_type == "11" ~ "mkt_ordr",
      order_type == "12" ~ "mktbl_lmt_ordr",
      order_type == "13" ~ "insd_qt_lmt_ordr",
      order_type == "14" ~ "at_qt_lmt_ordr",
      order_type == "15" ~ "nr_qt_lmt_ordr",
      TRUE ~ order_type # Keep the original value if none of the conditions match
    ))

  df <- df %>%
    mutate(order_size = case_when(
      order_size == "21" ~ "100-499",
      order_size == "22" ~ "500-1999",
      order_size == "23" ~ "2000-4999",
      order_size == "24" ~ "5000+",
      TRUE ~ order_size # Keep the original value if none of the conditions match
    ))

  # Add new column total_exec_shrs as the sum of mc_exec_shrs and away_exec_shrs
  # Remove the columns mc_exec_shrs and away_exec_shrs
  df <- df %>%
    mutate(total_exec_shrs = mc_exec_shrs + away_exec_shrs) %>%
    select(-mc_exec_shrs, -away_exec_shrs)

  return(df)
}

###############################################
# Calculate weighted median for net price improvement per order size
###############################################

get_weighted_quantiles_per_size <- function(df, otype, osize) {
  rule605_size_wq <- data.frame()
  for (i in 1:length(osize)) {
    df_sz <- df %>% filter(order_type %in% otype, order_size == osize[[i]])
    quantiles <- t(data.frame(wtd.quantile(df_sz$net_pi, df_sz$total_exec_shrs)))
    rownames(quantiles) <- osize[[i]]
    colnames(quantiles) <- c("0%", "25%", "50%", "75%", "100%")
    rule605_size_wq <- rbind(rule605_size_wq, quantiles)
  }
  colnames(rule605_size_wq) <- c("0%", "25%", "50%", "75%", "100%")
  rule605_size_wq$order_size <- ordered(rownames(rule605_size_wq), levels = osize)
  return(rule605_size_wq)
}

###############################################
# Calculate weighted median for net price improvement per order type
###############################################

get_weighted_quantiles_per_type <- function(df, otype, osize) {
  rule605_type_wq <- data.frame()
  for (i in 1:length(otype)) {
    df_sz <- df %>% filter(order_type == otype[i], order_size %in% osize)
    quantiles <- t(data.frame(wtd.quantile(df_sz$net_pi, df_sz$total_exec_shrs)))
    rownames(quantiles) <- otype[i]
    colnames(quantiles) <- c("0%", "25%", "50%", "75%", "100%")
    rule605_type_wq <- rbind(rule605_type_wq, quantiles)
  }
  colnames(rule605_type_wq) <- c("0%", "25%", "50%", "75%", "100%")
  rule605_type_wq$order_type <- ordered(rownames(rule605_type_wq), levels = otype)
  return(rule605_type_wq)
}
