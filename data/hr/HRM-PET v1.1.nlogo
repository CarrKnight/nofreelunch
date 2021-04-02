;;The idea of Motivation and Hygiene factors used here is derived from Herzberg, et al. (1959) The Motivation to Work, Publisher: John Wiley & Sons, Inc.

breed [workers a-workers]

turtles-own [
  achievement-style
  recognition-style
  work-itself-style
  responsibility-style
  advancement-style
  policy-tolerance
  supervision-tolerance
  relationship-tolerance
  conditions-tolerance
  salary-tolerance
  satisfaction
  dissatisfaction
  moved?
  halfinclination
  fifthinclination
]  ;; Agents own their ideal motivation needs and their ability to tolerate hygiene factors. The motivation factors used here are from the primary ones identified in the
;; original publication of the Herzberg's Two-Factor Theory. The hygiene toleration levels enable the agent-environment interaction in the simulation.


patches-own [
  policy-style
  supervision-style
  relationship-style
  conditions-style
  salary-style
  achievement-potential
  recognition-potential
  work-itself-potential
  responsibility-potential
  advancement-potential
  hygiene-total
  satisfaction-turtles-here
  dissatisfaction-turtles-here
]  ;; Patches represent work units and have hygiene factors and potential motivation levels. The hygiene factors used here are from the primary ones identified in the
;; original publication of the Herzberg's Two-Factor Theory. The potential motivation levels enable the agent-environment interaction in the simulation.

globals [

  s-greater-d ;;number of agents with satisfaction greater than dissatsfaction
  d-greater-s ;;number of agents with dissatisfaction greater than satisfaction
  sprout-count; number of turtles hired
  die-count; number of turtles that have retired


]

;; this procedures sets up the model
to setup
  clear-all
  ask patches [
    set satisfaction-turtles-here 0
    set dissatisfaction-turtles-here 0
    ;; sets hygiene levels of patches, color it shades of cyan
    if hygiene-factor-distribution = "random" [
      set policy-style random 10
      set supervision-style random 10
      set relationship-style random 10
      set conditions-style random 10
      set salary-style random 10
      set achievement-potential random 10
      set recognition-potential random 10
      set work-itself-potential random 10
      set responsibility-potential random 10
      set advancement-potential random 10
    ]
    if hygiene-factor-distribution = "normal" [
      set policy-style random-normal 5 2.5
      set supervision-style random-normal 5 2.5
      set relationship-style random-normal 5 2.5
      set conditions-style random-normal 5 2.5
      set salary-style random-normal 5 2.5
      set achievement-potential random-normal 5 2.5
      set recognition-potential random-normal 5 2.5
      set work-itself-potential random-normal 5 2.5
      set responsibility-potential random-normal 5 2.5
      set advancement-potential random-normal 5 2.5

    ]
    ;; poisson version does not yet work properly, cannot get it to distribute less than zero
    if hygiene-factor-distribution = "poisson" [
      set policy-style random-poisson 0.5
      set supervision-style random-poisson 0.5
      set relationship-style random-poisson 0.5
      set conditions-style random-poisson 0.5
      set salary-style random-poisson 0.5
      set achievement-potential random-poisson 0.5
      set recognition-potential random-poisson 0.5
      set work-itself-potential random-poisson 0.5
      set responsibility-potential random-poisson 0.5
      set advancement-potential random-poisson 0.5

    ]
    set hygiene-total sqrt((policy-style + supervision-style + relationship-style + conditions-style + salary-style) *
      (policy-style + supervision-style + relationship-style + conditions-style + salary-style))
    set pcolor scale-color cyan hygiene-total 0 50
  ]

  create-workers number-of-workers [
    setxy random-xcor random-ycor
    set color yellow
    set shape "person"
  ]
  ask turtles [
    set satisfaction 0
    set dissatisfaction 0
    set halfinclination random 2
    set fifthinclination random 5
    if motivation-factor-distribution = "random" [
      set achievement-style random 10
      set recognition-style random 10
      set work-itself-style random 10
      set responsibility-style random 10
      set advancement-style random 10
      set policy-tolerance random 10
      set supervision-tolerance random 10
      set relationship-tolerance random 10
      set conditions-tolerance random 10
      set salary-tolerance random 10
    ]
    if motivation-factor-distribution = "normal" [
      set achievement-style random-normal 5 2.5
      set recognition-style random-normal 5 2.5
      set work-itself-style random-normal 5 2.5
      set responsibility-style random-normal 5 2.5
      set advancement-style random-normal 5 2.5
      set policy-tolerance random-normal 5 2.5
      set supervision-tolerance random-normal 5 2.5
      set relationship-tolerance random-normal 5 2.5
      set conditions-tolerance random-normal 5 2.5
      set salary-tolerance random-normal 5 2.5
    ]
    if motivation-factor-distribution = "poisson" [
      set achievement-style random-poisson 0.5
      set recognition-style random-poisson 0.5
      set work-itself-style random-poisson 0.5
      set responsibility-style random-poisson 0.5
      set advancement-style random-poisson 0.5
      set policy-tolerance random-poisson 0.5
      set supervision-tolerance random-poisson 0.5
      set relationship-tolerance random-poisson 0.5
      set conditions-tolerance random-poisson 0.5
      set salary-tolerance random-poisson 0.5
    ]
  ]
  reset-ticks
