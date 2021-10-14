globals [ noise-level
 current-turtle
 vocabulary
 alphabet
]

turtles-own [
  prize-count
  temp-word
  current-word
  currently-playing
]

to setup
  clear-all
  ifelse Garrulous?
    [resize-world -100 100 -50 50]
    [resize-world -100 100 -100 100]
  set current-turtle []
  set alphabet ["a" "b" "C" "c" "d" "e" "f" "g" "o" "1" "2" "3" "4" "5"]
  set vocabulary [["a" "a" "a"] ["b" "b" "b"] ["C" "c" "c"] ["1" "1" "1"] ["2" "2" "2"] ["d" "3" "d"] ["f" "o" "o"] ["g" "e" "e"] ["g" "4" "5"] ["l" "o" "l"] ]
  set-default-shape turtles "person"
  ask patches with [ pxcor < -11 and pxcor > 11 ] [ set pcolor white]
  create-turtles Number_Players [
    set size 3                   ;; be easier to see
    set color 2
    __set-line-thickness 2
    set currently-playing 0
    set prize-count 0
    set current-word [""]]
  establish-layout
  set noise-level random 100
  reset-ticks
  if Garrulous? [print "Initial set up is now complete."]
end

to establish-layout
  ifelse layout-style = "random" [ask turtles [move-to one-of patches]]
      [layout-circle turtles 50]
  if Garrulous? [print (word "Layout set to " layout-style ".")]
end

to go
  set noise-level noise-level + random 10 - random 10
  if noise-level < 0 [set noise-level 0]
  ifelse length current-turtle = 0
  [start-new-game]
  [ifelse length current-turtle = game-length
    [wait .5
     end-game]
    [play-game]]
  tick
end

to start-new-game
  ask turtles [set currently-playing 0]
  if choose-starter = "randomly" [ask-random]
  if choose-starter = "most prizes" [ask-most]
  if choose-starter = "least prizes" [ask-least]
end

to ask-random
  ask one-of turtles with [currently-playing = 0 ]
  [  if Garrulous? [print "Random player asked to play..."]
   participate]
end

to ask-most
  ifelse mean [prize-count] of turtles != 0 and any? turtles with [currently-playing = 0 and prize-count > mean [prize-count] of turtles]
  [ask one-of turtles with [currently-playing = 0 and prize-count > mean [prize-count] of turtles] [participate]]
    [ask-random]
end

to ask-least
  ifelse mean [prize-count] of turtles != 0 and any? turtles with [currently-playing = 0 and prize-count < mean [prize-count] of turtles]
  [ask one-of turtles with [currently-playing = 0 and prize-count < mean [prize-count] of turtles] [participate]]
  [ask-random]
end

to ask-nearest
  let closest-to-me min-one-of turtles [distance myself]
  ifelse [currently-playing] of closest-to-me = 0 [ask closest-to-me [participate]]
  [ask one-of turtles with [currently-playing = 0 ][participate]]
end

to ask-nearish
  ifelse any? turtles in-radius 5 with [currently-playing = 0]
  [ask one-of turtles in-radius 5 with [currently-playing = 0][participate]]
  [ask one-of turtles in-radius 55 with [currently-playing = 0][participate]]
end

to participate
  set currently-playing 1
  set size 5
  ifelse length current-turtle = 0
     [set xcor -10
      set ycor 0 ]
      [set xcor ([xcor] of turtle first current-turtle + 10)
      set ycor ([ycor] of turtle first current-turtle + 1)]
  ifelse length current-turtle = 0
     [set temp-word one-of vocabulary
      set current-word temp-word
      if Garrulous? [wait .5 print (word "Player " length current-turtle " has decided to whisper the word " current-word ".")]]
     [set temp-word ([current-word] of turtle first current-turtle)
      if Garrulous? [wait .5 print (word "Player " length current-turtle " is listening...")]
      apply-distortion]
  set current-turtle fput [who] of self current-turtle
  set label current-word
end

to play-game
  if choose-next = "randomly" [ask-random]
  if choose-next = "most prizes" [ask-most]
  if choose-next = "least prizes" [ask-least]
  if choose-next = "nearest" [ask turtle first current-turtle [ask-nearest]]
  if choose-next = "nearish" [ask turtle first current-turtle [ask-nearish]]
end

