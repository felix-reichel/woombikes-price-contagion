setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

### BASIC EXPLORATIVE STATISTICAL ANALYSIS ###

bikes <- read.csv(
  "data/willhaben_woom_bikes_sample.csv", 
  stringsAsFactors = FALSE)

### RUN a SLR ###

summary(lm(price_parsed ~ PriceObfuscation_i, data = bikes))
# Coefficients:
#  Estimate Std. Error t value Pr(>|t|)    
# (Intercept)         344.010      5.176  66.465   <2e-16 ***
#  PriceObfuscation_i   23.973     12.920   1.856   0.0639 .  
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# R^2 is only  0.00471

sum(bikes$PriceObfuscation_i==1)
# 102 out of 794 obs.


## Trying with all initial bikes
all_bikes <- all_bikes %>%
  mutate(PriceObfuscation_i = ifelse(grepl("9$|90$|99$", price_parsed), 1, 0))

summary(lm(price_parsed ~ PriceObfuscation_i, data = all_bikes))

sum(all_bikes$PriceObfuscation_i==1)
# 223 out of 1508 obs.

# Coefficients:
#  Estimate Std. Error t value Pr(>|t|)    
# (Intercept)         337.849      3.578   94.43   <2e-16 ***
#  PriceObfuscation_i   19.200      9.101    2.11   0.0351 *  

# but with an even lesser R^2 of 0,003





### Run MLR ###

bikes2 <- bikes

bikes <- bikes %>%
  filter(
    !is.na(price_parsed),
    !is.na(PriceObfuscation_i),
    !is.na(FCategory_i),
    !is.na(FColor_i),
    !is.na(Last_48_hours_i),
    !is.na(FCond_i),
    !is.na(Uebergabeart_i),
    !is.na(Dealer_i),
    !is.na(AnzahlSameProductsRadius0To10_i),
    !is.na(AnzahlSameProductsRadius10To30_i),
    !is.na(AnzahlSameProductsRadius30To60_i)
  )
# bikes <- 615 obs. out of 794 obs.

bikes <- bikes %>%
  mutate(
    FCategory_i = as.factor(WoomCategory_i),
    FColor_i = as.factor(Color_i),
    FCond_i = as.factor(Cond_i),
  )

bikes$FCategory_i <- relevel(bikes$FCategory_i, ref = 1)
bikes$FColor_i <- relevel(bikes$FColor_i, ref = "Andere")
bikes$FCond_i <- relevel(bikes$FCond_i, ref = "used")

mlr_model <- lm(price_parsed ~ PriceObfuscation_i + FCategory_i + FColor_i + Last_48_hours_i + 
                  FCond_i + Uebergabeart_i + Dealer_i + 
                  AnzahlSameProductsRadius0To10_i + 
                  AnzahlSameProductsRadius10To30_i + 
                  AnzahlSameProductsRadius30To60_i, 
                data = bikes)

summary(mlr_model)

mlr_model_2 <- lm(price_parsed ~ PriceObfuscation_i + FCategory_i + Last_48_hours_i + 
                    FCond_i + Uebergabeart_i + Dealer_i + 
                    AnzahlSameProductsRadius0To10_i + 
                    AnzahlSameProductsRadius10To30_i + 
                    AnzahlSameProductsRadius30To60_i, 
                  data = bikes)

summary(mlr_model_2)

# Coefficients:
#  Estimate Std. Error t value Pr(>|t|)    
# (Intercept)                      181.32773   18.91662   9.586  < 2e-16 ***
#  PriceObfuscation_i                 9.63164    9.54096   1.010   0.3131    
#  FCategory_i2                     120.25257   20.14478   5.969 4.08e-09 ***
#  FCategory_i3                     153.00315   18.06546   8.469  < 2e-16 ***
#  FCategory_i4                     246.87114   19.01752  12.981  < 2e-16 ***
#  FCategory_i5                     311.53810   21.89255  14.230  < 2e-16 ***
#  FCategory_i6                     363.38589   23.46201  15.488  < 2e-16 ***
#  FCategory_i7                      10.98887   88.67248   0.124   0.9014    
#  FCategory_i8                     130.07404   63.81410   2.038   0.0420 *  
#  Last_48_hours_i                    1.25606   10.65957   0.118   0.9062    
#  FCond_ias good as new             41.41229    8.59383   4.819 1.83e-06 ***
#  FCond_igood                        4.70298   22.90075   0.205   0.8374    
#  Uebergabeart_i                    -1.15499    9.31997  -0.124   0.9014    
#  Dealer_i                          -8.38230    8.31758  -1.008   0.3140    
# AnzahlSameProductsRadius0To10_i    0.06505    0.14099   0.461   0.6447    
# AnzahlSameProductsRadius10To30_i  -0.12840    0.07219  -1.779   0.0758 .  
# AnzahlSameProductsRadius30To60_i   0.03157    0.04531   0.697   0.4862    
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

# Residual standard error: 86.29 on 598 degrees of freedom
# Multiple R-squared:  0.4624,	Adjusted R-squared:  0.448 
# F-statistic: 32.14 on 16 and 598 DF,  p-value: < 2.2e-16

mlr_model_3 <- lm(price_parsed ~ PriceObfuscation_i + Last_48_hours_i + 
                    FCond_i + Uebergabeart_i + 
                    AnzahlSameProductsRadius0To10_i + 
                    AnzahlSameProductsRadius10To30_i + 
                    AnzahlSameProductsRadius30To60_i, 
                  data = bikes)

summary(mlr_model_3)
# FCond_ias good as new             37.85221   11.41256   3.317 0.000965 ***

sum(bikes$FCond_i=="as good as new")
# 136 obs.



bikes$FCond_i <- relevel(bikes$FCond_i, ref = "good")
sum(bikes$FCond_i=="good")
# 16. obs. , insufficient observations.

mlr_model_4 <- lm(price_parsed ~ FCond_i,
                  data = bikes)
summary(mlr_model_4)


### LASSO Reg ###
library(glmnet)

x <- model.matrix(price_parsed ~ PriceObfuscation_i + FCategory_i + FColor_i + Last_48_hours_i + 
                    FCond_i + Uebergabeart_i + Dealer_i + 
                    AnzahlSameProductsRadius0To10_i + 
                    AnzahlSameProductsRadius10To30_i + 
                    AnzahlSameProductsRadius30To60_i, data = bikes)[, -1]

y <- bikes$price_parsed


LASSO <- cv.glmnet(x, y, alpha = 1)

summary(LASSO)

# Plot LASSO Path
library(ggplot2)
plot(LASSO)
# Cross-Validation MSE
plot(LASSO$cvm, type = "b", pch = 19, xlab = "Log(Lambda)", ylab = "Cross-Validation MSE")
title("Cross-Validation MSE")



