top_n <- function(x, n = 10) {
  return(names(head(sort(table(x), decreasing = TRUE), n)))
}
simplify_factor <- function(x, n = 10) {
  return(ifelse(x %in% top_n(x, n), as.character(x), 'Other'))
}
df_to_tbl <- function(x) {
  y <- as.table(as.matrix(x[1:2, 2:3]))
  rownames(y) <- as.character(x[[1]])
  return(y)
}
flip_rows <- function(x) x[rev(1:nrow(x)), ]
flip_cols <- function(x) x[, rev(1:ncol(x))]

ggprops <- function(data, var_name, var_title, n = 10) {
  data[[var_name]] %<>% simplify_factor(n)
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
           scale_y_continuous(name = "Proportion", labels = scales::percent_format()) +
           geom_errorbar(aes(ymax = proportion + 2 * se, ymin = proportion - 2 * se),
                         position = position_dodge(width = 0.9), width = 0.25) +
           wmf::theme_fivethirtynine() + theme(rect = element_blank()))
}

bcda_battery <- function(x) {
  # Runs the full battery of BCDA tools
  return(list(Probabilities = BCDA::est_multinom(x),
              `Test of Independence` = BCDA::test_indepen(x),
              `Difference` = BCDA::ci_prop_diff_tail(x),
              `Relative Risk` = BCDA::ci_relative_risk(x),
              `Odds Ratio` = BCDA::ci_odds_ratio(x)))
}

format_bcda_battery <- function(x, comments = rep('', 3)) {
  format_ci <- function(ci) {
    sprintf("(%.3f,&nbsp;%.3f)", ci[1], ci[2])
  }
  temp <- data.frame(Value = apply(as.data.frame(x[3:5]), 2, format_ci),
                     stringsAsFactors = FALSE)
  temp <- rbind(sprintf("%.3f", x[[2]]$`Bayes Factor`), temp)
  rownames(temp) <- c('Bayes Factor', paste("95% C.I. for", names(x)[3:5]))
  temp$Comment = c(x[[2]]$Interpretation, comments)
  return(knitr::kable(temp))
}

format_table <- function(x, units = "") {
  if ( all(x <= 1) ) {
    y <- as.table(matrix(sprintf("%.2f%%", 100*addmargins(x)), nrow = nrow(x)+1, ncol = ncol(x)+1))
  } else {
    y <- as.table(matrix(sprintf("%.0f (%.1f%%)", addmargins(x), 100*addmargins(BCDA::est_multinom(x))), nrow = nrow(x)+1, ncol = ncol(x)+1))
  }
  dimnames(y) <- lapply(dimnames(x), . %>% c(., "sum"))
  return(y)
}
