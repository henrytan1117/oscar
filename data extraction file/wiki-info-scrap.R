library(stringr)

df <- read.csv("wiki-link.csv")

# --- 1. DEFINE THE SCRAPER FUNCTION ---
# This function takes one URL, reads the HTML, and extracts all metrics
scrape_movie_details <- function(wiki_url) {
  
  # Error handling: Try to read the page; return NAs if the link fails
  html_text <- tryCatch({
    paste(readLines(wiki_url, warn = FALSE), collapse = "\n")
  }, error = function(e) return(NULL))
  
  if (is.null(html_text)) {
    return(data.frame(Running_Time = NA, Countries = NA, 
                      Budget = NA, Box_Office = NA, Director = NA))
  }
  
  # i) Running time (Flexible for <div><th> or <th>)
  running_time <- str_match(html_text, '>Running time</div></th><td class="infobox-data">(\\d+) minutes')[,2]
  
  # ii) Budget
  budget <- str_match(html_text, 'Budget</th>.*?<td[^>]*>([^<]+)<')[,2]
  budget <- str_replace_all(budget, '<[^>]+>', '') # Clean potential tags
  
  # iii) Box office
  box_office <- str_match(html_text, '>Box office</th>.*?<td[^>]*>([^<]+)<')[,2]
  box_office <- str_replace_all(box_office, '<[^>]+>', '')
  
  # iv) Director name
  director_name <- str_match(html_text, 'Directed by</th>.*?<td[^>]*><a[^>]*>([^<]+)</a>')[,2]
  
  # Return as a single row data frame
  return(data.frame(
    Running_Time = running_time,
    Budget = budget,
    Box_Office = box_office,
    Director = director_name,
    stringsAsFactors = FALSE
  ))
}

# --- 2. THE LOOP ---
# Assume 'final_df' is your dataframe with the 'wiki_link' column
# Creating a results container
results_list <- list()

for (i in 1:nrow(df)) {
  url <- df$wiki_link[i]
  film_name <- df$film[i]
  
  message(paste0("Scraping (", i, "/", nrow(df), "): ", film_name))
  
  # Call our function
  movie_details <- scrape_movie_details(url)
  
  # Add the film name back to the row
  movie_details$film <- film_name
  
  # Store in list
  results_list[[i]] <- movie_details
  
  # Polite Scraping: Pause for 0.5 seconds to avoid being blocked by Wikipedia
  Sys.sleep(0.5)
}

# --- 3. COMBINE EVERYTHING ---

# Stack all the rows into one big data frame
movie_stats_df <- do.call(rbind, results_list)

# Merge back with your original data if you want all original columns (like year/winner)
final_complete_df <- merge(df, movie_stats_df, by = "film")
# Sort by the 'year' column
final_complete_df <- final_complete_df[order(final_complete_df$year), ]

# Optional: Reset the index (row names) so they are 1, 2, 3...
rownames(final_complete_df) <- NULL

# View the final product
head(final_complete_df)

write.csv(final_complete_df, "wiki-info-scrap.csv", row.names=F)









