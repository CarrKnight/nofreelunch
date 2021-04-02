;;; PEER REVIEW GAME ;;;
;;; baseline version ;;;

extensions [profiler]

globals [
  exp-qual-ranking          ;;; ordered distribution of expected quality --> in case of total-resourceiple reviewers, exp-sub-qual and exp-rev-qual
  comparison-value          ;;; third quartile of submission qualities

  ;;; indexes
  evaluation-bias
  productivity-loss
  reviewing-expenses
  gini-index
  pub-quality
  top-quality
;  publication-list
;  effort-list
  total-resource
  avgEvalBias
  avgProdLoss
  avgRevExpenses
  avgGini
  avgPubQual
  avgTopQual
]

turtles-own [
  resource-share
  submission-effort
  reviewing-effort
  n-publications
  group                          ;;; flow control variable for assignment of agents to roles
  submission-quality
  review-quality
  reviewed?                       ;;; flow control for avoidance of more reviews
  recommended?
  published?
  should-have-been-published?
  perceived-quality
  noise
]


to setup
  let my-seed new-seed
  clear-all
  set total-resource researcher-time * n-researchers
  random-seed my-seed
  ask patches [set pcolor white]
  create-turtles n-researchers [
    setxy random-xcor random-ycor
    set shape "person"
    ifelse skewed-resource-dist = TRUE   ;; power law initial situation
    [
      let max-publications 50 ; set the maximum number of publications at the beginning of the game
      let gamma -0.15 ; regulates how skewed is the ditribution: values between -0.3 and -0.10 are probably fine
      set n-publications 1 + round ((max-publications - 1) * exp (gamma * random (max-publications + 1))) ;1 + round((max - 1)*exp(gamma * runif(n, 0, max)))
    ]
    [set n-publications 1]   ;; max equality initial situation
    if effort-dist = "uniform" [set submission-effort random-float 1]
    if effort-dist = "left-skewed" [
      let x random-gamma 2 1
      set submission-effort (x / (x + random-gamma 7 1))
    ]
    if effort-dist = "right-skewed" [
      let x random-gamma 7 1
      set submission-effort (x / (x + random-gamma 2 1))
    ]
    set reviewing-effort 1 - submission-effort
  ]
;  set publication-list []
;  set effort-list [submission-effort] of turtles
  reset-ticks
end


to go
  tick
  initialization                        ;;; resource updating + effort distribution
  set-groups
  game                                  ;;; game playing
  publication-outcome                   ;;; compute agents' new resource share
  indexes                               ;;; update outcome indexes
end

;to initialization-old
;  ask turtles [
;  ;;; investment updating
;
;  if strategy = 1 [increase-submission-effort]
;  if strategy = 2 [
;    ifelse published? = true
;    [increase-submission-effort]
;    [decrease-submission-effort]
;  ]
;  if strategy = 3 [
;    ifelse published? = true
;    [decrease-submission-effort]
;    [increase-submission-effort]
;  ]
;  ;; collaborative with a fair system
;  if strategy = 4 [
;    set submission-quality submission-quality + overestimation * submission-quality
;    ifelse (published? = true AND submission-quality >= comparison-value)
;     OR (published? = false AND submission-quality < comparison-value)
;    [decrease-submission-effort]
;    [increase-submission-effort]
;  ]
;  ;; strive for success
;  if strategy = 5 [
;    set submission-quality submission-quality + overestimation * submission-quality
;    ifelse (published? = true AND submission-quality >= comparison-value)
;     OR (published? = false AND submission-quality < comparison-value)
;    [increase-submission-effort]
;    [decrease-submission-effort]
;  ]
;  set recommended? false
;  set published? false
;  set reviewed? false
;  set should-have-been-published? false
;  set group 0
;  set review-quality 0
;  set resource-share total-resource * n-publications / sum [n-publications] of turtles
;  set submission-quality submission-effort * resource-share
;]
;end

