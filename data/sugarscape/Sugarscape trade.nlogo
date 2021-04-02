globals [
  gini-index-reserve
  normalized-gini
  lorenz-points
  prices
  number_of_prices
  mean_prices
]

turtles-own [
  sugar           ;; the amount of sugar this turtle has
  spice
  potsugar
  potspice
  sugar-metabolism      ;; the amount of sugar that each turtles loses each tick
  spice-metabolism      ;;
  vision          ;; the distance that this turtle can see in the horizontal and vertical directions
  vision-points   ;; the points that this turtle can see in relative to it's current position (based on vision)
  wealth
]

patches-own [
  psugar           ;; the amount of sugar on this patch
  max-psugar       ;; the maximum amount of sugar that can be on this patch
  pspice
  max-pspice
  expected-wealth
]

;;
;; Setup Procedures
;;

to setup
  if maximum-sugar-endowment <= minimum-sugar-endowment [
    user-message "Oops: the maximum-sugar-endowment must be larger than the minimum-sugar-endowment"
    stop
  ]
  clear-all
  create-turtles initial-population [ turtle-setup ]
  setup-patches
  update-lorenz-and-gini
  reset-ticks
  set prices []
end

to turtle-setup ;; turtle procedure
  set color blue
  set shape "circle"
  move-to one-of patches with [not any? other turtles-here]
  set sugar random-in-range minimum-sugar-endowment maximum-sugar-endowment
  set spice random-in-range minimum-spice-endowment maximum-spice-endowment
  set sugar-metabolism random-in-range 1 4
  set spice-metabolism random-in-range 1 4
  set vision random-in-range 1 6
  ;; turtles can look horizontally and vertically up to vision patches
  ;; but cannot look diagonally at all
  set vision-points []
  foreach (range 1 (vision + 1)) [ n ->
    set vision-points sentence vision-points (list (list 0 n) (list n 0) (list 0 (- n)) (list (- n) 0))
  ]
  set wealth wealth-func sugar spice sugar-metabolism spice-metabolism
  run visualization
end

to turtle-setup-offspring ;; turtle procedure
  set color blue
  set shape "circle"
  move-to one-of patches in-radius 3 with [not any? other turtles-here]
  if random-float 1 < pmut [ifelse random 2 = 0 [set sugar-metabolism sugar-metabolism - 1][set sugar-metabolism sugar-metabolism + 1]]
  if random-float 1 < pmut [ifelse random 2 = 0 [set spice-metabolism spice-metabolism - 1][set spice-metabolism spice-metabolism + 1]]
  if random-float 1 < pmut [ifelse random 2 = 0 [set vision vision - 1][set vision vision + 1]]
  if vision > 6 [set vision 6]
  if sugar-metabolism < 1 [set sugar-metabolism 1]
  if spice-metabolism < 1 [set spice-metabolism 1]
  ;; turtles can look horizontally and vertically up to vision patches
  ;; but cannot look diagonally at all
  set vision-points []
  foreach (range 1 (vision + 1)) [ n ->
    set vision-points sentence vision-points (list (list 0 n) (list n 0) (list 0 (- n)) (list (- n) 0))
  ]
  set wealth wealth-func sugar spice sugar-metabolism spice-metabolism
  run visualization
end

