library(omxr)
library(tidyverse)
library(Matrix)
library(R.matlab)

skim_file <- "data/1Skm_TotTransitTime_Pk.mtx.omx"

# get a list of all the matrix names
cores <- list_omx(skim_file)
matrix_names <- cores$Matrices$name[1:12]

print(matrix_names)

# read each matrix based on its name, and put the value in a list
skims <- lapply(matrix_names, function (name){
  read_omx(skim_file, name) %>% gather_matrix(value_name = "time")
}) 

names(skims) <- matrix_names # name the list elements with our matrix names

# Bind and spread
skims_df <- skims %>%
  bind_rows(.id = "skim") %>%
  mutate(time = ifelse(time == 0, NA, time)) %>% # convert zero transit time to NA
  pivot_wider(names_from = skim, values_from = time)

# find minimum
skims_min <- skims_df %>%
  add_column(mintime = NA) %>%
  mutate(mintime = pmin(d4time, d5time, d6time, d7time, d8time, d9time, w4time, w5time, w6time, w7time, w8time, w9time, na.rm=TRUE)) %>% # find minimum value
  mutate_all(~replace(., is.na(.), 0)) # replace NA back to 0


# join the WFRC <--> USTM zone crosswalk
crosswalk <- read.csv("data/NodeEquiv_WF2.csv") # node equivalency for WFRC to USTM


# renaming the columns & removing the unnecessary one
names(crosswalk) <- sub("X.PrevNode", "origin", names(crosswalk))
names(crosswalk) <- sub("New_Node", "USTM_origin", names(crosswalk))
crosswalk2 = subset(crosswalk, select = -c(Type) )

# duplicating the information but for the destinations
crosswalk3 <- crosswalk2
names(crosswalk3) <- sub("origin", "destination", names(crosswalk3))
names(crosswalk3) <- sub("USTM_origin", "USTM_destination", names(crosswalk3))

# merging the crosswalk and skim by origin and by destination
joined <- merge(crosswalk2, skims_min, by = "origin")
joined2 <- merge(crosswalk3, joined, by = "destination")

# removing the WFRC origins and destinations
USTM_Transit = subset(joined2, select = c(USTM_origin,USTM_destination, mintime) )

#deleting external values, where there aren't USTM zones for the WFRC ones
USTM_Transit2 <- USTM_Transit[!rowSums(USTM_Transit > 20000),] 

all_zones <- expand.grid(x = 1:8775, y = 1:8775)
zones <- expand.grid(x = c(3867:6724), y = c(3867:6724)) %>% mutate(time = USTM_Transit2$mintime) 
USTM_Transit3 <- left_join(all_zones, zones, by = c("x", "y"))


# getting the right format
USTM_Transit4 <- USTM_Transit3 %>%
  add_column(matrix = 1) %>% 
  mutate_all(~replace(., is.na(.), 0))
  
USTM_Transit5 <- USTM_Transit4[,c("x", "y", "matrix", "time")]
  
## Writing to new file

write.table(USTM_Transit5, file = "USTM_transit_skimNEW.csv", row.names = FALSE, col.names = FALSE, sep = ",")

