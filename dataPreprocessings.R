library(dplyr)
library(lubridate)
library(stringr)
library(readxl)
library(geodist)
library(ggplot2)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Read data from the initial file
data_file <- "data/willhaben_woom_bikes.csv"
bikes_in <- read.csv(data_file, stringsAsFactors = FALSE)

bikes <- bikes_in %>% distinct(item_url, .keep_all = TRUE)
bikes <- bikes %>% mutate(obs_id = row_number())

### DATA CLEANING ###

bikes <- bikes %>% filter(!str_detect(title, regex("helm", ignore_case = TRUE)))
bikes <- bikes %>% filter(!str_detect(title, regex("tasche", ignore_case = TRUE)))

### DATA PREPROCESSINGS ###

parse_price <- function(price_str) {
  price_cleaned <- gsub("[[:space:]]|€", "", price_str, perl = TRUE)
  price_numeric <- as.numeric(str_extract(price_cleaned, "\\d+"))
  return(price_numeric)
}

bikes <- bikes %>% mutate(price_parsed = parse_price(price))

bikes <- bikes %>% mutate(zip_code = str_extract(location, "\\b\\d{4,5}\\b"))

bikes <- bikes %>% mutate(city_name = str_extract(location, "^[^,]*"))

bikes <- bikes %>% mutate(WoomCategory_i = str_extract(title, "\\b\\d\\b"))
sum(is.na(bikes$WoomCategory_i))

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

sum(bikes$Color_i == "Andere")

bikes <- bikes %>%
  mutate(last_modified_dt = dmy_hm(str_extract(last_modified, "\\d{2}\\.\\d{2}\\.\\d{4}, \\d{2}:\\d{2}")),
         last_modified_unix = as.numeric(as.POSIXct(last_modified_dt, origin = "1970-01-01", tz = "UTC")))

max_last_modified_dt <- max(bikes$last_modified_dt, na.rm = TRUE)
print(max_last_modified_dt)

bikes <- bikes %>%
  mutate(Last_48_hours_i = ifelse(difftime(max_last_modified_dt, last_modified_dt, units = "hours") <= 48, 1, 0))
sum(bikes$Last_48_hours_i == 1)

bikes <- bikes %>%
  mutate(Cond_i = case_when(
    str_detect(details, regex("neuwertig", ignore_case = TRUE)) ~ "as good as new",
    str_detect(details, regex("gebraucht|used", ignore_case = TRUE)) ~ "used",
    TRUE ~ "good"
  ))
sum(bikes$Cond_i == "as good as new")

bikes <- bikes %>%
  mutate(Uebergabeart_i = case_when(
    str_detect(details, regex("Versand", ignore_case = TRUE)) ~ 1,
    str_detect(details, regex("Selbstabholung", ignore_case = TRUE)) ~ 0,
    TRUE ~ NA_real_
  ))

bikes <- bikes %>%
  mutate(Dealer_i = ifelse(seller_info == "Privatperson", 0, 1))

sum(bikes$Dealer_i == 1)
sum(bikes$Dealer_i == 0)

### WRITE CSV ###
write.csv(bikes, "data/processed_willhaben_woom_bikes.csv", row.names = FALSE)

### DATA PREPROCESSINGS PART 2 ###

bikes <- read.csv("data/processed_willhaben_woom_bikes.csv", stringsAsFactors = FALSE)

plz_verzeichnis <- read_excel("data/PLZ_Verzeichnis_20240628.xlsx")
coords <- read.csv("data/plz-coord-austria.csv", stringsAsFactors = FALSE)

bikes <- bikes %>%
  mutate(zip_code_result = ifelse(is.na(zip_code), 
                                  plz_verzeichnis$PLZ[match(city_name, plz_verzeichnis$Ort)], 
                                  zip_code))
sum(is.na(bikes$zip_code_result))

bikes <- bikes %>% filter(!is.na(zip_code_result))

