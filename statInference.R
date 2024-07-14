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


initial_model <- lm(log_price ~ size + condition + color + Dealer_i + Last_48_hours_i 
                                 + hasPsychologicalPricing_i + Uebergabeart_i + logistic_costs, 
                    data = data)

vif(initial_model)  # Check for multicollinearity

model <- initial_model
coeftest(model, vcov = vcovHC(model, type = "HC0")) # Huber-White
summary(model)


# Stepwise Regression for model selection
stepwise_model <- stepAIC(initial_model, direction = "both")

final_model <- stepwise_model
coeftest_final <- coeftest(final_model, vcov = vcovHC(final_model, type = "HC0")) # Huber-White
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
                    "AnzahlSameProductsRadius30To60_i", "Uebergabeart_i", "logistic_costs")

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

coeftest(mlr_model, vcov = vcovHC(mlr_model, type = "const"))
coeftest_mlr <- coeftest(mlr_model, vcov = vcovHC(mlr_model, type = "HC0")) # Huber-White
# Dealer_i                  -22.6716    13.0937 -1.7315  0.084645 .  
# Last_48_hours_i           -15.6358     8.0568 -1.9407  0.053463 .  
# hasPsychologicalPricing_i  13.1611     7.8365  1.6795  0.094360 .  
summary(mlr_model)


mlr_model_2 <- lm(price_parsed ~ 
                  size 
                + condition 
                + Dealer_i
                + Last_48_hours_i 
                + hasPsychologicalPricing_i
                + logistic_costs,
                data = data)
coeftest(mlr_model_2, vcov = vcovHC(mlr_model, type = "const"))
coeftest_mlr2 <- coeftest(mlr_model_2, vcov = vcovHC(mlr_model_2, type = "HC0")) # Huber-White
# Dealer_i                  -23.17233   12.97932 -1.7853  0.075471 .  
# Last_48_hours_i           -17.20966    8.16769 -2.1070  0.036152 *  
# hasPsychologicalPricing_i  13.64490    7.74777  1.7611  0.079488 .  
# logistic_costs              1.65148    0.58453  2.8253  0.005121 ** 

summary(mlr_model_2)


### Output tables ###
stargazer(final_model, type = "latex", 
          se = list(coeftest_final[, 2]), 
          p = list(coeftest_final[, 4]), 
          title = "Stepwise Regression Model", 
          label = "tab:stepwise_model",
          star.cutoffs = c(0.05, 0.01, 0.001),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(final_model)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(final_model)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: * p<0.05; ** p<0.01; *** p<0.001.",
          table.placement = "H",
          keep.stat = c("n", "rsq", "adj.rsq"))

stargazer(mlr_model, type = "latex", 
          se = list(coeftest_mlr[, 2]), 
          p = list(coeftest_mlr[, 4]), 
          title = "Multiple Linear Regression Model", 
          label = "tab:mlr_model",
          star.cutoffs = c(0.10, 0.05, 0.01),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(mlr_model)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(mlr_model)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: * p<0.05; ** p<0.01; *** p<0.001.",
          table.placement = "H",
          keep.stat = c("n", "rsq", "adj.rsq"))

stargazer(mlr_model_2, type = "latex", 
          se = list(coeftest_mlr2[, 2]), 
          p = list(coeftest_mlr2[, 4]), 
          title = "Multiple Linear Regression Model with Logistic Costs", 
          label = "tab:mlr_model_2",
          star.cutoffs = c(0.10, 0.05, 0.01),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(mlr_model_2)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(mlr_model_2)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: * p<0.05; ** p<0.01; *** p<0.001.",
          table.placement = "H",
          keep.stat = c("n", "rsq", "adj.rsq"))
