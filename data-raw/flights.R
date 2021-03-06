library(dplyr)
library(readr)
library(RCurl)

last_year <- as.numeric(substr(Sys.time(), 1, 4)) - 1

flight_url <- function(year = last_year, month) {
  base_url <- "http://www.transtats.bts.gov/PREZIP/"
  sprintf(paste0(base_url, "On_Time_On_Time_Performance_%d_%d.zip"), year, month)
}

download_month <- function(year = last_year, month) {
  url <- flight_url(year, month)
  if (url.exists(url)) {
    temp <- tempfile(fileext = ".zip")
    download.file(url, temp)
  } else stop(sprintf("Can't access `flights` link in 'data-raw.flights.R' for month %d (%s) in %d. \n Check date of 'Latest Available Data' for 'Airline On-Time Performance Data' on \n https://www.transtats.bts.gov/releaseinfo.asp", month, month.name[month], year))

  files <- unzip(temp, list = TRUE)
  # Only extract biggest file
  csv <- files$Name[order(files$Length, decreasing = TRUE)[1]]

  unzip(temp, exdir = "data-raw/flights", junkpaths = TRUE, files = csv)

  src <- paste0("data-raw/flights/", csv)
  dst <- paste0("data-raw/flights/", last_year, "-", month, ".csv")
  file.rename(src, dst)
}

months <- 1:12
needed <- paste0(last_year, "-", months, ".csv")
missing <- months[!(needed %in% dir("data-raw/flights"))]

lapply(missing, download_month, year = last_year)

get_nyc <- function(path) {
  col_types <- cols(
    DepTime = col_integer(),
    ArrTime = col_integer(),
    CRSDepTime = col_integer(),
    CRSArrTime = col_integer(),
    Carrier = col_character(),
    UniqueCarrier = col_character()
  )
  suppressWarnings(read_csv(path, col_types = col_types)) %>%
    select(
      year = Year, month = Month, day = DayofMonth,
      dep_time = DepTime, sched_dep_time = CRSDepTime, dep_delay = DepDelay,
      arr_time = ArrTime, sched_arr_time = CRSArrTime, arr_delay = ArrDelay,
      carrier = Carrier,  flight = FlightNum, tailnum = TailNum,
      origin = Origin, dest = Dest,
      air_time = AirTime, distance = Distance
    ) %>%
    filter(origin %in% c("JFK", "LGA", "EWR")) %>%
    mutate(
      hour = sched_dep_time %/% 100,
      minute = sched_dep_time %% 100,
      time_hour = lubridate::make_datetime(year, month, day, hour, 0, 0)
    ) %>%
    arrange(year, month, day, dep_time)
}

all <- lapply(dir("data-raw/flights", full.names = TRUE), get_nyc)
flights <- bind_rows(all)
flights$tailnum[flights$tailnum == ""] <- NA

dir.create("data", showWarnings = FALSE)
save(flights, file = "data/flights.rda", compress = "bzip2")
