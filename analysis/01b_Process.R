library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)

load("CompletionSuggestionTest_20151019.RData")

# Perform some data transformations
data$browser_major <- paste(data$browser, data$browser_major) %>% factor
data$user_id <- paste(data$clientIp, data$userAgent) %>%
  factor %>% as.numeric %>% factor
data$timestamp %<>% lubridate::ymd_hms()
data <- data[order(data$user_id, data$timestamp), ]

data %>%
  keep_where(timestamp > lubridate::ymd('2015-09-16') & timestamp < lubridate::ymd('2015-10-19')) %>%
  group_by(user_id, event_pageViewToken, event_bucket) %>%
  summarize(`events_per_pageViewToken` = n()) %>%
  group_by(`user_id`) %>%
  summarize(`pageViewTokens per user` = n()) %>%
  mutate(`pageViewTokens per user` = ifelse(`pageViewTokens per user` < 10,
                                            `pageViewTokens per user`, '10')) %>%
  group_by(`pageViewTokens per user`) %>%
  summarize(n = n()) %>%
  mutate(`pageViewTokens per user` = as.numeric(`pageViewTokens per user`)) %>%
  arrange(`pageViewTokens per user`) %>%
  { .$`pageViewTokens per user` <- factor(.$`pageViewTokens per user`, 1:10, c(1:9, '10+')); . } %>%
  mutate(proportion = n/sum(n)) %>%
  ggplot(data = ., aes(x = `pageViewTokens per user`, y = proportion)) +
  geom_bar(stat = "identity") +
  ggtitle('Distribution of pageViewTokens per user for EL data recorded between 09/16 and 10/19') +
  geom_text(aes(label = sprintf("%.0f (%.1f%%)", n, 100*proportion), y = proportion + 0.025)) +
  scale_y_continuous(name = "Proportion of users", labels = scales::percent_format()) +
  wmf::theme_fivethirtynine()

data %>%
  group_by(user_id, event_pageViewToken, event_bucket) %>%
  summarize(`events_per_pageViewToken` = n()) %>%
  group_by(`user_id`) %>%
  summarize(`pageViewTokens per user` = n()) %>%
  keep_where(`pageViewTokens per user` > 1) %>%
  dplyr::left_join(data[, c('user_id', 'timestamp')]) %>%
  group_by(user_id) %>%
  summarize(`session length` = as.numeric(max(timestamp) - min(timestamp))) %>%
  summary()
  ggplot(data = ., aes(x = `session length`)) +
  geom_histogram() +
  scale_x_continuous(name = "max(timestamp) - min(timestamp) (in hours)") +
  scale_y_continuous(name = "Users") +
  ggtitle("Session length for clientIp+userAgent groupings with 2+ unique pageViewTokens") +
  wmf::theme_fivethirtynine()

data %>%
  select(user_id, event_bucket) %>%
  unique() %>%
  group_by(user_id) %>%
  summarize(`buckets per user` = n()) %>%
  group_by(`buckets per user`) %>%
  summarize(users = n()) %>%
  mutate(prop = 100*users/sum(users))

data %>%
  select(user_id, wiki) %>%
  unique() %>%
  group_by(user_id) %>%
  summarize(`wikis per user` = n()) %>%
  group_by(`wikis per user`) %>%
  summarize(users = n()) %>%
  mutate(prop = 100*users/sum(users))

data$event_bucket %<>% factor
data$event_pageViewToken %<>% factor

data$device %<>% factor
data$os %<>% factor
data$browser %<>% factor

data$results <- factor(data$event_numResults > 0, c(FALSE, TRUE), c("0", "1+"))

# Throw away columns we don't need
data <- data[, c('timestamp', 'user_id', 'wiki', 'event_bucket',
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
dual_bucketeers <- data[, c('user_id' ,'event_bucket')] %>%
  unique %>% { .$user_id } %>% table %>% { .[. > 1] }
length(dual_bucketeers) # 1294
data$bucket_membership <- factor(ifelse(data$user_id %in% names(dual_bucketeers), 'Dual', 'Single'))
rm(dual_bucketeers)

# Number of users who used different wikis:
dual_wikis <- data[, c('user_id' ,'wiki')] %>%
  unique %>% { .$user_id } %>% table %>% { .[. > 1] }
length(dual_wikis) # 579
data$wiki_usage <- factor(ifelse(data$user_id %in% names(dual_wikis), 'Dual', 'Single'))
rm(dual_wikis)

data %<>% mutate(Valid = bucket_membership == 'Single' & wiki_usage == 'Single')
table(ifelse(data$Valid, 'Valid', 'Invalid'))

valid_data <- data %>% keep_where(Valid) %>% select(-c(bucket_membership, wiki_usage, Valid))

users <- unique(valid_data[, c('user_id', 'event_bucket', 'device', 'os', 'browser', 'browser_major', 'wiki', 'project', 'language')])
events <- valid_data[, c('timestamp', 'user_id', 'event_numResults', 'results')]
rm(data)

majority <- 

users <- events %>%
  group_by(user_id) %>%
  summarize(`any nonzero` = any(event_numResults > 0),
            `any zero` = any(event_numResults == 0),
            `last event's results` = tail(event_numResults, 1) > 0,
            `majority nonzero` = sum(event_numResults)) %>%
  mutate(`any nonzero` = factor(`any nonzero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`any zero` = factor(`any zero`, c(TRUE, FALSE), c("Yes", "No"))) %>%
  mutate(`last event's results` = factor(`last event's results`, c(TRUE, FALSE), c("1+", "0"))) %>%
  dplyr::left_join(users, ., by = "user_id")

save(list = c('users', 'events'), file = 'Processed_20151019.RData')

rm(list = ls())
