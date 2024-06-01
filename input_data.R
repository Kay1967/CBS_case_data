library(httr)
library(xml2)
library(jsonlite)
library(tidyverse)
library(dplyr)
library(lubridate)
library(RSQLite)
library(ggplot2)
library(stringr)

#Input_data
base_url <- "https://opendata.cbs.nl/ODataApi/OData/83131NED/TypedDataSet"

# Function to fetch data with pagination
fetch_data_with_pagination <- function(base_url, rows_per_request = 9999) {
  all_data <- list()
  skip <- 0
  repeat {
    # Construct the URL with pagination parameters
    url <- paste0(base_url, "?$top=", rows_per_request, "&$skip=", skip)
    response <- GET(url)
    
    # Check if the response is successful
    if (status_code(response) != 200) {
      stop("Error fetching data: ", content(response, "text", encoding = "UTF-8"))
    }
    
    # Parse the JSON data
    data <- content(response, "text", encoding = "UTF-8")
    json_data <- fromJSON(data, flatten = TRUE)
    
    # Check if there's any data returned
    if (length(json_data$value) == 0) {
      break
    }
    
    # Convert the list to a data frame and add to the list
    all_data <- append(all_data, list(as_tibble(json_data$value)))
    
    # Update the skip value
    skip <- skip + rows_per_request
  }
  
  # Combine all the data frames into a single data frame
  df <- bind_rows(all_data)
  return(df)
}

# Fetch all data
df <- fetch_data_with_pagination(base_url)
#print(df)

# Take the product fruit from the dataframe based on the code of the product and for years from 1900 to the end of 2024
df11600 <- df %>%
  filter(Perioden >= "1900MM10" & Perioden <= "2024MM12") %>%
  filter(Bestedingscategorieen == "CPI011600") %>%
  arrange(Perioden) %>%
  arrange(Bestedingscategorieen)
# Take the product auto from the dataframe based on the code of the product and for years from 1900 to the end of 2024
df71100 <- df %>%
  #filter(str_detect(Perioden, "^2023|^2024"))
  filter(Perioden >= "1900MM10" & Perioden <= "2024MM12") %>%
  filter(Bestedingscategorieen == "CPI071100") %>%
  arrange(Perioden) %>%
  arrange(Bestedingscategorieen)

# Print the sorted and filtered data frame
#print(df11600)
#print(df71100)