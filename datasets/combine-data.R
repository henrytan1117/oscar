### This file will combine all the datasets extracted.

### We first read the dataset
file.1 <- read.csv("academy.csv")
head(file.1)
file.1$best_picture_winner <- as.numeric(file.1$winner)
file.1 <- file.1[,-4]
# This file contains year, ceremony, film, winner

file.2 <- read.csv("wiki-info-scrap-clean.csv")
head(file.2)

# This file contains year, film, ceremony, winner, wiki_link, running time, budget, box_office

file.3 <- read.csv("academy_rt_results.csv")
head(file.3)
# year, film, rotten-tomato url, tomatometer, tomatometer_count, popcornmeter, popcornmeter_countm
# director, genre, rating, original language
# Some correction on names
row_idx <- which(file.3$film == "Good Night, and Good Luck.")
file.3[row_idx, "film"] <- "Good Night, and Good Luck"

row_idx <- which(file.3$film == "Moulin Rouge")
file.3[row_idx, "film"] <- "Moulin Rouge!"


file.4 <- read.csv("academy_with_editing.csv")
head(file.4)
# Convert to binary
file.4$nominated_for_film_editing <- as.numeric(file.4$nominated_for_film_editing)
file.4$awarded_for_film_editing <- as.numeric(file.4$awarded_for_film_editing)
# nominated for film_editing, awarded for film_editing

# Correction on names
row_idx <- which(file.4$film == "Good Night, and Good Luck.")
file.4[row_idx, "film"] <- "Good Night, and Good Luck"

row_idx <- which(file.4$film == "Moulin Rouge")
file.4[row_idx, "film"] <- "Moulin Rouge!"


file.5 <- read.csv("academy_with_golden_globes.csv")
head(file.5)
file.5$gg_drama_nominated <- as.numeric(file.5$gg_drama_nominated)
file.5$gg_drama_won <- as.numeric(file.5$gg_drama_won)
file.5$gg_comedy_nominated <- as.numeric(file.5$gg_comedy_nominated)
file.5$gg_comedy_won <- as.numeric(file.5$gg_comedy_won)
# results for golden globes awards, split by categories

# Correction on names
row_idx <- which(file.5$film == "Good Night, and Good Luck.")
file.5[row_idx, "film"] <- "Good Night, and Good Luck"

row_idx <- which(file.5$film == "Moulin Rouge")
file.5[row_idx, "film"] <- "Moulin Rouge!"


file.6 <- read.csv("nominations_and_awards.csv")
head(file.6)
# Rename the col, remember to minus 1 later
colnames(file.6)[colnames(file.6) == "awards"] <- "awards_exclude_best_pics"
# Result on total nominations and awards (remember to exclude best pics)

# Correction on names
row_idx <- which(file.6$film == "Good Night, and Good Luck.")
file.6[row_idx, "film"] <- "Good Night, and Good Luck"

row_idx <- which(file.6$film == "Moulin Rouge")
file.6[row_idx, "film"] <- "Moulin Rouge!"

row_idx <- which(file.6$film == "Once Upon a Time in Hollywood")
file.6[row_idx, "film"] <- "Once upon a Time...in Hollywood"

row_idx <- which(file.6$film == "Precious")
file.6[row_idx, "film"] <- "Precious: Based on the Novel 'Push' by Sapphire"

row_idx <- which(file.6$film == "Three Billboards Outside Ebbing, Missouri")
file.6[row_idx, "film"] <- "Three Billboards outside Ebbing, Missouri"

# Results in 213 rows
# Correction
file.6[137,5] <- 8
file.6[137,6] <- 1

# Drop
file.6 <- file.6[-c(54, 65, 81, 83, 138, 144, 145, 146, 164, 170, 172, 188),]


file.7 <- read.csv("film_director_bd_wins.csv")
head(file.7)
# The past and current Academy Awards achievements of the directors

# Correction on names
row_idx <- which(file.7$film == "Good Night, and Good Luck.")
file.7[row_idx, "film"] <- "Good Night, and Good Luck"

row_idx <- which(file.7$film == "Moulin Rouge")
file.7[row_idx, "film"] <- "Moulin Rouge!"

###### Start combining data ######
# Make sure every merge maintain 201 rows

# Merging dataset 1 and 2
merge.1 <- merge(file.1, file.2, by='film')
nrow(merge.1) #201
merge.1 <- merge.1[,-c(5,6,7,8)] # drop other columns in common
head(merge.1)

# Merging with dataset 3
merge.2 <- merge(merge.1, file.3, by='film')
nrow(merge.2)
colnames(merge.2)
merge.2 <- merge.2[,-c(3,9,12,14,19)] # drop other columns in common

# Merging with dataset 4
merge.3 <- merge(merge.2, file.4, by='film')
nrow(merge.3)
colnames(merge.3)
merge.3 <- merge.3[,-c(15,16,17)] # drop other columns in common

# Merging with dataset 5
merge.4 <- merge(merge.3, file.5, by='film')
nrow(merge.4)
colnames(merge.4)
merge.4 <- merge.4[,-c(17,18,19)] # drop other columns in common

# Merging with dataset 6
merge.5 <- merge(merge.4, file.6, by='film')
nrow(merge.5)
colnames(merge.5)
merge.5 <- merge.5[,-c(21,22,23)] # drop other columns in common

# Merging with dataset 7
# First, reorder the dataframe according to years
# Sort by Year, then by film as a tie-breaker
merge.5 <- merge.5[order(merge.5$year.x, merge.5$film), ]

merge.6 <- merge(merge.5, file.7, by='film')
nrow(merge.6)
colnames(merge.6)
merge.6 <- merge.6[,-c(23,24,29)] # drop other columns in common

# Make modifications to the awards exclude best pics
merge.6$awards_exclude_best_pics <- as.numeric(merge.6$awards_exclude_best_pics)
row <- which(merge.6$best_picture_winner==1)

merge.6[row,]$awards_exclude_best_pics <- merge.6[row,]$awards_exclude_best_pics-1

###### Finish Combining Dataframe ######
colnames(merge.6)


# Rearrange the rename the column
library(dplyr)

df_final <- merge.6 %>%
  select(
    # 1. Identifiers (Renamed and moved to the front)
    film, 
    release_year = year.x, 
    director = director.x,
    
    # 2. Key Success Metrics 
    best_picture_winner,
    tomatometer,
    popcornmeter,
    total_academy_nominations = nominations,
    total_academy_award_exclude_best_pic = awards_exclude_best_pics,
    
    # 3. Movie-specific details
    running_time_minutes = Running_Time_Minutes,
    genre,
    rating,
    language = original_language,
    
    # 4. Financials
    budget_millions = Budget_Millions,
    box_bffice_millions = Box_Office_Millions,
    
    # 5. Other Awards
    nominee_film_edit = nominated_for_film_editing,
    award_film_edit = awarded_for_film_editing,
    nominee_drama_gg = gg_drama_nominated,
    won_drama_gg = gg_drama_won,
    nominee_comedy_gg = gg_comedy_nominated,
    won_comedy_gg = gg_comedy_won,
    
    # 6. Director Awards
    best_director_nominee_before = bd_nominate_no_concurrent,
    best_director_nominee_include_now = bd_nominate_yes_concurrent,
    best_director_award_before = bd_award_no_concurrent,
    best_director_award_now = bd_award_yes_concurrent,
    
    # 7. Extra
    wikipedia = wiki_link,
    rotten_tomato = url,
  )

# Export the csv file
write.csv(df_final, "academy_final.csv", row.names=FALSE)


