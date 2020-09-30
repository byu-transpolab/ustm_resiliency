
library("arsenal")
library("tidyr")
library("tidyverse")
library("sf")
library("leaflet")
library("foreign")
library("maptools")
rowsum <- read.dbf("Data/01_DCLS_ROWSUM.DBF")
rowsum1 <- read.dbf("Data/01_DCLS_ROWSUM1.DBF")
rowsum2 <- read.dbf("Data/01_DCLS_ROWSUM2.DBF")
rowsum3 <- read.dbf("Data/01_DCLS_ROWSUM3.DBF")
rowsum4 <- read.dbf("Data/01_DCLS_ROWSUM4.DBF")

map <- st_read("Data/RoanokeTAZ.shp")

mean(rowsum$LNHBW)
mean(rowsum1$LNHBW)
mean(rowsum2$LNHBW)
mean(rowsum3$LNHBW)
n.diffs(comparedf(rowsum, rowsum4))

rowsum5 <- left_join(map, rowsum4, by = c("ID" = "A"))

plot(rowsum5[, "LNHBW"])
plot(rowsum[, "LNHBW"])


change_broken <- list(
  "Original" = rowsum,
  "Broken Link" = rowsum4
) %>%
  bind_rows(.id = "Scenario") %>%
  as_tibble() %>%
  gather("purpose", "logsum", -Scenario, -A) %>%
  spread(Scenario, logsum, fill = NA) %>%
  mutate(
    difference = (`Broken Link` - Original)
  ) %>%
  select(A, purpose, difference) %>%
  spread(purpose, difference, NA)


broken_map <- left_join(map, change_broken, by = c("ID" = "A"))

plot(broken_map[, c("LNHBO", "LNHBW", "LNREC", "LNHBC", "LNNHB")])

                