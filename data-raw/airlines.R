library(dplyr)
library(readr)
library(RCurl)

if (url.exists("https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_haVdhR_PNeeVRef")) {
  raw <- read_csv("https://www.transtats.bts.gov/Download_Lookup.asp?Y11x72=Y_haVdhR_PNeeVRef")
} else stop("Can't access `airlines` link in 'data-raw/airlines.R'")


load("data/flights.rda")

airlines <- raw %>%
  select(carrier = Code, name = Description) %>%
  semi_join(flights) %>%
  arrange(carrier)

write_csv(airlines, "data-raw/airlines.csv")
save(airlines, file = "data/airlines.rda", compress = "bzip2")
