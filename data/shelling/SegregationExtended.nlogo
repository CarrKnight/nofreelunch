;; This NetLogo model accompanies our chapter "Agent-based computational models" in the forthcoming volume The Research Handbook on Analytical Sociology (Ed. G. Manzo)
;; It is based on Wilensky's NetLogo implementation of Schelling's segregation model (reference see below).
;; The present NetLogo model is a considerably extended version developed by Andreas Flache & Carlos de Matos Fernandes (University of Groningen, The Netherlands)
;; For more information on our research group, please see https://sites.google.com/view/normsandnetworks/home
;; The second NetLogo model that relates to our chapter is labelled as SegregationDiscreteChoice.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Notice that in this model we use very inefficient programming to maximize transparency for users new to NetLogo. E.g. constructing lists or arrays for several globals would save a lot of lines of code.
;; We chose for more transparency of code over efficient coding because this model accompanies a chapter meant to be an introduction for newcomers to ABM.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------
;-------------turtles are labelled as households
breed [ households household ]     ;;a household is an agent with an "ethnicity" and an initial location (= patch)

;-------------each household has the following variables
households-own [
  ethnicity                         ;; 1= Red, 2= Green, 3=Blue, 4=Yellow  ;; Baseon Clark & Fosset (2008) US constituency: White, Black, Hispanic, Asian
  happy?                            ;; for each household, indicates whether satisfied: % household's neighbors <, =, > to households ethnicity
  similar-nearby                    ;; how many neighboring patches have a household with my ethnicity?
  other-nearby                      ;; how many have a household of another ethnicity?
  total-nearby                      ;; sum of previous two variables
]

;-------------global information to calculate macro-level ouctomes
globals [
  percent-similar                   ;; on the average, what percent of a household's neighbors are the same ethnicity as that household? This is T in the paper.
  percent-similar-Red               ;; percent-similar for Red agents only
  percent-similar-Green             ;; percent-similar for Green agents only
  percent-similar-Blue              ;; percent-similar for Blue agents only
  percent-similar-Yellow            ;; percent-similar for Yellow agents only

  percent-unhappy                   ;; what percent of the households are unhappy?
  percent-unhappy-Red               ;; what percent of the red households are unhappy?
  percent-unhappy-Green             ;; what percent of the green households are unhappy?
  percent-unhappy-Blue              ;; what percent of the blue households are unhappy?
  percent-unhappy-Yellow            ;; what percent of the yellow households are unhappy?

  ;; Variables for storing initial state (beforing presing "GO") to report in simulation experiment
  ;; You can see this is other variables via the added '0'
  percent-similar-0                 ;; on the average, what percent of a household's neighbors are the same ethnicity as that household?
  percent-similar-Red-0             ;; percent-similar for Red agents only
  percent-similar-Green-0           ;; percent-similar for Green agents only
  percent-similar-Blue-0            ;; percent-similar for Blue agents only
  percent-similar-Yellow-0          ;; percent-similar for Yellow agents only
  percent-unhappy-0                 ;; what percent of the households are unhappy?
  percent-unhappy-Red-0             ;; what percent of the red households are unhappy?
  percent-unhappy-Green-0           ;; what percent of the green households are unhappy?
  percent-unhappy-Blue-0            ;; what percent of the blue households are unhappy?
  percent-unhappy-Yellow-0          ;; what percent of the yellow households are unhappy?

  percent-clustering-Red            ;; percent-similar-Red divided by percent of Red agents in population
  percent-clustering-Green          ;; percent-similar-Green divided by percent of Green agents in population
  percent-clustering-Blue           ;; percent-similar-Blue divided by percent of Blue agents in population
  percent-clustering-Yellow         ;; percent-similar-Yelow divided by percent of Yellow agents in population

  ;; to generate a 60/20/10/10 (fourgroups) or a 50/50 (two groups) population
  population-composition            ;; a list object created upon setup defining which share each of the possible four groups has in the population

  num-Population                    ;; number of households that were created upon initialization, calculated in set-up
  num-Red-Population                ;; number of households of type Red, calculated upon setup after populationComposition was defined
  num-Green-Population              ;; number of households of type Green, calculated upon setup after populationComposition was defined
  num-Blue-Population               ;; number of households of type Blue, calculated upon setup after populationComposition was defined
  num-Yellow-Population             ;; number of households of type Yellow, calculated upon setup after populationComposition was defined
  percent-Red-Population            ;; percent of households of type Red, calculated upon setup after households were created and counted
  percent-Green-Population          ;; percent of households of type Green, calculated upon setup after households were created and counted
  percent-Blue-Population           ;; percent of households of type Blue, calculated upon setup after households were created and counted
  percent-Yellow-Population         ;; percent of households of type Yellow, calculated upon setup after households were created and counted
]