end

;; make the model run
to go
  ask turtles [
    hire
    assess-hygiene ;; check to see if agent should die
    assess-state
    adjust-state
  ]
  adjust-hygiene    ;; the hygiene grows back
  my-update-plots ;; plot the population counts

  tick
;  if not any? turtles with [moved? = TRUE] [
;    stop]

end

to hire
  if dissatisfaction > 100 [

    ask patch-here [sprout-workers 1 [
      setxy random-xcor random-ycor
      set color yellow
      set shape "person"
      set satisfaction 0
      set dissatisfaction 0
      set halfinclination random 2
      set fifthinclination random 5
      if motivation-factor-distribution = "random" [
        set achievement-style random 10
        set recognition-style random 10
        set work-itself-style random 10
        set responsibility-style random 10
        set advancement-style random 10
        set policy-tolerance random 10
        set supervision-tolerance random 10
        set relationship-tolerance random 10
        set conditions-tolerance random 10
        set salary-tolerance random 10
      ]
      if motivation-factor-distribution = "normal" [
        set achievement-style random-normal 5 2.5
        set recognition-style random-normal 5 2.5
        set work-itself-style random-normal 5 2.5
        set responsibility-style random-normal 5 2.5
        set advancement-style random-normal 5 2.5
        set policy-tolerance random-normal 5 2.5
        set supervision-tolerance random-normal 5 2.5
        set relationship-tolerance random-normal 5 2.5
        set conditions-tolerance random-normal 5 2.5
        set salary-tolerance random-normal 5 2.5
      ]
      if motivation-factor-distribution = "poisson" [
        set achievement-style random-poisson 0.5
        set recognition-style random-poisson 0.5
        set work-itself-style random-poisson 0.5
        set responsibility-style random-poisson 0.5
        set advancement-style random-poisson 0.5
        set policy-tolerance random-poisson 0.5
        set supervision-tolerance random-poisson 0.5
        set relationship-tolerance random-poisson 0.5
        set conditions-tolerance random-poisson 0.5
        set salary-tolerance random-poisson 0.5
      ]
      ]
    ]
    set sprout-count (sprout-count + 1)
    set die-count (die-count + 1)
    die

  ]
end

;; The Decide-Move procedure has agents assess their initial work environment and whether it meets their minimum acceptable level. If it isn't the agent moves.

