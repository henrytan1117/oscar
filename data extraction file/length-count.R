
### This file contains code that calculate word and character count for each film.

academy1 <- read.csv("academy_final.csv")
academy2 <- academy1[,1]
head(academy2)

# 1. Count Number of Characters (including spaces/punctuation)
char_count <- nchar(academy2)

# 2. Count Number of Words (phrases)
# We use stringr for a very straightforward approach
# install.packages("stringr") # Uncomment if not installed
library(stringr)
word_count <- str_count(academy2, "\\w+")

# Create a summary table to see the results clearly
movie_analysis <- data.frame(
  film = academy2,
  characters = char_count,
  words = word_count
)

head(movie_analysis)

# write.csv(movie_analysis, "name-length.csv", row.names = FALSE)

# Merge with the current dataset
result <- merge(academy1, movie_analysis, by = "film")
result <- result[order(result$release_year), ]
write.csv(result, "academy_final.csv", row.names = FALSE)


