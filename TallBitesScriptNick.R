#Talladega Bites

#remotes::install_github("eco4cast/neon4cast")
library(tidyverse)
library(neon4cast)
library(lubridate)
library(rMR)
library(arrow)
require(ggplot2)
forecast_date <- lubridate::as_date("2016-01-01")  

  ## load site data
site_data <- readr::read_csv("https://raw.githubusercontent.com/eco4cast/neon4cast-targets/main/NEON_Field_Site_Metadata_20220412.csv") |> 
  dplyr::filter(ticks == 1)
tall_data <- site_data[8, ]

  # tick data
ticks_data <- readr::read_csv("https://data.ecoforecast.org/neon4cast-targets/ticks/ticks-targets.csv.gz", guess_max = 1e6)
TALL_ticks <- ticks_data[ticks_data$site_id == 'TALL',]

# weather data - humidity and temperature - only goes as far back as september 2020
weather_stage3 <- neon4cast::noaa_stage3()
airtemp_hist <- as.matrix(weather_stage3 |> 
                            dplyr::filter(site_id == "TALL", variable == "air_temperature")|>
                            dplyr::rename(ensemble = parameter) |>
                            dplyr::select(datetime, prediction, ensemble) |>
                            dplyr::mutate(date = as_date(datetime)) |>
                            dplyr::group_by(date) |>
                            dplyr::summarize(air_temperature = mean(prediction, na.rm = TRUE),
                                             .groups = "drop") |>
                            dplyr::rename(datetime = date) |>
                            dplyr::mutate(air_temperature = air_temperature - 273.15) |>
                            dplyr::collect())
humidity_hist <- as.matrix(weather_stage3 |> 
                             dplyr::filter(site_id == "TALL", variable == "relative_humidity")|>
                             dplyr::rename(ensemble = parameter) |>
                             dplyr::select(datetime, prediction, ensemble) |>
                             dplyr::mutate(date = as_date(datetime)) |>
                             dplyr::group_by(date) |>
                             dplyr::summarize(relative_humidity = mean(prediction, na.rm = TRUE),
                                              .groups = "drop") |>
                             dplyr::rename(datetime = date) |>
                             dplyr::collect())

##Visualize the data
# Add a column that converts the 'date' to a 'month'.
TALL_ticks$month <- month(TALL_ticks$datetime, label=TRUE)

# add another column for year
TALL_ticks$year <- year(TALL_ticks$datetime)

# Plot the data
theme_set(theme_bw())
ggplot(aes(x = datetime, y = observation), data = TALL_ticks) + 
  geom_point()

# converting airtemp into data frame
airtemp <- data.frame(airtemp_hist)
colnames(airtemp) <- c("datetime", "air_temperature")
airtemp$air_temperature  <- as.numeric(airtemp$air_temperature)
airtemp$datetime  <- as.Date(airtemp$datetime)


#plotting air temp
theme_set(theme_bw())
ggplot(aes(x = datetime, y = air_temperature), data = airtemp) + 
  geom_point()

# converting humidity into data frame
humidity <- data.frame(humidity_hist)
colnames(humidity) <- c("datetime", "rel_humidity")
humidity$rel_humidity  <- as.numeric(humidity$rel_humidity)
humidity$datetime  <- as.Date(humidity$datetime)

#plotting air temp
theme_set(theme_bw())
ggplot(aes(x = datetime, y = rel_humidity), data = humidity) + 
  geom_point()




## optional visuals for tick counts
#visualize tick data w/ box/whisker plot by month
ggplot(TALL_ticks, aes(x = month, y = observation)) +
  geom_boxplot(fill = "lightblue", outlier.colour = "red") +
  geom_jitter(width = 0.2, alpha = 0.5, color = "darkblue") +
  labs(title = "Tick Counts by Month",
       x = "Month",
       y = "Tick Count") +
  theme_bw()

#tick data w/ violin plot by month
ggplot(TALL_ticks, aes(x = month, y = observation)) +
  geom_violin(fill = "lightgreen") +
  geom_jitter(width = 0.2, alpha = 0.5, color = "darkblue") +
  scale_y_log10() +
  labs(title = "Tick Counts by Month (Log Scale)",
       x = "Month",
       y = "Tick Count (log scale)") +
  theme_bw()

#visualize tick data with line plot using monthly means
monthly_mean <- TALL_ticks %>%
  group_by(month) %>%
  summarize(mean_ticks = mean(observation, na.rm = TRUE))

ggplot(monthly_mean, aes(x = month, y = mean_ticks, group = 1)) +
  geom_line(color = "darkgreen") +
  geom_point(color = "darkred", size = 3) +
  labs(title = "Mean Tick Counts by Month",
       x = "Month",
       y = "Mean Tick Count") +
  theme_bw()

#visualize monthly tick data/trends by year
monthly_yearly <- TALL_ticks %>%
  group_by(year, month) %>%
  summarize(mean_ticks = mean(observation, na.rm = TRUE), .groups = "drop")
# Plot the data with a separate line for each year on the same graph
ggplot(monthly_yearly, aes(x = month, y = mean_ticks, group = year, color = as.factor(year))) +
  geom_line() +
  geom_point() +
  labs(title = "Monthly Tick Trends by Year",
       x = "Month",
       y = "Mean Tick Count",
       color = "Year") +
  theme_bw()


#visualize tick data using heatmap by month and year
ggplot(monthly_yearly, aes(x = month, y = as.factor(year), fill = mean_ticks)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c() +
  labs(title = "Heatmap of Mean Tick Counts by Month and Year",
       x = "Month",
       y = "Year",
       fill = "Mean Tick Count") +
  theme_minimal()

#visualize tick data using facet boxplots by month and year
ggplot(TALL_ticks, aes(x = month, y = observation)) +
  geom_boxplot(fill = "lightblue", outlier.colour = "red") +
  facet_wrap(~ year, ncol = 3) +
  labs(title = "Distribution of Tick Counts by Month and Year",
       x = "Month",
       y = "Tick Count") +
  theme_bw()