bikes <- bikes %>%
  mutate(
    latitude = coords[, 10][match(zip_code_result, coords[, 1])],
    longitude = coords[, 11][match(zip_code_result, coords[, 1])]
  )
sum(is.na(bikes$latitude))
sum(is.na(bikes$longitude))

bikes <- na.omit(bikes)

### Calculate counts within radius ###

count_similar_products_within_radius <- function(bikes, radius_min, radius_max, condition, size) {
  distances <- geodist(bikes[, c("longitude", "latitude")], measure = "haversine")
  counts <- sapply(1:nrow(distances), function(i) {
    sum(distances[i, ] > radius_min & distances[i, ] <= radius_max & 
          bikes$Cond_i == condition & bikes$WoomCategory_i == size)
  })
  return(counts)
}

# Define radius thresholds in meters
radius_min_km <- c(0, 10, 30) * 1000
radius_max_km <- c(10, 30, 60) * 1000

bikes <- bikes %>%
  mutate(
    AnzahlSameProductsRadius0To10_i = count_similar_products_within_radius(., radius_min_km[1], radius_max_km[1], Cond_i, WoomCategory_i),
    AnzahlSameProductsRadius10To30_i = count_similar_products_within_radius(., radius_min_km[2], radius_max_km[2], Cond_i, WoomCategory_i),
    AnzahlSameProductsRadius30To60_i = count_similar_products_within_radius(., radius_min_km[3], radius_max_km[3], Cond_i, WoomCategory_i)
  )

# Replace NA values with 0 in columns starting with "AnzahlSameProductsRadius"
bikes <- bikes %>% mutate_at(vars(starts_with("AnzahlSameProductsRadius")), ~ifelse(is.na(.), 0, .))

bikes <- bikes %>% mutate(hasPsychologicalPricing_i = ifelse(grepl("9$|90$|99$", price_parsed), 1, 0))

bikes <- bikes %>% mutate(log_price = log(price_parsed))

# Logistic costs model
weights <- c(1/10, 1/30, 1/60)

bikes <- bikes %>%
  mutate(
    logistic_costs = {
      total_count <- AnzahlSameProductsRadius0To10_i + AnzahlSameProductsRadius10To30_i + AnzahlSameProductsRadius30To60_i
      
      weighted_sum <- (AnzahlSameProductsRadius0To10_i * weights[1] +
                         AnzahlSameProductsRadius10To30_i * weights[2] +
                         AnzahlSameProductsRadius30To60_i * weights[3])
      
      ifelse(total_count == 0, 0, 1 / weighted_sum)
    }
  )

bikes <- bikes %>%
  mutate(
    color = as.factor(Color_i),
    condition = as.factor(Cond_i)
  )

### Remove price outliers ###

ggplot(bikes, aes(x = price_parsed)) +
  geom_histogram(binwidth = 50, fill = "blue", color = "black", alpha = 0.7) +
  labs(title = "Histogram of price_parsed", x = "Price", y = "Frequency")

summary_stats <- summary(bikes$price_parsed)
IQR_value <- IQR(bikes$price_parsed, na.rm = TRUE)
Q1 <- summary_stats["1st Qu."]
Q3 <- summary_stats["3rd Qu."]

lower_bound <- Q1 - 1.5 * IQR_value
upper_bound <- Q3 + 1.5 * IQR_value

bikes_no_outliers <- bikes %>% filter(price_parsed >= lower_bound & price_parsed <= upper_bound)

ggplot(bikes_no_outliers, aes(x = price_parsed)) +
  geom_histogram(binwidth = 50, fill = "green", color = "black", alpha = 0.7) +
  labs(title = "Histogram of price_parsed (No Outliers)", x = "Price", y = "Frequency")

na_count <- sum(is.na(bikes_no_outliers$price_parsed))

write.csv(bikes_no_outliers, "data/willhaben_woom_bikes_sample.csv", row.names = FALSE)