to assess-hygiene
  if hygiene-weight = "low-satisficing" [
    (ifelse policy-tolerance < policy-style OR
      supervision-tolerance < supervision-style OR
      relationship-tolerance < relationship-style OR
      conditions-tolerance < conditions-style OR
      salary-tolerance < salary-style [
        set moved? FALSE
        assess-motivation
      ]
      [ first-move
    ])
  ]
  if hygiene-weight = "mid-satisficing" [
    (ifelse policy-tolerance < policy-style AND
      (supervision-tolerance < supervision-style OR
        relationship-tolerance < relationship-style OR
        conditions-tolerance < conditions-style OR
        salary-tolerance < salary-style) [
        set moved? FALSE
        assess-motivation
      ]
      [ first-move
    ])
  ]
  if hygiene-weight = "high" [
    (ifelse policy-tolerance < policy-style AND
      supervision-tolerance < supervision-style AND
      relationship-tolerance < relationship-style AND
      conditions-tolerance < conditions-style AND
      salary-tolerance < salary-style [
        set moved? FALSE
        assess-motivation
      ]
      [ first-move
    ])
  ]
end

to assess-motivation

  if motivation-weight = "short-term" [
    (ifelse achievement-style < achievement-potential AND
      recognition-style < recognition-potential [
        set moved? FALSE
        ;assess-state
      ]
      [ second-move ])

    ]

  if motivation-weight = "long-term" [
    (ifelse work-itself-style < work-itself-potential AND
      responsibility-style < responsibility-potential AND
      advancement-style < advancement-potential [
        set moved? FALSE
        ;assess-state
      ]
      [ second-move ])
  ]

  if motivation-weight = "half-short-long" [
    if halfinclination = 0 [
      (ifelse achievement-style < achievement-potential AND
        recognition-style < recognition-potential [
          set moved? FALSE
         ; assess-state
        ]
        [ second-move ])
    ]
    if halfinclination = 1 [
      (ifelse work-itself-style < work-itself-potential AND
        responsibility-style < responsibility-potential AND
        advancement-style < advancement-potential [
          set moved? FALSE
          ;assess-state
        ]
        [ second-move ])
    ]
  ]

  if motivation-weight = "varied" [
    if fifthinclination = 0 [
      (ifelse achievement-style < achievement-potential [
        set moved? FALSE
          ;assess-state
        ]
        [ second-move ])
    ]
    if fifthinclination = 1 [
      (ifelse recognition-style < recognition-potential [
        set moved? FALSE
        ;  assess-state
        ]
        [ second-move ])
    ]
    if fifthinclination = 2 [
      (ifelse work-itself-style < work-itself-potential [
        set moved? FALSE
         ; assess-state
        ]
        [ second-move ])
    ]
    if fifthinclination = 3 [
      (ifelse responsibility-style < responsibility-potential [
        set moved? FALSE
          ;assess-state
        ]
        [ second-move ])
    ]
    if fifthinclination = 4 [
      (ifelse advancement-style < advancement-potential  [
        set moved? FALSE
          ;assess-state
        ]
        [ second-move ])
    ]
  ]
end

to first-move  ; turtle procedure

  rt random 50
  lt random 50
  fd 1
  set moved? TRUE
  set satisfaction 0
  set dissatisfaction 0
  assess-motivation

end

to second-move  ; turtle procedure

  rt random 50
  lt random 50
  fd 1
  set moved? TRUE
  set satisfaction 0
  set dissatisfaction 0
  ;assess-state

end

;; The Assess-state procedure determines the satisfaction and dissatisfaction levels of each agent based on their current work environment.
to assess-state

  if achievement-style < achievement-potential [
    set satisfaction satisfaction + 0.2 ]
  if recognition-style < recognition-potential [
    set satisfaction satisfaction + 0.17 ]
  if work-itself-style < work-itself-potential [
    set satisfaction satisfaction + 0.13 ]
  if responsibility-style < responsibility-potential [
    set satisfaction satisfaction + 0.12 ]
  if advancement-style < advancement-potential [
    set satisfaction satisfaction + 0.1 ]
  if policy-tolerance < policy-style [
    set dissatisfaction dissatisfaction + 0.28 ]
  if supervision-tolerance < supervision-style [
    set dissatisfaction dissatisfaction + 0.18 ]
  if relationship-tolerance < relationship-style [
    set dissatisfaction dissatisfaction + 0.14 ]
  if conditions-tolerance < conditions-style [
    set dissatisfaction dissatisfaction + 0.1 ]
  if salary-tolerance < salary-style [
    set dissatisfaction dissatisfaction + 0.15 ]

