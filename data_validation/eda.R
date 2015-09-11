library(magrittr)
library(tidyr)
import::from(dplyr, select, mutate, rename, arrange, group_by, summarize, keep_where = filter)

# pageId: "A unique identifier generated per visited page. This allows events from the same page to be correlated."

load("data_validation/Initial.RData")

dupes <- data[data$user_id %in% names(table(users$user_id))[table(users$user_id) == 2], ]
