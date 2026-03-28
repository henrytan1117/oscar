library(rvest)
library(tidyverse)

page <- read_html("best_director.html")
tables <- page %>% html_nodes("table.wikitable")

results <- list()

for (table in tables) {
  rows <- table %>% html_nodes("tr")
  current_year <- NA
  
  for (row in rows) {
    th <- row %>% html_node("th[scope='row']")
    if (!is.null(th)) {
      text <- th %>% html_text(trim = TRUE)
      # Extract first 4-digit year e.g. "1927/28(1st)" → 1927
      yr <- str_extract(text, "\\d{4}")
      if (!is.na(yr)) current_year <- as.integer(yr)
    }
    
    tds <- row %>% html_nodes("td")
    if (length(tds) < 2 || is.na(current_year)) next
    
    director_td <- tds[[1]]
    
    link <- director_td %>% html_node("a")
    director <- if (!is.null(link)) {
      link %>% html_text(trim = TRUE)
    } else {
      director_td %>% html_text(trim = TRUE)
    }
    
    director <- str_remove_all(director, "\\[.*?\\]") %>% str_trim()
    if (is.na(director) || director == "") next
    
    style <- director_td %>% html_attr("style")
    status <- if (!is.na(style) && str_detect(style, "FAEB86")) "award" else "nomination"
    
    results[[length(results) + 1]] <- tibble(year = current_year, director = director, status = status)
  }
}

bd <- bind_rows(results)

cat("Total rows:", nrow(bd), "\n")
cat("Winners:", sum(bd$status == "award"), "\n")
print(head(bd, 15))


# matching and merging
academy_rt <- read_csv("academy_rt_results.csv") %>%
  select(film, director, year)

bd_counts <- academy_rt %>%
  left_join(bd, by = "director", suffix = c("_film", "_bd"), relationship = "many-to-many") %>%
  group_by(film, director, year = year_film) %>%
  summarise(
    bd_award_no_concurrent     = sum(year_bd < year_film  & status == "award",      na.rm = TRUE),
    bd_award_yes_concurrent    = sum(year_bd <= year_film & status == "award",      na.rm = TRUE),
    bd_nominate_no_concurrent  = sum(year_bd < year_film  & status == "nomination", na.rm = TRUE),
    bd_nominate_yes_concurrent = sum(year_bd <= year_film & status == "nomination", na.rm = TRUE),
    .groups = "drop"
  )

# Join back to original to preserve row order
result <- academy_rt %>%
  left_join(bd_counts, by = c("film", "director", "year"))

cat("Rows:", nrow(result), "\n")
write_csv(result, "film_director_bd_wins.csv")