end


;; The adjust-state procedure sets the agents' new motivation factor styles (where satisfaction is greater than dissatisfaction) and new hygiene-tolerance levels (where dissatisfaction is greater than satsifaction)
;; based on the experimenter's test. If not testing a specific theory set to "consistent-change" and 0.0.
to adjust-state
  if satisfaction <= 0 [
    set satisfaction 0
  ]
  if dissatisfaction <= 0 [
    set dissatisfaction 0
  ]

  if satisfaction >= 0 AND dissatisfaction >= 0 [
    if satisfaction - dissatisfaction > 0 [
      if satisfaction-motivation-change = "consistent-change" [
        set achievement-style achievement-style + motivation-consistent-change-amount
        set recognition-style recognition-style + motivation-consistent-change-amount
        set work-itself-style work-itself-style + motivation-consistent-change-amount
        set responsibility-style responsibility-style + motivation-consistent-change-amount
        set advancement-style advancement-style + motivation-consistent-change-amount
      ]
      if satisfaction-motivation-change = "varying-increase" [
        set achievement-style achievement-style + random-float 1
        set recognition-style recognition-style + random-float 1
        set work-itself-style work-itself-style + random-float 1
        set responsibility-style responsibility-style + random-float 1
        set advancement-style advancement-style + random-float 1
      ]
      if satisfaction-motivation-change = "varying-decrease" [
        set achievement-style achievement-style + random-float -1
        set recognition-style recognition-style + random-float -1
        set work-itself-style work-itself-style + random-float -1
        set responsibility-style responsibility-style + random-float -1
        set advancement-style advancement-style + random-float -1
      ]
    ]
    if satisfaction - dissatisfaction < 0 [
      if dissatisfaction-tolerance-change = "consistent-change" [
        set policy-tolerance policy-tolerance + tolerance-consistent-change-amount
        set supervision-tolerance supervision-tolerance + tolerance-consistent-change-amount
        set relationship-tolerance relationship-tolerance + tolerance-consistent-change-amount
        set conditions-tolerance conditions-tolerance + tolerance-consistent-change-amount
        set salary-tolerance salary-tolerance + tolerance-consistent-change-amount
      ]
      if dissatisfaction-tolerance-change = "varying-increase" [
        set policy-tolerance policy-tolerance + random-float 1
        set supervision-tolerance supervision-tolerance + random-float 1
        set relationship-tolerance relationship-tolerance + random-float 1
        set conditions-tolerance conditions-tolerance + random-float 1
        set salary-tolerance salary-tolerance + random-float 1
      ]
      if dissatisfaction-tolerance-change = "varying-decrease" [
        set policy-tolerance policy-tolerance + random-float -1
        set supervision-tolerance supervision-tolerance + random-float -1
        set relationship-tolerance relationship-tolerance + random-float -1
        set conditions-tolerance conditions-tolerance + random-float -1
        set salary-tolerance salary-tolerance + random-float -1
      ]
    ]
  ]
end

;; The hygiene procedures below determine the average satisfaction/dissatisfaction levels of the agents in their work unit and adjust hygiene factors and potential based on experimenter's setting.


