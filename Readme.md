# CBS Data Processing Tool

## Overview
This tool is designed to fetch, process, analyze, and store data from the CBS (Centraal Bureau voor de Statistiek) Open Data API. It retrieves data related to Consumer Price Index (CPI) for various products, performs data manipulation and aggregation, calculates quarterly metrics, generates visualizations, and stores the processed data into an SQLite database.

## Requirements
- R (programming language)
- Sqlite databse
- R packages:
  - httr
  - xml2
  - jsonlite
  - tidyverse
  - dplyr
  - lubridate
  - RSQLite
  - ggplot2
  - stringr

## Usage
1. **Input Data:** Fetches data from the CBS Open Data API using pagination and filters for specific products and time periods.

2. **Throughput Data:** Processes the fetched data, calculates quarterly CPI, and inserts quarterly data into the monthly/annual data.

3. **Output Data:** Integrates quarterly data with monthly/annual data and prepares the final datasets for storage and visualization.

4. **Plot Data:** Generates visualizations to compare quarterly metrics for different products.

5. **Connection to the Database:** Writes the final datasets to an SQLite database and verifies the data.

## How to Run
1. Install R and required packages listed in the Requirements section.
2. Copy the provided R scripts into your R environment or R script editor.
3. Execute the main script to run the entire data processing pipeline.

## Files
- **input_data.R:** Fetches and filters raw data from the CBS Open Data API.
- **throughput_data.R:** Processes and calculates quarterly metrics for the data.
- **output_data.R:** Integrates and prepares the final datasets.
- **plot_data.R:** Generates visualizations.
- **database_connection.R:** Writes data to an SQLite database and verifies it.
- **README.md:** This file providing an overview of the tool and instructions for usage.

## Notes
- The tool assumes a stable internet connection for fetching data from the CBS API.
- Data is retrieved from the CBS API using pagination due to the large size of the dataset, fetching 10,000 records at a time.
- Ensure that the SQLite database file (CBS_data.db) is not open in another application before running the tool.
- Note that plots are generated only for the years 2023 and 2024.

## Author
- Kay Hasany
- For any questions or issues, please contact keyhasani@gmail.com.
