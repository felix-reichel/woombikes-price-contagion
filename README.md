# woombikes-price-contagion
Repo for VU Online Market Places

**Observational Unit:** "Woom Bikes" ("Marktplatz -> Sport / Sportgeräte -> Fahrräder / Radsport -> Fahrräder")
**Number:** / (filtered by only using the "Original Series", which is assumed if only "Woom ? or "Woom Original ?" is in the title or desc, presumably 1k+)

## Model Specification (Draft)

### Model 1: Regression Model

#### Simple MLR Model 

$$
WHPrice_i = \beta_0 + \beta_1 WHPriceObfuscation_i + \beta_2 WHCategory_i + \beta_3 WHColor_i + ... + \beta_4 WHUebergabeart_i + \beta_5 AnzahlSameProductsRadius0To10_i + \beta_6 AnzahlSameProductsRadius10To30_i + \beta_7 AnzahlSameProductsRadius30To60_i + u_i
$$

#### Desc.:
- $WHPrice_i$: The observed price of the product i on the marketplace. It reflects the willhaben price, which may not represent the final price.
- Assumed as Exogenous: ~~$DistanceToNextDealer_i$: e.g. https://intl-checkout.woom.com/apps/dealerlocator~~
- Assumed as Exogenous: ~~$AnzahlToNextDealerRadius0To10_i$: The count of dealers within a 0-10 km radius from the product's location, calculated using zip codes.~~
- Assumed as Exogenous: ~~$AnzahlToNextDealerRadius10To30_i$: The count of dealers within a 0-30 km radius from the product's location, calculated using zip codes.~~
- $WHPriceObfuscation_i$: Dummy 1 if has priceparts (9, 90, 99), 0 otherwise.
- $WHCategory_i$: A categorical variable indicating the Woom Bike numbers (e.g., 4, 3).
- $WHColor_i$: A categorical variable representing the color of the product.
- $WHLast48hours_i$: Dummy 1 if ad <= 48 hours active, 0 otherwise.
- $WHCond_i$: Categorial Variable denoting the condition. (used, good, as good as new)
- $WHUebergabeart_i$: A categorical variable denoting the delivery method. It is encoded as 1 for "Versand" (shipping) and 0 for "Selbstabholung" (self-pickup) on willhaben.
- ~~$Pay_livery_i$: Dummy 1 if has paylivery, 0 otherwise.~~
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



