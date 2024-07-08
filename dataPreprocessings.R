library(dplyr)
library(lubridate)
library(stringr)

data_file <- "data/willhaben_woom_bikes.csv"

bikes_in <- read.csv(data_file, stringsAsFactors = FALSE)

bikes <- bikes_in %>% distinct(item_url, .keep_all = TRUE)

bikes <- bikes %>% mutate(obs_id = row_number())
# 1529 obs.

### DATA CLEANING ###

bikes <- bikes %>% filter(!str_detect(title, regex("helm", ignore_case = TRUE)))
# 18 obs. removed
bikes <- bikes %>% filter(!str_detect(title, regex("tasche", ignore_case = TRUE)))
# 3 obs.removed



### DATA PREPROCESSINGS ###

parse_price <- function(price_str) {
  price_cleaned <- gsub("[[:space:]]|€", "", price_str, perl = TRUE)
  price_numeric <- as.numeric(str_extract(price_cleaned, "\\d+"))
  return(price_numeric)
}

bikes <- bikes %>%
  mutate(price_parsed = parse_price(price))


bikes <- bikes %>% mutate(zip_code = str_extract(location, "\\b\\d{4,5}\\b"))

bikes <- bikes %>% mutate(city_name = str_extract(location, "^[^,]*"))




# WoomCategory_i
bikes <- bikes %>% mutate(WoomCategory_i = str_extract(title, "\\b\\d\\b"))

sum(is.na(bikes$WoomCategory_i))
# for 260 obs. no woom category could be extracted


# Color_i
bikes <- bikes %>%
  mutate(Color_i = case_when(
    str_detect(details, regex("Blau|blue", ignore_case = TRUE)) ~ "Blau",
    str_detect(details, regex("Grün|green", ignore_case = TRUE)) ~ "Grün",
    str_detect(details, regex("Gelb|yellow", ignore_case = TRUE)) ~ "Gelb",
    str_detect(details, regex("Rot|red", ignore_case = TRUE)) ~ "Rot",
    str_detect(details, regex("Violett|purple", ignore_case = TRUE)) ~ "Violett",
    str_detect(details, regex("Orange", ignore_case = TRUE)) ~ "Orange",
    TRUE ~ "Andere"
  ))

sum(bikes$Color_i=="Andere")
# 240 obs. have Color_i=="Andere"


bikes <- bikes %>%
  mutate(last_modified_dt = dmy_hm(str_extract(last_modified, "\\d{2}\\.\\d{2}\\.\\d{4}, \\d{2}:\\d{2}")))

bikes <- bikes %>%
  mutate(last_modified_unix = as.numeric(as.POSIXct(last_modified_dt, origin="1970-01-01", tz="UTC")))

max_last_modified_dt <- max(bikes$last_modified_dt, na.rm = TRUE)
print(max_last_modified_dt)
# "2024-07-06 21:39:00 UTC" approx. where the scraper started (one execution)


# Last_48_hours_i: Dummy 1 if bike ad <= 48 hours active, 0 otherwise
bikes <- bikes %>%
  mutate(Last_48_hours_i = ifelse(difftime(max_last_modified_dt, last_modified_dt, units = "hours") <= 48, 1, 0))
# as from the data set visible, there is some other ranking going on

# sum of Last_48_hours_i
sum(bikes$Last_48_hours_i==1)
# 188 obs.



# Cond_i: Condition of the bike
bikes <- bikes %>%
  mutate(Cond_i = case_when(
    str_detect(details, regex("neuwertig", ignore_case = TRUE)) ~ "as good as new",
    str_detect(details, regex("gebraucht|used", ignore_case = TRUE)) ~ "used",
    TRUE ~ "good"
  ))

sum(bikes$Cond_i=="as good as new") # 293 obs.


# Uebergabeart_i where Versand = 1 and Selbstabholung = 0.
bikes <- bikes %>%
  mutate(Uebergabeart_i = case_when(
    str_detect(details, regex("Versand", ignore_case = TRUE)) ~ 1,
    str_detect(details, regex("Selbstabholung", ignore_case = TRUE)) ~ 0,
    TRUE ~ NA_real_
  ))


# BAD DATA QUALITIY COLUMN
# Dealer_i: Dummy 1 if dealer, 0 otherwise
bikes <- bikes %>%
  mutate(Dealer_i = ifelse(seller_info == "Privatperson", 0, 1))

sum(bikes$Dealer_i==1) # 1176 obs. where "Privatperson" is not explicit, but very likely. 
sum(bikes$Dealer_i==0) 



### WRITE CSV ###
write.csv(
  bikes, 
  "data/processed_willhaben_woom_bikes.csv", 
  row.names = FALSE)



### DATA PREPROCESSINGS PART 2 ###

library(dplyr)
library(readxl)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

bikes <- read.csv("data/processed_willhaben_woom_bikes.csv", stringsAsFactors = FALSE)
# 1508 obs.

plz_verzeichnis <- read_excel("data/PLZ_Verzeichnis_20240628.xlsx")
coords <- read.csv("data/plz-coord-austria.csv", stringsAsFactors = FALSE)



bikes <- bikes %>%
  mutate(zip_code_result = ifelse(is.na(zip_code), 
                                  plz_verzeichnis$PLZ[match(city_name, plz_verzeichnis$Ort)], 
                                  zip_code))

sum(is.na(bikes$zip_code_result)) # 690 obs.

all_bikes<-bikes

bikes <- bikes %>% filter(!is.na(zip_code_result))
# 818 obs.

bikes <- bikes %>%
  mutate(
    latitude = coords[, 10][match(zip_code_result, coords[, 1])],
    longitude = coords[, 11][match(zip_code_result, coords[, 1])]
)

sum(is.na(bikes$latitude))# 24
sum(is.na(bikes$longitude)) # 24

bikes <- bikes %>% filter(!is.na(latitude)) # 794 obs.

library(geodist)

count_similar_products_within_radius <- function(bikes, radius_min, radius_max) {
  distances <- geodist(bikes[, c("longitude", "latitude")], measure = "haversine")
  counts <- sapply(1:nrow(distances), function(i) {
    sum(distances[i, ] > radius_min & distances[i, ] <= radius_max)
  })
  return(counts)
}

radius_min_km <- c(0, 10, 30) * 1000
radius_max_km <- c(10, 30, 60) * 1000

bikes <- bikes %>%
  mutate(
    AnzahlSameProductsRadius0To10_i = count_similar_products_within_radius(bikes, radius_min_km[1], radius_max_km[1]),
    AnzahlSameProductsRadius10To30_i = count_similar_products_within_radius(bikes, radius_min_km[2], radius_max_km[2]),
    AnzahlSameProductsRadius30To60_i = count_similar_products_within_radius(bikes, radius_min_km[3], radius_max_km[3])
  )


bikes <- bikes %>%
  mutate(PriceObfuscation_i = ifelse(grepl("9$|90$|99$", price_parsed), 1, 0))


write.csv(bikes, 
          "data/willhaben_woom_bikes_sample.csv", 
          row.names = FALSE)