to adjust-hygiene
  ask patches [
    if count turtles-here > 0 [
      set satisfaction-turtles-here ((sum [satisfaction] of turtles-here) / count turtles-here)
      set dissatisfaction-turtles-here ((sum [dissatisfaction] of turtles-here) / count turtles-here)
    ]
    if (satisfaction-turtles-here - dissatisfaction-turtles-here) > 0 [
      if satisfaction-potential-change = "consistent-change" [
        set achievement-potential achievement-potential + potential-consistent-change-amount
        set recognition-potential recognition-potential + potential-consistent-change-amount
        set work-itself-potential work-itself-potential + potential-consistent-change-amount
        set responsibility-potential responsibility-potential + potential-consistent-change-amount
        set advancement-potential advancement-potential + potential-consistent-change-amount
      ]
      if satisfaction-potential-change = "varying-increase" [
        set achievement-potential achievement-potential + random-float 1
        set recognition-potential recognition-potential + random-float 1
        set work-itself-potential work-itself-potential + random-float 1
        set responsibility-potential responsibility-potential + random-float 1
        set advancement-potential advancement-potential + random-float 1
      ]
      if satisfaction-potential-change = "varying-decrease" [
        set achievement-potential achievement-potential + random-float -1
        set recognition-potential recognition-potential + random-float -1
        set work-itself-potential work-itself-potential + random-float -1
        set responsibility-potential responsibility-potential + random-float -1
        set advancement-potential advancement-potential + random-float -1
      ]
    ]
    if (satisfaction-turtles-here - dissatisfaction-turtles-here) < 0 [
      if dissatisfaction-hygiene-change = "consistent-change" [
        set policy-style policy-style + hygiene-consistent-change-amount
        set supervision-style supervision-style + hygiene-consistent-change-amount
        set relationship-style relationship-style + hygiene-consistent-change-amount
        set conditions-style conditions-style + hygiene-consistent-change-amount
        set salary-style salary-style + hygiene-consistent-change-amount
      ]
      if dissatisfaction-hygiene-change = "varying-increase" [
        set policy-style policy-style + random-float 1
        set supervision-style supervision-style + random-float 1
        set relationship-style relationship-style + random-float 1
        set conditions-style conditions-style + random-float 1
        set salary-style salary-style + random-float 1
      ]
      if dissatisfaction-hygiene-change = "varying-decrease" [
        set policy-style policy-style + random-float -1
        set supervision-style supervision-style + random-float -1
        set relationship-style relationship-style + random-float -1
        set conditions-style conditions-style + random-float -1
        set salary-style salary-style + random-float -1
      ]
    ]
    if count turtles-here = 0 [
      set satisfaction-turtles-here 0
      set dissatisfaction-turtles-here 0
    ]
   recolor-hygiene
  ]
end

to recolor-hygiene
  set hygiene-total sqrt((policy-style + supervision-style + relationship-style + conditions-style + salary-style) *
      (policy-style + supervision-style + relationship-style + conditions-style + salary-style))
  set pcolor scale-color cyan hygiene-total 0 50
end

;; update the plots in the interface tab
to my-update-plots
  set s-greater-d (count turtles with [satisfaction > dissatisfaction])
  set d-greater-s (count turtles with [satisfaction < dissatisfaction])
  if ticks = 100 [ export-world (word "100 " random-float 1.00 ".csv") ]
  if ticks = 500 [ export-world (word "500 " random-float 1.00 ".csv")]
  if ticks = 1000 [ export-world (word "1000 " random-float 1.00 ".csv")]
  if ticks = 2000 [ export-world (word "2000 " random-float 1.00 ".csv")]
  if ticks = 4000 [ export-world (word "4000 " random-float 1.00 ".csv")]
end
@#$#@#$#@
GRAPHICS-WINDOW
705
15
1133
444
-1
-1
12.0
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
35
80
101
113
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
180
80
243
113
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

SLIDER
53
11
231
44
number-of-workers
number-of-workers
0
5000
0.0
1
1
NIL
HORIZONTAL

BUTTON
110
80
173
113
go
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
35
260
317
293
tolerance-consistent-change-amount
tolerance-consistent-change-amount
-1.0
1.0
0.0
0.1
1
NIL
HORIZONTAL

CHOOSER
35
120
227
165
satisfaction-motivation-change
satisfaction-motivation-change
"varying-increase" "varying-decrease" "consistent-change"
2

SLIDER
35
170
302
203
motivation-consistent-change-amount
motivation-consistent-change-amount
-1.0
1.0
0.0
0.1
1
NIL
HORIZONTAL

