## Global options, necessary libraries, etc.
##   Take time to install if needed.

options(stringsAsFactors = FALSE)
library(ggplot2)
library(sqldf)
library(tidyverse)
detach("package:RPostgreSQL", unload=TRUE) 

## Always good to start off by checking and/or setting your working directory
getwd()           
setwd("//nask.man.ac.uk/home$/Desktop/ABM/Experimental_Results")

## Read in csv files
GM_Tram_Raw <- (read.csv("//nask.man.ac.uk/home$/Desktop/ABM/Experimental_Results/GM_LAs_CodeTest_-473979832.csv", 
                         header = TRUE))

## Basic clean up 
## Remove parertheses
GM_Tram_Raw$Origen  <- (gsub("[()]", "", GM_Tram_Raw$Origen))

## Split the Origen column into one that tracks the agent-type and another than has that agent's who number
GM_Tram_Adjusted <- GM_Tram_Raw %>% 
  separate(Origen, c("Journey", "OSpecifics"), 6)

## Remove unneeded columns
GM_Tram_Slim <- GM_Tram_Adjusted[c("Commuter", "Journey","Origen_LA","Destination_LA","Travel_time")]

## Rename some columns to streamline interpretation
GM_Tram_Slim <- GM_Tram_Slim %>% 
  rename(
    Origen = Origen_LA,
    Destination = Destination_LA )

## Shockingly basic analysis
## Count the number of journeys taken between each pair of LAs
Tram_Journey_Count <- GM_Tram_Slim %>%
  group_by (Origen, Destination) %>%
  summarize( GM_Tram_Slim = n())            


#Heat map of travel time between Origen LA and destination LA
TravelTime.heatmap <- ggplot(data = GM_Tram_Slim, mapping = aes(x = Origen,
                                                           y = Destination,
                                                       fill = Travel_time)) +
  geom_tile() +
  xlab(label = "Heatmap of Travel Time")

