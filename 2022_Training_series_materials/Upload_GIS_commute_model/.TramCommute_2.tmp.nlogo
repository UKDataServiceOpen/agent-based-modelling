extensions [ gis                                                              ; GIS extension for NetLogo, needed if using imported shapefiles
             nw                                                               ; NW extension for NetLogo, needed to create the network shapes for houses, destinations, etc.
             csv ]                                                            ; CSV extension for NetLogo, needed to read in the file of which tramstops are connected

globals [ tramstops-dataset                                                   ; These are declared here to make it easier to switch between the Random and GM projections
          tramlines-dataset
          LAs-dataset
          Tramstop_Connections
          output-filename
          run-seed ]

breed [tramstops tramstop]                                     ; Breeds allows the modeller to easily ask some sets of agents to run commands or otherwise take actions
breed [houses house]
breed [places place]
breed [denizens denizen]
breed [ LAs LA ]

turtles-own    [LAs-name-t                                     ; These are (in addition to primitive features like size or color) the features that every agent in this model has
                LAs-population-t]
tramstops-own  [myneighbors
                Tramstop_Name]
patches-own    [ centroid                                      ; Like turtles-own, these are the features that all patches in this model have (also, primitive patch features like location and color)
                LAs-population
                LAs-name]
LAs-own        [centroid-x]                                    ; These are the features that only the subset of LA agents have. No other turtle will have these.
links-own      [Speed                                          ; Like turtles-own and patches-own, links can be assigned model specific features here.
                Capacity]
denizens-own [My_Places                                        ; Denizens have the most features as these are the only agents that move around when the model runs.
              current-location
              current-path
              next-location
              current-speed
              destination
              starting-place
              travel-timer]

to setup
  clear-all                                                                   ; Always start by clearing everything.
  set run-seed new-seed                                                       ; Creates a "seed" to use as a unique identifier for the run (also, allows the run to be re-run exactly)
  random-seed run-seed                                                        ; Initiates this run using the just created seed
  set output-filename (word projection "_" Output_File "_" run-seed )         ; Creates an output file to record the model run based on the projection selected, a user input value and the seed created to identify this run
  ifelse projection = "Random"                                                ; The model diverges significantly depending on whether you want to use randomly generated or imported features of the model world
    [ setup-random ]                                                          ; This initiates the procedures to set up a random world, drawing on the various "Random_Generated" switches and sliders.
    [ setup-input  ]                                                          ; This initiates the procedures to set up a world based on imported shapefiles. This too draws on switches and sliders, but not those specific to
  setup-trams                                                                 ; the Random projection models, such as "Random_Generated_Tramstops".
  if Garrulous? [ask links [print end1]]
  setup-houses-and-places
  setup-denizens
  check-speed
  initial-exports
  reset-ticks
end

