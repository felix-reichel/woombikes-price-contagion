library(readr)
library(dplyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(car)
library(MASS)
library(stargazer)


data <- read_csv("data/willhaben_woom_bikes_sample.csv")
spec(data)

data$WoomCategory_i <- as.factor(data$WoomCategory_i)
data$Cond_i <- as.factor(data$Cond_i)
data$Color_i <- as.factor(data$Color_i)
data$Dealer_i <- as.factor(data$Dealer_i)
data$Last_48_hours_i <- as.factor(data$Last_48_hours_i)
data$hasPsychologicalPricing_i <- as.factor(data$hasPsychologicalPricing_i)


plot(data$WoomCategory_i)
plot(data$Cond_i)

data$AnzahlSameProductsRadius0To10_i
data$AnzahlSameProductsRadius10To30_i
data$AnzahlSameProductsRadius30To60_i
data$logistic_costs


### Analysis of T = hasPsychologicalPricing_i using PSM
# Matching
library(MatchIt)
library(caret)

# T = hasPsychologicalPricing_i
psm_model <- glm(hasPsychologicalPricing_i ~ Cond_i + WoomCategory_i + Color_i + Dealer_i + Last_48_hours_i 
                 + AnzahlSameProductsRadius0To10_i + AnzahlSameProductsRadius10To30_i + AnzahlSameProductsRadius30To60_i, 
                 data = data, 
                 family = binomial())

# nearest nb matching
matched_data <- matchit(hasPsychologicalPricing_i ~ Cond_i + WoomCategory_i + Color_i + Dealer_i + Last_48_hours_i 
                       + AnzahlSameProductsRadius0To10_i + AnzahlSameProductsRadius10To30_i + AnzahlSameProductsRadius30To60_i, 
                        data = data, 
                        method = "nearest", 
                        distance = psm_model$fitted.values)

matched_data_frame <- match.data(matched_data)

# check covariate balance
summary(matched_data)



levels(matched_data_frame$Cond_i)
levels(matched_data_frame$WoomCategory_i)
levels(matched_data_frame$Color_i)
levels(matched_data_frame$Dealer_i)
levels(matched_data_frame$Last_48_hours_i)



# GLM, T = hasPsychologicalPricing_i
logistic_model <- glm(hasPsychologicalPricing_i ~ Cond_i + WoomCategory_i + Color_i + Dealer_i + Last_48_hours_i +
                      AnzahlSameProductsRadius0To10_i + AnzahlSameProductsRadius10To30_i + AnzahlSameProductsRadius30To60_i,
                      data = matched_data_frame,
                      family = binomial())

summary(logistic_model)


# LM
lm <- lm(log_price ~ Cond_i + WoomCategory_i + Color_i + Dealer_i + Last_48_hours_i + hasPsychologicalPricing_i + 
                     AnzahlSameProductsRadius0To10_i + AnzahlSameProductsRadius10To30_i + AnzahlSameProductsRadius30To60_i,
                   data = matched_data_frame)
summary(lm)


lm <- lm(log_price ~ Cond_i + WoomCategory_i + 
           + AnzahlSameProductsRadius10To30_i,
         data = matched_data_frame)

summary(lm)


