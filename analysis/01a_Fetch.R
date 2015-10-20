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

# Save data
save(list = 'data', file = 'Data/CompletionSuggestionTest_20151019.RData')
q(save = "no")

## Download the data
# scp stat3:/home/bearloga/Data/CompletionSuggestionTest_20151019.RData ~/Documents/Projects/Discovery\ Tests/Completion\ Suggester/