to setup-random                                                                                                    ; The random setup has several steps
  resize-world -90 90 -90 90                                                                                       ; 1- Define the size of the world
  set-patch-size 3                                                                                                 ; Patch size interacts with world dimensions to determine the world size.
  ask LAs [die]                                                                                                    ; 2- LAs are agents (or turtles) that are useful for creating and displaying labels. But first, make sure none are leftover from previous runs.
  create-LAs Number_Generated_LAs_Random_Only [                                                                    ; According to modeller input on a slider in the interface, the model creates a certain number of "Local Authority" agents
    setxy 0 0                                                                                                      ; Those LA agents start at the centre ...
    set xcor xcor + random 50 - random 50                                                                          ; Move randomly right and left ...
    set ycor ycor + random 50 - random 50                                                                          ; Move randomly up and down ...
    set size 0                                                                                                     ; Set their size to 0 so as to be invisible ...
    set label-color yellow                                                                                         ; Set their label color to yellow to increase visibility  ...
    set LAs-population-t 5 + random Max_Random_Population                                                          ; 3- The LA agents set their population as 5 plus a random number up to the maximum set by the modeller (this prevents a 0 population error).
    if Label_LAs? [set LAs-name-t (word "LA " who)]                                                                ; 4- The LA agents check to see if the modeller has asked them to display their names, and if so they do.
    ask patch-here [set LAs-population [LAs-population-t] of LAs-here                                              ; 5- Then the LA agents talks to the patch underneath themselves.
                    set LAs-name [LAs-name-t] of LAs-here                                                          ; The LA agent asks the patch to copy details like population and name from the LA agent to itself.
                    set pcolor red                                                                                 ; And also asks the patches to set their color to red.
                    if Garrulous? [print (word pxcor pycor LAs-population LAs-name)]]                              ; 6- If the model is set to run in Garrulous mode, it prints some descriptive details to the command centre pane in the interface.

    ask patches with [pcolor = red] [                                                                              ; 7- The model then asks all patches that are colored red
      set LAs-population item 0 LAs-population                                                                     ; To reformat the information they have written in their name and population (this ensures these are recorded properly as strings or numbers
      set LAs-name item 0 LAs-name                                                                                 ; rather than lists.
      set pcolor red + ((LAs-population - min [LAs-population] of patches with [is-number? LAs-population]) * .1 ) ; The patches then set their color relative to their population to improve visibility.
      if pcolor = black [set pcolor pcolor + 5 ] ] ]                                                               ; Ask any LA patches that are black to recolor themselves, just for clarity.

  repeat 50 [ask patches with [pcolor = black] [if any? neighbors with [pcolor != black] [                         ; 8- Then, in 50 separate rounds, black patches check to see if they have any non-black neighbouring patches.
    let join-LAs one-of neighbors with [pcolor != black]                                                           ; 9- If so, they copy the name, population and colour of one of their non-black neighbours.
    set pcolor [pcolor] of join-LAs                                                                                ; This creates the growth of random "LA-like" zones of color across the world.
    set LAs-population  [LAs-population] of join-LAs
    set LAs-name [LAs-name] of join-LAs] ] ]
end

to setup-input                                                                                      ; The non-random projection also has several steps, many are similar to those in the random set up.
     gis:load-coordinate-system (word "Model_Data/" projection ".prj")                              ; 1- Set the coordinate system or 'projection'. This is optional as long as all of the datasets use the same coordinate system.
     set tramstops-dataset gis:load-dataset "Model_Data/GM_Tramstops.shp"                           ; Load all of your non-random datasets (as many as you need), assigning them to the globals created above.
     set tramlines-dataset gis:load-dataset "Model_Data/Tramlines_Current.shp"
     set LAs-dataset gis:load-dataset "Model_Data/GM_LAs_R.shp"
     gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of tramstops-dataset)              ; 2- Set the world envelope to the union of all of the datasets' envelopes. This ensures they line up correctly.
                                                   (gis:envelope-of tramlines-dataset)
                                                   (gis:envelope-of LAs-dataset))
   set Tramstop_Connections (csv:from-file "Model_Data/Tramstop_Connections.csv" "," )              ; Load the .csv file of which tramstops are connected

  ask LAs [ die ]                                                                                   ; 3- As with the Random projection, clear any agents that may be around.
  gis:set-drawing-color white                                                                       ; 4- Set the drawing color to white.
  gis:draw LAs-dataset 1                                                                            ; Draw the polygon data from the shapefile.
   let i 1                                                                                          ; 5- Technical processes of identifing features from the shapefile and loading them into temporary values.
   foreach gis:feature-list-of LAs-dataset [ vector-feature ->
      let centroid-y gis:location-of gis:centroid-of vector-feature                                 ; The middle of each polygon is identified and added to a list (but not if it lies outside the world as defined).
      if not empty? centroid-y                                                                      ; 6- If the centroid list is not empty,
      [ create-LAs 1                                                                                ; Then create an LA agent and ...
        [ set xcor item 0 centroid-y                                                                ; Move it to the right position (right/left)
          set ycor item 1 centroid-y                                                                ; Move it to the right position (up/down)
          set size 0                                                                                ; Set their size to 0 so as to be invisible ...
          set label-color yellow                                                                    ; Set their label color to yellow to increase visibility  ...
          if Label_LAs? [set label gis:property-value vector-feature "name"]                        ; Set their label to be their name, which is drawn from the imported shapefile ...
          set LAs-population-t gis:property-value vector-feature "population"                       ; Set their LAs-population variable to be the population value drawn from the imported shapefile...
          set LAs-name-t gis:property-value vector-feature "name"                                   ; Set their LAs-name variable to be the name  value drawn from the imported shapefile...
          ask patch-here [set LAs-population [LAs-population-t] of LAs-here                         ; 7- Then the LA agents talks to the patch underneath themselves.
                          set LAs-name [LAs-name-t] of LAs-here                                     ; The LA agent asks the patch to copy details like population and name from the LA agent to itself.
          set pcolor red] ] ]                                                                       ; And also asks the patches to set their color to red.
    set i i + 1 ]                                                                                   ; This code incrementally increases the value of 'i', so that the for-loop proceeds to the next LA.
                                                                                                    ; The next LA will then run through the same #6 and #7 steps and increase 'i' by 1 until all LAs are created

   gis:apply-coverage LAs-dataset "POPULATION" LAs-population                                       ; 8- All pateches within the LA polygon then copy the values of population from the imported shapefile to the patch values
   gis:apply-coverage LAs-dataset "NAME" LAs-name                                                   ; All pateches within the LA polygon then copy the values of name from the imported shapefile to the patch values
   let min-pop min [read-from-string LAs-population ] of patches with [is-string? LAs-population]   ; 9- LA polygons then colour themselves by first setting a global variable to hold the population of the LA with the smallest population.
   ask patches with [is-string? LAs-population] [                                                   ; Then, all patches that are within any LA (those with a value in their LAs-population feature)...
   set pcolor red + ((read-from-string LAs-population - min-pop) * .1 )                             ; Set their colour to be red plus 10% of the difference between their population and the minimum population. The LA with the smallest population will be red.
    if pcolor = black [set pcolor pcolor + 5 ]]                                                     ; Finally, all patches that are currently black (that is, not those coloured by population) reset themselves to near black for clarity.
