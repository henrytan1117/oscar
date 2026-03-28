library(rvest)
library(dplyr)
library(readr)

# ── 1. Parse the HTML ──────────────────────────────────────────────────────────
page <- read_html("best_film_editing.html")

# All nomination blocks
details <- page |> html_elements("div.result-details")

# Extract film title and whether it's a winner (has a glyphicon-star)
editing_data <- lapply(details, function(detail) {
  film <- detail |>
    html_element("div.awards-result-film-title a") |>
    html_text(trim = TRUE)
  
  is_winner <- length(html_elements(detail, "span.glyphicon-star")) > 0
  
  if (!is.na(film) && nchar(film) > 0) {
    data.frame(film = film, editing_winner = is_winner)
  }
}) |>
  bind_rows()

# ── 2. Collapse to one row per film ───────────────────────────────────────────
editing_summary <- editing_data |>
  group_by(film) |>
  summarise(
    nominated_for_film_editing = TRUE,
    awarded_for_film_editing   = any(editing_winner),
    .groups = "drop"
  )

# ── 3. Load academy.csv and join ──────────────────────────────────────────────
academy <- read_csv("academy.csv")

academy_enriched <- academy |>
  left_join(editing_summary, by = "film") |>
  mutate(
    nominated_for_film_editing = replace_na(nominated_for_film_editing, FALSE),
    awarded_for_film_editing   = replace_na(awarded_for_film_editing,   FALSE)
  )

# ── 4. Save ───────────────────────────────────────────────────────────────────
write_csv(academy_enriched, "academy_with_editing.csv")

# ── 5. Quick sanity check ─────────────────────────────────────────────────────
cat("Nominated for editing:", sum(academy_enriched$nominated_for_film_editing), "\n")
cat("Awarded for editing:  ", sum(academy_enriched$awarded_for_film_editing),   "\n")

academy_enriched |>
  filter(winner == TRUE, awarded_for_film_editing == TRUE)
