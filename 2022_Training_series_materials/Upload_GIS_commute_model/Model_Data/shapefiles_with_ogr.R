## Setup

install.packages('rgdal')   # Install rgdal package
install.packages('ggplot2') # Install ggplot2 package
library(rgdal)                 # make rgdal package available
library(ggplot2)            # make ggplot2 package available

GM_shape <- readOGR(dsn = ".", layer = "GM_LAs_R") 
                                                   # load a shapefile from current directory

GM_shape <- readOGR(dsn = "path/to/file", layer = "SHAPEFILE_NAME") 
                                                   # or from other directories

## Explore

typeof(GM_shape)           # This should come back as an 'S4', which is a class 
                           # that allows rich and complicated data to be 
                           # represented in a way that is (relatively) 
                           # simple for end users. 

colnames(GM_shape@data)    # Get the column names.

GM_shape$name              # Get the values for a column.

plot(GM_shape)             # Get a few basic views of the data using 'plot'

plot(GM_shape$population)  # or from just one view from one feature



## Visualise

data_for_mapping <- broom::tidy(GM_shape) # Extract the data from the S4 object 
typeof(data_for_mapping)                  # Confirm the data is now a list
lapply(data_for_mapping, class)           # Ensure the list items are treated as classes

head(data_for_mapping)                    # Check the top of the list. For funsies?

GM_map <- ggplot() +                                   # create a new ggplot object
  geom_polygon(data = GM_shape,                        # using the shapefile
               aes(x = long, y = lat, group = group),  # in the right orientation
               colour = "black", fill = NA)            # and with basic black lines

GM_map                                                 # check the ggplot object

cnames <- 
  aggregate(cbind(long, lat) ~ id,                     # put the list object
            data=data_for_mapping, FUN=mean)           # into a vector... I think.

GM_map +                                                   # add a new layer to ggplot
  geom_text(data = cnames,                                 # with the vector as the data source
            aes(x = long, y = lat, label = GM_shape$name), # adding labels
            size = 4) + theme_void()                       #  



## Manipulate and save

GM_shape$nickname = c("Tamesidewinders",               # Add a new column
                      "Hatters","Reds", "Shakers",     # with nicknames
                      "Rochdalian", "Pie-eaters",      # for each GM local 
                      "Cottonopolis", "Trotters",      # authority.
                      "Ammies", "Yonners")


colnames(GM_shape)                                     # Get column names 
                                                       # to check it was added


writeOGR(GM_shape, dsn = '.',               # write edited object as a shapefile
         layer = 'ogr_export',
         driver = "ESRI Shapefile")


##### Activity
# Can you redo the visual with nickname instead of name?