to setup-patches
    ask patch 38 38 [set max-psugar 4 ask patches in-radius 4 [set max-psugar 4 ]
    ask patches in-radius 8 with [max-psugar = 0][set max-psugar 3]
    ask patches in-radius 12 with [max-psugar = 0][set max-psugar 2]
    ask patches in-radius 16 with [max-psugar = 0][set max-psugar 1]]
  ask patch 12 12 [set max-psugar 4 ask patches in-radius 4 [set max-psugar 4 ]
        ask patches in-radius 8 with [max-psugar = 0][set max-psugar 3]
    ask patches in-radius 12 with [max-psugar = 0][set max-psugar 2]
    ask patches in-radius 16 with [max-psugar = 0][set max-psugar 1]]
  ask patch 12 38 [set max-pspice 4 ask patches in-radius 4 [set max-pspice 4 ]
    ask patches in-radius 8 with [max-pspice = 0][set max-pspice 3]
    ask patches in-radius 12 with [max-pspice = 0][set max-pspice 2]
    ask patches in-radius 16 with [max-pspice = 0][set max-pspice 1]]
  ask patch 38 12 [set max-pspice 4 ask patches in-radius 4 [set max-pspice 4 ]
        ask patches in-radius 8 with [max-pspice = 0][set max-pspice 3]
    ask patches in-radius 12 with [max-pspice = 0][set max-pspice 2]
    ask patches in-radius 16 with [max-pspice = 0][set max-pspice 1]]

  ask patches [set psugar max-psugar set pspice max-pspice patch-recolor]
end

;;
;; Runtime Procedures
;;

to go
  if not any? turtles [
    stop
  ]
  ask patches [
    patch-growback
    patch-recolor
  ]
  ask turtles [
    turtle-move
    turtle-eat
    if sugar <= 0 [die]
    if spice <= 0 [die]
  ]

  if trade? [
    set prices []
    ask turtles [
      trade
    ]
  ]
  ask turtles [
    if sugar <= 0 [die]
    if spice <= 0 [die]
    if wealth > wealth-reproduction [
      if count patches in-radius 3 with [not any? other turtles-here] > 0 [
      set sugar sugar / 2
      set spice spice / 2
        hatch 1 [ turtle-setup-offspring ]]
    ]
    run visualization
  ]
  ask turtles [
    set wealth wealth-func sugar spice sugar-metabolism spice-metabolism
  ]
  update-lorenz-and-gini
  set number_of_prices length prices
  if number_of_prices > 0 [
    set mean_prices mean prices
  ]
  tick
end

to turtle-move ;; turtle procedure
  ;; consider moving to unoccupied patches in our vision, as well as staying at the current patch
  let move-candidates (patch-set patch-here (patches at-points vision-points) with [not any? turtles-here])

  let ac-sugar [sugar] of self
  let ac-spice [spice] of self
  let m-sugar [sugar-metabolism] of self
  let m-spice [spice-metabolism] of self
  ask move-candidates [
    set expected-wealth wealth-func (ac-sugar + psugar) (ac-spice + pspice) m-sugar m-spice
  ;  show expected-wealth
  ]
  let possible-winners move-candidates with-max [expected-wealth]
  if any? possible-winners [
    ;; if there are any such patches move to one of the patches that is closest
    move-to min-one-of possible-winners [distance myself]
  ]
end

to turtle-eat ;; turtle procedure
  ;; metabolize some sugar and spice, and eat all the sugar and spice on the current patch
  set sugar (sugar - sugar-metabolism + psugar)
  set psugar 0
  set spice (spice - spice-metabolism + pspice)
  set pspice 0
end

to trade
  let agentA self
  ask turtles-on neighbors [
    let MRS_A ([spice] of agentA / [spice-metabolism] of agentA) / ([sugar] of agentA / [sugar-metabolism] of agentA)
    let MRS_B (spice / spice-metabolism) / (sugar / sugar-metabolism)
    let price sqrt (MRS_A * MRS_B)

    if MRS_A > MRS_B [
      if price >= 1 [ask agentA [set potspice spice - price set potsugar sugar + 1] set potspice spice + price set potsugar sugar - 1]
      if price < 1 [ask agentA [set potspice spice - 1 set potsugar sugar + 1 / price] set potspice spice + 1 set potsugar sugar - 1 / price]
    ]

    if MRS_A < MRS_B [
      if price >= 1 [set potspice spice - price set potsugar sugar + 1 ask agentA [set potspice spice + price set potsugar sugar - 1]]
        if price < 1 [set potspice spice - 1 set potsugar sugar + 1 / price ask agentA [set potspice spice + 1 set potsugar sugar - 1 / price]]
    ]
    ; wealth potential trade
    let potwealthA wealth-func [potsugar] of agentA [potspice] of agentA [sugar-metabolism] of agentA [spice-metabolism] of agentA
    let potwealthB wealth-func potsugar potspice sugar-metabolism spice-metabolism
    if (potwealthA >= [wealth] of agentA) and (potwealthB >= wealth) [
      ask agentA [set spice potspice set sugar potsugar set wealth potwealthA]
      set spice potspice set sugar potsugar set wealth potwealthB
      set prices lput price prices
    ]
  ]
