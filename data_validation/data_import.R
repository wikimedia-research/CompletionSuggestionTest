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
data <- mysql_read("SELECT * FROM CompletionSuggestions_13424343", database = "log") # use on stat1002 or stat1003

# Parse UA info
data_ua <- uaparser::parse_agents(data$userAgent)
data <- cbind(data, data_ua)
rm(data_ua)

# Perform some data transformations
data$browser_major <- paste(data$browser, data$browser_major) %>% factor
data$user_id <- paste(data$clientIp, data$os, data$browser_major, data$wiki, sep = ':') %>%
  factor %>% as.numeric %>% factor
data$timestamp %<>% lubridate::ymd_hms()
data$event_bucket %<>% factor
data$event_logId %<>% factor
data$event_pageId %<>% factor
data$device %<>% factor
data$os %<>% factor
data$browser %<>% factor
data$results <- factor(data$event_numResults > 0, c(FALSE, TRUE), c("0", "1+"))

# Check for duplicated events:
table(table(data$event_logId)) # 2506 of 1s, so we're good

# Throw away columns we don't need
data <- data[, c('timestamp', 'wiki', 'user_id', 'event_bucket',
                 'event_numResults', 'results','event_pageId',
                 'device', 'os', 'browser', 'browser_major')]
data <- data[order(data$user_id, data$event_pageId, data$timestamp), ]

users <- unique(data[, c('user_id', 'wiki', 'event_bucket', 'device', 'os', 'browser', 'browser_major')])
dual_citizens <- 
events <- data[, c('timestamp', 'user_id', 'wiki', 'event_numResults', 'results', 'event_pageId')]

data <- data[!duplicated(data[, c('user_id', 'event_numResults', 'event_pageId')]), ]

# Save data
save(list = 'data', file = '~/CompletionSuggestionTest_2015-09-10/Initial.RData')

## Download the data
# scp stat3:/home/bearloga/CompletionSuggestionTest_2015-09-10/Initial.RData ~/Documents/Projects/CompletionSuggestionTest/data_validation/
