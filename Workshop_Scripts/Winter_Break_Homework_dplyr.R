rm(list = ls())
setwd("~/soda-dvm/Workshop_Data/Multi_Datasets")
library(dplyr)
library(readr)
library(purrr)

# This assignment is a bit more open ended. If you go and look at the working
# directory, you will find 471 .csv files. You will need to read these in and
# combine them. They record some information about bills introduced in the U.S.
# Congress over a 22 year period (1993-2014). Each bill is broken down into
# sections, so there are multiple observations for each bill. Here is an
# explanation of what each variable is:

# $session -- The session of Congress in which the bill was introduced.
# $chamber -- HR = House of Representatives, S = Senate.
# $number -- The number assigned to the bill in that session of Congress.
# $type -- IH = Introduced in House, IS = Introduced in Senate.
# $section -- The index of each section.
# $Cosponsr -- The number of Cosponsors for each bill.
# $IntrDate -- The date the bill was introduced.
# $Title -- The title of the bill.
# $NameFull -- The full name of the legislator who introduced the bill.
# $major_topic_label -- The topic of the bill.
# $party_name -- The party of the legislator that introduced the bill.




### Exercise 1 ###

# raw_data <- list.files(getwd(), pattern = "*.csv") %>%
#   map(read_csv, col_types = 
#     cols(
#       session = col_integer(),
#       chamber = col_character(),
#       number = col_integer(),
#       type = col_character(),
#       section = col_integer(),
#       Cosponsr = col_integer(),
#       IntrDate = col_date(format = ""),
#       Title = col_character(),
#       NameFull = col_character(),
#       major_topic_label = col_character(),
#       party_name = col_character()
#     )
#   ) %>%
#   reduce(rbind)

raw_data <- readRDS("raw_data.rds")

# nrow(raw_data) is 470800

### Exercise 2 ###

# Create a new dataset that collapses the original dataset over bill sections so
# there is only one entry per unique bill. Add a field to this collapsed dataset
# called "Sections" that records the total number of sections associated with
# that bill. Removed the "section" variable from the data.frame as it is no
# longer necessary. How many rows are in this data.frame? Does the sum of the
# "Sections" variable in your new data.frame equal the number of rows in the old
# data.frame (with one entry per section)?

summary1 <- raw_data %>%
  mutate(bill_id = paste(session, chamber, number, sep="-")) %>%
  group_by(bill_id) %>%
  mutate(Sections = n()) %>%
  distinct(bill_id, .keep_all = TRUE) %>%
  select(-section) %>%
  ungroup()


### Exercise 3 ###

# Now collapse your data even further. Create a new dataset with one row for
# each unique legislator (e.g. 'unique(data$NameFull)'). This dataset should
# have the following fields:

# $Name -- the name of the legislator (from the $NameFull field)
# $Total_Bills -- The total number of bills introduced by that legislator
# $Total_Sections -- The total number of sections in bills they introduced.
# $Average_Sections -- The average number of sections in bills they introduced.
# $Earliest_Bill -- The session their first bill was introduced.
# $Most_Common_Topic -- The most common topic for bills they introduced. If
# there is a tie, take the first one, alphabetically.

# stores full name with most common topic

raw_data <- raw_data %>%
  rename(
    Name = NameFull, 
    Most_Common_Topic = major_topic_label)

names_with_topic_counts <- raw_data %>%
  select(Name, Most_Common_Topic) %>%
  group_by(Name) %>%
  count(Most_Common_Topic, sort = TRUE) %>%
  top_n(1, n) %>%
  top_n(-1, Most_Common_Topic) %>%
  select(-n)

legislator <- raw_data %>%
  group_by(Name) %>%
  summarize(
    Total_Bills = n(),
    Total_Sections = sum(section),
    Average_Sections = mean(section),
    Earliest_Bill = min(IntrDate))

# the final tibble
reduced_data <- left_join(legislator, names_with_topic_counts, by = "Name")

# free the temporary tibbles
names_with_topic_counts <- NULL     
legislator <- NULL


# # a single pipeline -- in progress. doesn't collapse across legislators.
# legislator <- raw_data %>%
#   # rename(Name = NameFull) %>%
#   select(Name, Most_Common_Topic, Sections, IntrDate) %>%     # reduce size of tibble
#   group_by(Name) %>%
#   add_count(Most_Common_Topic, sort = TRUE) %>%
#   mutate(
#     Total_Bills = n(),
#     Total_Sections = sum(Sections),
#     Average_Sections = mean(Sections),
#     Earliest_Bill = min(IntrDate)) %>%
#     # Most_Common_Topic = top_n(-1, top_n(1, n, major_topic_label)))
#     # Most_Common_Topic = Most_Common_Topic) %>%
#   top_n(1, n) %>%
#   top_n(-1, Most_Common_Topic) %>%
#   summarize(Total_Bills, Total_Sections, Average_Sections, Earliest_Bill, Most_Common_Topic)