;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------
;-------------Prepare the model for initialization
to setup
  clear-all
  resize-world -25 25 -25 25                                                       ;; to ensure a 51x51 world size (see chapter)
  set population-composition ifelse-value fourGroups                               ;; added option fourGroups to mimic relatively realistic scenario for big US city
  [ [ 1 1 1 1 1 1 2 2 3 4 ] ]                                                      ;; proportion of 60% reds/20% greens/10% blues /10% yellows
  [ [ 1 2 ] ]                                                                      ;; 50-50 proportion per group

  ask patches [                                                                    ;; create households on random patches with ethnity assigned randomly based on population composition
    set pcolor white
    if random 100 < density [                                                      ;; create an agent on patch with probability given by occupancy density
      sprout-households 1 [ set ethnicity one-of population-composition ]          ;; one-of selects at random one element from list population-composition
      ;;-----if ( pxcor != 0 ) [ sprout-households 1 [ ifelse ( pxcor < 0 ) [ set ethnicity 1 ][ set ethnicity 2 ] ] ]         ;;-----Addition: It generates an initially maximally segregated population (works only for two groups version)
    ]
  ]

  ask households [ ifelse BlackWhiteVis              ;; assign to created households their color
    [ set color ( ifelse-value                       ;; IF BlackWhiteVis = ON
      ethnicity = 1 [ 6 ]                            ;; 6 is grey
      ethnicity = 2 [ 6 ]
      ethnicity = 3 [ Black ]
      ethnicity = 4 [ Black ] )
    ]
    [ set color ( ifelse-value                       ;; ELSE BlackWhiteVis = OFF
      ethnicity = 1 [ Red ]
      ethnicity = 2 [ Green ]
      ethnicity = 3 [ Blue ]
      ethnicity = 4 [ Yellow ] )
    ]
  ]

  calculate-group-size                               ;; compute numbers of households and of different household types that were assigned above
  update-households                                  ;; calculate if the household is happy and wants to move
  update-globals                                     ;; update outcome measures
  store-initial-neigh                                ;; store initial happiness and percentage similar in first neighborhood
  reset-ticks
end

;-------------Calculate group sizes and percentages per group
to calculate-group-size
  set num-Population count households
  set num-Red-Population ( count households with [ ethnicity = 1 ] )
  set num-Green-Population ( count households with [ ethnicity = 2 ] )
  set num-Blue-Population ( count households with [ ethnicity = 3 ] )
  set num-Yellow-Population ( count households with [ ethnicity = 4 ] )
  set percent-Red-Population ( 100 * num-Red-Population / num-Population )
  set percent-Green-Population ( 100 * num-Green-Population / num-Population )
  set percent-Blue-Population ( 100 * num-Blue-Population / num-Population )
  set percent-Yellow-Population ( 100 * num-Yellow-Population / num-Population )
end

;-------------Set variables for storing initial state prior to any relocations to report in simulation experiment
to store-initial-neigh
  set percent-similar-0 percent-similar                  ;; on the average, what percent of a household's neighbors are the same ethnicity as that household?
  set percent-unhappy-0 percent-unhappy                  ;; what percent of the households are unhappy?
  set percent-unhappy-Red-0 percent-unhappy-Red          ;; what percent of the red households are unhappy?
  set percent-unhappy-Green-0 percent-unhappy-Green      ;; what percent of the green households are unhappy?
  set percent-unhappy-Blue-0 percent-unhappy-Blue        ;; what percent of the blue households are unhappy?
  set percent-unhappy-Yellow-0 percent-unhappy-Yellow    ;; what percent of the yellow households are unhappy?
  set percent-similar-Red-0 percent-similar-Red          ;; percent-similar for Red agents only
  set percent-similar-Green-0 percent-similar-Green      ;; percent-similar for Green agents only
  set percent-similar-Blue-0 percent-similar-Blue        ;; percent-similar for Blue agents only
  set percent-similar-Yellow-0 percent-similar-Yellow    ;; percent-similar for Yellow agents only
