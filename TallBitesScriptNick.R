#Talladega Bites

remotes::install_github("eco4cast/neon4cast")
library(tidyverse)
library(neon4cast)
library(lubridate)
library(rMR)
library(arrow)
require(ggplot2)
forecast_date <- lubridate::as_date("2016-01-01")  

  # load site data
site_data <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv") |> 
  dplyr::filter(ticks == 1)
tall_data <- site_data[8, ]

  # tick data
ticks_data <- readr::read_csv("https://data.ecoforecast.org/neon4cast-targets/ticks/ticks-targets.csv.gz", guess_max = 1e6)

# The code below slices the data corresponding to the TALL site.
# There will be a merge error because Nick did the same thing, just choose one!
# -Connor
TALL_ticks <- ticks_data[ticks_data$site_id == 'TALL',]

# Add a column that converts the 'date' to a 'month'.
TALL_ticks$month <- month(TALL_ticks$datetime, label=TRUE)

# Plot the data
theme_set(theme_bw())
ggplot(aes(x = datetime, y = observation), data = TALL_ticks) + 
  geom_point()

  # weather data - humidity and temperature
df_past <- neon4cast::noaa_stage3()
weather_stage3 <- neon4cast::noaa_stage3()
as.matrix(weather_stage3 |> 
  dplyr::filter(site_id == "TALL" & variable == "air_temperature") |>
  dplyr::collect())
