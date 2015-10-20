set.seed(0)
n <- 1e8
x1 <- character(n) # Current method
x2 <- rbinom(n, 1, 1/5000)
x2[x2 == 1] <- sample(letters[1:2], size = sum(x2), replace = TRUE)
x2[x2 == 0] <- NA
for ( i in 1:n ) {
  if ( rbinom(1, 1, 1/1e4) ) {
    x1[i] <- 'a'
  } else if ( rbinom(1, 1, 1/9999) ) {
    x1[i] <- 'b'
  } else {
    x1[i] <- NA
  }
}