to initialization
  ask turtles [
    ;;; investment updating

    ifelse strategy = 1
    [
      increase-submission-effort
    ]
    [
      ifelse strategy = 2
      [
        ifelse published? = true
        [increase-submission-effort]
        [decrease-submission-effort]
      ]
      [
        ifelse strategy = 3
        [
          ifelse published? = true
          [decrease-submission-effort]
          [increase-submission-effort]
        ]
        [
          ;; collaborative with a fair system
          ifelse strategy = 4
          [
            set submission-quality submission-quality + overestimation * submission-quality
            ifelse (published? = true AND submission-quality >= comparison-value)
            OR (published? = false AND submission-quality < comparison-value)
            [decrease-submission-effort]
            [increase-submission-effort]
          ]
          ;; strive for success
          [
            ; put here the ifs for any new strategy
            set submission-quality submission-quality + overestimation * submission-quality
            ifelse (published? = true AND submission-quality >= comparison-value)
            OR (published? = false AND submission-quality < comparison-value)
            [increase-submission-effort]
            [decrease-submission-effort]
          ]
        ]
      ]
    ]
    set recommended? false
    set published? false
    set reviewed? false
    set should-have-been-published? false
    set group 0
    set review-quality 0
    set resource-share total-resource * n-publications / sum [n-publications] of turtles
    set submission-quality submission-effort * resource-share
  ]
end


to increase-submission-effort
  set submission-effort submission-effort + effort-change
  if submission-effort > 1 [set submission-effort 1]
  set reviewing-effort 1 - submission-effort
end

to decrease-submission-effort
  set submission-effort submission-effort - effort-change
  if submission-effort < effort-change [set submission-effort effort-change]
  set reviewing-effort 1 - submission-effort
end

to set-groups                    ;;; allows multiple reviewers
  let group-label 0
  repeat n-reviewers + 1 [
    set group-label group-label + 1
    let counter 0
    while [counter < n-researchers / (n-reviewers + 1)] [
      ask one-of turtles with [group = 0] [set group group-label]
      set counter counter + 1
    ]
  ]
end

to game                          ;;; allows multiple reviewers but needs to be adjusted
  let rep 0
  repeat n-reviewers + 1 [
    set rep rep + 1
    ask turtles with [group = rep] [
      ; if submission-quality >= min-review-time [set should-have-been-published? true] ; the fact that a paper should gave been published can be seen only after all researchers played
      ; I wrote a new routine in the publication-outcome procedure
      let rev one-of turtles with [group != rep and reviewed? = false]
      ask rev [
        set review-quality reviewing-effort * resource-share
        set reviewed? true
      ]
      set noise random-normal (1) (min-review-time - min list (min-review-time) ([review-quality] of rev))
      set perceived-quality submission-quality * noise
    ]
  ]
end

to publication-outcome
  ask max-n-of (n-researchers * published-proportion) turtles [perceived-quality] [
    set published? true
    set n-publications n-publications + 1
  ]
  ask max-n-of (n-researchers * published-proportion) turtles [submission-quality] [
    set should-have-been-published? true
  ]
  ;;; comparison-value
  ifelse count turtles with [published? = true] > 0
  [
    let pub-qual [submission-quality] of turtles with [published? = true]
    set pub-qual sort-by > pub-qual
    ifelse high-comparison = true
    [set comparison-value item (length pub-qual / 4 - 1) pub-qual]
    [set comparison-value item (length pub-qual / 4 * 3 - 1) pub-qual]
  ]
  [
    set comparison-value 1
  ]
end

;to indexes-old
;  ;;; evaluation bias
;  ;;; productivity loss
;  ifelse sum [submission-quality] of turtles with [should-have-been-published? = true] > 0
;  [
;    ;set evaluation-bias count turtles with [published? = false and should-have-been-published? = true] / (published-proportion * n-researchers) ; this is slightly more efficient
;    set evaluation-bias count turtles with [published? = false and should-have-been-published? = true] / count turtles with [should-have-been-published? = true]
;    ; count turtles with [should-have-been-published? = true]
;    set productivity-loss (sum [submission-quality] of turtles with [should-have-been-published? = true] - sum [submission-quality] of turtles with [published? = true]) / sum [submission-quality] of turtles with [should-have-been-published? = true]
;  ]
;  [
;    set evaluation-bias 0
;    set productivity-loss 0
;  ]
;  ;;; reviewing expenses
;  ifelse sum [submission-quality] of turtles > 0
;  [set reviewing-expenses sum [review-quality] of turtles / sum [submission-quality] of turtles]
;  [set reviewing-expenses 1]
;
;  ;;; gini index
;  let list1 [who] of turtles
;  let list2 [who] of turtles
;  let s 0
;  foreach list1 [
;    let temp [n-publications] of turtle ?
;    foreach list2 [
;      set s s + abs(temp - [n-publications] of turtle ?)
;    ]
;  ]
;  set gini-index s / (2 * (mean [n-publications] of turtles) * (count turtles) ^ 2)
;
;  ;;; average quality of published articles
;  ifelse count turtles with [published? = true] > 0
;  [set pub-quality mean [submission-quality] of turtles with [published? = true]]
;  [set pub-quality 0]
;
;;  ;;;effort-list
;;  set effort-list [submission-effort] of turtles
;;
;;  ;;;publication list
;;  set publication-list [n-publications] of turtles
;
;  ;;;quality top
;  let pub-qual-list [submission-quality] of turtles with [published? = true]
;  set pub-qual-list sort-by > pub-qual-list
;  set top-quality mean sublist pub-qual-list 0 top
;
;  ;; compute moving average of indexes
;  if ticks > 400 [
;    set avgEvalBias (evaluation-bias + (ticks - 400 - 1) * avgEvalBias) / (ticks - 400)
;    set avgProdLoss (productivity-loss + (ticks - 400 - 1) * avgProdLoss) / (ticks - 400)
;    set avgRevExpenses (reviewing-expenses + (ticks - 400 - 1) * avgRevExpenses) / (ticks - 400)
;    set avgGini (gini-index + (ticks - 400 - 1) * avgGini) / (ticks - 400)
;    set avgPubQual (pub-quality + (ticks - 400 - 1) * avgPubQual) / (ticks - 400)
;    set avgTopQual (top-quality + (ticks - 400 - 1) * avgTopQual) / (ticks - 400)
;  ]
;end

