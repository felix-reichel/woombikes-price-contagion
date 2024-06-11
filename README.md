# woombikes-price-contagion
Repo for VU Online Market Places

**Observational Unit:** "Woom Bikes" ("Marktplatz -> Sport / Sportgeräte -> Fahrräder / Radsport -> Fahrräder")
**Number:** / (filtered by only using the "Original Series", which is assumed if only "Woom ? or "Woom Original ?" is in the title or desc, presumably 1k+)

## Model Specification (Draft)

### Model 1: Regression Model

#### Simple MLR Model 

$$
WHPrice_i = \beta_0 + \beta_1 Distance_i + \beta_2 ProductCategory_i + \beta_3 Color_i + ... + \beta_4 Uebergabeart_i + \beta_5 AnzahlSameProductsRadius0To10_i + \beta_6 AnzahlSameProductsRadius10To30_i + \beta_7 AnzahlSameProductsRadius30To60_i + u_i
$$

#### Desc.:
- $WHPrice_i$: The observed price of the product i on the marketplace. It reflects the willhaben price, which may not represent the final price.
- $Distance_i$: The proximity to the nearest similar product. Further covariates such as the proximity to a retailer or product condition might be included.
- $ProductCategory_i$: A categorical variable indicating the product category, utilizing coded Woom Bike numbers (e.g., 4, 3).
- $Color_i$: A categorical variable representing the color of the product.
- $Last_48_hours_i$: Dummy 1 if ad <= 48 hours active, 0 otherwise.
- $Cond_i$: Categorial Variable denoting the condition. (used, good, as good as new)
- $Uebergabeart_i$: A categorical variable denoting the delivery method. It is encoded as 1 for "Versand" (shipping) and 0 for "Selbstabholung" (self-pickup) on willhaben.
- $Pay_livery_i$: Dummy 1 if has paylivery, 0 otherwise.
- $Dealer_i$: Dummy 1 if dealer, 0 otherwise (private exchange).
- $AnzahlSameProductsRadius0To10_i$: The count of similar products within a 0-10 km radius from the product's location, calculated using zip codes.
- $AnzahlSameProductsRadius10To30_i$: The count of similar products within a 10-30 km radius.
- $AnzahlSameProductsRadius30To60_i$: The count of similar products within a 30-60 km radius.
- $u_i$: Error term capturing unobserved factors influencing the product's price.

### Model 2: Spatial Regression Model



## Data

products with uvp: https://woom.com/de_AT/

a c2c marketplace: https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder-radsport/fahrraeder-4552?sfId=b8725e40-07af-41a5-bb6d-6d32deed8220&rows=30&isNavigation=true&keyword=woom+4

all woom b2c reseller with zip codes and country: https://intl-checkout.woom.com/apps/dealerlocator

austrian zip codes data according some ISO standard:  

a scraping code example using 'scrapy': https://github.com/maksimKorzh/scrapy-tutorials/blob/master/src/willhaben/willhaben.py



