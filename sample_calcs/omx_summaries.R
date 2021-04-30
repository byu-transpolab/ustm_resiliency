library(tidyverse)
library(foreign)
library(omxr)
library(rhdf5)
library(rhdf5filters)
library(Rhdf5lib)

#read in omx files from cube outputs
resiliency_costs <- 'C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/TRAVELTIMEresiliency50COSTS.OMX'
ustm_costs <- 'C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/TRAVELTIME50COSTS.OMX'
base_trips <- 'C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/COMBINED_TRIPS0.OMX'
scen_trips <- 'C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/COMBINED_TRIPS50.OMX'
tooele_trips <- 'C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/COMBINED_TRIPS_50.OMX'

#list all names of matrices in omx file
list_omx(resiliency_costs)

#read in scenario matrices as dataframes
base_trips_hbw <- read_all_omx(base_trips, c("HBWauto"))
base_trips_hbo <- read_all_omx(base_trips, c("HBOauto"))
base_trips_nhb <- read_all_omx(base_trips, c("NHBauto"))
scen_trips_hbw <- read_all_omx(scen_trips, c("HBW"))
scen_trips_hbo <- read_all_omx(scen_trips, c("HBO"))
scen_trips_nhb <- read_all_omx(scen_trips, c("NHB"))

taz <- foreign::read.dbf("Data/TAZ.dbf") %>% tibble()

co_base_hbw <- base_trips_hbw %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>% 
  group_by(or_county, de_county) %>%
  summarize(HBW = sum(HBWauto, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

co_base_hbo <- base_trips_hbo %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBO = sum(HBOauto, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

co_base_nhb <- base_trips_nhb %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(NHB = sum(NHBauto, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

co_scen_hbw <- scen_trips_hbw %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBW = sum(HBW, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

co_scen_hbo <- scen_trips_hbo %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBO = sum(HBO, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

co_scen_nhb <- scen_trips_nhb %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(NHB = sum(NHB, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

base_trips_hbw <- read_all_omx(base_trips, c("HBWauto"))
base_trips_hbo <- read_all_omx(base_trips, c("HBOauto"))

resiliency_hbw <- read_all_omx(resiliency_costs, c("HBW"))
resiliency_hbo <- read_all_omx(resiliency_costs, c("HBO"))
resiliency_nhb <- read_all_omx(resiliency_costs, c("NHB"))
resiliency_rec <- read_all_omx(resiliency_costs, c("REC"))
resiliency_xxp <- read_all_omx(resiliency_costs, c("XXP"))
resiliency_xxf <- read_all_omx(resiliency_costs, c("XXF"))
resiliency_ixf <- read_all_omx(resiliency_costs, c("IXF"))
resiliency_iif <- read_all_omx(resiliency_costs, c("IIF"))


resiliency_cost_tooele_slc_hbw <- resiliency_hbw %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBW = sum(HBW, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_hbo <- resiliency_hbo %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBO = sum(HBO, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_nhb <- resiliency_nhb %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(NHB = sum(NHB, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_rec <- resiliency_rec %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(REC = sum(REC, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_xxp <- resiliency_xxp %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(XXP = sum(XXP, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_xxf <- resiliency_xxf %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(XXF = sum(XXF, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_ixf <- resiliency_ixf %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(IXF = sum(IXF, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

resiliency_cost_tooele_slc_iif <- resiliency_iif %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(IIF = sum(IIF, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_costs_hbw <- read_all_omx(ustm_costs, c("HBW"))
ustm_costs_hbo <- read_all_omx(ustm_costs, c("HBO"))
ustm_costs_nhb <- read_all_omx(ustm_costs, c("NHB"))
tooele_trips_hbw <- read_all_omx(tooele_trips, c("HBW"))
tooele_trips_hbo <- read_all_omx(tooele_trips, c("HBO"))
tooele_trips_nhb <- read_all_omx(tooele_trips, c("NHB"))
tooele_trips_rec <- read_all_omx(tooele_trips, c("REC"))
tooele_trips_xxp <- read_all_omx(tooele_trips, c("Pass"))
tooele_trips_xxf <- read_all_omx(tooele_trips, c("XXF"))
tooele_trips_ixf <- read_all_omx(tooele_trips, c("IXF"))
tooele_trips_iif <- read_all_omx(tooele_trips, c("Freight"))

ustm_cost_tooele_slc_hbw <- tooele_trips_hbw %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBW = sum(HBW, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_cost_tooele_slc_hbo <- ustm_costs_hbo %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(HBO = sum(HBO, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_cost_tooele_slc_nhb <- tooele_trips_nhb %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(NHB = sum(NHB, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_cost_tooele_slc_rec <- tooele_trips_rec %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(REC = sum(REC, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_cost_tooele_slc_Pass <- tooele_trips_xxp %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(Pass = sum(Pass, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")

ustm_cost_tooele_slc_freight <- tooele_trips_iif %>%
  left_join(taz %>% select(origin = TAZID, or_county = CO_NAME)) %>%
  left_join(taz %>% select(destination = TAZID, de_county = CO_NAME)) %>%
  group_by(or_county, de_county) %>%
  summarize(Freight = sum(Freight, na.rm = TRUE)) %>%
  filter(or_county == "TOOELE")