end

to patch-recolor ;; patch procedure
  ;; color patches based on the amount of sugar and spice they have
  if pxcor > 24 and pycor > 24 [set pcolor (yellow + 4.9 - psugar)]
  if pxcor <= 24 and pycor <= 24 [set pcolor (yellow + 4.9 - psugar)]
  if pxcor > 24 and pycor <= 24 [set pcolor (red + 4.9 - pspice)]
  if pxcor <= 24 and pycor > 24 [set pcolor (red + 4.9 - pspice)]
end

to patch-growback ;; patch procedure
  ;; gradually grow back all of the sugar and spice for the patch
  set psugar min (list max-psugar (psugar + 1))
  set pspice min (list max-pspice (pspice + 1))
end

to update-lorenz-and-gini
  let num-people count turtles
  let sorted-wealths sort [wealth] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set normalized-gini 0
  set lorenz-points []
  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve
      gini-index-reserve +
      (index / num-people) -
      (wealth-sum-so-far / total-wealth)
  ]
  ifelse count turtles > 0 [
    set normalized-gini (gini-index-reserve / count turtles) * 2]
  [
  set normalized-gini 0
  ]
end

;;
;; Utilities
;;

to-report random-in-range [low high]
  report low + random (high - low + 1)
end

to-report wealth-func [ac-sugar ac-spice m-sugar m-spice]
  let wealth-report 0
  if ac-sugar > 0 and ac-spice > 0 [set wealth-report (ac-sugar ^ (m-sugar /(m-sugar + m-spice)) ) * (ac-spice ^ (m-spice / (m-sugar + m-spice)))]
  report wealth-report
end
;;
;; Visualization Procedures
;;

to no-visualization ;; turtle procedure
  set color blue
end

to color-agents-by-vision ;; turtle procedure
  set color blue - (vision - 3.5)
end

to color-agents-by-metabolism ;; turtle procedure
  set color blue + ((sugar-metabolism + spice-metabolism) / 2 - 2.5)
end


; Copyright 2009 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
295
10
703
419
-1
-1
8.0
1
10
1
1
1
0
1
1
1
0
49
0
49
1
1
1
ticks
30.0

BUTTON
5
190
85
230
NIL
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
90
190
180
230
NIL
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
185
190
275
230
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

CHOOSER
5
240
285
285
visualization
visualization
"no-visualization" "color-agents-by-vision" "color-agents-by-metabolism"
2

SLIDER
10
10
290
43
initial-population
initial-population
0
1000
400.0
10
1
NIL
HORIZONTAL

SLIDER
10
45
290
78
minimum-sugar-endowment
minimum-sugar-endowment
0
200
5.0
1
1
NIL
HORIZONTAL

PLOT
710
220
970
420
Gini index vs. time
Time
Gini
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot (gini-index-reserve / count turtles) * 2"

SLIDER
10
80
290
113
maximum-sugar-endowment
maximum-sugar-endowment
0
200
25.0
1
1
NIL
HORIZONTAL

SLIDER
5
325
285
358
wealth-reproduction
wealth-reproduction
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
10
115
290
148
minimum-spice-endowment
minimum-spice-endowment
5
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
10
150
290
183
maximum-spice-endowment
maximum-spice-endowment
5
100
25.0
1
1
NIL
HORIZONTAL

