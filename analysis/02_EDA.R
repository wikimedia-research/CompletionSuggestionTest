load("data_validation/Processed.RData")

library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)
library(ggplot2)
library(wmf)
library(ggfortify)

load('Processed_20151019.RData')

top_n <- function(x, n = 10) {
  return(names(head(sort(table(x), decreasing = TRUE), n)))
}
simplify_factor <- function(x, n = 10) {
  return(ifelse(x %in% top_n(x, n), as.character(x), 'Other'))
}

dir.create('figures')

ggprops <- function(data, var_name, var_title) {
  data[[var_name]] %<>% simplify_factor
  proportions <- data %>%
    dplyr::group_by_(var_name) %>%
    summarize(`controls (opensearch)` = (function(x) { sum(x)/length(x) })(event_bucket == "opensearch"),
              `test (cirrus-suggest)` = (function(x) { sum(x)/length(x) })(event_bucket == "cirrus-suggest"),
              `se` = (function(x) {
                p <- sum(x)/length(x)
                q <- sum(!x)/length(x)
                n <- length(x)
                return(sqrt(p*q/n))
              })(event_bucket == "opensearch")) %>%
    tidyr::gather(group, proportion, 2:3)
  return(ggplot(data = proportions,
                aes_string(y = "proportion", x = var_name, fill = "group")) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
    scale_x_discrete(name = var_title) +
    geom_errorbar(aes(ymax = proportion + 2 * se, ymin = proportion - 2 * se),
                  position = position_dodge(width = 0.9), width = 0.25) +
    theme_fivethirtynine())
}

ggsave(plot = ggprops(users, 'browser_major', 'Browser') +
         ggtitle("Differences in bucketing across top 10 browsers"),
       file = "figures/proportions_browser_major.png",
       width = 15, height = 5, dpi = 150)
ggsave(plot = ggprops(users, 'browser', 'Browser') +
         ggtitle("Differences in bucketing across top 10 browsers"),
       file = "figures/proportions_browser.png",
       width = 15, height = 5, dpi = 150)
ggsave(plot = ggprops(users, 'wiki', 'wiki') +
         ggtitle("Differences in bucketing"),
       file = "figures/proportions_wiki.png",
       width = 5, height = 5, dpi = 150)

outcomes <- users %>%
  group_by(event_bucket, `any nonzero`, `any zero`, `last event's results`) %>%
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

ggplot(data = outcomes, aes(x = outcome, y = n, fill = event_bucket)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_continuous(name = "Users") +
  wmf::theme_fivethirtynine()

ggplot(data = keep_where(outcomes, outcome == 'some zero & nonzero results'),
       aes(x = `last event's results`, y = n, fill = event_bucket)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_continuous(name = "Users") +
  wmf::theme_fivethirtynine()

df_to_tbl <- function(x) {
  y <- as.table(as.matrix(x[1:2, 2:3]))
  rownames(y) <- as.character(x[[1]])
  return(y)
}
flip_rows <- function(x) x[rev(1:nrow(x)), ]
flip_cols <- function(x) x[, rev(1:ncol(x))]

bcda_battery <- function(x) {
  # Runs the full battery of BCDA tools
  return(list(Probabilities = BCDA::est_multinom(x),
              `Test of Independence` = BCDA::test_indepen(x),
              `Difference of Proportions` = BCDA::ci_prop_diff_tail(x),
              `Relative Risk` = BCDA::ci_relative_risk(x),
              `Odds Ratio` = BCDA::ci_odds_ratio(x)))
}

outcomes %>%
  keep_where(outcome == 'some zero & nonzero results') %>%
  select(c(event_bucket, `last event's results`, n)) %>%
  tidyr::spread(`last event's results`, n) %>%
  df_to_tbl %>%
  bcda_battery

outcomes %>%
  keep_where(outcome != 'some zero & nonzero results') %>%
  select(c(event_bucket, outcome, n)) %>%
  tidyr::spread(outcome, n) %>%
  df_to_tbl %>%
  bcda_battery
