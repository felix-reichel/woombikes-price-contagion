# woombikes-price-contagion
Repo for VU Online Market Places

**Observational Unit:** "Woom Bikes" ("Marktplatz -> Sport / Sportgeräte -> Fahrräder / Radsport -> Fahrräder")

**Number:** $\sim$ 1,5k+ (One snapshot, Observations at $t_0$)

## Analysis of Willhaben Ads (Supply side) 

### Model Specification (Draft)

#### Model 1: Simple MLR Model 

$$
WHPriceProxy_i = \beta_0 + \beta * X_{WH_i} + u_i
$$

#### Desc.:
- $WHPriceProxy_i$: The observed price of the product i on the marketplace. It reflects the willhaben price, which may not represent the final price.

- $WHCategory_i$: A categorical variable indicating the Woom Bike numbers (e.g., 4, 3).
- $WHCond_i$: Categorial Variable denoting the condition. (used, good, as good as new).
- $WHColor_i$: A categorical variable representing the color of the product.
- $WHUebergabeart_i$: A categorical variable denoting the delivery method. It is encoded as 1 for "Versand" (shipping) and 0 for "Selbstabholung" (self-pickup) on willhaben.
- $WHLast48hours_i$: Dummy 1 if ad <= 48 hours active, 0 otherwise.
- $WHHasNinePrice_i$: Dummy 1 if has priceparts (9, 90, 99), 0 otherwise.
- $WHDealer_i$: Dummy 1 if dealer, 0 otherwise (private exchange).
- $WHAnzahlSameProductsRadius0To10_i$: The count of similar products within a 0-10 km radius from the product's location, calculated using zip codes.
- $WHAnzahlSameProductsRadius10To30_i$: The count of similar products within a 10-30 km radius.
- $WHAnzahlSameProductsRadius30To60_i$: The count of similar products within a 30-60 km radius.
- $u_i$: Error term capturing unobserved factors influencing the product's price.

### Model 2: Spatial Regression Model



## Data

products with uvp: https://woom.com/de_AT/

a c2c marketplace: https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder-radsport/fahrraeder-4552?sfId=b8725e40-07af-41a5-bb6d-6d32deed8220&rows=30&isNavigation=true&keyword=woom+4

all woom b2c reseller with zip codes and country: https://intl-checkout.woom.com/apps/dealerlocator

austrian zip codes data according some ISO standard:  

a scraping code example using 'scrapy': https://github.com/maksimKorzh/scrapy-tutorials/blob/master/src/willhaben/willhaben.py



