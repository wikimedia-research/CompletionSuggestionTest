load("data_validation/Processed.RData")

library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)

library(ggplot2)
library(wmf)
library(ggfortify)

top_browsers <- users %>%
  group_by(browser_major) %>%
  summarize(n = n()) %>%
  dplyr::top_n(10, n) %>%
  select(browser_major) %>%
  unlist %>%
  as.character
ggsave(plot = ggplot(data = keep_where(users, browser_major %in% top_browsers),
                     aes(x = browser_major, fill = event_bucket)) +
         geom_bar(position = "dodge") +
         scale_x_discrete(name = "Browser") +
         theme_fivethirtynine(),
       filename = "data_validation/browsers.png", width = 10, height = 6)
