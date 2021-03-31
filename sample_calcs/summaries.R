library(tidyverse)
library(foreign)

scenarios_folder <- "C:projcts/ustm_resiliency/sample_calcs/OUTPUTS/"

# read hh productions by purpose 
prod <- read.dbf(file.path(scenarios_folder, "HH_PROD.DBF")) %>%
  as_tibble() %>%
  gather(purpose, productions, -TAZ) %>%
  mutate(purpose = gsub("P", "", purpose))


# read scenario_outputs
outputs <- dir(scenarios_folder)

logsums <- lapply(outputs[outputs != "HH_PROD.DBF"], function(scenario){
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


summary_table %>%
  select(purpose, scenario, pct_delta) %>%
  spread(purpose, pct_delta)  %>%
  arrange(-HBW)