CHOOSER
35
210
237
255
dissatisfaction-tolerance-change
dissatisfaction-tolerance-change
"varying-increase" "varying-decrease" "consistent-change"
2

CHOOSER
345
120
587
165
dissatisfaction-hygiene-change
dissatisfaction-hygiene-change
"varying-increase" "varying-decrease" "consistent-change"
2

CHOOSER
345
210
527
255
satisfaction-potential-change
satisfaction-potential-change
"varying-increase" "varying-decrease" "consistent-change"
2

SLIDER
345
170
622
203
hygiene-consistent-change-amount
hygiene-consistent-change-amount
-1.0
1.0
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
345
260
592
293
potential-consistent-change-amount
potential-consistent-change-amount
-1.0
1.0
0.0
0.1
1
NIL
HORIZONTAL

PLOT
35
305
415
525
satisfaction-dissatisfaction count
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sat>dissat" 1.0 0 -16777216 true "" "plot s-greater-d"
"dissat>sat" 1.0 0 -7500403 true "" "plot d-greater-s"

MONITOR
525
485
625
530
Moved work units
count turtles with [moved? = TRUE]
17
1
11

CHOOSER
305
50
487
95
motivation-factor-distribution
motivation-factor-distribution
"random" "normal" "poisson"
0

CHOOSER
515
50
687
95
hygiene-factor-distribution
hygiene-factor-distribution
"random" "normal" "poisson"
0

MONITOR
430
485
512
530
NIL
count turtles
17
1
11

CHOOSER
440
320
578
365
hygiene-weight
hygiene-weight
"low-satisficing" "mid-satisficing" "high"
1

CHOOSER
440
375
578
420
motivation-weight
motivation-weight
"short-term" "long-term" "half-short-long" "varied"
2

MONITOR
430
435
512
480
hires
sprout-count
17
1
11

MONITOR
525
435
597
480
departures
die-count
17
1
11

@#$#@#$#@
## ACKNOWLEDGMENT



## WHAT IS IT?
According to Herzberg's Two Factor Theory, when individuals are dsatisfied in their jobs they report factors associated to their place in the job, motivation factors. When individuals report dissatisfaction, they report factors associated with the job context, hygiene factors. In Herzberg's original studies he identified the primary factors contributing to satisfaction as Achievement, Recognition, the Work Itself, Responsibility, and Advancement. The Hygiene factors found most contributing to dissatisfaction in his studies were Company Policy and Adminstration, Technical Supervision, Interpersonal Relations, Salary, and Working Conditions. In this way improving hygiene factors does not create satisfaction but rather removes the impediments to the factors that lead to satisfaction. 

## HOW IT WORKS



## HOW TO USE IT

## HOW TO CITE

For the model itself:

* Iasiello, C. (2020).  NetLogo Herzberg Model.  

For the theory implemented in this model cite:

*Herzberg, et al. (1959) The Motivation to Work, Publisher: John Wiley & Sons, Inc.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

moose
false
0
Polygon -7500403 true true 196 228 198 297 180 297 178 244 166 213 136 213 106 213 79 227 73 259 50 257 49 229 38 197 26 168 26 137 46 120 101 122 147 102 181 111 217 121 256 136 294 151 286 169 256 169 241 198 211 188
Polygon -7500403 true true 74 258 87 299 63 297 49 256
Polygon -7500403 true true 25 135 15 186 10 200 23 217 25 188 35 141
Polygon -7500403 true true 270 150 253 100 231 94 213 100 208 135
Polygon -7500403 true true 225 120 204 66 207 29 185 56 178 27 171 59 150 45 165 90
Polygon -7500403 true true 225 120 249 61 241 31 265 56 272 27 280 59 300 45 285 90

