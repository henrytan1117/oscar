
### This file contains code that convert information scrapped from rotten tomato into data frame
### and format the data types.


library(stringr)
library(readr)

# ── 1. Load saved HTML ─────────────────────────────────────────────────────────
raw_html <- readRDS("raw_html.rds")

# ── 2. Helpers ─────────────────────────────────────────────────────────────────
extract_info <- function(movie_info, label) {
  block <- str_extract(movie_info, paste0('(?s)data-qa="item-label">', label, '</rt-text>.*?</dd>'))
  vals  <- str_extract_all(block, '(?<=data-qa="item-value">)[^<]+')[[1]]
  if (length(vals) == 0) return(NA_character_)
  paste(str_trim(vals), collapse = ", ")
}

parse_html <- function(x) {
  sc <- x$scorecard
  mi <- x$movie_info
  
  release_year <- as.integer(str_extract(mi, '(?s)Release Date.*?(\\d{4})', group = 1))
  year_check   <- abs(as.integer(x$year) - release_year)
  year_flag    <- is.na(release_year) | (!is.na(year_check) & year_check > 1)
  
  data.frame(
    film               = x$film,
    year               = x$year,
    url                = x$url,
    tomatometer        = str_extract(sc, 'slot="critics-score"[^>]*>(\\d+)%',             group = 1),
    tomatometer_count  = str_extract(sc, '(\\d+)(?= Reviews)',                             group = 1),
    popcornmeter       = str_extract(sc, 'slot="audience-score"[^>]*>(\\d+)%',            group = 1),
    popcornmeter_count = str_trim(str_extract(sc, '(?s)slot="audience-reviews"[^>]*>\\s*([^<]+?)\\s*Ratings', group = 1)),
    director           = extract_info(mi, "Director"),
    genre              = extract_info(mi, "Genre"),
    rating             = extract_info(mi, "Rating"),      # ← new
    original_language  = extract_info(mi, "Original Language"),
    release_year       = release_year,
    stringsAsFactors   = FALSE
  )
}

# ── 3. Parse ───────────────────────────────────────────────────────────────────
message("── Phase 2: Parsing HTML ────────────────────────────────────────────")
results    <- lapply(raw_html, parse_html)
results_df <- dplyr::bind_rows(results)

print(names(results_df))

# ── 4. Flag year mismatches (kept for console review, not written to CSV) ──────
year_check <- abs(as.integer(results_df$year) - results_df$release_year)
year_flag  <- is.na(results_df$release_year) | (!is.na(year_check) & year_check > 1)

flagged <- results_df[which(year_flag), c("film", "year", "release_year", "url")]
message(sprintf("\n── %d year-mismatched films ──────────────────────────────────────────", nrow(flagged)))
print(flagged)

# ── 5. Save ────────────────────────────────────────────────────────────────────
write_csv(results_df, "academy_rt_results.csv")
message("\nSaved to academy_rt_results.csv")

# ── 6. Check NAs ───────────────────────────────────────────────────────────────
key_cols <- c("tomatometer", "tomatometer_count", "popcornmeter", "popcornmeter_count",
              "director", "genre", "rating", "original_language", "release_year")

na_summary <- sapply(key_cols, function(col) sum(is.na(results_df[[col]])))
message("\n── NA counts per column ──────────────────────────────────────────────")
print(na_summary)

na_tomatometer <- results_df[is.na(results_df$tomatometer), c("film", "year", "url")]
message(sprintf("\n── %d films missing tomatometer ──────────────────────────────────────", nrow(na_tomatometer)))
print(na_tomatometer)