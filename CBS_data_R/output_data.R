library(httr)
library(xml2)
library(jsonlite)
library(tidyverse)
library(dplyr)
library(lubridate)
library(RSQLite)
library(ggplot2)
library(stringr)

# Output_data

#Intergating Kwartaal and Maand/Jaar data
# Function to insert rows from quarterly_cpi_fruit into data_fruit_new based on conditions
insert_quarterly_data <- function(monthly_data, quarterly_data) {
  # Create an empty data frame to store the result
  result <- data.frame()
  quarterly_index <- 1
  mm_count <- 0  # Counter for "MM" rows
  
  # Loop through the rows of the monthly data
  for (i in 1:nrow(monthly_data)) {
    # Add the current row of the monthly data to the result
    result <- rbind(result, monthly_data[i,])
    
    # Check if the row is a monthly data row
    if (grepl("MM", monthly_data$Perioden[i])) {
      mm_count <- mm_count + 1  # Increment the "MM" row counter

      # Check if three "MM" rows have been added and if there's more quarterly data to insert
      if (mm_count %% 3 == 0 && quarterly_index <= nrow(quarterly_data)) {
        # Add the current row of the quarterly data to the result
        result <- rbind(result, quarterly_data[quarterly_index,])
        # Increment the index for the quarterly data
        quarterly_index <- quarterly_index + 1
      }
    }
  }
  
  # Return the combined data
  return(result)
}

# Insert the quarterly data into the monthly/yealy data to create yearly, quarterly and monthly data together.
final_data_fruit <- insert_quarterly_data(data_fruit_new, quarterly_cpi_fruit)
final_data_auto <- insert_quarterly_data(data_auto_new, quarterly_cpi_auto)
# Print the final combined data
print(final_data_fruit, n=390)
print(final_data_auto, n=390)

# Plot_data

# Define the function to plot the quarterly metrics for fruit and auto
# Here I chose only for 2023 and 2024. I could make it being interactive. It means that values could be provided by the user.
plot_combined <- function(data_fruit, data_auto) {
  # Filter data for the years 2023 and 2024
  filtered_data <- bind_rows(
    mutate(data_fruit, Product = "Fruit"),
    mutate(data_auto, Product = "Auto")
  ) %>%
    filter(substr(Perioden, 1, 4) %in% c("2023", "2024"))
  
  # Create the plot
  ggplot(filtered_data, aes(x = Perioden, y = Kwartaalmutatie, fill = Product)) +
    geom_bar(stat = "identity", position = "dodge") +
    theme_minimal() +
    labs(title = "Comparison of Kwartaalmutatie for Fruit and Auto (2023-2024)", x = "Quarter", y = "Kwartaalmutatie (%)") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# Plot the combined quarterly metrics for fruit and auto
print(plot_combined(final_data_fruit, final_data_auto))

# Connection to the Database

write_to_sqlite <- function(db_name, df_list) {
  # Connect to the SQLite database
  con <- dbConnect(SQLite(), dbname = db_name)
  if (is.null(con)) {
    stop("Failed to connect to the SQLite database.")
  }
  
  # Iterate over the list of data frames and write each one to the database
  for (df_name in names(df_list)) {
    message(paste("Writing table:", df_name))
    dbWriteTable(con, df_name, df_list[[df_name]], overwrite = TRUE, row.names = FALSE)
  }
  
  # Disconnect from the SQLite database
  dbDisconnect(con)
  message("Data written and connection closed.")
}

# List of data frames to be written to SQLite
df_list <- list(
  fruit_products = final_data_fruit,
  auto_products = final_data_auto
)

# Write the data frames to the SQLite database
write_to_sqlite("CBS_data.db", df_list)

# Connect to the SQLite database to verify
con <- dbConnect(SQLite(), dbname = "CBS_data.db")
if (is.null(con)) {
  stop("Failed to connect to the SQLite database for verification.")
}

# List all tables in the database
tables <- dbListTables(con)
print(tables)

# Function to query and print the first few rows of each table
print_table_contents <- function(con, table_name) {
  query <- paste("SELECT * FROM", table_name, "LIMIT 10")
  data <- dbGetQuery(con, query)
  print(paste("Table:", table_name))
  print(data)
}

# Print the contents of each table
lapply(tables, function(table) print_table_contents(con, table))

# Disconnect from the SQLite database
dbDisconnect(con)
message("Verification complete.")