to indexes
  let sum-should-have sum [submission-quality] of turtles with [should-have-been-published? = true]
  let pub-qual-list [submission-quality] of turtles with [published? = true]

  ;;; evaluation bias
  ;;; productivity loss
  ifelse sum-should-have > 0
  [
    set evaluation-bias count turtles with [published? = false and should-have-been-published? = true] / count turtles with [should-have-been-published? = true]
    set productivity-loss (sum-should-have - sum pub-qual-list) / sum-should-have
  ]
  [
    set evaluation-bias 0
    set productivity-loss 0
  ]
  ;;; reviewing expenses
  ifelse sum [submission-quality] of turtles > 0
  [set reviewing-expenses sum [review-quality] of turtles / sum [submission-quality] of turtles]
  [set reviewing-expenses 1]

  ;;; gini index
  let list1 [who] of turtles
  let list2 [who] of turtles
  let s 0
  foreach list1 [ ?1 ->
    let temp [n-publications] of turtle ?1
    foreach list2 [ ??1 ->
      set s s + abs(temp - [n-publications] of turtle ??1)
    ]
  ]
  set gini-index s / (2 * (mean [n-publications] of turtles) * (count turtles) ^ 2)

  ;;; average quality of published articles
  ifelse count turtles with [published? = true] > 0
  [set pub-quality mean pub-qual-list]
  [set pub-quality 0]