to apply-distortion
  ifelse apply-noise-distortion?
  [ifelse noise-level < Acceptable-noise-level
         [set current-word temp-word if Garrulous? [print (word "Player " length current-turtle " can hear easily at " noise-level " decibels." )]]
         [set current-word temp-word
             ifelse random 3 >= 2
                 [set temp-word replace-item 0 temp-word one-of alphabet
                  if Garrulous? [print (word "Ah, it is quite noisy at " noise-level " decibels. Player " length current-turtle " has misheard the first phoneme. ")]]
                 [if Garrulous? [print (word "Player " length current-turtle " is listening closely, even at " noise-level " decibels and has heard the first phoneme correctly.")]]
             ifelse random 3 >= 2
                  [set temp-word replace-item 1 temp-word one-of alphabet
                   if Garrulous? [print (word "Ah, it is quite noisy at " noise-level " decibels. Player " length current-turtle " has misheard the second phoneme. ")]]
                  [if Garrulous? [print (word "Player " length current-turtle " is listening closely, even at " noise-level " decibels and has heard the second phoneme correctly.")]]
             ifelse random 3 >= 2
                  [set temp-word replace-item 2 temp-word one-of alphabet
                   if Garrulous? [print (word "Ah, it is quite noisy at " noise-level " decibels. Player " length current-turtle " has misheard the third phoneme. ")]]
                  [if Garrulous? [print (word "Player " length current-turtle " is listening closely, even at " noise-level " decibels and has heard the third phoneme correctly.")]]
             set current-word temp-word
             if Garrulous? [print (word "Player " length current-turtle " has heard" current-word ".")]]]
    [set current-word temp-word
    if Garrulous? [print (word "Player " length current-turtle " has heard" current-word ".")]]
end

to end-game
  if Garrulous? [print (word "The players this round were "current-turtle ".")]
  let start-turtle-word [current-word] of turtle last current-turtle
  let end-turtle-word [current-word] of turtle first current-turtle
  ifelse start-turtle-word = end-turtle-word [
    if Garrulous? [print (word "Everyone gets a big prize! Player 0 whispered " start-turtle-word " and Player " length current-turtle " heard " end-turtle-word ".")]
    ask turtles with [currently-playing = 1] [    set prize-count prize-count + 5]]
[ if Garrulous? [print (word "It was just too noisy. Player 0 whispered " start-turtle-word " but Player " length current-turtle " heard " end-turtle-word ". Still, small prizes will be awarded if any of the phonemes match.")]
    ask turtles with [size = 5][
    if item 0 start-turtle-word = item 0 end-turtle-word [set prize-count prize-count + 1]
    if item 1 start-turtle-word = item 1 end-turtle-word [ set prize-count prize-count + 1]
      if item 2 start-turtle-word = item 2 end-turtle-word [ set prize-count prize-count + 1]]]
  ask turtles with [size = 5][
    set color 0 + prize-count
    if remainder color 10 = 0 [set color color + 2]
    set size 3
    set currently-playing 0
    set label ""]
  set current-turtle []
  establish-layout
end
@#$#@#$#@
GRAPHICS-WINDOW
275
15
1067
418
-1
-1
3.90244
1
14
1
1
1
0
1
1
1
-100
100
-50
50
1
1
1
ticks
30.0

BUTTON
30
10
98
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
181
10
249
43
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
99
10
180
43
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
1225
15
1395
48
Number_Players
Number_Players
10
300
95.0
1
1
NIL
HORIZONTAL

PLOT
10
203
260
368
Prize distribution
Players
Prize count
0.0
10.0
0.0
150.0
true
false
"set-plot-x-range 0 count turtles\nset-plot-y-range 0 count turtles\nset-histogram-num-bars Number_Players\n\n" ""
PENS
"Distribution" 1.0 1 -10899396 true "" "histogram [color] of turtles"

MONITOR
135
65
260
110
Total prize count
sum [prize-count] of turtles
3
1
11

MONITOR
5
65
130
110
Current noise level
noise-level
3
1
11

CHOOSER
1080
70
1218
115
choose-starter
choose-starter
"randomly" "most prizes" "least prizes"
0

CHOOSER
1080
125
1218
170
choose-next
choose-next
"randomly" "nearest" "most prizes" "least prizes" "nearish"
0

CHOOSER
1080
15
1218
60
layout-style
layout-style
"layout-circle" "random"
0

SWITCH
1225
105
1395
138
apply-noise-distortion?
apply-noise-distortion?
0
1
-1000

SWITCH
1080
240
1192
273
Garrulous?
Garrulous?
0
1
-1000

SLIDER
1225
60
1397
93
game-length
game-length
2
10
4.0
1
1
NIL
HORIZONTAL

INPUTBOX
1230
155
1382
215
Acceptable-noise-level
70.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

This is a model of a game of Telephone (also known as Chinese Whispers in the UK), with agents representing people that can be asked, to play. The first player selects a word from their internal vocabulary and "whispers" it to the next player, who may mishear it depending on the current noise level, who whispers that word to the next player, and so on. 

When the game ends, the word chosen by the first player is compared to the word heard by the last player. If they match exactly, all players earn large prize. If the words do not match exactly, a small prize is awarded to all players for each part of the words that do match. Players change color to reflect their current prize-count. A histogram shows the distribution of colors over all the players. 

