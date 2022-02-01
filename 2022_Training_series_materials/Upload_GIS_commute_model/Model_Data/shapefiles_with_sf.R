## Setup

install.packages('sf')      # Install sf package
install.packages('ggplot2') # Install ggplot2 package
library(sf)                 # make sf package available
library(ggplot2)            # make ggplot2 package available


GM_shape_sf <- read_sf('GM_LAs_R.shp') 
                           # load a shapefile from current directory

# shapename <- read_sf('~/path/to/file.shp')
                           # or load a shapefile from other directories

## Explore
typeof(GM_shape_sf)        # Object type should be a 'list',
                           # but it is a pretty complicated list with sublists. 

colnames(GM_shape_sf)      # Get the column names.

GM_shape_sf$name           # Get the values for a column.

plot(GM_shape_sf)          # Get a few basic views of the data using 'plot'

plot(GM_shape_sf["population"]) # or from just one view from one feature




## Visualise
# More useful maps come from using 'ggplot'

GM_map_sf <- ggplot(data = GM_shape_sf) +
  geom_sf() +
  geom_sf(data = GM_shape_sf, fill = NA) +
  geom_sf_label(aes(label = GM_shape_sf$name))

GM_map_sf


## Manipulate and save

GM_shape_sf$nickname = c("Tamesidewinders",               # Add a new column
                         "Hatters","Reds", "Shakers",     # with nicknames
                         "Rochdalian", "Pie-eaters",      # for each GM local 
                         "Cottonopolis", "Trotters",      # authority.
                         "Ammies", "Yonners")


colnames(GM_shape_sf)                       # Get column names 
                                            # to check it was added


st_write(GM_shape_sf, "sf_export.shp")      # write edited object as a shapefile


##### Activity
# Can you redo the visual with nickname instead of name?


