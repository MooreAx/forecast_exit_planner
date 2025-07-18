#Assembles input data sources for Python (export to 'intermediates' folder)

rm(list = ls())

library(tidyverse)
library(janitor)
library(readxl)
library(readr)

InvFldr <- "C:/Users/alex.moore/OneDrive - Canopy Growth Corporation/Documents/Working Folder/Inventory/OHWSI"
Downloads <- "C:/Users/alex.moore/Downloads"
MAPEBIAS <- "C:/Users/alex.moore/OneDrive - Canopy Growth Corporation/Documents/Working Folder/R/mape_bias"


#POD REQUIREMENTS
POD_long <- read_csv(paste(MAPEBIAS,"POD_long.csv", sep = "/"))

#forecast
FC <- read_csv(paste(MAPEBIAS, "/Intermediates/FC_Master.csv", sep = "/")) %>%
  filter(PublishDate == max(PublishDate)) %>%
  select(SKU, Part, Prov, Channel, Form, Date, FC) %>%
  
  left_join(
    POD_long,
    join_by(Prov, Form),
    relationship = "many-to-one"
  )

#write to csv
FC %>% write_csv("intermediates/Forecast.csv")

#INTERNAL INVENTORY

# List all Excel files
files <- list.files(path = InvFldr, pattern = "\\.xlsx$", full.names = TRUE)

# Extract dates from filenames (expecting format like "2025-06-03" in the name)
file_dates <- str_extract(basename(files), "\\d{4}-\\d{2}-\\d{2}")
valid_dates <- !is.na(file_dates)

# Convert to Date and find the latest
latest_file <- files[valid_dates][which.max(ymd(file_dates[valid_dates]))]
latest_file_date <- max(ymd(file_dates[valid_dates]))

# Read the latest file
InvData <- read_xlsx(
  path = latest_file,
  skip = 1,
  col_types = "text"  # same as setting all columns to character
) %>%
  clean_names() %>%
  select(name, number, is_stamped, pool, qa_status, warehouse, id, manufactured, available) %>%
  mutate(
    manufactured = parse_number(manufactured),
    manufactured = as.Date(manufactured, origin = "1899-12-30"),
    age = interval(manufactured, latest_file_date),
    age = time_length(age, "days"),
    available = parse_number(available)
  ) %>%
  filter(
    qa_status %in% c("A", "eComm-A"),
    available > 0
  ) %>%
  rename(
    part = name,
    lotnum = number,
    locid = id
  ) %>%
  drop_na(manufactured)

Inv_Med <- InvData %>%
  filter(str_sub(locid, 1, 2) == "50") %>%
  group_by(part, lotnum, manufactured, age) %>%
  summarise(available = sum(available), .groups = "drop") %>%
  mutate(pool = "MED")

Inv_Rec_Stamped <- InvData %>%
  filter(is_stamped == "Y") %>%
  group_by(part, lotnum, pool, manufactured, age) %>%
  summarise(available = sum(available), .groups = "drop")

Inv_Rec_Unstamped <- InvData %>%
  filter(is_stamped == "N") %>%
  group_by(part, lotnum, pool, manufactured, age) %>%
  summarise(available = sum(available), .groups = "drop")

#write to csv
Inv_Med %>% write_csv("intermediates/Inv_Med.csv")
Inv_Rec_Stamped %>% write_csv("intermediates/Inv_Rec_Stamped.csv")
Inv_Rec_Unstamped %>% write_csv("intermediates/Inv_Rec_Unstamped.csv")


#BOARD INVENTORY

binv <- read_delim(
  "inputs/_Dep_Inv Export (New).csv",
  delim = "\t",
  locale = locale(encoding = "UTF-16LE"), #unusual encoding from Tableau
  col_types = cols(.default = "c")
) %>%
  clean_names() %>%
  mutate(
    inventory_qty = parse_number(inventory_qty),
    on_order_qty = parse_number(on_order_qty),
    ttl_pipeline = parse_number(ttl_pipeline)
  ) %>%
  filter(week_end_date == max(week_end_date), licensed_producer == "CANOPY GROWTH CORP") %>%
  select(week_end_date, province, part_number, inventory_qty, on_order_qty, ttl_pipeline) %>%
  mutate(week_end_date = mdy(week_end_date))

#write_csv
binv %>% write_csv("intermediates/binv.csv")


#rationalization list
ratlist <- read_csv(
  "inputs/ratlist.csv",
  col_types = cols(.default = "c")
)


### simple cut (python later)
FCstopdates <- FC %>%
  #start with distinct part provs
  select(Part, Prov) %>%
  distinct() %>%
  
  #add exit dates (filtered to remove indefinite items)
  left_join(
    FC %>% 
      group_by(Part,Prov) %>%
      summarise(ExitDate = max(Date), .groups = "drop") %>%
      filter(ExitDate < max(ExitDate)),
    join_by(Part, Prov),
    relationship = "one-to-one"
  )

totalFC <- FC %>%
  group_by(Part, Prov) %>%
  summarise(
    totaldmd = sum(FC), .groups = "drop"
  )

outputdata <- ratlist %>%
  #add stop dates
  left_join(
    FCstopdates,
    join_by(name == Part),
    relationship = "one-to-many"
  ) %>%
  #add board inventory
  left_join(
    binv %>%
      select(part_number, province, ttl_pipeline) %>%
      rename(boardinv = ttl_pipeline),
    join_by(name == part_number, Prov == province),
    relationship = "one-to-one"
  ) %>%
  #add medical inventory
  left_join(
    Inv_Med %>%
      select(part, available) %>%
      mutate(prov = "MED") %>%
      group_by(part, prov) %>%
      summarise(medinv = sum(available), .groups = "drop"),
    join_by(name == part, Prov == prov),
    relationship = "one-to-one"
  ) %>%
  #add stamped inv
  left_join(
    Inv_Rec_Stamped %>%
      group_by(part, pool) %>%
      summarise(stamped = sum(available), .groups = "drop"),
    join_by(name == part, Prov == pool),
    relationship = "one-to-one"
  ) %>%
  #add unstamped inventory
  left_join(
    Inv_Rec_Unstamped %>%
      group_by(part) %>%
      summarise(unstamped = sum(available), .groups = "drop"),
    join_by(name == part),
    relationship = "many-to-one"
  ) %>%
  #add total demand
  left_join(
    totalFC,
    join_by(name == Part, Prov),
    relationship = "one-to-one"
  )


