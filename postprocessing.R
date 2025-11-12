## note: preprocessing.R must be run first

#get python outputs
short_log <- read_csv("outputs/shortlog.csv") %>%
  mutate(part = as.character(part))

ship_log <- read_csv("outputs/shipmentlog.csv") %>%
  mutate(part = as.character(part))

inv1 <- read_csv("outputs/starting_inv.csv") %>%
  mutate(part = as.character(part)) %>%
  rename(qty_start = qty)

inv2 <- read_csv("outputs/ending_inv.csv") %>%
  mutate(part = as.character(part)) %>%
  rename(qty_end = qty)


#calculate stockout dates
stockout_dates <- short_log %>%
  group_by(part, prov) %>%
  summarise(stockout = min(date), .groups = "drop")

#join to output data

outputdata2 <- outputdata %>%
  left_join(
    stockout_dates,
    join_by(name == part, Prov == prov),
    relationship = "one-to-one"
  )

outputdata2 %>% write_csv("outputs/inventorydata.csv")


#calculate change in inventory
delta_inv <- inv1 %>%
  select(part, prov, channel, lot, manufactured, age, qty_start) %>%
  left_join(
    inv2 %>%
      select(part, prov, channel, lot, manufactured, qty_end),
    join_by(part, prov, channel, lot, manufactured),
    relationship = "one-to-one"
  ) %>%
  mutate(
    consumed_qty = qty_start - qty_end
  ) %>%
  filter(part %in% ratlist$name)

delta_inv %>% write_csv("outputs/delta_inv.csv")

outputdata3 <- outputdata2 %>%
  group_by(name) %>%
  summarise(
    boardinv = sum(boardinv, na.rm = TRUE),
    medinv = sum(medinv, na.rm = TRUE),
    stamped = sum(stamped, na.rm = TRUE),
    unstamped = sum(unstamped, na.rm = TRUE),
    totaldmd = sum(totaldmd, na.rm = TRUE)
  )

delta_inv_sum <- delta_inv %>%
  mutate(
    cat = case_when(
      channel == "REC" & lot != "board_inv" ~ "stamped",
      channel == "REC" & lot == "board_inv" ~ "boardinv",
      channel == "MED" ~ "medinv",
      channel == "ANY" ~ "unstamped",
    )
  ) %>%
  group_by(part, cat) %>%
  summarise(consumed = sum(consumed_qty, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(
    names_from = cat,
    values_from = consumed
  )
  