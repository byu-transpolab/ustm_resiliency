library("arsenal")
library("tidyr")
library("tidyverse")
library("sf")
library("leaflet")
library("foreign")
library("maptools")
library("modelr")

# Loading two data sets and a base map from the data folder
# The first data set is the whole network named WHOLE_ROWSUMS.DBF
# The second data set is 01_ROWSUMS.DBF, which should be taken
# from the CUBE model each time a new iteration is run
whole_rowsum <- read.dbf("Data/WHOLE_ROWSUMS.DBF")  #original unbroken network
broken_rowsum <- read.dbf("Data/01_ROWSUMS.DBF")    #altered broken network
map <- st_read("Data/RoanokeTAZ.shp")               #load shapefile

# Calculate the number of differences between data sets
n.diffs(comparedf(whole_rowsum, broken_rowsum))

# Create rowsum_map object and plot the HBW map and data
# for initial visualization
rowsum_map <- left_join(map, broken_rowsum, by = c("ID" = "TAZ"))
plot(rowsum_map[, "LNHBW"])
plot(whole_rowsum[, "LNHBW"])



# Difference comparison

change_broken <- list(
  "Original" = whole_rowsum,
  "Broken Link" = broken_rowsum
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -TAZ) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = (`Broken Link` - Original)
  ) %>%
  select(TAZ, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "TAZ"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])

# Absolute error comparison

change_broken <- list(
  "Original" = whole_rowsum,
  "Broken Link" = broken_rowsum
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -TAZ) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = (abs(`Broken Link` - Original))
  ) %>%
  select(TAZ, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "TAZ"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])

# RMSE comparison <--shows minor change between outer zones

change_broken <- list(
  "Original" = whole_rowsum,
  "Broken Link" = broken_rowsum
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -TAZ) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = sqrt(((Original - `Broken Link`)^2)/nrow(whole_rowsum))
  ) %>%
  select(TAZ, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "TAZ"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])

# Mean absolute error comparison <- shows more change in downtown areas

change_broken <- list(
  "Original" = whole_rowsum,
  "Broken Link" = broken_rowsum
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -TAZ) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = (abs(`Broken Link` - Original)/nrow(whole_rowsum))
  ) %>%
  select(TAZ, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "TAZ"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])

# Mean absolute percentage error <- shows spread out

change_broken <- list(
  "Original" = whole_rowsum,
  "Broken Link" = broken_rowsum
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -TAZ) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = (abs((Original - `Broken Link`)/`Broken Link`))*(1/nrow(whole_rowsum))
  ) %>%
  select(TAZ, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "TAZ"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])


