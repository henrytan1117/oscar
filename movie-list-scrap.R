library(rvest)
library(purrr)
library(dplyr)

page <- read_html("academy.html")
year_groups <- page |> html_elements(".result-group")

oscar_list <- map(year_groups, function(group) {
  year        <- group |> html_element(".result-group-title a") |> html_text2()
  nominations <- group |> html_elements(".result-details")
  
  films <- map_dfr(nominations, function(nom) {
    film   <- nom |> html_element(".awards-result-film-title a") |> html_text2()
    winner <- length(html_elements(nom, ".glyphicon-star")) > 0
    tibble(film = film, winner = winner)
  }) |> filter(!is.na(film))
  
  list(year = year, films = films)
})

names(oscar_list) <- map_chr(oscar_list, "year")

df <- map_dfr(oscar_list, ~ .x$films |> mutate(year = .x$year)) |>
  select(year, film, winner) |>
  mutate(
    ceremony = as.integer(stringr::str_extract(year, "(?<=\\()\\d+")),
    year     = as.integer(stringr::str_extract(year, "\\d{4}"))
  ) |>
  select(year, ceremony, film, winner)

