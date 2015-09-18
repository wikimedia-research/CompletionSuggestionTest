load("data_validation/Processed.RData")

library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)

library(ggplot2)
library(wmf)
library(ggfortify)

# Browsers
top_browsers <- users %>%
  group_by(browser_major) %>%
  summarize(n = n()) %>%
  dplyr::top_n(10, n) %>%
  select(browser_major) %>%
  unlist %>%
  as.character
ggsave(plot = ggplot(data = keep_where(users, browser_major %in% top_browsers),
                     aes(x = browser_major, fill = event_bucket)) +
         geom_bar(position = dodge) +
         scale_x_discrete(name = "Browser") +
         theme_fivethirtynine(),
       filename = "data_validation/browsers.png", width = 10, height = 6)

# By wiki
proportions <- users %>%
  group_by(wiki) %>%
  summarize(`controls (opensearch)` = (function(x) { sum(x)/length(x) })(event_bucket == "opensearch"),
            `test (cirrus-suggest)` = (function(x) { sum(x)/length(x) })(event_bucket == "cirrus-suggest"),
            `se` = (function(x) {
              p <- sum(x)/length(x)
              q <- sum(!x)/length(x)
              n <- length(x)
              return(sqrt(p*q/n))
            })(event_bucket == "opensearch")) %>%
  tidyr::gather(group, proportion, 2:3)
ggsave(plot = ggplot(data = proportions,
                     aes(y = proportion, x = wiki, fill = group)) +
         geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
         scale_x_discrete(name = "Browser") +
         geom_errorbar(aes(ymax = proportion + 2 * se, ymin = proportion - 2 * se),
                       position = position_dodge(width = 0.9), width = 0.25) +
         theme_fivethirtynine(),
       filename = "data_validation/wiki.png", width = 5, height = 5)
