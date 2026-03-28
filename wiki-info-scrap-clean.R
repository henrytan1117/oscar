# This file will clean the budget, box office and running time, information scrap from the wikipedia page
# Challenge when extracting and cleaning

# Read the dataset
df <- read.csv("wiki-info-scrap.csv")

# Convert running time to numeric
df$Running_Time <- as.numeric(df$Running_Time)

# Missing running time for row 84
df[73, 6] <- 139


# Drop the director column since we have that information in rotten tomato csv
df <- df[, names(df) != "Director"]

### Clean the Formatting Error
## (1) &#160; should be replaced with an empty space, in both column

# Clean Budget
df$Budget <- df$Budget %>%
  str_replace_all("&#160;", " ") %>%
  str_squish()

# Clean Box Office
df$Box_Office <- df$Box_Office %>%
  str_replace_all("&#160;", " ") %>%
  str_squish()

## (2) Dollars cleaning
# If there is dollar sign VS no-dollar sign
# First, flag those without $ sign and filter out, so we can convert the currency + fill in NA
# Second, eliminate $ sign and US
# Third, if there is million, eliminate million
# If there is billion, multiply by 1000
# If the content contains dash "-",eg, $30 - 35, extra the prior and value after, take the average
# Convert everything to numeric
# If after elimination, the length is still >=6, divided by 1000000 to convert to million

#### Step 1: Convert currency and fill in NA

# Row 142, we need to convert
df[142, 7] <- '$11.4 million'
df[142, 8] <- '$258.1 million'

# Row 186, we need to only the dollar segment in budget
df[186, 7] <- '$26 million'


#### Step 2: Filter all the NAs, and fill in the values

### Check for budget NA first
df[which(is.na(df$Budget)),]

# Row 166: Estimated from 1MDB: https://www.imdb.com/title/tt14444726/: $25m
df[166, 7] <- '$25 million'

# Row 181: https://www.imdb.com/title/tt7160372/: $15m
df[181, 7] <- '$15 million'

# Row 185: From Wikipedia: $190m (Budget), $715m (Box office)
df[185, c(7,8)] <- c('$190 million','715 million')

### Then check for box office NA
df[which(is.na(df$Box_Office)),]


# Row 162: This is a Netflix backed movie, we don't have data on the box office
# It has reached a 150M+ hours viewed
# But the only data available for us in $2878 for the worldwide box office
# Potentially dropping this data point since it cannot be compared equally with other films
df[162, 8] <- '$2878'

# Row 191: https://en.wikipedia.org/wiki/Wicked_(2024_film), $758.8m
df[191, 8] <- '$758.8 million'

# Row 201: Train Dreams is a Netflix stream
df[201, 8] <- '0'

#### Step 3: Eliminate all $ and millions, and convert billions to millions
library(dplyr)

# 1. Detect and Handle Ranges (Average of numbers before and after dash)
# We use [0-9.]+ to find numbers with decimals
# We use [-–—] to catch all types of dashes Wikipedia uses (hyphen, en-dash, em-dash)

df$Budget <- sapply(df$Budget, function(x) {
  if (is.na(x)) return(NA)
  
  # Detect if a dash exists
  if (str_detect(x, "-|–|—")) {
    # Extract all numeric values found in the string
    nums <- as.numeric(str_extract_all(x, "[0-9.]+")[[1]])
    
    # If we found at least two numbers, take the average
    if (length(nums) >= 2) {
      # We take the mean of the first two numbers found
      avg_val <- mean(nums[1:2])
      # Put the average back into the string so we can process units next
      # e.g., "32.5 million"
      x <- str_replace(x, ".*[-–—].*", as.character(avg_val))
    }
  }
  return(x)
})

# 2. Now handle Billion (Multiply by 1000)
# This must happen BEFORE we delete the word "billion"
df$Budget <- ifelse(
  str_detect(tolower(df$Budget), "billion"), 
  as.numeric(str_extract(df$Budget, "[0-9.]+")) * 1000,
  df$Budget
)

# 3. Final Cleaning (Remove $, million, and convert to numeric)
df$Budget <- df$Budget %>%
  str_remove_all("\\$|US|million|\\,|\\(") %>%
  str_trim(side = "both") %>%
  str_squish() %>%
  as.numeric()

# 4. Handle very large raw numbers (Length >= 6 digits)
# If a value like 480678 exists, it's a raw dollar amount, not millions
df$Budget <- ifelse(!is.na(df$Budget) & df$Budget >= 10000, 
                    df$Budget / 1000000, 
                    df$Budget)

#### Repeat for Box Office

# 1. Detect and Handle Ranges (Average of numbers before and after dash)
# We use [0-9.]+ to find numbers with decimals
# We use [-–—] to catch all types of dashes Wikipedia uses (hyphen, en-dash, em-dash)

df$Box_Office <- sapply(df$Box_Office, function(x) {
  if (is.na(x)) return(NA)
  
  # Detect if a dash exists
  if (str_detect(x, "-|–|—")) {
    # Extract all numeric values found in the string
    nums <- as.numeric(str_extract_all(x, "[0-9.]+")[[1]])
    
    # If we found at least two numbers, take the average
    if (length(nums) >= 2) {
      # We take the mean of the first two numbers found
      avg_val <- mean(nums[1:2])
      # Put the average back into the string so we can process units next
      # e.g., "32.5 million"
      x <- str_replace(x, ".*[-–—].*", as.character(avg_val))
    }
  }
  return(x)
})

# 2. Now handle Billion (Multiply by 1000)
# This must happen BEFORE we delete the word "billion"
df$Box_Office<- ifelse(
  str_detect(tolower(df$Box_Office), "billion"), 
  as.numeric(str_extract(df$Box_Office, "[0-9.]+")) * 1000,
  df$Box_Office
)

# 3. Final Cleaning (Remove $, million, and convert to numeric)
df$Box_Office <- df$Box_Office %>%
  str_remove_all("\\$|US|million|\\,") %>%
  str_trim(side = "both") %>%
  str_squish() %>%
  as.numeric()

# 4. Handle very large raw numbers (Length >= 6 digits)
# If a value like 480678 exists, it's a raw dollar amount, not millions
df$Box_Office <- ifelse(!is.na(df$Box_Office) & df$Box_Office >= 10000, 
                    df$Box_Office / 1000000, 
                    df$Box_Office)


# Rename the columns
# New_Name = Old_Name
df <- df %>% 
  rename(Budget_Millions = Budget, 
         Box_Office_Millions = Box_Office,
         Running_Time_Minutes = Running_Time)


write.csv(df, file="wifi-info-scrap-clean.csv")








