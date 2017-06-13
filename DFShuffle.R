## Shuffling the original data frame based on a column

x <- data.frame("SN" = 1:5, "Age" = c(6,6 ,7,9 ,10), "Name" = c("John", "Dora", "Lim", "Patrick", "Peter"), stringsAsFactors = FALSE)
(shuffled <- x[sample(1:NROW(x$SN)),])
(x$shuffled = shuffled$Age)
x$Age = NULL
# x

## Generating a sequence and appending it to an original vector
desc <- seq(from = 0.0005, to = 1, by = 0.0001)
desc
vect <- c(1, 2)
vectDesc <- append(vect, desc)
vectDesc