end



;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------
;-------------Reset initial parameters
to setup-default
  set density 90
  set radiusNeighborhood 3
  set noise 0
  set fourGroups true
  set %-similar-wanted 25
  set BlackWhiteVis false
  set maxTicks 10
  set stepsBetweenUpdates 100
end



;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------
;-------------INITIALIZE THE MODEL
to go
  if (all? households [ happy? ] ) or ( ( ticks > 0 ) and ( ticks = maxTicks ) )    ;; end of if all? households are happy; maxTicks = 0 means no time limit
  [ update-globals                                                                  ;; to assure that globals are updated before simulation stops
    ;go-perturb ]
    stop ]                                                                          ;; stop the model: DEACTIVATE THIS FOR GO-PERTURB
  let step 1                                                                        ;; input for the while function
  while [ step <= stepsBetweenUpdates ]                                             ;; run the while function for [stepsBetweenUpdates] times before the next tick
  [ move-unhappy-households                                                         ;; engage in moving
    update-households                                                               ;; check happiness in new neighborhood
    set step step + 1 ]
  update-globals                                                                    ;; updating globals slows down program, this allows to do it only every step ticks. NOTE: this only works if globals are not used by agents for updating
  update-plots                                                                      ;; plotting slows down program, this allows to plot only every step ticks
  tick-advance 1                                                                    ;; include just 'tick' here would also suffice
end


;-------------added by to asses effect of perturbation in stable state, for using it, see note below
to go-perturb
  ;; if you want to use this: 1) deactivate stopping the simulation if all agents are happy (in go). 2) deactivate noise (in update-households)
  ask households [
    let r random 100                                          ;; generate a random number between 0 and 100
    if r < noise [ set happy? not happy? ] ]                  ;; small probability of spontaneous perturbation happiness state, for example modelling exogenous reasons to move or stay
end

;-------------unhappy households try to find a new spot
to move-unhappy-households
  ask households with [ not happy? ] [ find-new-spot ]
end

;-------------move until we find an unoccupied spot
to find-new-spot
  rt random-float 360                             ;; rt, The turtle (aka household) turns right by number degrees (random number between 0 and 360).
  fd random-float 10                              ;; fd, The turtle (aka household) moves forward by number steps (random number between 0 and 10).
  if any? other households-here [ find-new-spot ] ;; keep going until we find an unoccupied patch
  move-to patch-here                              ;; move to center of patch. This is important for in-radius to work properly for finding neighbors.
end

;-------------Calculate per household if they are happy or not in their neighborhood
to update-households
  ask households [                                                                                                                  ;; "in-radius" to test patches within radius around self patch, that is surrounding the current patch
    set similar-nearby count (households-on (patches in-radius radiusNeighborhood))  with [ ethnicity = [ ethnicity ] of myself ]   ;; count how many SIMILAR households there are in the neighborhood
    set similar-nearby (similar-nearby - 1)                                                                                         ;; because with patches in-radius agents also counts herself
    set other-nearby count (households-on (patches in-radius radiusNeighborhood)) with [ ethnicity != [ ethnicity ] of myself ]     ;; count how many OTHER househoulds there are in the neighborhood
    set total-nearby similar-nearby + other-nearby                                                                                  ;; count how many households there are in the neighborhood

    set happy? ((similar-nearby >= (%-similar-wanted * total-nearby / 100)))                                                        ;; if the household is happy with their neighboord (comparing similar nearby to the threshold T [which is %-similar-wanted])
    ;;----set happy? (%-similar-wanted / 100) - (similar-nearby / total-nearby)  ;;ranges from -1 .. +1                             ;;----Addition: this is to test what happens if more unhappy households move more likely than less unhappy households.

    let r random 100                                                                                                                ;; generate a random number between 0 and 100: DEACTIVATE THIS FOR GO-PERTURB
    if r < noise [set happy? not happy?]                                                                                            ;; Noise: if random number is below level of noise, set unhappy even though the household is happy: DEACTIVATE THIS FOR GO-PERTURB

    ifelse BlackWhiteVis                                                                                                            ;; Visualiszation of groups who are happy (square or triangle) or unhappy (x)
    [ if ( ( ethnicity = 2 ) or ( ethnicity = 3 ) ) [ set shape ifelse-value happy? [ "square" ] [ "x" ] ]                          ;; IF blackwhitevis is true
      if ( ( ethnicity = 1 ) or ( ethnicity = 4 ) ) [ set shape ifelse-value happy? [ "triangle" ] [ "x" ] ] ]                      ;; with "x" is visualized in the chapter
     ;;----[ if ((ethnicity = 2) or (ethnicity = 3))  [ifelse happy? [set shape "square"] [ set shape "line half" ]]                ;;----Addition: this is for other visualizations
     ;;------if ((ethnicity = 1) or (ethnicity = 4)) [ifelse happy? [set shape "triangle"] [ set shape "line half" ]]]
    [ set shape ifelse-value happy? [ "square" ] [ "x" ] ]                                                                          ;; ELSE blackwhitevis is false, this is for color mode
  ]
