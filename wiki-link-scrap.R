### This file is used to extract all the wikipedia links to the corresponding film
### This is for us to extract more film-specific details, including box office, release date, etc


### Challenge
# Some of the name of the films in the Wikipedia is not so properly formatted, with an extra space or indent
# We detect that by checking if the number of rows matches (final_df and initial_df)
# It does not match, so we do some trimming to remove whitespaces
# We also do unique to remove duplicates from the web url extraction
# After that, we merge with the df films and reorder to form the final df.


library(stringr)

# Read the dataframe
df <- read.csv("academy.csv")

# 2. The HTML text (representing the file content you provided)
# In a real scenario, use: html_text <- readLines("your_file.html")
html_text <- paste0(readLines("Academy Award for Best Picture - Wikipedia.html", warn = FALSE), collapse = "\n")

# 3. Use Regular Expressions to extract the links and the clean film names
# This pattern looks for the href and the link text inside the italics tags <i>
# Group 1: The URL
# Group 2: The Film Name as it appears in the link text

regex_pattern <- '<i>(?:<b>)?<a href="([^"]+)"[^>]*>([^<]+)</a>'

# Extract all matches from the HTML text
matches <- str_match_all(html_text, regex_pattern)[[1]]

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

# Now perform the merge
final_df <- merge(df, wiki_links_df, by = "film", all.x = TRUE)

# Re-sort and reset index
final_df <- final_df[order(final_df$year), ]
rownames(final_df) <- NULL

head(final_df)
nrow(final_df) == nrow(df)