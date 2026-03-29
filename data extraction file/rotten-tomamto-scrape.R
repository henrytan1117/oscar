library(httr)
library(stringr)
library(readr)

# ── 1. Load data ───────────────────────────────────────────────────────────────
academy <- read_csv("academy.csv")
films   <- unique(academy[, c("film", "year")])

# ── 2. Title → RT slug ────────────────────────────────────────────────────────
make_slug <- function(title) {
  title |>
    tolower() |>
    str_replace_all("[''']", "")       |>
    str_replace_all("[^a-z0-9 ]", " ") |>
    str_squish()                        |>
    str_replace_all(" ", "_")
}

slug_overrides <- c(
  "1917"                                               = "1917_2019",
  "All Quiet on the Western Front"                     = "all_quiet_on_the_western_front_2022",
  "Amour"                                              = "amour_2013",
  "Argo"                                               = "argo_2012",
  "Arrival"                                            = "arrival_2016",
  "Birdman or (The Unexpected Virtue of Ignorance)"   = "birdman_2014",
  "Black Panther"                                      = "black_panther_2018",
  "Black Swan"                                         = "black_swan_2010",
  "Capote"                                             = "1151898-capote",
  "CODA"                                               = "coda_2021",
  "Crash"                                              = "1144992-crash",
  "Darkest Hour"                                       = "darkest_hour_2017",
  "Don't Look Up"                                      = "dont_look_up_2021",
  "Dune"                                               = "dune_2021",
  "Dunkirk"                                            = "dunkirk_2017",
  "Emilia Pérez"                                       = "emilia_perez",
  "Extremely Loud & Incredibly Close"                  = "extremely_loud_and_incredibly_close",
  "Fences"                                             = "fences_2016",
  "Frankenstein"                                       = "frankenstein_2025",
  "Frost/Nixon"                                        = "frostnixon",
  "Gravity"                                            = "gravity_2013",
  "Her"                                                = "her",
  "I'm Still Here"                                     = "im_still_here_2024",
  "Joker"                                              = "joker_2019",
  "Les Misérables"                                     = "les_miserables_2012",
  "Lincoln"                                            = "lincoln_2011",
  "Lion"                                               = "lion_2016",
  "Little Women"                                       = "little_women_2019",
  "Maestro"                                            = "maestro_2023",
  "Mank"                                               = "mank",
  "Marriage Story"                                     = "marriage_story_2019",
  "Moonlight"                                          = "moonlight_2016",
  "Moulin Rouge"                                       = "moulin_rouge_2001",
  "Nightmare Alley"                                    = "nightmare_alley_2021",
  "Once upon a Time...in Hollywood"                    = "once_upon_a_time_in_hollywood",
  "Oppenheimer"                                        = "oppenheimer_2023",
  "Parasite"                                           = "parasite_2019",
  "Precious: Based on the Novel 'Push' by Sapphire"   = "precious",
  "Roma"                                               = "roma_2018",
  "Room"                                               = "room_2015",
  "Sinners"                                            = "sinners_2025",
  "Spotlight"                                          = "spotlight_2015",
  "Tár"                                                = "tar_2022",
  "The Aviator"                                        = "aviator",
  "The Curious Case of Benjamin Button"                = "curious_case_of_benjamin_button",
  "The Descendants"                                    = "the_descendants_2011",
  "The Father"                                         = "the_father_2020",
  "The Hours"                                          = "hours",
  "The Pianist"                                        = "pianist",
  "The Reader"                                         = "reader",
  "The Revenant"                                       = "the_revenant_2015",
  "The Secret Agent"                                   = "the_secret_agent_2025",
  "The Shape of Water"                                 = "the_shape_of_water_2017",
  "The Theory of Everything"                           = "the_theory_of_everything_2014",
  "The Wolf of Wall Street"                            = "the_wolf_of_wall_street_2013",
  "Traffic"                                            = "1103281-traffic",
  "True Grit"                                          = "true_grit_2010",
  "Up in the Air"                                      = "up_in_the_air_2009",
  "Vice"                                               = "vice_2018",
  "West Side Story"                                    = "west_side_story_2021",
  "Whiplash"                                           = "whiplash_2014",
  "Wicked"                                             = "wicked_2024",
  "Winter's Bone"                                      = "10012136-winters_bone"
)

get_slug <- function(title) {
  if (title %in% names(slug_overrides)) slug_overrides[[title]]
  else make_slug(title)
}

# ── 3. Fetch one film ──────────────────────────────────────────────────────────
fetch_html <- function(film, year) {
  slug <- get_slug(film)
  url  <- paste0("https://www.rottentomatoes.com/m/", slug)
  
  resp <- tryCatch(
    GET(url, add_headers(`User-Agent` = paste0(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ",
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    )), timeout(15)),
    error = function(e) NULL
  )
  
  status <- if (is.null(resp)) 0L else status_code(resp)
  
  if (is.null(resp) || status != 200) {
    return(list(film = film, year = year, slug = slug, url = url,
                status = status, scorecard = NA, movie_info = NA))
  }
  
  html <- content(resp, "text", encoding = "UTF-8")
  list(
    film       = film,
    year       = year,
    slug       = slug,
    url        = url,
    status     = status,
    scorecard  = str_extract(html, "(?s)<media-scorecard.*?</media-scorecard>"),
    movie_info = str_extract(html, "(?s)Movie Info.*?</section>")
  )
}

# ── 4. Fetch all films, retrying missing ones in-place ────────────────────────
# Load existing results if available, otherwise start fresh
if (file.exists("raw_html.rds")) {
  raw_html <- readRDS("raw_html.rds")
  message("Loaded existing raw_html.rds with ", length(raw_html), " entries")
  # keep only the 201 original entries in case of accidental duplicates
  raw_html <- raw_html[seq_len(nrow(films))]
} else {
  raw_html <- vector("list", nrow(films))
}

# ── Films to force re-fetch (wrong page previously) ──────────────────────────
force_refetch <- c(
  "Dunkirk"
)
# Find indices that still need fetching (missing OR forced re-fetch)
todo_idx <- which(sapply(seq_len(nrow(films)), function(i) {
  is.null(raw_html[[i]])          ||
    is.na(raw_html[[i]]$scorecard)  ||
    films$film[i] %in% force_refetch
}))

message(sprintf("── Fetching %d films ─────────────────────────────────────────────────", length(todo_idx)))

for (i in todo_idx) {
  message(sprintf("[%d/%d] %s (%d)", i, nrow(films), films$film[i], films$year[i]))
  raw_html[[i]] <- fetch_html(films$film[i], films$year[i])
  Sys.sleep(runif(1, 2, 3))
}

# ── 5. Save & report ──────────────────────────────────────────────────────────
saveRDS(raw_html, "raw_html.rds")
message("Saved to raw_html.rds — ", length(raw_html), " entries total")

missing_idx <- which(sapply(raw_html, function(x) is.na(x$scorecard)))
message(sprintf("\n── %d still missing ──────────────────────────────────────────────────", length(missing_idx)))
for (i in missing_idx) {
  message(sprintf("  [%d] %s (%d) -> %s [status %d]",
                  i, raw_html[[i]]$film, raw_html[[i]]$year,
                  raw_html[[i]]$slug, raw_html[[i]]$status))
}