PLOT
710
10
970
220
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
970
220
1245
420
Turtle attributes
NIL
NIL
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"sugar" 1.0 0 -16777216 true "" "plot mean [sugar-metabolism] of turtles"
"spice" 1.0 0 -2674135 true "" "plot mean [spice-metabolism] of turtles"
"vision" 1.0 0 -14439633 true "" "plot mean [vision] of turtles"

SWITCH
5
290
108
323
Trade?
Trade?
0
1
-1000

SLIDER
110
290
285
323
pmut
pmut
0
0.1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
970
10
1245
220
resources
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"sugar" 1.0 0 -16777216 true "" "plot sum [psugar] of patches"
"spice" 1.0 0 -2674135 true "" "plot sum [pspice] of patches"

PLOT
1245
220
1510
420
Price
NIL
NIL
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"average" 1.0 0 -16777216 true "" "if ticks > 0 and length prices > 0 [plot mean prices]"

PLOT
1245
10
1510
220
trades
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [plot length prices]"

@#$#@#$#@
## WHAT IS IT?

Note that this an adjustment of the third model in the NetLogo Sugarscape suite implements Epstein & Axtell's Sugarscape Wealth Distribution model, as described in chapter 2 of their book Growing Artificial Societies: Social Science from the Bottom Up. It provides a ground-up simulation of inequality in wealth. Only a minority of the population have above average wealth, while most agents have wealth near the same level as the initial endowment.

As discussed in the model documentation we include spice, reproduction, a welfare function, and trade.

## HOW IT WORKS

Each patch contains some sugar or spice, the maximum amount of which is predetermined. At each tick, each patch regains one unit of sugar or spice, until it reaches the maximum amount.
The amount of sugar or spicea patch currently contains is indicated by its color; the darker the yellow, the more sugar, and the darker the red, the more spice.

At setup, agents are placed at random within the world. Each agent can only see a certain distance horizontally and vertically. At each tick, each agent will move to the nearest unoccupied location within their vision range with the most welfare after consuming the resources on that patch, and collect all the sugar and spice there.  If its current location has as much or more sugar and spice than any unoccupied location it can see, it will stay put.

Agents also use (and thus lose) a certain amount of sugar and spice each tick, based on their metabolism rates. If an agent runs out of sugar or spice, it dies.

Each agent also reproduces if the wealth is beyond a certain threshold.


## HOW TO USE IT

The INITIAL-POPULATION slider sets how many agents are in the world.

The MINIMUM-SUGAR-ENDOWMENT and MAXIMUM-SUGAR-ENDOWMENT sliders set the initial amount of sugar ("wealth") each agent has when it hatches. The actual value is randomly chosen from the given range.

Press SETUP to populate the world with agents and import the sugar map data. GO will run the simulation continuously, while GO ONCE will run one tick.

The VISUALIZATION chooser gives different visualization options and may be changed while the GO button is pressed. When NO-VISUALIZATION is selected all the agents will be red. When COLOR-AGENTS-BY-VISION is selected the agents with the longest vision will be darkest and, similarly, when COLOR-AGENTS-BY-METABOLISM is selected the agents with the lowest metabolism will be darkest.



## NETLOGO FEATURES

Since agents cannot see diagonally we cannot use `in-radius` to find the patches in the agents' vision.  Instead, we use `at-points`.

## RELATED MODELS

Other models in the NetLogo Sugarscape suite include:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback
* Sugarspace 3 Wealth DIstribution

For more explanation of the Lorenz curve and the Gini index, see the Info tab of the Wealth Distribution model.  (That model is also based on Epstein and Axtell's Sugarscape model, but more loosely.)

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up.  Washington, D.C.: Brookings Institution Press.


## COPYRIGHT AND LICENSE

Copyright 2009 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2009 Cite: Li, J. -->
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
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>avg_price</metric>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wealth-reproduction">
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-spice-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-spice-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pmut">
      <value value="0.05"/>
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
1
@#$#@#$#@
