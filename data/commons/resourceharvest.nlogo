globals
[
  max-resource    ; maximum amount any patch can hold
  avgresource
  avgnorm
  avgwealth
]

patches-own
[
  resource-here      ; the current amount of resource on this patch
  max-resource-here  ; the maximum amount of resource this patch can hold
]

turtles-own
[
  wealth            ; the amount of resource a turtle has
  vision            ; how many patches ahead a turtle can see
  norm-min-resource ; minimum amount of resources on patch before agent will harvest
  copied-norm
  harvestedlevel
]


to setup
  clear-all
  set max-resource 50
  setup-patches
  setup-turtles
  reset-ticks
end

to setup-patches
  ask patches
    [ set max-resource-here 0
      if (random-float 100.0) <= percent-best-land
        [ set max-resource-here max-resource
          set resource-here max-resource-here ] ]
   repeat 5
    [ ask patches with [max-resource-here != 0]
        [ set resource-here max-resource-here ]
      diffuse resource-here 0.25 ]
  repeat 10
    [ diffuse resource-here 0.25 ]
  ask patches
    [ set resource-here floor resource-here    ;; round resource levels to whole numbers
      set max-resource-here resource-here      ;; initial resource level is also maximum
      recolor-patch ]
end

to recolor-patch
  set pcolor scale-color yellow resource-here 0 max-resource
end

to setup-turtles
  set-default-shape turtles "dot"
  crt num-people
    [ move-to one-of patches
      set size 2
      set color red
      ifelse imitate? [
        set norm-min-resource 0.5
      ][
        set norm-min-resource min-resource
      ]
      face one-of neighbors4
      set wealth 0
      set vision 1 + random max-vision
  ]
end

to go
  ask turtles [ turn-towards-resource ]  ;; choose direction holding most resource within the turtle's vision
  ask turtles [ fd 1]
  harvest
  ask turtles [ set wealth wealth * discount]
  if punish? [
    monitor]
  if imitate? [imitate]
  ask turtles [
    if wealth < 0 [set wealth 0 set norm-min-resource [norm-min-resource] of one-of turtles with [who != self]]]
  ask patches [ grow-resource ]
  ask turtles [set size 1 + 2 * norm-min-resource]
  if ticks > 1000 [
    set avgnorm avgnorm + 0.001 * mean [norm-min-resource] of turtles
    set avgwealth avgwealth + 0.001 * mean [wealth] of turtles
    set avgresource avgresource + 0.001 * mean [resource-here] of patches
  ]
  tick
end

; determine the direction which is most profitable for each turtle in the surrounding patches within the turtles' vision
to turn-towards-resource  ;; turtle procedure
  set heading 0
  let best-direction [0]
  let best-amount resource-ahead
  set heading 90
  if (resource-ahead = best-amount) [set best-direction lput 90 best-direction]
  if (resource-ahead > best-amount) [set best-direction [90] set best-amount resource-ahead]
  set heading 180
  if (resource-ahead = best-amount) [set best-direction lput 180 best-direction]
  if (resource-ahead > best-amount) [set best-direction [180] set best-amount resource-ahead]
  set heading 270
  if (resource-ahead = best-amount) [set best-direction lput 270 best-direction]
  if (resource-ahead > best-amount) [set best-direction [270] set best-amount resource-ahead]
  ifelse best-amount > (norm-min-resource * max-resource-here) [
    set heading one-of best-direction
  ][
    set heading one-of [0 90 180 270]
  ]
end

to-report resource-ahead
  let total 0
  let how-far 1
  repeat vision
    [ set total total + [resource-here] of patch-ahead how-far
      set how-far how-far + 1 ]
  report total
end

to grow-resource
  if max-resource-here > 0 [
    set resource-here resource-here + regrowth-rate * resource-here * (1 - resource-here / max-resource-here)]
  recolor-patch
end

;; each turtle harvests the resource on its patch.
to harvest
  ask turtles [set harvestedlevel 10] ; so that only agents who actually harvested may get punished
  ask turtles [ if resource-here >= 1 and resource-here >= (norm-min-resource * max-resource-here) [
      set harvestedlevel resource-here / max-resource-here
      set resource-here resource-here - 1
      set wealth wealth + 1]
  ]
  ask turtles [recolor-patch ]
end

to imitate
  ask turtles [set copied-norm norm-min-resource]
  ask turtles [
    let otheragent one-of other turtles-here
    if otheragent != nobody [
      let ratio 0
      if [wealth] of otheragent > wealth [
        set copied-norm [norm-min-resource] of otheragent + random-normal 0 stdeverror
        if copied-norm > 1 [set copied-norm 1]
        if copied-norm < 0 [set copied-norm 0]
      ]
    ]
  ]
  ask turtles [set norm-min-resource copied-norm]
end

to monitor
  ask turtles [
    if wealth > costpunish [
      let threshold norm-min-resource
      let cheatingagents turtles in-radius radius with [harvestedlevel < threshold]

      if cheatingagents != nobody [
        set wealth wealth - count cheatingagents * costpunish
        ask cheatingagents [set wealth wealth - costpunished]
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
184
10
545
372
-1
-1
3.5
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
9
189
85
222
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
100
189
176
222
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
1

SLIDER
9
45
177
78
max-vision
max-vision
1
15
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
226
175
259
regrowth-rate
regrowth-rate
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
9
10
177
43
num-people
num-people
0
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
9
152
177
185
percent-best-land
percent-best-land
5
25
10.0
1
1
%
HORIZONTAL

PLOT
561
11
818
170
Resource
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
"default" 1.0 0 -16777216 true "" "plot mean [resource-here] of patches"

SLIDER
9
80
177
113
min-resource
min-resource
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
9
116
177
149
discount
discount
0
1
0.95
0.01
1
NIL
HORIZONTAL

PLOT
562
339
818
496
Wealth
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
"default" 1.0 0 -16777216 true "" "plot mean [wealth] of turtles"

SWITCH
8
262
113
295
imitate?
imitate?
0
1
-1000

SLIDER
8
299
174
332
stdeverror
stdeverror
0
0.1
0.01
0.01
1
NIL
HORIZONTAL

PLOT
562
174
818
333
Threshold
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [norm-min-resource] of turtles"

SLIDER
8
335
174
368
costpunish
costpunish
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
8
371
174
404
costpunished
costpunished
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
8
407
174
440
radius
radius
0
10
5.0
1
1
NIL
HORIZONTAL

SWITCH
8
448
111
481
punish?
punish?
0
1
-1000

@#$#@#$#@
Build on the code base of Wealth Distribution by Uri Wilensky in the NetLogo Library (social sciences).

If there is no imitation and min-resource, the agents are greedy and overharvest the resource.
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
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>avgresource</metric>
    <metric>avgnorm</metric>
    <metric>avgwealth</metric>
    <enumeratedValueSet variable="discount">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="imitate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stdeverror">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costpunish">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radius">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-best-land">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="punish?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-vision">
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-resource">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="costpunished" first="0" step="0.02" last="0.1"/>
    <enumeratedValueSet variable="num-people">
      <value value="1000"/>
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
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225
@#$#@#$#@
0
@#$#@#$#@