end



;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------;-------------
;-------------MODEL OUTPUT: update macro-level outcomes (percent similar, percent unhappy, and clustering)
to update-globals
  ;;compute percent-similar for all households
  let similar-neighbors sum [ similar-nearby ] of households                                                         ;; let creates new local variable and assigns value to it
  let total-neighbors sum [ total-nearby ] of households                                                             ;; how many household are nearby
  set percent-similar ( similar-neighbors / total-neighbors ) * 100                                                  ;; set assigns value to existing variable

  ;;compute per group the percent-similarEthnicity global, provided the ethnicity is not empty
  ;;compute-percent-similar-group is a reporter function defined below
  set percent-similar-Red ifelse-value ( num-Red-Population != 0 ) [ compute-percent-similar-group 1 ] [ 0 ]         ;; percent similar for REDS
  set percent-similar-Green ifelse-value ( num-Green-Population != 0 ) [ compute-percent-similar-group 2 ] [ 0 ]     ;; percent similar for GREENS
  set percent-similar-Blue ifelse-value ( num-Blue-Population != 0 ) [ compute-percent-similar-group 3 ] [ 0 ]       ;; percent similar for BLUES
  set percent-similar-Yellow ifelse-value ( num-Yellow-Population != 0 )  [ compute-percent-similar-group 4 ] [ 0 ]  ;; percent similar for YELLOWS

  ;;compute per group the percent-similarEthnicityRelative global, provided the ethnicity is not empty
  ;;compute-clustering-group is a reporter function defined below
  set percent-clustering-Red ifelse-value ( num-Red-Population != 0 ) [ compute-clustering-group 1 ] [  0 ]          ;; clustering for REDS
  set percent-clustering-Green ifelse-value ( num-Green-Population != 0 ) [ compute-clustering-group 2 ] [  0 ]      ;; clustering for GREENS
  set percent-clustering-Blue ifelse-value ( num-Blue-Population != 0 ) [ compute-clustering-group 3 ] [  0 ]        ;; clustering for BLUES
  set percent-clustering-Yellow ifelse-value ( num-Yellow-Population != 0 ) [ compute-clustering-group 4 ] [  0 ]    ;; clustering for YELLOWS

  ;;compute percent households per type which are unhappy
  set percent-unhappy (count households with [ not happy? ]) / (count households) * 100                                                                                            ;; percent unhappy for ALL HOUSEHOLDS
  set percent-unhappy-Red ifelse-value ( num-Red-Population != 0 ) [ 100 * ( count households with [ not happy? and ethnicity = 1 ] ) / ( num-Red-Population ) ] [ 0 ]             ;; percent unhappy for REDS
  set percent-unhappy-Green ifelse-value ( num-Green-Population != 0 ) [ 100 * ( count households with [ not happy? and ethnicity = 2 ] ) / ( num-Green-Population ) ] [ 0 ]       ;; percent unhappy for GREENS
  set percent-unhappy-Blue ifelse-value ( num-Blue-Population != 0 ) [ 100 * ( count households with [ not happy? and ethnicity = 3 ] ) / ( num-Blue-Population ) ] [ 0 ]          ;; percent unhappy for BLUES
  set percent-unhappy-Yellow  ifelse-value ( num-Yellow-Population != 0 ) [ 100 * ( count households with [ not happy? and ethnicity = 4 ] ) / (  num-Yellow-Population ) ] [ 0 ]  ;; percent unhappy for YELLOWS
