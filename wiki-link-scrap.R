### This file is used to extract all the wikipedia links to the corresponding film
### This is for us to extract more film-specific details, including box office, release date, etc


### Challenge
# Some of the name of the films in the Wikipedia is not so properly formatted, with an extra space or indent
# We detect that by checking if the number of rows matches (final_df and initial_df)
# It does not match, so we do some trimming to remove whitespaces
# We also do unique to remove duplicates from the web url extraction
# After that, we merge with the df films and reorder to form the final df.

### Challenge
# Some of film names in the present has the same name as the film in the past
# Hence we are extracting the wrong link

### Challenge
# Some wikipedias have different format (around 10 of time), with an extra <i> and </i>


library(stringr)

# Read the dataframe
df <- read.csv("academy.csv")

# 2. The HTML text (representing the file content you provided)
# In a real scenario, use: html_text <- readLines("your_file.html")
html_text <- paste0(readLines("Academy Award for Best Picture - Wikipedia.html", warn = FALSE), collapse = "\n")


# --- NEW SLICING STEP ---
# This looks for the 2000s header and keeps only the text AFTER it.
# We search for the unique ID 'id="2000s"'
split_html <- str_split(html_text, 'id="2000s"')[[1]]

if (length(split_html) > 1) {
  # Keep the second part of the split (everything after the 2000s ID)
  html_filtered <- split_html[2]
} else {
  # Fallback if the ID isn't found
  message("Warning: 2000s section marker not found. Using full text.")
  html_filtered <- html_full
}

# 3. Use Regular Expressions to extract the links and the clean film names
# This pattern looks for the href and the link text inside the italics tags <i>
# Group 1: The URL
# Group 2: The Film Name as it appears in the link text

regex_pattern <- '<i>(?:<b>)?<a href="(https://en.wikipedia.org/wiki/[^"]+)"[^>]*>(?:<i>)?([^<]+)(?:</i>)?</a>'


# Extract all matches from the HTML text
matches <- str_match_all(html_filtered, regex_pattern)[[1]]

# After extracting the matches...
wiki_links_df <- data.frame(
  wiki_link = matches[, 2],
  film = matches[, 3],
  stringsAsFactors = FALSE
)

### Removing formatting issues


# Trim whitespace to prevent "invisible" duplicates (e.g., "Traffic" vs "Traffic ")
wiki_links_df$film <- trimws(wiki_links_df$film)
df$film <- trimws(df$film)

# Keep only unique film/link pairs
wiki_links_df <- unique(wiki_links_df)

# If a film STILL has two different links (rare), keep only the first one
wiki_links_df <- wiki_links_df[!duplicated(wiki_links_df$film), ]

### Correct the name before merging
# Manually, error in the wikipedia name, change it to match with master academy file

wiki_links_df[52,2] <- 'Precious: Based on the Novel \'Push\' by Sapphire'
wiki_links_df[68,2] <- 'Extremely Loud & Incredibly Close'
wiki_links_df[126,2] <- 'Three Billboards outside Ebbing, Missouri'
wiki_links_df[143,2] <- 'Once upon a Time...in Hollywood'

# Now perform the merge
final_df <- merge(df, wiki_links_df, by = "film", all.x = TRUE)

# Re-sort and reset index
final_df <- final_df[order(final_df$year), ]
rownames(final_df) <- NULL

head(final_df)
nrow(final_df) == nrow(df)

# Export as CSV
write.csv(final_df, "wiki-link.csv", row.names=FALSE)
