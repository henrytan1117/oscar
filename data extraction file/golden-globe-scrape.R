
### This file contains code that extract award history for golden globe awards in the 21st century.

library(rvest)
library(purrr)
library(dplyr)
library(readr)

# ── 1. Scraper function ────────────────────────────────────────────────────────
scrape_gg_films <- function(page) {
  decades <- c("2000s", "2010s", "2020s")
  
  map_dfr(decades, function(decade) {
    table_node <- page %>%
      html_element(xpath = paste0('//div[h3[@id="', decade, '"]]/following-sibling::table[1]'))
    
    if (is.na(table_node)) {
      message("Table not found for decade: ", decade)
      return(NULL)
    }
    
    rows <- table_node %>% html_elements("tr")
    
    map_dfr(rows, function(row) {
      tds <- row %>% html_elements("td")
      if (length(tds) == 0) return(NULL)
      
      film_td   <- tds[[1]]
      style     <- film_td %>% html_attr("style")
      is_winner <- !is.na(style) && grepl("B0C4DE", style, fixed = TRUE)
      
      film_name <- film_td %>% html_element("i") %>% html_text(trim = TRUE)
      if (is.na(film_name) || film_name == "") return(NULL)
      
      tibble(film = film_name, nominated = TRUE, won = is_winner)
    })
  }) %>%
    group_by(film) %>%
    summarise(nominated = any(nominated), won = any(won), .groups = "drop")
}

# ── 2. Scrape both pages ───────────────────────────────────────────────────────
page_drama          <- read_html("Golden_Globe_Drama.html")
page_musical_comedy <- read_html("Golden_Globe_Musical_or_Comedy.html")

gg_drama  <- scrape_gg_films(page_drama)
gg_comedy <- scrape_gg_films(page_musical_comedy)

cat("Drama films scraped:  ", nrow(gg_drama),  "\n")
cat("Comedy films scraped: ", nrow(gg_comedy), "\n")

# ── 3. Load academy list ───────────────────────────────────────────────────────
academy <- read_csv("academy.csv")

# ── 4. Manual name corrections ────────────────────────────────────────────────
manual_map <- tribble(
  ~academy_name,                                      ~gg_name,
  "Birdman or (The Unexpected Virtue of Ignorance)",  "Birdman",
  "Good Night, and Good Luck.",                       "Good Night, and Good Luck",
  "Moulin Rouge",                                     "Moulin Rouge!",
  "Once upon a Time...in Hollywood",                  "Once Upon a Time in Hollywood",
  "Precious: Based on the Novel 'Push' by Sapphire",  "Precious",
  "Three Billboards outside Ebbing, Missouri",        "Three Billboards Outside Ebbing, Missouri"
)

academy_normalised <- academy %>%
  left_join(manual_map, by = c("film" = "academy_name")) %>%
  mutate(film_lookup = coalesce(gg_name, film)) %>%
  select(-gg_name)

# ── 5. Left joins using corrected name as key ─────────────────────────────────
academy_joined <- academy_normalised %>%
  left_join(
    gg_drama %>% rename(gg_drama_nominated = nominated, gg_drama_won = won),
    by = c("film_lookup" = "film")
  ) %>%
  left_join(
    gg_comedy %>% rename(gg_comedy_nominated = nominated, gg_comedy_won = won),
    by = c("film_lookup" = "film")
  ) %>%
  mutate(
    gg_drama_nominated  = coalesce(gg_drama_nominated,  FALSE),
    gg_drama_won        = coalesce(gg_drama_won,        FALSE),
    gg_comedy_nominated = coalesce(gg_comedy_nominated, FALSE),
    gg_comedy_won       = coalesce(gg_comedy_won,       FALSE)
  ) %>%
  select(-film_lookup)  # drop helper, keep original film name

# ── 6. Flag unmatched films for manual review ──────────────────────────────────
unmatched <- academy_joined %>%
  filter(!gg_drama_nominated & !gg_comedy_nominated) %>%
  distinct(film) %>%
  arrange(film)

cat("\n── Films with NO Golden Globe match (manual review needed) ──\n")
print(unmatched, n = Inf)

# ── 7. Quick sanity check ──────────────────────────────────────────────────────
cat("\nColumn summary:\n")
academy_joined %>%
  summarise(across(starts_with("gg_"), sum)) %>%
  print()


# ── 8. Export to CSV ───────────────────────────────────────────────────────────
write_csv(academy_joined, "academy_with_golden_globes.csv")