end

;-------------Calculate percent similar per group
to-report compute-percent-similar-group [ group-type ]
  let similar-neighbors-group sum [ similar-nearby ] of households with [ ethnicity = group-type ]
  let total-neighbors-group sum [ total-nearby ] of households with [ ethnicity = group-type ]
  let percent-similar-group ( similar-neighbors-group / total-neighbors-group ) * 100
  report percent-similar-group
end

;-------------Calculate clustering per group
to-report compute-clustering-group [ group-type ]
  let similar-neighbors-group sum [ similar-nearby ] of households with [ ethnicity = group-type ]
  let total-neighbors-group sum [ total-nearby ] of households with [ ethnicity = group-type ]
  let percent-similar-group ( similar-neighbors-group / total-neighbors-group ) * 100
  let percentage-group ( ifelse-value
    group-type = 1 [ percent-Red-Population ]
    group-type = 2 [ percent-Green-Population ]
    group-type = 3 [ percent-Blue-Population ]
    group-type = 4 [ percent-Yellow-Population ] )
  report percent-similar-group / percentage-group
end


;-----This code is derived from a simpler model version provided in the NetLogo model library.
;-----Code extensions have been added by Andreas Flache & Carlos de Matos Fernandes
;; Based on: Wilensky, U. (1997). NetLogo Segregation model. http://ccl.northwestern.edu/netlogo/models/Segregation. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;; Copyright 1997 Uri Wilensky.
;; See Info tab for full copyright and license for the original Wilensky implementation.
@#$#@#$#@
GRAPHICS-WINDOW
751
52
1153
455
-1
-1
7.73
1
10
1
1
1
0
0
0
1
-25
25
-25
25
1
1
1
ticks
50.0

MONITOR
1460
306
1553
351
% unhappy all
percent-unhappy
1
1
11

MONITOR
1462
150
1528
195
% similar
percent-similar
1
1
11

PLOT
1210
52
1459
195
Percent Similar
time
%
0.0
5.0
0.0
100.0
true
true
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plotxy ticks percent-similar"
"red" 1.0 0 -2674135 true "" "plotxy ticks percent-similar-Red"
"green" 1.0 0 -10899396 true "" "plotxy ticks percent-similar-Green"
"blue" 1.0 0 -13345367 true "" "plotxy ticks percent-similar-Blue"
"yellow" 1.0 0 -1184463 true "" "plotxy ticks percent-similar-Yellow"

SLIDER
4
203
264
236
%-similar-wanted
%-similar-wanted
0
100
25.0
1
1
%
HORIZONTAL

BUTTON
409
54
583
205
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
590
93
671
203
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
590
57
672
91
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
3
67
293
100
density
density
20
99
90.0
1
1
%
HORIZONTAL

PLOT
1210
202
1458
352
Percent Unhappy
time
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plotxy ticks percent-unhappy"
"Red" 1.0 0 -2674135 true "" "plotxy ticks percent-unhappy-Red"
"Green" 1.0 0 -10899396 true "" "plotxy ticks percent-unhappy-Green"
"Blue" 1.0 0 -13345367 true "" "plotxy ticks percent-unhappy-Blue"
"Yellow" 1.0 0 -1184463 true "" "plotxy ticks percent-unhappy-Yellow"

MONITOR
1462
52
1528
97
# agents
num-Population
1
1
11

SLIDER
4
142
293
175
radiusNeighborhood
radiusNeighborhood
1
9
3.0
2
1
NIL
HORIZONTAL

SLIDER
3
279
291
312
noise
noise
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
2
344
120
377
fourGroups
fourGroups
0
1
-1000

PLOT
1210
365
1453
518
Clustering
time
ratio
0.0
10.0
0.0
4.0
true
true
"" ""
PENS
"Red" 1.0 0 -2674135 true "" "plotxy ticks percent-clustering-Red"
"Green" 1.0 0 -10899396 true "" "plotxy ticks percent-clustering-Green"
"Blue" 1.0 0 -13345367 true "" "plotxy ticks percent-clustering-Blue"
"Yellow" 1.0 0 -1184463 true "" "plotxy ticks percent-clustering-Yellow"