moose-face
false
0
Circle -7566196 true true 101 110 95
Circle -7566196 true true 111 170 77
Polygon -7566196 true true 135 243 140 267 144 253 150 272 156 250 158 258 161 241
Circle -16777216 true false 127 222 9
Circle -16777216 true false 157 222 8
Circle -1 true false 118 143 16
Circle -1 true false 159 143 16
Polygon -7566196 true true 106 135 88 135 71 111 79 95 86 110 111 121
Polygon -7566196 true true 205 134 190 135 185 122 209 115 212 99 218 118
Polygon -7566196 true true 118 118 95 98 69 84 23 76 8 35 27 19 27 40 38 47 48 16 55 23 58 41 71 35 75 15 90 19 86 38 100 49 111 76 117 99
Polygon -7566196 true true 167 112 190 96 221 84 263 74 276 30 258 13 258 35 244 38 240 11 230 11 226 35 212 39 200 15 192 18 195 43 169 64 165 92

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
Polygon -7500403 true true 75 225 97 249 112 252 122 252 114 242 102 241 89 224 94 181 64 113 46 119 31 150 32 164 61 204 57 242 85 266 91 271 101 271 96 257 89 257 70 242
Polygon -7500403 true true 216 73 219 56 229 42 237 66 226 71
Polygon -7500403 true true 181 106 213 69 226 62 257 70 260 89 285 110 272 124 234 116 218 134 209 150 204 163 192 178 169 185 154 189 129 189 89 180 69 166 63 113 124 110 160 111 170 104
Polygon -6459832 true true 252 143 242 141
Polygon -6459832 true true 254 136 232 137
Line -16777216 false 75 224 89 179
Line -16777216 false 80 159 89 179
Polygon -6459832 true true 262 138 234 149
Polygon -7500403 true true 50 121 36 119 24 123 14 128 6 143 8 165 8 181 7 197 4 233 23 201 28 184 30 169 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 187 163 195 240 214 260 222 256 222 248 212 245 205 230 205 155
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 47 118
Polygon -16777216 true false 235 90 250 91 255 99 248 98 244 92
Line -16777216 false 236 112 246 119
Polygon -16777216 true false 278 119 282 116 274 113
Line -16777216 false 189 201 203 161
Line -16777216 false 90 262 94 272
Line -16777216 false 110 246 119 252
Line -16777216 false 190 266 194 274
Line -16777216 false 218 251 219 257
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 246 67 234 64
Line -16777216 false 229 45 235 68
Line -16777216 false 30 150 30 165

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
  <experiment name="Sensitivity Analysis - consistent change condition 0" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5001"/>
    <metric>s-greater-d</metric>
    <metric>d-greater-s</metric>
    <metric>sprout-count</metric>
    <metric>die-count</metric>
    <metric>count turtles with [moved? = TRUE]</metric>
    <enumeratedValueSet variable="number-of-workers">
      <value value="100"/>
      <value value="1000"/>
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="potential-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tolerance-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satisfaction-potential-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satisfaction-motivation-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-factor-distribution">
      <value value="&quot;random&quot;"/>
      <value value="&quot;normal&quot;"/>
      <value value="&quot;poisson&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dissatisfaction-hygiene-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-factor-distribution">
      <value value="&quot;random&quot;"/>
      <value value="&quot;normal&quot;"/>
      <value value="&quot;poisson&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-weight">
      <value value="&quot;low-satsficing&quot;"/>
      <value value="&quot;mid-satsificing&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-weight">
      <value value="&quot;varied&quot;"/>
      <value value="&quot;short-term&quot;"/>
      <value value="&quot;long-term&quot;"/>
      <value value="&quot;half-short-long&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dissatisfaction-tolerance-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Hygiene Distribution - 5000" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2001"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-workers">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="potential-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tolerance-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satisfaction-potential-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-consistent-change-amount">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="satisfaction-motivation-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dissatisfaction-hygiene-change">
      <value value="&quot;consistent-change&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-factor-distribution">
      <value value="&quot;random&quot;"/>
      <value value="&quot;normal&quot;"/>
      <value value="&quot;poisson&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-factor-distribution">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hygiene-weight">
      <value value="&quot;high&quot;"/>
      <value value="&quot;mid-satisficing&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivation-weight">
      <value value="&quot;half-short-long&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dissatisfaction-tolerance-change">
      <value value="&quot;consistent-change&quot;"/>
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
