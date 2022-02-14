## Import tidyverse

install.packages('tidyverse')
install.packages("xlsx")
library(xlsx)
library(tidyverse)
library(readxl)

##establish working directory (should be ~/Documents/Data Skills Pathway Project?R_Analysis?Resource_Clusters)
## change as necessary
getwd()
setwd("[PATH-TO-FILE]/agent-based-modelling/2022_Training_series_materials/Traffic_model_experiments")


# create list of all .csv files in folder
wide <- as_tibble(read.csv("Traffic_wide_tidy.csv", header =TRUE))

# you may want to rename the columns at this point to match the names in this list. 
names(wide) <-  c("run", "acceleration", "number_cars", "deceleration", "step", "red_speed")

# now, explore a bit

wide_summary <- wide %>%
  group_by(number_cars, acceleration, deceleration, step) %>%
  summarise(mean = mean(red_speed), n = n())

ggplot(wide_summary, 
       aes(x=step, y=mean, group=factor(acceleration), 
           color=factor(acceleration))) +
       geom_line() + facet_wrap(~ number_cars)

