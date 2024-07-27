library(readr)
library(dplyr)
library(ggplot2)
library(sf)
library(spdep)
library(spatialreg)

data <- read_csv("data/willhaben_woom_bikes_sample.csv")

data$WoomCategory_i <- as.factor(data$WoomCategory_i)
data$Cond_i <- as.factor(data$Cond_i)
data$Color_i <- as.factor(data$Color_i)
data$Dealer_i <- as.factor(data$Dealer_i)
data$Last_48_hours_i <- as.factor(data$Last_48_hours_i)
data$hasPsychologicalPricing_i <- as.factor(data$hasPsychologicalPricing_i)

plot(data$hasPsychologicalPricing_i)

data <- data %>%
  mutate(latitude = as.numeric(latitude),
         longitude = as.numeric(longitude))


data_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)


ggplot(data_sf) +
  geom_sf(aes(color = hasPsychologicalPricing_i)) +
  theme_minimal() +
  labs(title = "Spatial Distribution of Psychological Pricing")


data_sp <- as_Spatial(data_sf)
plot(data_sp)


# Construct W
max_distance <- 2
?dnearneigh
nb_dist <- dnearneigh(coordinates(data_sp), 1, max_distance)
print(nb_dist)

listw_dist <- nb2listw(nb_dist, style = "W")
print(listw_dist)

# Moran's I
moran_test_log_price <- moran.test(data$log_price, listw_dist)
print(moran_test_log_price)

moran_test_has_psych_pricing <- moran.test(as.numeric(data$hasPsychologicalPricing_i), listw_dist)
print(moran_test_has_psych_pricing)
