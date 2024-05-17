# woombikes-price-contagion
Repo for VU Online Market Places

## Model Specification (Draft)


### Model 1: Regression Model

#### (Initial) Model Specification: 

**Observational Unit:** "Woom Bikes" (Market place -> bikes)

$$
  WHPrice_i = \beta_0 + \beta_1 Distance_i + \beta_2 ProductCategory_i + \beta_3 Color_i + \beta_4 Uebergabeart_i
$$

$$
 +\beta_5 AnzahlSameProductsRadius0To10_i + \beta_6        
  AnzahlSameProductsRadius10To30_i + \beta_7 AnzahlSameProductsRadius30To60_i + u_i
$$

- $Price_i$: The price of the product \( i \). *We can only observed the willhaben price, which might not is the 'final' price.

- $Distance_i$: The distance to the nearest similar product. *We might control further covariates here (e.g. nearest retailer product new)

- $ProductCategory_i$: A dummy variable indicating the product category. *Here we will put in the coded Voom Bike Numbers (e.g. 4, 3)

- $Color_i$: A categorical variable indicating the color of the product.

- $Uebergabeart_i$: A categorical variable indicating the delivery method. * Selbstabholung / Versand on willhaben => encode as Versand==1

- $AnzahlSameProductsRadius0To10_i$: The count of similar products within a 0-10 km radius. (=> calculated for each obs. unit from zip codes of offers)
- $AnzahlSameProductsRadius10To30_i$: The count of similar products within a 10-30 km radius.
- $AnzahlSameProductsRadius30To60_i$: The count of similar products within a 30-60 km radius.
- $u_i$: error term capturing unobserved U.

#### Partial Effects c.p.

- $\beta_1$: \( $\frac{\partial Price_i}{\partial Distance_i} = \beta_1 \$)
- $\beta_2$: \( $\frac{\partial Price_i}{\partial ProductCategory_i} = \beta_2 \$)
- $\beta_3$: \( $\frac{\partial Price_i}{\partial Color_i} = \beta_3 \$)
- $\beta_4$: \( $\frac{\partial Price_i}{\partial Uebergabeart_i} = \beta_4 \$)
- $\beta_5$: \( $\frac{\partial Price_i}{\partial AnzahlSameProductsRadius0To10_i} = \beta_5 \$)
- $\beta_6$: \( $\frac{\partial Price_i}{\partial AnzahlSameProductsRadius10To30_i} = \beta_6 \$)
- $\beta_7$: \( $\frac{\partial Price_i}{\partial AnzahlSameProductsRadius30To60_i} = \beta_7 \$)


### Model 2: Spatial Autoregressive Model (SAR)

#### Model Specifications: 


### Model 3: Spatial Error Model (SEM)

#### Model Specifications: 

$$
WHPrice_i = \beta_0 + \beta_1 Distance_i + \beta_2 AnzahlSameProductsRadius0To10_i + \beta_3 AnzahlSameProductsRadius10To30_i + \beta_4 AnzahlSameProductsRadius30To60_i + u_i
$$

$$
u_i = \lambda W u_i + \epsilon_i
$$




## Data

products with uvp: https://woom.com/de_AT/

a c2c marketplace: https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder-radsport/fahrraeder-4552?sfId=b8725e40-07af-41a5-bb6d-6d32deed8220&rows=30&isNavigation=true&keyword=woom+4

all woom b2c reseller with zip codes and country: https://intl-checkout.woom.com/apps/dealerlocator

austrian zip codes data according some ISO standard:  

a scraping code example using 'scrapy': https://github.com/maksimKorzh/scrapy-tutorials/blob/master/src/willhaben/willhaben.py