INPUTBOX
192
421
313
481
stepsBetweenUpdates
100.0
1
0
Number

SWITCH
140
344
258
377
BlackWhiteVis
BlackWhiteVis
1
1
-1000

INPUTBOX
0
420
98
480
maxTicks
10.0
1
0
Number

TEXTBOX
9
187
226
205
In the chapter, we refer to this as T.
11
0.0
1

MONITOR
1462
98
1528
143
empty cells
count patches - (count turtles-on patches)
17
1
11

TEXTBOX
9
52
307
70
How many household are there in percentages total
11
0.0
1

TEXTBOX
3
385
120
416
Stop after ? ticks (0 is no time limit)
11
0.0
1

TEXTBOX
130
388
253
423
Update world after every X steps
11
0.0
1

TEXTBOX
143
327
310
345
Color Black and White
11
0.0
1

TEXTBOX
1564
57
1744
94
Proportion per group for Reds, Greens, Blues, and Yellows
11
0.0
1

BUTTON
409
268
610
305
NIL
setup-default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
418
246
633
264
Set all parameters to the original setup
11
0.0
1

TEXTBOX
4
325
154
343
Two or four groups?
11
0.0
1

TEXTBOX
5
10
358
48
Input for the model
28
0.0
1

TEXTBOX
10
111
290
138
In which radius do households compare %-similar-wanted to the neighborhood composition
11
0.0
1

TEXTBOX
7
247
292
274
Include random switching from happy to unhappy in neighborhood (not in chapter)
11
0.0
1

TEXTBOX
408
11
684
79
Initialize the model
28
0.0
1

TEXTBOX
756
10
906
44
World
28
0.0
1

TEXTBOX
1211
10
1758
44
Model output: Macro-level characteristics 
28
0.0
1

TEXTBOX
901
455
1051
539
With four groups ON\nBlack square = Blue\nGrey square = Green\nBlack triangle = Yellow\nGrey triangle = Red\nx = unhappy household
11
0.0
1

TEXTBOX
754
456
890
516
With four groups OFF\nGrey square = Green\nGrey triangle = Red\nx = unhappy household
11
0.0
1

TEXTBOX
1040
455
1190
483
With BlackWhiteVis OFF\ncolor = group
11
0.0
1

MONITOR
1560
90
1704
135
NIL
percent-Red-Population
1
1
11

MONITOR
1560
188
1705
233
NIL
percent-Green-Population
1
1
11

MONITOR
1560
140
1706
185
NIL
percent-Blue-Population
1
1
11

MONITOR
1560
237
1708
282
NIL
percent-Yellow-Population
1
1
11

TEXTBOX
196
487
321
557
If you set this to 1, the world updates every tick. Otherwise, there are [stepsBetweenUpdates] steps per tick.
11
0.0
1

TEXTBOX
844
26
1094
48
A single run will stop if all households are happy.
11
0.0
1

TEXTBOX
10
488
160
506
NIL
11
0.0
1

TEXTBOX
7
485
162
653
Input maxTicks stops a single run when maxTicks reaches the tick counter (top grey panel}. If stepsBetweenUpdates = 1 and maxTicks = 10, then are steps and ticks the same (10). But if stepsBetweenUpdates = 100 and maxTicks = 10, then we have 1000 steps and 10 ticks.
11
0.0
1

@#$#@#$#@
# WHAT IS IT?

This project allows to model the behavior of four types of agents in a neighborhood. We adapted Wilensky's (1997) model to accommodate four groups. Agents are households. A type represents an ethnic group. The red, green, blue, and yellow get along with one another. But each household wants to make sure that it lives near some of "its own." That is, each household wants to live in a neighborhood with a certain percentage of its own. That percentage can be varied (`%-similar-wanted`). If the individual threshold is not met, households move to another vacant spot. The simulation shows how these individual thresholds ripple through neighborhoods, leading to large-scale segregation patterns.

This project was inspired by Thomas Schelling's writings about social systems (such as housing patterns in cities) but adapted to mimic, to some extent, US society (Clark & Fosset, 2008). Also, this model accompanies our ABM chapter in _The Research Handbook of Analytical Sociology_ (2021; ed. G. Manzo) to show how ABMs can contribute to research in analytical sociology.

