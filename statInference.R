library(readr)
library(dplyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(car)
library(MASS)


data <- read_csv("data/willhaben_woom_bikes_sample.csv")
spec(data)


hist(as.numeric(data$size))
hist(as.numeric(data$condition))
hist(as.numeric(data$color))
hist(as.numeric(data$Dealer_i))
hist(as.numeric(data$Last_48_hours_i))
hist(as.numeric(data$hasPsychologicalPricing_i))

### Stepwise AIC Best MLR Model
data <- data %>% 
  mutate(
    size = as.factor(WoomCategory_i),
    color = as.factor(Color_i),
    condition = as.factor(Cond_i)
  )

initial_model <- lm(log_price ~ size + condition
                    + color + Dealer_i + Last_48_hours_i + hasPsychologicalPricing_i, 
                    data = data)

vif(initial_model)  # Check for multicollinearity

model <- initial_model
coeftest(model, vcov = vcovHC(model, type = "HC1"))
summary(model)


# Stepwise Regression for model selection
stepwise_model <- stepAIC(initial_model, direction = "both")

final_model <- stepwise_model
coeftest(final_model, vcov = vcovHC(final_model, type = "HC1"))
summary(final_model)
# Model Summary:
# --------------------------------------------------------
# Call:
# lm(formula = log_price ~ size + condition + Dealer_i + 
#    Last_48_hours_i + hasPsychologicalPricing_i, data = data)
# 
# Residuals:
#   Min       1Q   Median       3Q      Max 
# -0.47166 -0.06139  0.00533  0.07915  0.24108 
# 
# Coefficients:
#             Estimate Std. Error t value Pr(>|t|)    
# (Intercept)                5.33485    0.04931 108.196  < 2e-16 ***
# size2                      0.46305    0.05260   8.804 2.62e-16 ***
# size3                      0.54049    0.04912  11.004  < 2e-16 ***
# size4                      0.73868    0.05098  14.489  < 2e-16 ***
# size5                      0.88076    0.05877  14.987  < 2e-16 ***
# size6                      0.81588    0.06558  12.442  < 2e-16 ***
# size7                     -0.04183    0.12590  -0.332   0.7400    
# size8                      0.49102    0.09458   5.191 4.44e-07 ***
# conditiongood              0.10195    0.05166   1.974   0.0496 *  
# conditionused             -0.08041    0.01772  -4.539 8.94e-06 ***
# Dealer_i                  -0.06831    0.03435  -1.989   0.0479 *  
# Last_48_hours_i           -0.04506    0.02297  -1.962   0.0510 .  
# hasPsychologicalPricing_i  0.03442    0.02039   1.688   0.0927 .  
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.1158 on 241 degrees of freedom
# Multiple R-squared:  0.646,  Adjusted R-squared:  0.6283 
# F-statistic: 36.64 on 12 and 241 DF,  p-value: < 2.2e-16
# --------------------------------------------------------

# diagnostics
par(mfrow = c(2, 2))
plot(final_model)



### SLR Bivariate Models ###
bivariate_models <- list()
predictor_vars <- c("size", "condition", "Dealer_i", "Last_48_hours_i", 
                    "hasPsychologicalPricing_i", "color",
                    "AnzahlSameProductsRadius0To10_i", "AnzahlSameProductsRadius10To30_i",
                    "AnzahlSameProductsRadius30To60_i")

for (var in predictor_vars) {
  formula <- paste("log_price ~", var)
  bivariate_models[[var]] <- lm(formula = formula, data = data)
}
for (var in predictor_vars) {
  print(summary(bivariate_models[[var]]))
}
bivariate_metrics <- data.frame(
  Predictor = predictor_vars,
  R_squared = sapply(bivariate_models, function(model) summary(model)$r.squared),
  Adj_R_squared = sapply(bivariate_models, function(model) summary(model)$adj.r.squared)
)
print(bivariate_metrics)


### MLR Models ### 

mlr_model <- lm(price_parsed ~ 
                  size 
                + condition 
                + Dealer_i
                + Last_48_hours_i 
                + hasPsychologicalPricing_i,
                data = data)
coeftest(mlr_model, vcov = vcovHC(mlr_model, type = "HC1"))
# Dealer_i                  -22.6716    13.4422 -1.6866  0.092975 .  
# Last_48_hours_i           -15.6358     8.2713 -1.8904  0.059908 .  
# hasPsychologicalPricing_i  13.1611     8.0451  1.6359  0.103164   
# summary(mlr_model)

mlr_model_2 <- lm(price_parsed ~ 
                  size 
                + condition 
                + Dealer_i
                + Last_48_hours_i 
                + hasPsychologicalPricing_i
                + logistic_costs,
                data = data)
coeftest(mlr_model_2, vcov = vcovHC(mlr_model_2, type = "HC1"))
# Dealer_i                  -23.17233   13.35252 -1.7354  0.083949 .  
# Last_48_hours_i           -17.20966    8.40253 -2.0482  0.041634 *  
# hasPsychologicalPricing_i  13.64490    7.97054  1.7119  0.088204 . 
# logistic_costs              1.65148    0.60133  2.7464  0.006483 ** 
summary(mlr_model_2)

