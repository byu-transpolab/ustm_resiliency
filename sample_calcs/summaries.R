library(tidyverse)
library(foreign)
library(omxr)
library(rhdf5)
library(rhdf5filters)
library(Rhdf5lib)

#move files to correct folder for each scenario
file.copy(from="D:/road49/Output/01_ROWSUMS.DBF", to= "C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/ROAD49ROWSUM.DBF")

#link folder for files and add constants
scenarios_folder <- "C:/projects/ustm_resiliency/sample_calcs/OUTPUTS/"
mc_cost_coef <- -0.0016
taz <- foreign::read.dbf("Data/TAZ.dbf") %>% tibble()

# read hh productions by purpose 
prod <- read.dbf(file.path(scenarios_folder, "HH_PROD.DBF")) %>%
  as_tibble() %>%
  gather(purpose, productions, -TAZ) %>%
  mutate(purpose = gsub("P", "", purpose))

# read scenario_outputs for logsum
outputs <- list.files(scenarios_folder, pattern = "\\.DBF$")

#create function that inputs logsums from different scenarios
logsums <- lapply(outputs[outputs != ("HH_PROD.DBF")], function(scenario){
    # get scenario name
    scenario_name <- gsub("ROWSUM.DBF", "", scenario)
    logsums <- read.dbf(file.path(scenarios_folder, scenario))  %>%
      as_tibble() %>%
      gather(purpose, logsum, -TAZ) %>%
      mutate(
        scenario = scenario_name,
        purpose = gsub("LN", "", purpose))
}) %>%
  bind_rows()


summary_table <- logsums %>%
  left_join(prod, by = c("purpose", "TAZ")) %>%
  mutate( total = productions * logsum ) %>%
  group_by(purpose, scenario) %>%
  summarise(total = sum(total)) %>%
  spread(scenario, total, fill = 0) %>%
  gather(scenario, total, -purpose, -BASE) %>%
  mutate(
    delta = total - BASE,
    pct_delta = delta / BASE * 100
  ) 


summary_table1 <- summary_table %>%
  #filter(purpose!= "REC") %>%
  select(purpose, scenario, pct_delta) %>%
  spread(purpose, pct_delta)  %>%
  arrange(-HBW)

tibble(
  summary_table1 %>%
    select(-HBC)
) %>%
  knitr::kable(caption = "Total Benefit accross Utah", format = "markdown")

total_costs <- summary_table %>%
  group_by(scenario) %>%
  summarise(total_delta = sum(delta)) %>%
  mutate(
    value = total_delta / mc_cost_coef
  ) %>% 
  arrange(value)
  
total_costs1 <-total_costs[-1,]


tibble(
  total_costs1)%>%
  knitr::kable(caption = "Cost associated with closure per day", format = "markdown", digits = 2) 

#compute logsum by location
logsum_scenario50 <- read.dbf('C:/projects/ustm_resiliency/Base/road50/Output/01_ROWSUMS.DBF')
logsum_internal <- logsum_scenario50[-c(1:30),] %>%
  rename(TAZID = TAZ)

#figuring out why HBO is positive
logsums %>% filter(purpose == "NHB") %>%
  filter(scenario %in% c("BASE", "ROAD44"))%>%
  pivot_wider(values_from = logsum, names_from = scenario)%>%
  mutate(diff = ROAD44 - BASE, totdiff = sum(diff)) %>%
  arrange(-diff)


write_rds(logsums, 'C:/projects/ustm_resiliency/sample_calcs/logsum_table.rds')
#logsum origin destination county calculations, need to adjust tables first so that I can join
#them together and end up with a table that has all the desired information in it

#TAZID, purpose, value
table3 <- logsum_internal %>% 
  pivot_longer(
    cols = starts_with("LN"),
    names_to = "purpose"
  ) %>%
  mutate(
    purpose = gsub("LN", "", purpose))

# add CO_NAME and productions
table1 <- left_join(taz, prod, by = c("TAZID" = "TAZ")) %>%
  select(TAZID, CO_NAME, purpose, productions) %>%
  left_join(logsums, by = c("TAZID" = "TAZ", "purpose"))

#compute total, delta, pct_delta
logsum_costs <- table1 %>%
  group_by(CO_NAME, purpose)%>%
  pivot_wider(names_from = scenario, values_from = logsum)%>%
  pivot_longer(cols = matches("ROAD"), names_to = "scenario", names_prefix = "ROAD", values_to = "logsum")%>%
  mutate(
    total = productions * logsum,
    basetotal = productions * BASE,
    delta = total - basetotal,
    pct_delta = delta / basetotal * 100)%>%
  filter(basetotal > 0)

# get total delta and cost associated with closure by county
logsum_summary <- logsum_costs %>%
  group_by(CO_NAME, purpose, scenario) %>%
  summarise(total_delta = sum(delta)) %>%
  mutate(
    cost_value = total_delta / mc_cost_coef)
logsum_summary



#change whole rowsums table to display info by county for each scenario
#TAZID, purpose, value

logsum_internal_all <- logsums%>%
  rename(TAZID = TAZ)

table3_all <- logsum_internal_all %>% 
  pivot_longer(
    cols = starts_with("LN"),
    names_to = "purpose"
  ) %>%
  mutate(
    purpose = gsub("LN", "", purpose))

# add CO_NAME and productions
table1_all <- left_join(taz, prod, by = c("TAZID" = "TAZ")) %>%
  select(TAZID, CO_NAME, purpose, productions) %>%
  left_join(logsums, by = c("TAZID" = "TAZ", "purpose"))

#compute total, delta, pct_delta
logsum_costs_all <- table1_all %>%
  group_by(CO_NAME, purpose)%>%
  pivot_wider(names_from = scenario, values_from = logsum)%>%
  pivot_longer(cols = matches("ROAD"), names_to = "scenario", names_prefix = "ROAD", values_to = "logsum")%>%
  mutate(
    total = productions * logsum,
    basetotal = productions * BASE,
    delta = total - basetotal,
    pct_delta = delta / basetotal * 100)%>%
  filter(basetotal > 0)

# get total delta and cost associated with closure by county
#logsum_summary_all <- 
logsum_costs_all %>%
  group_by(CO_NAME, purpose, scenario) %>%
  summarise(total_delta = sum(delta)) %>%
  mutate(
    cost_value = total_delta / mc_cost_coef * 1 / 100
  ) %>% 
  select(-total_delta) %>% 
  pivot_wider(names_from = scenario, names_prefix = "Road ", values_from = cost_value)
logsum_summary_all