## Additions

Features added in comparison to the segregation model:

  1. The neighborhood size can be changed with the slider `radiusNeighborhood`. radius = 1 is von Neumann. In general, radius = max number of steps in horizontal or vertical direction to reach a neighbor.
  2. Possibility to run a version with four populations (of size 60% / 20% / 10% / 10%), which is a rough representation of modern big US cities (Clark & Fosset, 2008).
  3. Possibility to add probability of `noise`: random probability of spontaneous change of "happiness" state of a household
  4. Measures showing how clustered the groups become over time

**Note that we adjusted the info tab (cf. Wilensky, 1997) as well.**

# HOW TO USE THE MODEL

On the interface, you can see four titles: input, initialize, world, and output. 

## Input for the model

The `density` slider controls the occupancy density of the neighborhood (and thus the total number of agents). (It takes effect the next time you click `setup`.)  The `%-similar-wanted` (threshold _t_) slider controls the percentage of same-type agents that each agent wants among its neighbors. For example, if the slider is set at 30, each green agent wants at least 30% of its neighbors to be green agents.

The `noise` slider controls how many randomness is added to the model. Randomness means here a random switch from happy to unhappy or reverse. If `noise` is set to 1, households have a 1 percent chance to switch happy to unhappy. 

The switches `fourGroups` and `BlackWhiteVis` control how many ethnicities are added and the coloring of the world, respectively. 

The input `maxTicks` and `stepsBetweenUpdates` control how many simulation ticks and after how many steps the world view is updated, respectively.


## Initialize the model

Click the SETUP button to set up the agents. There are approximately 60% reds, 20% green, 10% blues, and 10% yellows (if `fourGroups` = on). The agents are set up so no patch has more than one agent. Click GO to start the simulation. If agents don't have enough same-type neighbors, they move to a nearby patch. (The topology is **not** wrapping, so that patches on the bottom/left edge are **not** neighbors with patches on the top/right).

## World

The "World" view shows if and where households move to. Note that with varying levels of %-similar-wanted clusters of same-type households arise in the world. 

## Model output

We implemented several macro-level outcome measures visualized under "Model output". We model the percent-similar, percent-happy, and clustering. The percent-similar monitor shows the average percentage of same-type neighbors for each agent. The percent-unhappy monitor shows the number of unhappy agents, who thus want to move. Both monitors are also plotted, as well as clustering. Inspect the block `update-globals` to see how these outcomes are measured.


# THINGS TO NOTICE

When you execute `setup` (using the default settings), the agents are randomly distributed throughout the neighborhood. But many agents are "unhappy" since they don't have enough same-type neighbors. The unhappy agents move to new locations in the vicinity. But in the new locations, they might tip the balance of the local population, prompting other agents to leave. For example, if a few red agents move into an area, the local green agents might leave. But when the green agents move to a new area, they might prompt red agents to leave that area.

If you set `RadiusNeighborhood` = 1 (rather than `RadiusNeighborhood` = 3 as in the default setting), then in the case where each agent wants at least 26% same-type neighbors, the agents end up with (on average) 77% same-type neighbors (with `RadiusNeighborhood` = 1). So relatively small individual preferences can lead to significant overall segregation here. 

Over time, the number of unhappy agents decreases. But the neighborhoods becomes more segregated, with clusters of same-type agents.

We rely on asynchronous updating because one household changes their location at a time.  To keep the code simple, the original Wilensky model made updating not perfectly asynchronous, because only after all unhappy households have found new spots, all households update their happiness state. This precludes that households who become unhappy due to the entry of a new neighbor in their neighborhood can move away in the same round. This simplification is inherited by segregationExtended. Explorative simulation experiments with a fully asynchronous version suggested that this simplification does not affect main results reported in the chapter.

# THINGS TO TRY

Try different values for `%-similar-wanted`. How does the overall degree of segregation change?

Try different values of `density`. How does the initial occupancy density affect the percentage of unhappy agents? How does it affect the time it takes for the model to finish?

Try different values of 'radius'. How does this affect the way`%-similar-wanted` relates to the overall degree of segregation?


Can you set sliders so that the model never finishes running, and agents keep looking for new locations?

