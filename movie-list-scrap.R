### This file is used to extract the list of nominated films
### From 2000 to 2024


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


# Convert the file above into dataframe
df <- data.frame(df)

# The Academy Awards catalogue is not fully updated with 2025 data
# So we will manually add the 2025 data into the data frame

# Create a new dataframe for the 2025 nominees
df_2025 <- data.frame(
  year = 2025,
  ceremony = 98,
  film = c(
    "One Battle After Another", 
    "Bugonia", 
    "F1", 
    "Frankenstein", 
    "Hamnet", 
    "Marty Supreme", 
    "The Secret Agent", 
    "Sentimental Value", 
    "Sinners", 
    "Train Dreams"
  ),
  winner = c(TRUE, rep(FALSE, 9)), # One Battler After Another is the winner (TRUE), others are FALSE
  stringsAsFactors = FALSE
)

# Combine with your existing dataframe
# (Assuming your current dataframe is named 'df')
df <- rbind(df, df_2025)

# Verify the update
tail(df, 10)