end

to setup-trams
    ask tramstops [ die ]                                                                           ; Start by ensuring that there are no tramstops already present
    set-default-shape tramstops "building store"                                                    ; Set the default shape for a tram stop to the building shape that looks most appropriate
    ifelse projection = "Random"                                                                    ; Set up locations for tramstops (and create links between them) based on random generation and user input or uploaded shapefiles
    [  nw:generate-preferential-attachment tramstops links Number_Generated_Tramstops_Random_Only 1 [           ; IF RANDOM, create a random preferential attachment network of linked tramstops ...
    move-to one-of patches with [pcolor != black]                                                   ; and ask them to move to one of the LA areas already created
    if Label_Tramstops? [set label (word LAs-name-t who) ] ]                                        ; Check if the modeller has decided to label tramstops, and if so ask them to display their "who" number
    repeat 50 [ layout-spring tramstops links 0.2 11 1 ] ]                                          ; Move tramstops around with spring-layout to make the network look better
    [gis:set-drawing-color blue                                                                     ; IF NOT RANDOM, pick up a blue crayon and ...
     gis:draw tramlines-dataset 1                                                                   ; draw in tramlines according to the tramlines dataset
     gis:set-drawing-color cyan                                                                     ; Pick up a cyan crayon and ...
      foreach gis:feature-list-of tramstops-dataset [ vector-feature ->                             ; look into the tramstop dataset ...
      let centroid-stops gis:location-of gis:centroid-of vector-feature                             ; creating a list of all "centroids" within the bounds of the current NetLogo world, as defined by the current GIS coordinate transformation
      if not empty? centroid-stops                                                                  ; If centroid is not an empty list ...
      [ create-tramstops 1                                                                          ; create one tramstop per centroid...
        [ set xcor item 0 centroid-stops                                                            ; Move it to the X coordinate of the centroid
          set ycor item 1 centroid-stops                                                            ; Move it to the Y coordinate of the centroid
          set Tramstop_Name gis:property-value vector-feature "RSTNAM"                              ; Copy over the name of of the centroid
          if Label_Tramstops? [set label gis:property-value vector-feature "RSTNAM" ] ] ] ] ]       ; Check if the modeller has decided to label tramstops, and if so ask them to display the name they copied over.

  ask tramstops [
      set LAs-name-t [LAs-name] of patch-here                                                       ; Tramstops copy over the LA-name from the patches on which they find themselves and ..
      set LAs-population-t [LAs-population] of patch-here                                           ; the population of the LA.
      set color blue                                                                                ; They change their colour.
      set size 3                                                                                    ; And their size.
    if projection != "Random" [foreach Tramstop_Connections                                         ; IF NOT RANDOM, look into the uploaded .csv file and for each row ...
      [ [ LinkedStops ] -> ask tramstops with [Tramstop_Name  = (item 0 LinkedStops)]               ; create a temporary variable copy of that row, then ask tramstops whose names match the first item in the row
        [set myneighbors but-first LinkedStops] ]                                                   ; to set the "myneighbors" variable to be the rest of the items on the temporary variable list.
      foreach myneighbors                                                                           ; Then, for each item in the "myneighbors" variable...
      [ [ next_stop] -> ask tramstops with [Tramstop_Name  = next_stop]                             ; they create a temporary variable and ask the tramstop whose name matches that item to
        [create-link-with myself] ] ] ]                                                             ; create a link with the original tramstop that is doing the asking
  ask tramstops [ set myneighbors link-neighbors ]                                                  ; Then, all tramstops reset their "myneighbors" variable to the set of agents with which they are linked.
  ask links [set Speed 10                                                                           ; Then, all links, which at this point are only between tramstops, set their speed to 10 and ...
             set Capacity 100]                                                                      ; their capacity to 100. Capacity is not a functional variable in the current model code
