library(rvest)
library(purrr)
library(dplyr)

page <- read_html("wikipedia_nominations.html")

# Read your film list
our_films <- read.csv("academy.csv", stringsAsFactors = FALSE)

# Reformat namings for mismatches
our_films <- our_films |>
  mutate(film = case_when(
    film == "Good Night, and Good Luck." ~ "Good Night, and Good Luck",
    film == "Precious: Based on the Novel 'Push' by Sapphire" ~ "Precious",
    film == "Three Billboards outside Ebbing, Missouri" ~ "Three Billboards Outside Ebbing, Missouri",
    film == "Once upon a Time...in Hollywood" ~ "Once Upon a Time in Hollywood",
    .default = film
  ))

# Parse the wiki table
wiki <- page |>
  html_element("table.wikitable") |>
  html_table() |>
  select(film = Film, nominations = Nominations, awards = Awards)

enriched <- our_films |>
  left_join(wiki, by = "film")

enriched |> filter(is.na(nominations)) |> select(year, film)

write.csv(enriched, "nominations_and_awards.csv", row.names = FALSE)
