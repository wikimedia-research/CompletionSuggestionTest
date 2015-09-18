library(wmf)
library(RMySQL)
library(magrittr)
library(uaparser) # uaparser::update_regexes()

mysql_read <- function(query, database){
  con <- dbConnect(drv = RMySQL::MySQL(),
                   host = "analytics-store.eqiad.wmnet",
                   dbname = database,
                   default.file = "/etc/mysql/conf.d/research-client.cnf")
  to_fetch <- dbSendQuery(con, query)
  data <- fetch(to_fetch, -1)
  dbClearResult(dbListResults(con)[[1]])
  dbDisconnect(con)
  return(data)
}

# Fetch data
data <- mysql_read("SELECT * FROM CompletionSuggestions_13630018", database = "log") # use on stat1002 or stat1003

# Parse UA info
data_ua <- uaparser::parse_agents(data$userAgent)
data <- cbind(data, data_ua)
rm(data_ua)

# Perform some data transformations
data$browser_major <- paste(data$browser, data$browser_major) %>% factor
data$user_id <- paste(data$event_pageViewToken, data$userAgent, sep = '~') %>%
  factor %>% as.numeric %>% factor
data$timestamp %<>% lubridate::ymd_hms()
data$event_bucket %<>% factor
data$event_pageViewToken %<>% factor
data$device %<>% factor
data$os %<>% factor
data$browser %<>% factor
data$results <- factor(data$event_numResults > 0, c(FALSE, TRUE), c("0", "1+"))

# Throw away columns we don't need
data <- data[order(data$user_id, data$timestamp), ]
data <- data[, c('timestamp', 'user_id', 'wiki', 'event_bucket',
                 'event_numResults', 'results',
                 'device', 'os', 'browser', 'browser_major')]


# Save data
save(list = c('data'), file = '~/CompletionSuggestionTest_2015-09-18/Initial.RData')

## Download the data
# scp stat3:/home/bearloga/CompletionSuggestionTest_2015-09-18/Initial.RData ~/Documents/Projects/CompletionSuggestionTest/data_validation/

## Locally:
library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)


load("data_validation/Initial.RData")

source("~/Documents/Projects/UserSatisfaction/T112269_survanalysis/utils.R")
data <- cbind(data, parse_wiki(data$wiki))
data$wiki <- paste(ifelse(is.na(data$language), "", paste0(data$language, " ")),
                   data$project, sep = "") %>% factor
rm(prefixes, parse_wiki, get_data)

users <- unique(data[, c('user_id', 'event_bucket', 'device', 'os', 'browser', 'browser_major', 'wiki', 'project', 'language')])
events <- data[, c('timestamp', 'user_id', 'event_numResults', 'results')]
rm(data)

users <- events %>%
  group_by(user_id) %>%
  summarize(`any nonzero` = any(event_numResults > 0),
            `any zero` = any(event_numResults == 0),
            `last event's results` = tail(event_numResults, 1) > 0) %>%
  mutate(`any nonzero` = factor(`any nonzero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`any zero` = factor(`any zero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`last event's results` = factor(`last event's results`, c(TRUE, FALSE), c("1+", "0"))) %>%
  dplyr::left_join(users, ., by = "user_id")

save(list = c('users', 'events'), file = 'data_validation/Processed.RData')