end

to setup-houses-and-places
  ask houses [ die ]                                                                                ; Start by ensuring that there are no houses already present
  set-default-shape houses "house"                                                                  ; Set the default shape for a house to be house shaped
  ask LAs [if is-string? LAs-population-t                                                           ; A check to make sure that both random and non-random models have population recorded properly as a number
    [set LAs-population-t read-from-string LAs-population-t] ]                                      ; population recorded properly as a number.

  ifelse projection = "Random"                                                                      ; IF RANDOM,
    [ask LAs [ifelse Tram_Commute_Only?                                                             ; Check to see if the modeller input is set to "houses and places only in LAs with tramstops"
      [if any? tramstops with [LAs-name-t = [LAs-name-t] of myself]                                 ; IF SO, LAs with tramstops  ...
        [hatch-houses 1 + random LAs-population-t  ] ]                                              ; hatch at least one house, plus some random number between 0 and their populaton
      [hatch-houses 1 + random LAs-population-t  ] ] ]                                              ; OTHERWISE, all LAs hatch at least one house, plus some random number between 0 and their populaton.
    [                                                                                               ; IF NOT RANDOM,

  ask LAs [ifelse Tram_Commute_Only?                                                             ; Check to see if the modeller input is set to "houses and places only in LAs with tramstops"
      [if any? tramstops with [LAs-name-t = [LAs-name-t] of myself]                                 ; IF SO, LAs with tramstops  ...
           [hatch-houses ( LAs-population-t / 1000 )                                                ; Hatch one house per 1000 people
          if Garrulous?
          [print (word LAs-name-t  " has " (LAs-population-t / 1000) " houses.") ] ] ]
          [hatch-houses ( LAs-population-t / 1000 )                                                 ; Otherwise, all LAs hatch one house per 1000 people.
          if Garrulous?
          [print (word LAs-name-t  " has " (LAs-population-t / 1000) " houses.") ] ] ] ]

  ask houses [ let move-house one-of patches with [LAs-name = [LAs-name-t] of myself]               ; Houses then pick a random patch within the same LA
               set xcor [pxcor] of move-house                                                       ; Then sets its X coordinate to match that of the random patch
               set ycor [pycor] of move-house                                                       ; Then sets its Y coordinate to match that of the random patch
               create-link-with min-one-of tramstops [distance myself]                              ; Then creates a link to the nearest tramstop,
               set color yellow                                                                     ; Changes its colour
               set size 2                                                                           ; Sets its size
               set label "" ]                                                                       ; And removes its label (removing a label is the same as setting it to an empty string, written as "").

  ask places [ die ]                                                                                ; Start by ensuring that there are no places already present
  set-default-shape places "building institution"                                                   ; Set the default shape for a place to be sort of museum-shaped
  ask LAs [ifelse Tram_Commute_Only?                                                                ; Check to see if the modeller input is set to "houses and places only in LAs with tramstops"
      [if any? tramstops with [LAs-name-t = [LAs-name-t] of myself]                                 ; IF SO, LAs with tramstops  ...
      [let LAs_with_tramstops [LAs-name-t] of tramstops                                             ; create a list of all LAs that have tramstops,
       set LAs_with_tramstops remove-duplicates LAs_with_tramstops                                  ; removes any duplicate entries from that list,
       hatch-places (Number_Generated_Places / length LAs_with_tramstops ) ] ]                      ; and hatches places equal to the modeller input divided by the number of LAs with tramstops.
      [ hatch-places (Number_Generated_Places / Number_Generated_LAs_Random_Only ) ] ]              ; OTHERWISE, all LAs hatches places equal to the modeller input divided by the total number of LAs.

    ask places [let move-place one-of patches with [LAs-name = [LAs-name-t] of myself]              ; As the houses did before, places pick a random patch within the same LA
               set xcor [pxcor] of move-place                                                       ; Then sets its X coordinate to match that of the random patch
               set ycor [pycor] of move-place                                                       ; Then sets its Y coordinate to match that of the random patch
               create-link-with min-one-of tramstops [distance myself]                              ; Then creates a link to the nearest tramstop,
               set color orange                                                                     ; Changes its colour
               set size 3 ]                                                                         ; And its size

