erik_query <- "SELECT *,
                 (UNIX_TIMESTAMP(max_real_timestamp) - UNIX_TIMESTAMP(min_real_timestamp))/60/60 AS diff_hr
               FROM (
                 SELECT *,
                   CONCAT(SUBSTR(max_timestamp,1,4), '-', SUBSTR(max_timestamp, 5, 2), '-', SUBSTR(max_timestamp, 7, 2), ' ', SUBSTR(max_timestamp, 9, 2), ':', SUBSTR(max_timestamp, 11, 2), ':', SUBSTR(max_timestamp, 13,2)) as max_real_timestamp,
                   CONCAT(SUBSTR(min_timestamp,1,4), '-', SUBSTR(min_timestamp, 5, 2), '-', SUBSTR(min_timestamp, 7, 2), ' ', SUBSTR(min_timestamp, 9, 2), ':', SUBSTR(min_timestamp, 11, 2), ':', SUBSTR(min_timestamp, 13,2)) as min_real_timestamp
                 FROM (
                   SELECT clientIp, SUBSTR(userAgent, 20),
                     MIN(timestamp) AS min_timestamp, MAX(timestamp) AS max_timestamp,
                     COUNT(DISTINCT(event_pageViewToken)) AS count
                   FROM CompletionSuggestions_13630018
                   WHERE timestamp BETWEEN '20151012230900' AND '20151019230900'
                   GROUP BY clientIp, userAgent
                   HAVING count >= 2
                 ) AS x
               ) AS y
               ORDER BY diff_hr ASC LIMIT 100;"

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
  keep_where(`pageViewTokens per user` > 2) %>%
  dplyr::left_join(data[, c('user_id', 'timestamp')]) %>%
  group_by(user_id) %>%
  summarize(`session length` = difftime(max(timestamp), min(timestamp), unit = 'days'),
            `session length` = as.numeric(`session length`)) %>%
  arrange(desc(`session length`)) %>%
  ggplot(data = ., aes(x = `session length`)) +
  geom_histogram() +
  scale_x_continuous(name = "max(timestamp) - min(timestamp) (in days)") +
  scale_y_continuous(name = "Users") +
  ggtitle("max(ts)-min(ts) for clientIp+userAgent groupings with 3+ unique pageViewTokens") +
  wmf::theme_fivethirtynine()
