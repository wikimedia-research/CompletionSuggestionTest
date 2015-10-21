library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)

load("CompletionSuggestionTest_20151019.RData")

# Perform some data transformations
data$browser_major <- paste(data$browser, data$browser_major) %>% factor
# data$user_id <- paste(data$clientIp, data$userAgent) %>%
#   factor %>% as.numeric %>% factor
data$timestamp %<>% lubridate::ymd_hms()
data <- data[order(data$event_pageViewToken, data$timestamp), ]

data$event_bucket %<>% factor
data$event_pageViewToken %<>% factor
data$user_id <- factor(as.numeric(data$event_pageViewToken))

data$device %<>% factor
data$os %<>% factor
data$browser %<>% factor

data$results <- factor(data$event_numResults > 0, c(FALSE, TRUE), c("0", "1+"))

# Throw away columns we don't need
data <- data[, c('user_id', 'timestamp', 'wiki', 'event_bucket',
                 'event_numResults', 'results',
                 'device', 'os', 'browser', 'browser_major')]

## Not needed because the only two wikis are enwiki & dewiki:
# source("~/Documents/Projects/Discovery Research/User Satisfaction/T112269_survanalysis/utils.R")
# data <- cbind(data, parse_wiki(data$wiki))
# data$wiki <- paste(ifelse(is.na(data$language), "", paste0(data$language, " ")),
#                    data$project, sep = "") %>% factor
# rm(prefixes, parse_wiki, get_data)

data$wiki %<>% factor(c('enwiki', 'dewiki'), c('English Wikipedia', 'German Wikipedia'))

# Number of users who were put into two different buckets:
# dual_bucketeers <- data[, c('user_id' ,'event_bucket')] %>%
#   unique %>% { .$user_id } %>% table %>% { .[. > 1] }
# length(dual_bucketeers) # 1294
# data$bucket_membership <- factor(ifelse(data$user_id %in% names(dual_bucketeers), 'Dual', 'Single'))
# rm(dual_bucketeers)

# Number of users who used different wikis:
# dual_wikis <- data[, c('user_id' ,'wiki')] %>%
#   unique %>% { .$user_id } %>% table %>% { .[. > 1] }
# length(dual_wikis) # 579
# data$wiki_usage <- factor(ifelse(data$user_id %in% names(dual_wikis), 'Dual', 'Single'))
# rm(dual_wikis)

# data %<>% mutate(Valid = bucket_membership == 'Single' & wiki_usage == 'Single')
# table(ifelse(data$Valid, 'Valid', 'Invalid'))
# valid_data <- data %>% keep_where(Valid) %>% select(-c(bucket_membership, wiki_usage, Valid))

users <- unique(data[, c('user_id', 'event_bucket', 'device', 'os', 'browser', 'browser_major', 'wiki')])
events <- data[, c('timestamp', 'user_id', 'event_numResults', 'results')]
rm(data)

users <- events %>%
  group_by(user_id) %>%
  summarize(`any nonzero` = any(event_numResults > 0),
            `any zero` = any(event_numResults == 0),
            `last event's results` = tail(event_numResults, 1) > 0,
            majority = round(sum(event_numResults == 1)/length(event_numResults)),
            majority = factor(majority, 0:1, c('majority zero', 'majority nonzero'))) %>%
  mutate(`any nonzero` = factor(`any nonzero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`any zero` = factor(`any zero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`last event's results` = factor(`last event's results`, c(TRUE, FALSE), c("1+", "0"))) %>%
  dplyr::left_join(users, ., by = "user_id")

outcomes <- users %>%
  group_by(event_bucket, wiki, `any nonzero`, `any zero`, `last event's results`, majority) %>%
  summarize(n = n()) %>%
  dplyr::ungroup() %>%
  mutate(`any nonzero` = ifelse(`any nonzero` == 'Yes', 'some', 'no'),
         `any zero` = ifelse(`any zero` == 'Yes', 'some', 'no'),
         `last event's results` = ifelse(`last event's results` == '1+',
                                         'last event: nonzero result', 'last event: zero results'))
outcomes$outcome <- ""
outcomes$outcome[outcomes$`any nonzero` == 'some' & outcomes$`any zero` == 'some'] <- 'some zero & nonzero results'
outcomes$outcome[outcomes$`any nonzero` == 'no'] <- 'zero results only'
outcomes$outcome[outcomes$`any zero` == 'no'] <- 'nonzero results only'

save(list = c('users', 'events', 'outcomes'), file = 'Processed_20151019.RData')

rm(list = ls())