ask links [if Speed != 10 [                                                                         ; The model then asks all links to check if their speed has already been set to 10
    set Speed 1 + random 8                                                                          ; If not (should only apply to links between houses and tramstops or places and tramstops
    set Capacity 10]]                                                                               ; And sets capacity (again, still an unused variable).
    repeat 10 [ask tramstops [if not any? links with [Speed < 10][                                  ; Then, the model asks tramstops to check if they have any slow speed links
      ask one-of places with [LAs-name-t = [LAs-name-t] of self] [                                  ; And if not, asks one of the places within their LA to ...
               move-to myself                                                                       ; move to the same patch as the asking tramstop ...
               set  xcor xcor + random 2 - random 2                                                 ; Shift the X coordinate a bit
               set  ycor ycor + random 2 - random 2                                                 ; Shift the Y coordinate a bit
               ask my-links [die]                                                                   ; Sever links to other tramstops
               create-link-with myself [set Speed (1 + random 9)                                    ; And create an appropriate link with the asking tramstop.
                                        set Capacity 10]]
               ask one-of houses with [LAs-name-t = [LAs-name-t] of self] [                         ; This same process repeats with houses. These stepsensure
               move-to self                                                                         ; there are no tramstops that are not the "nearest" tramstop to anyone or anything.
               set  xcor xcor + random 2 - random 2
               set  ycor ycor + random 2 - random 2
               ask my-links [die]
          create-link-with myself[set Speed (1 + random 9)
                                  set Capacity 10]]]]]
end

to setup-denizens
  ask LAs [ if any? houses with [LAs-name-t = [LAs-name-t] of myself] [                              ; The model then asks the LAs that have houses to...
                  ifelse Reduce_Pop_For_Display?                                                     ; Check if the modeller wants to reduce the population for display and...
                       [hatch-denizens (Max_Random_Population + (LAs-population-t / 1000)) ]         ; If so, hatch a significant number of commuters (but not nearly as many as would be hatched if there are high populations
                       [hatch-denizens LAs-population-t] ] ]                                         ; Otherwise, hatch as many commuters as the population says to

   ask denizens [                                                                                    ; Ask the newly created commuter-agents
   move-to one-of houses with [LAs-name-t = [LAs-name-t] of myself]                                  ; to move to one of the houses in their LA
   set size 2                                                                                        ; Set their size
   set color green                                                                                   ; Set their colour
   create-link-with one-of houses-here                                                               ; And create a link to the house on their current location
   set current-location one-of houses-here                                                           ; And start setting various commuter specific details, like their current-location
    set My_Places []                                                                                 ; some variables are easier to set later if first set to an empty list, written as []
   set current-path []                                                                               ;  -
   repeat (5 + random 5 )[let possible-destination one-of places                                     ; Then, they start picking random places they might want to go
      if is-list? nw:turtles-on-path-to possible-destination [                                       ; check to make sure there is a path to get there
      set My_Places lput possible-destination My_Places]]                                            ; And if so, start filling up the previously empty list of their places
   set My_Places remove-duplicates My_Places                                                         ; Double check to be sure there are no duplicates on the list of places to go
    if empty? My_Places [die]                                                                        ; A security check to be sure that no agent can continue to exist if it has not managed to find any places that it can travel to
    set destination one-of My_Places                                                                 ; Select one of their places to go as their destination, or the next place they want to go
   set current-path nw:turtles-on-path-to destination                                                ; Record the path to get to their selected destination
   repeat 2 [ if not empty? current-path [set current-path but-first current-path]                   ; Remove the first two stops on the path because these will be themself, followed by the house they are currently located in
   set next-location first current-path                                                              ; Set the next stop on their path as their short-term goal, which should be the nearest tramstop
   face next-location ]                                                                              ; And face that tramstop
   set My_Places fput one-of houses-here My_Places                                                   ; Add the house in which they are currently located to their list of places (so they can get home again later)
   set starting-place one-of houses-here                                                             ; Ask them to record the origen of they next journey
   set travel-timer 0 ]                                                                              ; And ask them to ensure they start counting how long it takes to reach their destination from zero
end

to check-speed
  ask denizens [
    let who-here [who] of current-location
    let who-there [who] of next-location
    if link who-here who-there != nobody [set current-speed [Speed] of link who-here who-there]
    if link who-there who-here != nobody [set current-speed [Speed] of link who-there who-here]
    if Garrulous? [print current-speed]
  ]
end

to go
  ask denizens [                                                                                      ; The basic "go" process
    ifelse distance next-location > (1 * current-speed)                                               ; Commuters check to see if they are more they are less than one timestep away from arriving at their next proximal destination
    [fd 1 * current-speed                                                                             ; If so, they carry on moving forward
    set travel-timer travel-timer + 1 ]                                                               ; and add one to their travel time
    [move-to next-location                                                                            ; If they are closer than one timestep worth of travel to their next proximal destination, they move directly to it
     set travel-timer travel-timer + 1                                                                ; and one to their travel time
      ask my-links [die]                                                                              ; ask their links to the previous proximal destination to die
      ifelse length current-path > 1 [set-next-step]                                                  ; Check to see if they are at their destination
      [when-at-destination]]]                                                                         ; If not, they go through the processes to head to the next proximal destination
  tick                                                                                                ; Or they go through the processes for arriving at their destination
end

to when-at-destination
     set current-location next-location                                                ;  They copy over their next proximal destination to their current location
     set travel-timer travel-timer + 1                                                 ;  They add one to their travel time
    if Export_Data?                                                                    ;  Check to see if the modeller wants data exports
    [file-open (word output-filename ".csv" )                                          ;  If so, they open the appropriate file. The "," enables it to be formatted for .csv
    file-print                                                                         ;  Adds their who number, origen, origen LA, destination, destination LA, and travel time .
    (word who "," starting-place "," [LAs-name-t] of starting-place ","
              destination "," [LAs-name-t] of destination "," travel-timer)
    file-close]                                                                        ;  And closes the file - still important.
    set starting-place destination                                                     ;  They copy over their current destination to be the starting-place for the next journey.
    set destination one-of My_Places                                                   ;  Pick a  new destination is head to...
    set travel-timer 0                                                                 ;  Reset the counter that tracks time elapsed for travel back to zero
    if any? places-here                                                                ;  Checks to see if they are currently at a Place and...
       [create-link-with one-of places-here]                                           ;  If so, creates a link with that place.
     if any? houses-here                                                               ;  Checks to see if they are currently at a House and...
       [create-link-with one-of houses-here]                                           ;  If so, creates a link with that house.
     set current-path []                                                               ;  Resets the current-path to their new destination back to an empty list
     set current-path nw:turtles-on-path-to destination                                ;  Identifies the path to that new destination and fills in the recently reset current-path
     set next-location first current-path                                              ;  Sets next proximal destination
     face next-location                                                                ;  Turns to face that proximal destination
     set current-path but-first current-path                                           ;  And removes the proximal destination from the current-path
end


to set-next-step
     if any? tramstops-here                                                  ;  Having arrived at a proximal destination, the commuter-agent checks to see what tramstop is located at its current location
       [create-link-with one-of tramstops-here]                              ;  And creates a link with that tramstop
     if any? places-here                                                     ;  Although it should not happen, the the commuter-agent checks to see if there is a place at its current location instead of a tramstop
       [create-link-with one-of places-here]                                 ;  And if so, creates a link with that place
     if any? houses-here                                                     ;  Although it should not happen, the the commuter-agent checks to see if there is a housee at its current location instead of a tramstop
       [create-link-with one-of houses-here]                                 ;  And if so, creates a link with that house
     set current-location next-location                                      ;  copies the recently reached proximal destination over as its current location
     set current-path but-first current-path                                 ;  And removes the recently reach proximal destination from the path to take to its ultimate destination
     set next-location first current-path                                    ;  Sets its next proximal destination to be the first step on its path to its ultimate destination
     face next-location                                                      ;  And turns to face that proximal destination
end

to initial-exports
     if Export_Data?
        [file-open (word output-filename ".csv" )                                               ; Creates a file named with the output-filename created earlier. Wrapping it in (word  ".csv") allows you to set the file type to .csv
         file-print (word "Commuter,Origen,Origen_LA,Destination,Destination_LA,Travel_time")   ; Set up the headers that should appear in the output file
 ;       file-print (word " , , , , ,")                                                         ; Currently not needed - but you could use row (or more like it) to write out any other necessary details from the setup process
         file-close]                                                                            ; Closes the file - necessary to save the input just added and also prepare the file to be opened and written to again in the future
end
@#$#@#$#@
GRAPHICS-WINDOW
294
17
845
569
-1
-1
3.0
1
8
1
1
1
0
0
0
1
-90
90
-90
90
0
0
1
ticks
30.0

BUTTON
5
60
175
93
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
3
173
176
206
Label_Tramstops?
Label_Tramstops?
1
1
-1000

CHOOSER
5
10
175
55
projection
projection
"GM_LAs_R" "Random"
0

SLIDER
3
533
290
566
Number_Generated_Tramstops_Random_Only
Number_Generated_Tramstops_Random_Only
3
100
19.0
1
1
NIL
HORIZONTAL

SLIDER
4
571
304
604
Number_Generated_Places
Number_Generated_Places
3
100
69.0
1
1
NIL
HORIZONTAL

SWITCH
2
136
175
169
Garrulous?
Garrulous?
1
1
-1000

BUTTON
21
95
84
128
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
87
95
166
128
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
497
290
530
Number_Generated_LAs_Random_Only
Number_Generated_LAs_Random_Only
2
15
7.0
1
1
NIL
HORIZONTAL

INPUTBOX
6
432
158
492
Max_Random_Population
150.0
1
0
Number

SWITCH
3
212
177
245
Label_LAs?
Label_LAs?
1
1
-1000

SWITCH
2
249
179
282
Reduce_Pop_For_Display?
Reduce_Pop_For_Display?
0
1
-1000

SWITCH
3
286
183
319
Tram_Commute_Only?
Tram_Commute_Only?
0
1
-1000

INPUTBOX
2
322
202
382
Output_File
CodeTest
1
0
String

SWITCH
8
389
140
422
Export_Data?
Export_Data?
1
1
-1000

MONITOR
912
93
1014
138
Total population
count(denizens)
17
1
11

MONITOR
922
165
1005
210
Total houses
count(houses)
17
1
11

MONITOR
922
249
1001
294
Total places
count(places)
17
1
11

MONITOR
917
13
1023
58
Total trampstops
count(tramstops)
17
1
11

@#$#@#$#@
## WHAT IS IT?
This model is intended to demonstrate three broad concepts, each of which has an associated NetLogo extension: 
•	importing and exporting files into NetLogo via the CSV extension, 
•	loading point, line and polygon shapefiles into NetLogo via the GIS extension, and 
•	building and navigating networks of agents via the NW extension.
To achieve this, the model creates a cross-local authority tram network along with houses, commuters and places for them to travel to. The modeller can choose to create a randomly generated tram network via a few inputs that are only applicable to the random model (number of local authorities, number of tram stops, etc. all are indicated by "_Random_Only" in the name of the input) or can  load a real-world tram network using downloaded shape files (in this case, the shape files relate to the Greater Manchester combined authority and Metrolink system). 

## HOW IT WORKS
First, the "Projection" must be set to either "Random" or "GM_LAs". The model operation is broadly similar for both, although the set up procedures are different because. 

In both cases, the NetLogo world is divided into local authorities, each with a name and resident population, before tram stops are located and linked. If "Projection" is set to:
•	"Random" the model setup uses the value of the "Number_Generated_LAs_Random_Only" slider (between 2 and 15 in increments of 1) and built-in NetLogo functions to determine the number and random location of "LAs" agents. The LAs agents are then assigned a random population below the value of "Max_Random_Population" as input by the modeller. The LAs then adjust their colour relative to their population (with a special check to ensure they do not change it to black). The model then asks black patches to observe if any of their neighbours are a non-black colour and, if so, to change their colour to match (choosing randomly between colours if two or more neighbours are not black). The model setup then uses the value of "Number_Generated_Tramstops_Random_Only" slider (between 3 and 100 in increments of 1) to determine the number and initial location of tramstops throughout the entire area. The tramstops are then connected in a preferential attachment network and their position is adjusted by repeating "layout-spring" to improve its appearance.
•	"GM_LAs" the model setup draws on .prj, .csv, and .shp files made available by the modeller. These files contain the number, location, shape and name of local authorities (as well as their resident population), and the number, location and names of tramstops as well as how they are linked. 

The local authorities will display their names if the modeller input "Label_LAs?" is set to TRUE. The tramstops will display their names if the modeller input "Label_Tramstops?" is set to TRUE. If "Projection" is set to random, the names of LAs and tramstop agents is simply their who number. 

After this, the model setup is the same for both projections. Setup continues as the model uses the populations of each local authority and built-in NetLogo functions to create a number of houses within each local authority between 1 and the total population of that local authority). The houses are then located randomly within the local authority. The model then creates commuter agents equal to the population of the local authority, unless "Reduce_Population_for_display?" is set to TRUE. This limits the number of commuters per local authority to the value of "Max_Random_Population" + (the total population of the local authority / 1000). Although "Reduce_Population_for_display?" can be set to TRUE for both the random and non-random projections, it will only have a discernible effect on the non-random projection if "Max_Random_Population" is significantly smaller than the actual population of a given local authority. This switch is intended to improve the setup time, run speed and visual interpretability of non-random projections when the real-world population is problematically high. 

However many houses are created, they are then connected to the tram network by creating a link to the nearest tramstop.

The model then uses value of "Number_Generated_Places"  (between 3 and 100 in increments of 1) to create and locate places (non-house buildings that commuters can travel to) within the local authorities. The places are then connected to the tram network by creating a link to the nearest tramstop.

The model offers the option to locate houses and places either only within local authorities that have tram stops within their boundaries (by setting "Tram Commute Only?" to TRUE) or within any local authority (by setting "Tram Commute Only?" to FALSE).

The model then assigns commuters a small set of places across the network that they can travel to. The house that each commuter begins at is also added to this list of travel destinations. When the model runs, the commuters select one of their destinations, plots a path to get there via the tram network, and proceeds to move across the network. When they arrive, they choose a new destination and repeat the process. 

The model offers the option to allow to export data to a .csv file through the modeller inputs of "Export data?" and "Output_file". If "Export_data?" is set to TRUE, the model creates a .csv named using the input in the "Output_file" field and 6 columns.  Whenever a commuter arrives at their destination, they write a line to the .csv file that states their who number, the house or place at which the journey started, the local authority in which the journey started, the house or place at which the journey ended, the local authority in which the journey ended, and the number of time steps elapsed during the journey. 

NOTE: The random projection model requires several inputs that the non-random projection model does not (Number_Generated_LAs, Number_Generated_Tramstops, Max_Random_Population).
The non-random projection model draws these same details from the uploaded .shp files. Setting these variables will have no effect on the model if "Projection" is not set to "Random". 

There are also options intended to be useful for demonstration and bug-testing purposes.  "Reduce_Population_for_Dispaly?" limits the population to a fraction of its total in order to speed up the set up and go processes as well as improve the interpretability of the display. If "Garrulous?" is set to TRUE, the model runs with many outputs written to the command centre in order to improve bug testing. This is unlikely to be interesting for normal operation. 

## HOW TO USE IT
Put all files in a sensible folder. This is especially important when running the non-random projection as the model will need to access the shape files and/or .csv files. You may need to rename the files, the folders they are in, or the path to the files as it appears in the code. 
When the model is opened, the modeller will need to decide whether to run a random or non-random model. The modeller should set the options for labelling tram stops and/or local authorities, restricting the population for display, restricting the houses and places to LAs with tramstops only, and whether or not an export file should be created (as well as setting the name of that file in the Output_File field). 
Random models will require attention to the inputs at the bottom (Max_Random_Populaton, Number_of_Generated_LAs, Number_of_Generated_Tramstops, Number_of_Generated_Places). 
Hit set up. 
Hit Go once or Go Forever. 

## THINGS TO NOTICE
This model is not particularly realistic. It assumes that all commuters travel directly from their houses to their nearest tram stop, travel by tram to the stop nearest their intended destination, then travel directly to that destination before turning around and repeating the process with a new destination (which might be their house). 
There is no wait time at tram stops. There is no maximum capacity on the trams. There is no distribution of travel speeds among commuters to account for people that might bike, drive, bus, rollerskate or otherwise travel to the tram stop or people that walk slower than others. 
Commuters do not spend any significant time at their destinations. They do not have regular patterns of travel, analogous to a standard commute, but instead randomly pick their destination from among the small set of destinations they have designated as “theirs”. 
This is because this model is not intended to replicated an interesting real-wold behaviour with the detail and specificity needed to really say something about that behaviour. Instead, it is meant to demonstrate the processes of importing files, using GIS data, navigating networks, and running experiments. As such, the code is extremely thoroughly commented. 
## THINGS TO TRY
A couple of things to try would be to:
•	run parameter sweeps on the random model to identify whether there are interesting interactions,
•	replace the Greater Manchester shapefiles with analogous files for another tram network, or
•	rewrite the output file to include reports from place-agents or tramstop-agents to identify which is the most popular.
## EXTENDING THE MODEL
Reasonable interactions would include:
•	Adding bus, bike lane, road, train or other networks, 
•	Define the destinations that commuters travel to by when they are likely to arrive or how long they spend there, 
•	Add options to vary the travel speed, 
•	Introduce actual trams to the tram network so that commuters wait at tram stops or when changing tram lines, 
•	Other?
## NETLOGO FEATURES

## CREDITS AND REFERENCES
This model use the NetLogo code examples for Travel The Line and GIS extension. 

## HOW TO CITE
If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.
For the model itself:
* Kasmire, J. (2020). Tram Commute. UK Data Services and University of Manchester, UK.
Please cite the NetLogo software as: 
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

## COPYRIGHT AND LICENSE
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.
This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
setup
display-cities
display-countries
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
