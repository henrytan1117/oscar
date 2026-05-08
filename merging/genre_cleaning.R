
### This file cleaned the genre columns and convert them into individual genres binary indicator.


dat <- read.csv("academy_final.csv")
head(dat$genre, 5)

# clean raw genre strings: normalize &amp; -> & 
dat$genre <- gsub("&amp;", "&", dat$genre)

# meta data about the genre
# split on ", " to preserve compound genres like "Mystery & Thriller" as one token
all_genres <- unlist(strsplit(dat$genre, ", "))
all_genres <- trimws(all_genres)

# count occurrences of each distinct genre
genre_counts <- sort(table(all_genres), decreasing = TRUE)
print(genre_counts)

# get unique genre names (ordered by frequency)
unique_genres <- names(genre_counts)
unique_genres

# preview film and genre columns
head(dat[, c("film", "genre")])

# create binary indicator column for each genre
for (g in unique_genres) {
  # make safe column name e.g. "Mystery & Thriller" -> "genre_Mystery___Thriller"
  col_name <- paste0("genre_", gsub("[^a-zA-Z0-9]", "_", g))
  dat[[col_name]] <- as.integer(grepl(g, dat$genre, fixed = TRUE))
}

# sanity check: look at genre indicators for first few rows
head(dat[, c("film", "genre", paste0("genre_", gsub("[^a-zA-Z0-9]", "_", unique_genres)))])
# drop all duplicate characters/words columns, keep only the final ones
dat <- dat[, !grepl("characters\\..*|words\\..*", names(dat))]
write.csv(dat, "academy_final.csv", row.names = FALSE)

