# woombikes-price-contagion
Repository for VU Online Marketplaces

**Observational Unit:** "Woom Bikes" ("Marketplace -> Sport / Sports Equipment -> Bicycles / Cycling -> Bicycles")

**Number:** Approximately 3,000+ (Two snapshots, Observations at $t_0$ and $t_1$)

**Sample size:** 250

**Correlation Heatmap:**

![Correlation Heatmap](heatmap.png)

## Analysis of Willhaben Ads (Supply Side)

### Model Specification (Draft)

#### Model 1: Base MLR Model

$$
WHPriceProxy_i = \beta_0 + \beta * X_{WH_i} + u_i
$$


#### Description:
- $WHPriceProxy_i$: Observed price of product i on the marketplace, reflecting the Willhaben price.
- $X_{WH_i}$: Vector of explanatory variables for product i.

#### Model 2: Spatial Regression Model

##### Model choice based on research aim / Summary of Cook et al. (2020)
Cook et al. (2020) emphasize guiding model selection based on research aims. For unbiased estimates of non-spatial parameters, use SDM -> includes both observable spillovers (Wy and Wx). For testing spatial theories, use SAC or SDEM -> distinguishes spillovers in observables (SAC: ρWy, SDEM: WXγ) from unobservables -> prevents erroneous conclusions about diffusion/spillovers by controlling for non-observable clustering sources (p. 738).

tbd.



#### LR/Wald/LM Test Model Specification


## Data

- Products with UVP: [Woom Official Website](https://woom.com/de_AT/)
- C2C Marketplace: [Willhaben Bicycles](https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz/fahrraeder-radsport/fahrraeder-4552?sfId=b8725e40-07af-41a5-bb6d-6d32deed8220&rows=30&isNavigation=true&keyword=woom+4)
- All Woom B2C Resellers with Zip Codes and Country: [Dealer Locator](https://intl-checkout.woom.com/apps/dealerlocator)
- Austrian Zip Codes Data: According to ISO standard.

Example of scraping code using 'scrapy': [GitHub - scrapy-tutorials](https://github.com/maksimKorzh/scrapy-tutorials/blob/master/src/willhaben/willhaben.py)
