library(jsonlite)
library(tidyverse)
library(lubridate)

latitude <- 27.3364
longitude <- -82.5307
end_date <- Sys.Date() - 1
start_date <- end_date - 6

api_url <- paste0(
  "https://archive-api.open-meteo.com/v1/archive?",
  "latitude=", latitude,
  "&longitude=", longitude,
  "&start_date=", start_date,
  "&end_date=", end_date,
  "&hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code",
  "&temperature_unit=fahrenheit",
  "&wind_speed_unit=mph",
  "&precipitation_unit=inch",
  "&timezone=America%2FNew_York"
)

weather <- fromJSON(api_url)$hourly |>
  as_tibble() |>
  mutate(
    time = ymd_hm(time, tz = "America/New_York"),
    date = as.Date(format(time, "%Y-%m-%d", tz = "America/New_York")),
    hour = hour(time),
    weather = case_when(
      weather_code == 0 ~ "Clear",
      weather_code %in% c(1, 2, 3) ~ "Cloudy",
      weather_code %in% c(45, 48) ~ "Fog",
      weather_code %in% c(51, 53, 55, 56, 57) ~ "Drizzle",
      weather_code %in% c(61, 63, 65, 66, 67) ~ "Rain",
      weather_code %in% c(71, 73, 75, 77) ~ "Snow",
      weather_code %in% c(80, 81, 82) ~ "Showers",
      weather_code %in% c(95, 96, 99) ~ "Thunderstorm",
      TRUE ~ "Other"
    )
  ) |>
  select(time, date, hour, temperature_2m, relative_humidity_2m,
         precipitation, wind_speed_10m, weather)

names(weather) <- c(
  "time", "date", "hour", "temperature_f", "humidity_percent",
  "precipitation_in", "wind_mph", "weather"
)

 dir.create("data", showWarnings = FALSE)
write_csv(weather, "data/sarasota-weather.csv")
message("Saved ", nrow(weather), " hourly observations to data/sarasota-weather.csv")
