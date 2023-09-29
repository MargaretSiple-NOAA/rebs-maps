# rebs-maps-2023
Additional maps for the 2023 GOA REBS assessment

# Requirements

This code uses a few "bespoke" packages produced in GAP. `gapindex` is the package that produces the tables that will eventually be found in the GAP_PRODUCTS schema. It has functionality to pull survey data for species complexes relatively easily, so I have used it here.

## Packages

```{r}
library(devtools)
devtools::install_github("afsc-gap-products/gapindex")
devtools::install_github("afsc-gap-products/akgfmaps", build_vignettes = TRUE)

library(sf)
library(gapindex)
library(akgfmaps)
library(ggplot2)
```

# Map
The code in `R/` produces this map:
![REBS map 1](https://github.com/MargaretSiple-NOAA/rebs-maps-2023/blob/main/rebs_map_logcpue.png?raw=true)