;  ;;;effort-list
;  set effort-list [submission-effort] of turtles
;
;  ;;;publication list
;  set publication-list [n-publications] of turtles

  ;;;quality top
  ;let pub-qual-list [submission-quality] of turtles with [published? = true]
  set pub-qual-list sort-by > pub-qual-list
  set top-quality mean sublist pub-qual-list 0 top

  ;; compute moving average of indexes
  if ticks > 400 [
    set avgEvalBias (evaluation-bias + (ticks - 400 - 1) * avgEvalBias) / (ticks - 400)
    set avgProdLoss (productivity-loss + (ticks - 400 - 1) * avgProdLoss) / (ticks - 400)
    set avgRevExpenses (reviewing-expenses + (ticks - 400 - 1) * avgRevExpenses) / (ticks - 400)
    set avgGini (gini-index + (ticks - 400 - 1) * avgGini) / (ticks - 400)
    set avgPubQual (pub-quality + (ticks - 400 - 1) * avgPubQual) / (ticks - 400)
    set avgTopQual (top-quality + (ticks - 400 - 1) * avgTopQual) / (ticks - 400)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
201
77
389
266
-1
-1
5.455
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
27
15
180
59
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
29
69
96
107
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

BUTTON
103
70
181
108
step
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

PLOT
431
10
631
165
Evaluation Bias
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
"default" 1.0 0 -16777216 true "" "plot evaluation-bias"

PLOT
648
10
842
165
Productivity Loss
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
"default" 1.0 0 -16777216 true "" "plot productivity-loss"

SLIDER
28
125
181
158
n-researchers
n-researchers
0
1000
500.0
10
1
NIL
HORIZONTAL

PLOT
858
11
1058
161
Reviewing Expenses
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
"default" 1.0 0 -16777216 true "" "plot reviewing-expenses"

PLOT
652
185
852
333
Gini Index
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
"default" 1.0 0 -16777216 true "" "plot gini-index"

SLIDER
21
226
193
259
exp-sub-effort
exp-sub-effort
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
22
270
194
303
effort-change
effort-change
0
0.2
0.05
0.01
1
NIL
HORIZONTAL

PLOT
1086
10
1314
168
resources
NIL
NIL
0.0
250.0
0.0
250.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [resource-share] of turtles"

PLOT
877
193
1106
339
submission-effort distribution
NIL
NIL
0.0
1.5
0.0
100.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [submission-effort] of turtles"

SLIDER
29
172
182
205
n-reviewers
n-reviewers
1
3
1.0
1
1
NIL
HORIZONTAL

PLOT
879
357
1106
503
n-publications distribution
NIL
NIL
0.0
150.0
0.0
10.0
true
false
"" ""
PENS
"default" 5.0 1 -16777216 true "" "histogram [n-publications] of turtles"

PLOT
658
354
856
509
comparison-value
NIL
NIL
0.0
10.0
0.0
0.01
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot comparison-value"

PLOT
433
354
633
504
submission quality distribution
NIL
NIL
0.0
5.0
0.0
100.0
false
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [submission-quality] of turtles"

CHOOSER
200
19
373
64
strategy
strategy
1 2 3 4 5
0

SWITCH
221
396
395
429
skewed-resource-dist
skewed-resource-dist
1
1
-1000

SWITCH
221
485
394
518
high-comparison
high-comparison
0
1
-1000

CHOOSER
221
436
394
481
effort-dist
effort-dist
"uniform" "left-skewed" "right-skewed"
0

BUTTON
245
296
332
329
go x 500
repeat 500 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
207
342
280
387
NIL
top-quality
5
1
11

PLOT
431
188
631
338
quality-top
NIL
NIL
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"Published" 1.0 0 -16777216 true "" "plot pub-quality"
"Top" 1.0 0 -2674135 true "" "plot top-quality"

SLIDER
25
362
181
395
top
top
0
250
10.0
1
1
NIL
HORIZONTAL

MONITOR
296
343
376
388
NIL
pub-quality
5
1
11

SLIDER
24
321
182
354
overestimation
overestimation
0
0.5
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
19
453
186
486
researcher-time
researcher-time
0
200
90.0
10
1
hours
HORIZONTAL

SLIDER
20
498
181
531
min-review-time
min-review-time
0
10
6.0
1
1
hours
HORIZONTAL

SLIDER
25
404
181
437
published-proportion
published-proportion
0
1
0.25
0.05
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="v8blind_19-05" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>avgEvalBias</metric>
    <metric>avgProdLoss</metric>
    <metric>avgRevExpenses</metric>
    <metric>avgGini</metric>
    <metric>avgPubQual</metric>
    <metric>avgTopQual</metric>
    <enumeratedValueSet variable="n-reviewers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-researchers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-sub-effort">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-change">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skewed-resource-dist">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-dist">
      <value value="&quot;uniform&quot;"/>
      <value value="&quot;right-skewed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="researcher-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-review-time">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v8nonBlind_19-05" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>avgEvalBias</metric>
    <metric>avgProdLoss</metric>
    <metric>avgRevExpenses</metric>
    <metric>avgGini</metric>
    <metric>avgPubQual</metric>
    <metric>avgTopQual</metric>
    <enumeratedValueSet variable="n-reviewers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-researchers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-sub-effort">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-change">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skewed-resource-dist">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-dist">
      <value value="&quot;uniform&quot;"/>
      <value value="&quot;right-skewed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="researcher-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-review-time">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="high-comparison">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overestimation">
      <value value="0"/>
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v8blind_14-07-17" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>evaluation-bias</metric>
    <metric>pub-quality</metric>
    <metric>top-quality</metric>
    <enumeratedValueSet variable="n-reviewers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-researchers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-sub-effort">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-change">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skewed-resource-dist">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-dist">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="researcher-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-review-time">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v8nonBlind_04-07-17" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>evaluation-bias</metric>
    <metric>pub-quality</metric>
    <metric>top-quality</metric>
    <enumeratedValueSet variable="n-reviewers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-researchers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exp-sub-effort">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-change">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skewed-resource-dist">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effort-dist">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="researcher-time">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-review-time">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="high-comparison">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overestimation">
      <value value="0"/>
      <value value="0.1"/>
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