Inspect the role of adding `noise` to the model? Try out this feature to inspect if you can reach lower or higher levels of segregation.

The code can be more efficient (e.g. shorter). Can you implement a more efficient coding scheme for `update-households` or `update-globals`?

# EXTENDING THE MODEL

The `find-new-spot` procedure has the agents move locally till they find a spot. Can you rewrite this procedure so the agents move directly to an appropriate new spot?

Change the rules for agent happiness.  One idea: suppose that the agents need some minimum threshold of "good neighbors" to be happy with their location.  Suppose further that they don't always know if someone is a 'good' neighbor. When they do have such knowledge, they may use that information to accept or decline a potential new neihgborhood members.  When they don't, they use color as a proxy -- i.e., they assume that agents of the same color make good neighbors. See `update-households`.

At some point, we arrive at a stable equilibrium in which all households are happy. Try out the `go-perturb` function to see what happens in stable states as well as random perturbations while running the model.

The `square and x` visualization shows whether an agent is happy or not. Can you design a different visualization that emphasizes different aspects?

Incorporate social networks into this model. For instance, have unhappy agents decide on a new location based on information about what a neighborhood is like from other agents in their network.

An interesting option could be to start with segregation = 100%. Try to write a code to 
arrange all households such that all have 100% ingroup neighbors. 


# NETLOGO FEATURES

When an agent moves, `move-to` is used to move the agent to the center of the patch it eventually finds.

Note two different methods that can be used for `find-new-spot`, one of them (the one we use) is recursive.

# CREDITS AND REFERENCES

Schelling, T. C. (1971). Dynamic models of segregation. The Journal of Mathematical Sociology, 1(2), 143–186. doi: 10.1080/0022250X.1971.9989794.

Sakoda, J. M. (1971). The checkerboard model of social interaction. The Journal of Mathematical Sociology, 1(1), 119–132. doi: 10.1080/0022250X.1971.9989791.

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

Clark, W. A. V, & Fossett, M. (2008). Understanding the social context of the Schelling segregation model. Proceedings of the National Academy of Sciences of the United States of America, 105(11), 4109–4114. https://doi.org/10.1073/pnas.0708155105

See also: Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. http://www.theatlantic.com/magazine/archive/2002/04/seeing-around-corners/302471/


# HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the original model itself:

* Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

For our extension, please refer to:

* Andreas Flache & Carlos A. de Matos Fernandes. Forthcoming. "Agent-based computational models" in "The Research Handbook on Analytical Sociology" (Ed. G. Manzo). TO BE COMPLETED WITH PUBLISHER DETAILS ETC.



Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

# COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 -->
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

face-happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face-sad
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

person2
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 285 180 255 210 165 105
Polygon -7500403 true true 105 90 15 180 60 195 135 105

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

square - happy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 75 195 105 240 180 240 210 195 75 195

square - unhappy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 60 225 105 180 195 180 240 225 75 225

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square-small
false
0
Rectangle -7500403 true true 45 45 255 255

square-x
false
0
Rectangle -7500403 true true 30 30 270 270
Line -16777216 false 75 90 210 210
Line -16777216 false 210 90 75 210

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

triangle2
false
0
Polygon -7500403 true true 150 0 0 300 300 300

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
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1 (percent-similar_figure 2A)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>percent-similar</metric>
    <enumeratedValueSet variable="density">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stepsBetweenUpdates">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%-similar-wanted" first="0" step="1" last="70"/>
    <enumeratedValueSet variable="radiusNeighborhood">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourGroups">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2 (percent-unhappy_figure 2B)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1"/>
    <metric>percent-unhappy</metric>
    <enumeratedValueSet variable="density">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stepsBetweenUpdates">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%-similar-wanted" first="0" step="1" last="70"/>
    <enumeratedValueSet variable="radiusNeighborhood">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourGroups">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="addendum (clustering_figure)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>percent-clustering-Red</metric>
    <metric>percent-clustering-Green</metric>
    <metric>percent-clustering-Blue</metric>
    <metric>percent-clustering-Yellow</metric>
    <enumeratedValueSet variable="density">
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stepsBetweenUpdates">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%-similar-wanted" first="20" step="1" last="50"/>
    <enumeratedValueSet variable="radiusNeighborhood">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fourGroups">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