The user can decide on factors like 
* how many players there are, 
* whether they are laid out in a circle or just randomly, 
* how many players participate in a game, 
* whether to apply noise-distortion or not,
* at what decibel level noise distortion starts interfering with the game, 
* how the first player to participate is chosen, 
* how further players are chosen, and
* whether or not the games run quickly and silently or slowly and with commentary to explain what is happening. 

These factors influence how likely players are to win a game and thus how the color of players will be distributed over time. 

## HOW IT WORKS

The world has dimensions and also a noise level that moves up and down randomly at each time step, but cannot fall below 0. When the model is initiated, a number of characters are laid out across the dimensions according to a modeller input, which appears in the interface as "layout-style" and gives the options of random or circle. When created, all agents have a vocabulary (set in the code) of several 2 character "words" and an alphabet consisting of all the characters that appear in any position of any of the words in their vocabulary. 

The first player is chosen according to a modeller input, which appears on the interface as "choose-starter" which gives the options of randomly, most prizes and least prizes (self-explanatory). That agent randomly selects one of the words in their vocabulary. 

The next player is chosen according to a modeller input, which appears on the interface as "choose-next" which gives the options of randomly, most prizes, least prizes, nearest and near-ish (self-explanatory?). The first player "whispers" their chosen word to the next player, who will hear it correctly if the noise-level is below the "Appropriate-noise-level" as set by the modeller. If the noise level is above "Appropriate-noise-level" then a small test is performed for each part of the word, with a chance that the listener may mishear some but not all of the sounds. The listener then becomes the whisperer and the process is repeated until the number of players reaches the "game-length" as set by the modeller. At that point, the game ends, the word chosen by the first player and the word heard by the last player are compared and prizes are awarded. 

Each player in the game earns a 5 point prize if the two words match exactly. Thus, [a a a] and [a a a] earn 5 points for all players. 

Each player in the game earns a 1 point prize for each phoneme that matches when the two words do not match exactly. Thus, a maximum of 2 points can be awarded for partially matched words, so [a a a] and [a a b] would earn 2 points but [a a a] and [a b b] would earn 1 point. 

Players do not earn any points for words that have no matching phoneme-positions in common. Thus, [a a a] and [b b b] would earn 0 points, as would [a b a] and [b a b]. 


After the game ends and any prizes are awarded, all agents lay themselves out again according to the modeller designated layout-style and adjust their color to reflect their current prize-count. 0 prizes = dark grey (color value 2) but players that have won a prize for exactly matching the first and final words would become light grey (color value 7). If they won again, they would be dark red (color value 12), etc. Any player whose prize count ends in 0 (such as 10, 20, 150, etc.) would become invisible against a black background, so their prize count is increased by 2.  


A histogram shows the distribution of colors over all the players as a proxy for showing the distribution of prize counts. 


## HOW TO USE IT

Adjusting the layout-style has no effect on the model functioning. This is purely an option to demonstrate the visual capabilities of NetLogo. 

Similarly, adjusting Garrulous? To Yes or No has no real effect on the model functioning, although it does make the model run much slower and with much more writing appearing in the Command Centre bar at the bottom of the screen. This is useful for those unfamiliar with the model to gain an understanding of the steps taken by the model. It is also useful for bug-testing during model development. 

Adjusting the other sliders and switches DOES affect the model functioning. Choices about how 
* to select the first player or the subsequent players can skew the prize distribution. 
* long a game lasts can affect the chance that players will get a perfect match between first and final words. 
* to apply noise-distortion, and what level of noise is appropriate, influence the likelihood of earning (big) prizes.
* many agents are available to play can effect how long it takes for feedback loops and large scale dynamics to display.  

These are not always straightforward and can interact. For example, setting a long game means more players can win prizes but makes it much harder to win prizes if noise distortion is applied when Appropriate-noise-level is set low. 

## THINGS TO NOTICE

What shape is the histogram? Does this change over time? Does it depend on the way the sliders and swiches are set? 

## THINGS TO TRY

Try varying all of the switches and sliders in various combinations (excluding layout-style and Garrolous?, which only affect the modeller's experience of the model while it is running).


## EXTENDING THE MODEL

Add more words to the vocabulary. 
Extend the code to make the words longer. 
Adjust the prizes awarded for getting perfect and/or partial matches. 
Adjust the likelihood that players can correctly hear/mishear a word when the noise-level is above the Appropriate-noise-level.

## NETLOGO FEATURES

## CREDITS AND REFERENCES

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:
* Kasmire, J. (2020). Telephone Game. UK Data Services and University of Manchester, UK.
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
repeat 20 [ go ]
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
1
@#$#@#$#@
