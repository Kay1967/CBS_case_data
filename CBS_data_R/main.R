library(httr)
library(xml2)
library(jsonlite)
library(tidyverse)
library(dplyr)
library(lubridate)
library(RSQLite)
library(ggplot2)
library(stringr)

# Main

# Source the scripts
source("Input_data.R")
source("Throughput_data.R")
source("Output_data.R")

# Verify the tables in the database
con <- dbConnect(SQLite(), dbname = "CBS_data.db")
tables <- dbListTables(con)
print(tables)

# Print the contents of each table
lapply(tables, function(table) print_table_contents(con, table))

# Disconnect from the SQLite database
dbDisconnect(con)
