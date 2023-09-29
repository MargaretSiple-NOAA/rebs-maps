# All hauls in GOA 2023 survey vs. hauls with REBS in them.
# Author: Megsie Siple (using GAP packages)
# Needed to run code:
# - Oracle login and VPN  or other network connection
# - recent versions of akgfmaps and gapindex
library(devtools)
devtools::install_github("afsc-gap-products/gapindex")
devtools::install_github("afsc-gap-products/akgfmaps", build_vignettes = TRUE)

library(sf)
library(gapindex)
library(akgfmaps)
library(ggplot2)

# Grab data on REBS from RACEBASE -----------------------------------------
# This script saves it locally so you can access without network.
make_raw_local <- TRUE

if (make_raw_local) {
  sql_channel <- gapindex::get_connected()

  # Pull all the data
  dat <- gapindex::get_data(
    year_set = c(2023),
    survey_set = "GOA",
    pull_lengths = TRUE,
    spp_codes = data.frame(
      GROUP = "REBS",
      SPECIES_CODE = c(30050, 30051, 30052)
    ),
    haul_type = 3,
    abundance_haul = "Y",
    sql_channel = sql_channel
  ) # You'll get an age error for this because the age+growth ppl haven't aged anything yet. That is ok!

  # Calculate CPUE
  cpue_dat <- gapindex::calc_cpue(racebase_tables = dat)

  # Save it
  save(cpue_dat, file = "data/rebs_cpue_dat.Rdata")
}


# Setup map components ----------------------------------------------------
reg_dat_goa <- akgfmaps::get_base_layers(
  select.region = "goa",
  set.crs = "EPSG:3338"
)

reg_dat_goa$survey.area <- reg_dat_goa$survey.area |>
  dplyr::mutate(
    SRVY = "GOA",
    color = scales::alpha(colour = "grey80", 0.7),
    SURVEY = "Gulf of Alaska"
  )
reg_dat <- reg_dat_goa

# Make cpue table into an sf thingy

mapdata <- cpue_dat |>
  sf::st_as_sf(
    coords = c("LONGITUDE_DD_START", "LATITUDE_DD_START"),
    crs = "EPSG:4326"
  ) |>
  sf::st_transform(crs = reg_data$crs)



# Create the map!  --------------------------------------------------------
# This could probably be done more simply but I am very much a novice when it comes to maps. So you get the very painstakingly constructed version.

legendtitle <- bquote(log(CPUE(kg / km^2)))

f1 <- ggplot() +
  geom_sf(
    data = reg_dat$akland,
    color = NA,
    fill = "grey40"
  ) +
  # Hauls, but no REBS
  geom_sf( # x's for places where we sampled but didn't catch any of that species
    data = dplyr::filter(mapdata, CPUE_KGKM2 == 0),
    # alpha = 0.5,
    color = "lightblue",
    shape = 19,
    size = 1
  ) +
  # REBS present - you can modify the geoms here to make it just one color, or color by another variable such as depth. I also logged CPUE because there was one HUGE catch in the SE that was swamping all the color in the rest of the map.
  geom_sf(
    data = dplyr::filter(mapdata, CPUE_KGKM2 > 0),
    aes(color = log(CPUE_KGKM2))
  ) +
  scale_color_distiller(legendtitle,
    direction = 1,
    palette = "Oranges"
  )

f2 <- f1 +
  geom_sf(
    data = reg_dat$survey.area,
    fill = NA,
    shape = NA,
    size = .25,
    show.legend = FALSE
  )

# Limit the coords of the map frame
f3 <- f2 +
  ggplot2::scale_y_continuous(
    name = "", # "Latitude",
    limits = reg_dat$plot.boundary$y,
    breaks = reg_dat$lat.breaks
  ) +
  ggplot2::scale_x_continuous(
    name = "", # "Longitude",
    limits = reg_dat$plot.boundary$x,
    breaks = reg_dat$lon.breaks
  )

f4 <- f3 +
  guides(
    size = guide_legend(
      order = 1,
      title.position = "top",
      label.position = "top",
      title.hjust = 0.5,
      nrow = 1
    )
  )

figure <- f4 +
  theme( # set legend position and vertical arrangement
    panel.background = element_rect(
      fill = "white",
      colour = NA
    ),
    panel.border = element_rect(
      fill = NA,
      colour = "grey20"
    ),
    axis.text = element_text(size = 8),
    strip.background = element_blank(),
    strip.text = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    legend.background = element_rect(
      colour = "transparent",
      fill = "transparent"
    ),
    legend.key = element_rect(
      colour = "transparent",
      fill = "transparent"
    ),
    legend.position = "bottom",
    legend.box = "horizontal"
  ) +
  labs(size = legendtitle)


figure

png("rebs_map_logcpue.png", width = 8, height = 5, units = "in", res = 200)
figure
dev.off()