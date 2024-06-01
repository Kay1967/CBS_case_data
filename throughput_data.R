library(httr)
library(xml2)
library(jsonlite)
library(tidyverse)
library(dplyr)
library(lubridate)
library(RSQLite)
library(ggplot2)
library(stringr)

#Throughput_data 

#Calculate the format of kwartaal in order to be returned under the header Perioden
convert_to_quarter <- function(period) {
  if (str_detect(period, "MM")) {
    year <- str_sub(period, 1, 4)
    month <- as.integer(str_sub(period, 7, 8))
    quarter <- ceiling(month / 3)
    return(paste0(year, "KW", sprintf("%02d", quarter)))
  }
  return(NA)
}

# Apply the function to the data
# mutate allows to add new columns or modify existing ones by applying functions or operations to the data.
# sapply function applies the convert_to_quarter function to each element of the Perioden column.
df_fruit <- df11600 %>%
  mutate(quarter = sapply(Perioden, convert_to_quarter))
df_auto <- df71100 %>%
  mutate(quarter = sapply(Perioden, convert_to_quarter))

# Group by quarter and calculate quarterly CPI
# Summarize is used to condense multiple rows of a dataset into a single row.
quarterly_cpi_fruit <- df_fruit %>%
  group_by(quarter) %>%
  summarize(
    ID = first(ID),
    Bestedingscategorieen = first(Bestedingscategorieen),
    Perioden = first(quarter),
    CPI_1 = round(mean(CPI_1, na.rm = TRUE), 2), 
    CPIAfgeleid_2 = round(mean(CPIAfgeleid_2, na.rm = TRUE), 2),
    MaandmutatieCPI_3 = NA_real_,
    MaandmutatieCPIAfgeleid_4 = NA_real_,
    JaarmutatieCPI_5 = NA_real_,
    JaarmutatieCPIAfgeleid_6 = NA_real_,
    Wegingscoefficient_7 = first(Wegingscoefficient_7)
  ) %>%
  mutate(
    Kwartaalmutatie = round((CPI_1 - lag(CPI_1)) / lag(CPI_1) * 100, 2),
    KwartaalmutatieAfgeleid = round((CPIAfgeleid_2 - lag(CPIAfgeleid_2)) / lag(CPIAfgeleid_2) * 100, 2)
  ) %>%
  select(
    ID, Bestedingscategorieen, Perioden, CPI_1, CPIAfgeleid_2, 
    MaandmutatieCPI_3, MaandmutatieCPIAfgeleid_4, Kwartaalmutatie, 
    KwartaalmutatieAfgeleid, JaarmutatieCPI_5, JaarmutatieCPIAfgeleid_6, Wegingscoefficient_7
  )

quarterly_cpi_auto <- df_auto %>%
  group_by(quarter) %>%
  summarize(
    ID = first(ID),
    Bestedingscategorieen = first(Bestedingscategorieen),
    Perioden = first(quarter),
    CPI_1 = round(mean(CPI_1, na.rm = TRUE), 2), 
    CPIAfgeleid_2 = round(mean(CPIAfgeleid_2, na.rm = TRUE), 2),
    MaandmutatieCPI_3 = NA_real_,
    MaandmutatieCPIAfgeleid_4 = NA_real_,
    JaarmutatieCPI_5 = NA_real_,
    JaarmutatieCPIAfgeleid_6 = NA_real_,
    Wegingscoefficient_7 = first(Wegingscoefficient_7)
  ) %>%
  mutate(
    Kwartaalmutatie = round((CPI_1 - lag(CPI_1)) / lag(CPI_1) * 100, 2),
    KwartaalmutatieAfgeleid = round((CPIAfgeleid_2 - lag(CPIAfgeleid_2)) / lag(CPIAfgeleid_2) * 100, 2)
  ) %>%
  select(
    ID, Bestedingscategorieen, Perioden, CPI_1, CPIAfgeleid_2, 
    MaandmutatieCPI_3, MaandmutatieCPIAfgeleid_4, Kwartaalmutatie, 
    KwartaalmutatieAfgeleid, JaarmutatieCPI_5, JaarmutatieCPIAfgeleid_6, Wegingscoefficient_7
  )

# Print the result
#print(quarterly_cpi_fruit)
#print(quarterly_cpi_auto)

# Fetch all data
df <- fetch_data_with_pagination(base_url)

# Define the function to compute the quarterly CPI and quarterly CPI change
calculate_quarterly_metrics <- function(df) {
  # Filter out JJ00 rows for calculations
  filtered_df <- df %>% filter(substr(Perioden, 5, 6) == "MM")
  
  # Calculate quarterly CPI by averaging the CPI of three consecutive months
  new_df <- filtered_df %>%
    mutate(
      QuarterlyCPI = (CPI_1 + lag(CPI_1, 1) + lag(CPI_1, 2)) / 3,
      QuarterlyCPIDerived = (CPIAfgeleid_2 + lag(CPIAfgeleid_2, 1) + lag(CPIAfgeleid_2, 2)) / 3
    )
  
  # Calculate the quarterly CPI change (Kwartaalmutatie)
  new_df <- new_df %>%
    mutate(
      Kwartaalmutatie = round((QuarterlyCPI - lag(QuarterlyCPI, 3)) / lag(QuarterlyCPI, 3) * 100, 2),
      KwartaalmutatieAfgeleid = round((QuarterlyCPIDerived - lag(QuarterlyCPIDerived, 3)) / lag(QuarterlyCPIDerived, 3) * 100, 2)
    )
  
  # Merge the original data with the calculated quarterly metrics
  final_df <- df %>%
    left_join(new_df %>% select(Perioden, QuarterlyCPI, QuarterlyCPIDerived, Kwartaalmutatie, KwartaalmutatieAfgeleid), by = "Perioden")
  
  # Ensure JJ00 rows have NA values for the calculated columns
  final_df <- final_df %>%
    mutate(
      QuarterlyCPI = ifelse(substr(Perioden, 5, 8) == "JJ00", NA, QuarterlyCPI),
      QuarterlyCPIDerived = ifelse(substr(Perioden, 5, 8) == "JJ00", NA, QuarterlyCPIDerived),
      Kwartaalmutatie = ifelse(substr(Perioden, 5, 8) == "JJ00", NA, Kwartaalmutatie),
      KwartaalmutatieAfgeleid = ifelse(substr(Perioden, 5, 8) == "JJ00", NA, KwartaalmutatieAfgeleid)
    )
  
  return(final_df)
}

# Apply the function to calculate the quarterly metrics
data_fruit_new <- calculate_quarterly_metrics(df11600)
data_auto_new <- calculate_quarterly_metrics(df71100)

# Select and rearrange the columns
data_fruit_new <- data_fruit_new %>%
  select(
    ID, Bestedingscategorieen, Perioden, CPI_1, CPIAfgeleid_2, MaandmutatieCPI_3, MaandmutatieCPIAfgeleid_4, 
    Kwartaalmutatie, KwartaalmutatieAfgeleid, JaarmutatieCPI_5, JaarmutatieCPIAfgeleid_6, Wegingscoefficient_7
  )
data_auto_new <- data_auto_new %>%
  select(
    ID, Bestedingscategorieen, Perioden, CPI_1, CPIAfgeleid_2, MaandmutatieCPI_3, MaandmutatieCPIAfgeleid_4, 
    Kwartaalmutatie, KwartaalmutatieAfgeleid, JaarmutatieCPI_5, JaarmutatieCPIAfgeleid_6, Wegingscoefficient_7
  )

# Print the final data
#print(data_fruit_new, n = 400)
#print(data_auto_new, n = 400)
