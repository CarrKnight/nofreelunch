extensions [ nw ]

breed [ households household ] ; household turtles
directed-link-breed [ directed-edges directed-edge ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MODEL PARAMETERS
;; variable names that are commented are defined via the interface, only noted here for completeness
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals
[ dead-households               ; number of households died due to low budget
  insured-households            ; number of insured households
  request-threshold             ; threshold below which households ask for transfers
  donate-threshold              ; threshold above which households can give transfers
  transfer                      ; money to be transferred between households
  money-needed                  ; money needed from other households
  total-money-needed            ; total sum needed from other households per time step
  cum-money-needed              ; cumulative sum of money needed from other households
  shock-list                    ; list of possible shock events (covariate shock)
  idiosyncratic-shock-prob      ; probability for idiosyncratic shocks
  covariate-shock-prob-vlg      ; probability for village to be hit by covariate shocks
  requesting-households         ; number of households that need help per time step
  ; timesteps                   ; number of ticks that the simulation will be run
  ; network-type                ; no network or stylized small-world network
  ; number-households           ; homogeneous household setup: number of households in the network at the beginning
  ; neighborhood-size           ; number of nodes each node is initially connected to on each side
  ; rewire-prob                 ; probability with which each link is deleted and rewired to other household
  ; budget-init                 ; homogeneous household setup: initial budget of households
  ; income-lvl                  ; homogeneous household setup: regular income of households per time step
  ; consumption-lvl             ; consumption of households per time step
  ; insurance-take-up-rate      ; insurance take-up rate
  ; insurance-coverage          ; homogeneous household setup: fraction of income covered by insurance
  ; shock-type                  ; type of shock (idiosyncratic, covariate)
  ; covariate-shock-prob-hh     ; probability for  household to be hit in case village is hit by covariate shock
  ; shock-intensity             ; shock-rate for all households
  ; transfer-behavior           ; motive behind transfer decision of households (none, solidarity, no-solidarity)
  ; request-behavior            ; motive behind transfer request of households in need (random)
  ; factor-donate-threshold     ; threshold above which households can give transfers given as multiple of consumption-lvl
  ; donation-weighting          ; weighting factor for transfer of insured households to uninsured households in case of no-solidarity transfer
  ; agent-color                 ; color of households according to their budget or shock status
  ; network-layout              ; nodes displayed in circle or links as springs
  ; size-scale                  ; scaling factor for display of nodes
  ; show-flow?                  ; display transfers in network
  ; show-agent-budget?          ; display budget in network
  ; show-agent-number?          ; display household number in network
]

turtles-own
[ active                        ; households with active = 0 are dead
  sum-insured                   ; insured sum of income
  budget                        ; budget of the household
  insured                       ; insurance status of the household
  donation-willingness          ; willingness to help households in need if able to; value depending on transfer-behavior
  ind-shock-list                ; list of individual shock events
  shock-affected                ; is the household in this timestep affected by a shock (either covariate or idiosyncratic)
  shock-affected-sum            ; sum of shocks of the households over all time steps
  payout                        ; insurance payout in case of shock
  premium                       ; insurance premium
  given                         ; money given to other households
  received                      ; money received from other households
  current-requests              ; number of requests of this household in current time step
  total-requests                ; total number of requests of this household
  current-donates               ; number of donates of this household in current time step
  total-donates                 ; total number of donates of this household
]

links-own
[ current-flow                  ; money transferred through link
  total-flow                    ; cummulative sum of money transferred through link
  number-flows                  ; number of transfer events on this link
  common-links                  ; number of common links between households linked with this link
  active-link                   ; links with active-link = 0 are dead
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MODEL SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all

  ; check inputs for scenarios
  if factor-donate-threshold < factor-request-threshold
  [ user-message "Donate threshold must be equal to or greater than request threshold."
    stop
  ]

  ; set the model random seed - only necessary when using behavior space not for nlrx
  if set-seed?
  [ ;let model-seed behaviorspace-run-number
    random-seed model-seed
  ]

  if network-type = "none"
  [ with-local-randomness [ create-households number-households ]
    layout
  ]
  if network-type = "stylized" [ with-local-randomness [ create-small-world-network number-households neighborhood-size rewire-prob ] ]

  if shock-type = "covariate-shock"
  [ ifelse covariate-shock-prob-hh = 0
    [ user-message "Covariate shock: Shock probability for households must be greater than zero."
      stop
    ]
    [ set covariate-shock-prob-vlg precision (shock-prob / covariate-shock-prob-hh) 3
      set shock-list n-values timesteps [ ifelse-value (random-float 1.0 < covariate-shock-prob-vlg) [1] [0] ]
    ]
  ]

  ; initialize household variables
  setup-households

  set donate-threshold factor-donate-threshold * consumption-lvl
  set request-threshold factor-request-threshold * consumption-lvl

  with-local-randomness [ update-view ]
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP PROCEDURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-- Household setup ----------------------------------------------------------------------------------;
to setup-households ; initialize household variables
  ask households
  [ set sum-insured insurance-coverage * income-lvl
    set insured 0
    set donation-willingness 0
    set active 1
    if shock-type = "idiosyncratic-shock" [ set ind-shock-list n-values timesteps [ifelse-value (random-float 1.0 < shock-prob) [1] [0] ] ]
    if shock-type = "covariate-shock" [ with-local-randomness [ set ind-shock-list map [[x] -> ifelse-value (x = 1) and random-float 1.0 < covariate-shock-prob-hh [x] [0]] shock-list ] ]
  ]

  ask households [ set budget precision (budget-init * income-lvl) 2 ]

  insurance-take-up
  set-donation-willingness
end

;-- Network setup -------------------------------------------------------------------------------------;
to create-small-world-network [ N K P ]

  ; create a small-world network with directed links of N nodes with K degree and rewire prob P
  nw:generate-watts-strogatz households directed-edges N K P

  ; create links in opposite direction to existing links
  ask households
  [ let caller self
    ask in-link-neighbors [ create-directed-edge-from caller ]
  ]

  ; set all links active
  ask directed-edges [ set active-link 1 ]
  layout
end

;-- Insurance setup -------------------------------------------------------------------------------------;
to insurance-take-up ; set insurance status of households
  set insured-households floor (insurance-take-up-rate * number-households)
  with-local-randomness [ ask n-of insured-households households [ set insured 1 ] ]
end

to set-donation-willingness
  ask households
  [ if transfer-behavior = "none" [ set donation-willingness 0 ]
    if transfer-behavior = "solidarity" [ set donation-willingness 1 ]
    if transfer-behavior = "no-solidarity"
    [ ifelse insured = 1
      [ set donation-willingness donation-weighting ]
      [ set donation-willingness 1 ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN PROCEDURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if (ticks > timesteps - 1)  [ stop ]

  set total-money-needed 0
  set requesting-households 0

  ask households
  [ set shock-affected 0
    set current-donates 0
    set current-requests 0
  ]

  with-local-randomness
  [ ask links
    [ set color grey
      set current-flow 0
    ]
  ]

  ; calculate budget of households consisting of  income, consumption, shocks, insurance, transfers
  annual-income
  annual-consumption
  insurance-premium
  shock-loss
  insurance-payout
  informal-transfers

  ask households ; households with budget < 0 cannot make a living from natural resource use -> die out
  [ set total-donates total-donates + current-donates
    set total-requests total-requests + current-requests
    if precision budget 2 < 0
    [ set dead-households dead-households + 1
      set budget 0
      set active 0
      with-local-randomness [ ask my-directed-edges [ set active-link 0 ] ]
    ]
  ]

  set cum-money-needed cum-money-needed + total-money-needed

  with-local-randomness [ update-view ]
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BUDGET OF HOUSEHOLDS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-- Annual income ------------------------------------------------------------------------------------;
to annual-income ; calculate income
  ask households [ if active = 1 [ set budget precision (budget + income-lvl) 2 ] ]
end

;-- Annual consumption -------------------------------------------------------------------------------;
to annual-consumption ; calculate consumption of households
  ask households [ if active = 1 [ set budget precision (budget - consumption-lvl) 2 ] ]
end

;-- Income shocks ------------------------------------------------------------------------------------;
to shock-loss ; calculate loss due to covariate and idiosyncratic shocks
  ask households
  [ if (active = 1 and item ticks ind-shock-list = 1)
    [ set shock-affected 1
      set shock-affected-sum shock-affected-sum + 1
      set budget precision (budget - shock-intensity) 2
    ]
  ]
end

;-- Insurance premium --------------------------------------------------------------------------------;
to insurance-premium ; calculate insurance premium per time step, fair insurance: prob-shock * (premium - payout) + (1 - shock-prob) * premium = 0 -> premium = shock-prob * payout
  ask households
  [ if (insured = 1 and active = 1)
    [ set premium shock-prob * shock-intensity * sum-insured
      set budget precision (budget - premium) 2
    ]
  ]
end

;-- Insurance payout ---------------------------------------------------------------------------------;
to insurance-payout ; calculate insurance payout in case of a shock
  ask households
  [ if (insured = 1 and shock-affected = 1 and active = 1)
    [ set payout shock-intensity * sum-insured
      set budget precision (budget + payout) 2
    ]
  ]
end

;-- Informal transfers -------------------------------------------------------------------------------;
to informal-transfers ; calculate informal transfers between households
  ask households
  [ if (precision budget 2 < request-threshold and active = 1) ; only households with budget < request-threshold need help
    [ let receiver self

      set requesting-households requesting-households + 1

      set money-needed request-threshold - budget ; money household in need requests to reach request-threshold
      set total-money-needed total-money-needed + money-needed
      set transfer 0

      if any? out-directed-edge-neighbors  ; ask neighbors in network
      [ if request-behavior = "random"
        [ with-local-randomness
          [ ask out-directed-edge-neighbors
            [ let donor self
              if precision money-needed 2 > 0 [ transfer-request receiver donor ] ; ask neighbors as long as money needed to reach request threshold is not reached
            ]
          ]
        ]
      ]
    ]
  ]
end

to transfer-request [ receiver donor ]
  ask directed-edge [ who ] of receiver [ who ] of donor
  [ ask donor
    [ if precision budget 2 > donate-threshold ; only households with budget > donate-threshold can help
      [ set transfer (donation-willingness * transfer-amount donor money-needed)

        transfer-money donor receiver transfer
        set money-needed money-needed - transfer
      ]
    ]
  ]
end

to transfer-money [ donor receiver money-to-transfer ] ; calculate budget change due to transfer
  ask donor
  [ set budget precision (budget - money-to-transfer) 2
    set given given + money-to-transfer
    set current-donates current-donates + 1

    ask directed-edge [ who ] of donor [ who ] of receiver
    [ set current-flow money-to-transfer
      set total-flow total-flow + money-to-transfer
      set number-flows number-flows + 1
    ]
  ]
  ask receiver
  [ set budget precision (budget + money-to-transfer) 2
    set received received + money-to-transfer
    set current-requests current-requests + 1
  ]
end

to-report transfer-amount [ donor request ] ; calculate transfer amount: minimum of budget(donor) - donate-threshold, request-threshold - budget(receiver)
  report min (list ([ budget ] of donor - donate-threshold) request)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DISPLAY PROCEDURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-- Layout design ---------------------------------------------------------------------------------;
to layout ; choose layout design: circle or spring
  if network-layout = "circle" [ layout-circle sort households max-pxcor * 0.9 ]
  if network-layout = "spring"
  [ let factor sqrt count households
    if factor = 0 [ set factor 1 ]
    layout-spring households links (1 / factor) (50 / factor) (100 / factor) ; layout-spring turtle-set link-set spring-constant spring-length repulsion-constant
  ]
end

;-- Update display ---------------------------------------------------------------------------------;
to update-view
  ask links [ view-links-appearance ]
  ask households [ view-node-appearance ]
  ask households with [ active = 0 ]
  [ set color grey
    set label (word "#" who " (inactive)")]
  display
end

to view-links-appearance ; update link thickness and labels (link procedure)
  set shape "link-curve"
  set thickness 0

  if show-flow? [ set label (word "f=" precision current-flow 3) ] ; show current flow as link label
  if current-flow > 0 [ set color red ]
  if active-link = 0 [ set shape "dashed-curve" ]
end

to view-node-appearance ; update node size, colour and labels (turtle procedure)
  set size sqrt (budget) * size-scale

  ; color of households depends either on budget (request-threshold, donate-threshold) or on shocks (shock-affected = 0/1)
  ifelse agent-color = "budget"
  [ ifelse precision budget 2 > donate-threshold ; case 1:  budget > donate-threshold
    [ set color green ]
    [ ifelse precision budget 2 < request-threshold ; case 2: budget < request-threshold
      [ set color red ]
      [ set color blue ] ; case 3: request-threshold < budget < donate-threshold
    ]
  ]
  [ ifelse shock-affected = 1
    [ set color 17 ] ; shock
    [ set color green ] ; no shock
  ]

  ; shape of households depends on insurance take-up
  ifelse insured = 1
  [ set shape "circle" ] ; insurace -> filled circle
  [ set shape "circle 2" ] ; no insurance -> empty circle

  ; agent and link labels
  ifelse show-agent-number? and (show-agent-budget? and precision budget 2 > 0) ; show household number and household budget
  [ set label (word "#" who " $" precision budget 2) ]
  [ ifelse show-agent-number? ; show only household number
    [ set label (word "#" who) ]
    [ ifelse show-agent-budget? and precision budget 2 > 0
      [ set label (word "$" precision budget 2) ] ; show only household budget
      [ set label "" ] ; show no household number and no household budget
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OUTPUT FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-- GINI coefficient ---------------------------------------------------------------------------------;
;; GINI coefficient all households
to-report get-gini
  ifelse any? households
  [ ifelse total-budget = 0
    [ report 0 ]
    [ let n number-households
      let mu mean [ budget ] of households
      let list-budget sort [ budget ] of households
      let i dead-households
      let gini 0
      while [ i < n ]
      [ set gini gini + (2 * (i + 1) - n - 1) * item i list-budget
        set i i + 1
      ]
      set gini precision (gini / (n ^ 2) / mu) 2
      report gini
    ]
  ]
  [ report 0 ]
end

;; GINI coefficient insured households
to-report get-gini-insured
  ifelse any? households with [ insured = 1 ]
  [ ifelse total-budget-insured = 0
    [ report 0 ]
    [ let n count households with [ insured = 1 ]
      let mu mean [ budget ] of households with [ insured = 1 ]
      let list-budget sort [ budget ] of households with [ insured = 1 ]
      let i 0
      let gini 0
      while [ i < n ]
      [ set gini gini + (2 * (i + 1) - n - 1) * item i list-budget
        set i i + 1
      ]
      set gini precision (gini / (n ^ 2) / mu) 2
      report gini
    ]
  ]
  [ report 0 ]
end

;; GINI coefficient uninsured households
to-report get-gini-uninsured
  ifelse any? households with [ insured = 0 ]
  [ ifelse total-budget-uninsured = 0
    [ report 0 ]
    [ let n count households with [ insured = 0 ]
      let mu mean [ budget ] of households with [ insured = 0 ]
      let list-budget sort [ budget ] of households with [ insured = 0 ]
      let i 0
      let gini 0
      while [ i < n ]
      [ set gini gini + (2 * (i + 1) - n - 1) * item i list-budget
        set i i + 1
      ]
      set gini precision (gini / (n ^ 2) / mu) 2
      report gini
    ]
  ]
  [ report 0 ]
end

;-- Budget ---------------------------------------------------------------------------------;
;; sum of budget of all surviving households
to-report total-budget
  ifelse any? households with [ active = 1 ]
  [ report sum [ budget ] of households with [ active = 1 ] ]
  [ report 0 ]
end

;; sum of budget of all insured surviving households
to-report total-budget-insured
  ifelse any? households with [ active = 1 and insured = 1 ]
  [ report sum [ budget ] of households with [ active = 1 and insured = 1 ] ]
  [ report 0 ]
end

;; sum of budget of all uninsured surviving households
to-report total-budget-uninsured
  ifelse any? households with [ active = 1 and insured = 0 ]
  [ report sum [ budget ] of households with [ active = 1 and insured = 0 ] ]
  [ report 0 ]
end

;; mean budget of all surviving households
to-report mean-budget
  ifelse any? households with [ active = 1 ]
  [ report mean [ budget ] of households with [active = 1 ] ]
  [ report 0 ]
end

;; mean budget of all insured surviving households
to-report mean-budget-insured
  ifelse any? households with [ active = 1 and insured = 1 ]
  [ report mean [ budget ] of households with [ active = 1 and insured = 1 ] ]
  [ report 0 ]
end

;; mean budget of all uninsured surviving households
to-report mean-budget-uninsured
  ifelse any? households with [ active = 1 and insured = 0 ]
  [ report mean [ budget ] of households with [ active = 1 and insured = 0 ] ]
  [ report 0 ]
end

;-- Transfer ---------------------------------------------------------------------------------;
to-report total-transfer
  report sum [ given ] of households
end

to-report total-transfer-active
  report sum [ given ] of households with [ active = 1 ]
end

to-report total-transfer-given-insured
  ifelse any? households with [ insured = 1 ]
  [ report sum [ given ] of households with [ insured = 1 ] ]
  [ report 0 ]
end

to-report total-transfer-given-uninsured
  ifelse any? households with [ insured = 0 ]
  [ report sum [ given ] of households with [ insured = 0 ] ]
  [ report 0 ]
end

to-report total-transfer-given-uninsured-active
  ifelse any? households with [ active = 1 and insured = 0 ]
  [ report sum [ given ] of households with [ active = 1 and insured = 0 ] ]
  [ report 0 ]
end

to-report total-transfer-received-uninsured-active
  ifelse any? households with [ active = 1 and insured = 0 ]
  [ report sum [ received ] of households with [ active = 1 and insured = 0 ] ]
  [ report 0 ]
end

;-- Inactive households ---------------------------------------------------------------------------------;
to-report fraction-active
  report count households with [ active = 1 ] / number-households
end

to-report fraction-active-uninsured
  ifelse any? households with [ insured = 0 ]
  [ report count households with [ active = 1 and insured = 0 ] / count households with [ insured = 0 ] ]
  [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
625
10
1349
735
-1
-1
14.0541
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
30.0

BUTTON
320
10
393
43
setup
setup
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

INPUTBOX
10
385
105
445
budget-init
0.0
1
0
Number

INPUTBOX
10
185
115
245
number-households
10.0
1
0
Number

BUTTON
400
10
475
43
go once
go
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
480
10
543
43
go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SWITCH
920
770
1075
803
show-flow?
show-flow?
1
1
-1000

INPUTBOX
110
385
180
445
income-lvl
1.0
1
0
Number

TEXTBOX
320
250
489
284
transfer parameter
12
0.0
1

TEXTBOX
320
50
470
68
shocks
11
0.0
1

CHOOSER
425
270
535
315
transfer-behavior
transfer-behavior
"none" "solidarity" "no-solidarity"
1

TEXTBOX
15
490
165
508
insurance
11
0.0
1

SLIDER
10
505
165
538
insurance-take-up-rate
insurance-take-up-rate
0
1
0.6
0.1
1
NIL
HORIZONTAL

CHOOSER
705
760
797
805
agent-color
agent-color
"shock" "budget"
0

TEXTBOX
10
365
160
383
income, consumption\n
11
0.0
1

INPUTBOX
630
760
699
820
size-scale
1.0
1
0
Number

TEXTBOX
10
10
160
32
RiskNetABM
18
0.0
1

TEXTBOX
635
740
685
765
display\n\n
12
0.0
1

TEXTBOX
15
115
165
133
network parameter
12
0.0
1

INPUTBOX
10
250
115
310
neighborhood-size
2.0
1
0
Number

CHOOSER
805
760
915
805
network-layout
network-layout
"spring" "circle"
1

SLIDER
320
385
505
418
donation-weighting
donation-weighting
0
1
0.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
10
345
160
363
household parameter
12
0.0
1

SLIDER
320
160
495
193
covariate-shock-prob-hh
covariate-shock-prob-hh
shock-prob
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
545
145
578
insurance-coverage
insurance-coverage
0
1
1.0
0.1
1
NIL
HORIZONTAL

CHOOSER
320
70
470
115
shock-type
shock-type
"idiosyncratic-shock" "covariate-shock"
1

SLIDER
475
70
615
103
shock-intensity
shock-intensity
0
1
0.6
0.1
1
NIL
HORIZONTAL

SWITCH
1080
770
1235
803
show-agent-budget?
show-agent-budget?
0
1
-1000

TEXTBOX
925
755
1075
773
link labels
11
0.0
1

TEXTBOX
1080
755
1230
773
agent labels\n
11
0.0
1

SWITCH
1080
805
1235
838
show-agent-number?
show-agent-number?
0
1
-1000

SLIDER
10
450
170
483
consumption-lvl
consumption-lvl
0
1
0.7
0.1
1
NIL
HORIZONTAL

CHOOSER
320
270
420
315
request-behavior
request-behavior
"none" "random"
1

CHOOSER
10
135
148
180
network-type
network-type
"none" "stylized"
1

TEXTBOX
10
35
160
53
simulation length
11
0.0
1

INPUTBOX
10
50
80
110
timesteps
100.0
1
0
Number

INPUTBOX
320
320
440
380
factor-donate-threshold
0.0
1
0
Number

SLIDER
120
250
292
283
rewire-prob
rewire-prob
0
1
0.0
0.1
1
NIL
HORIZONTAL

MONITOR
155
135
260
180
Mean path length
nw:mean-path-length
3
1
11

INPUTBOX
445
320
597
380
factor-request-threshold
0.0
1
0
Number

SLIDER
320
120
495
153
shock-prob
shock-prob
0
1
0.1
0.1
1
NIL
HORIZONTAL

PLOT
1360
45
1620
250
fraction surviving households
time
NIL
0.0
100.0
0.0
1.0
false
false
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plot fraction-active"
"insured" 1.0 0 -10899396 true "" "ifelse any? households with [ insured = 1 ] [ plot count households with [ active = 1 and insured = 1 ] / count households with [ insured = 1 ] ] [ plot 0 ]"
"uninsured" 1.0 0 -2674135 true "" "plot fraction-active-uninsured"

PLOT
1360
255
1875
515
 budget
time
mean budget
0.0
100.0
0.0
0.1
true
false
"" ""
PENS
"all" 1.0 0 -16777216 true "" "ifelse fraction-active != 0 [ plot total-budget / (number-households * fraction-active) ] [ plot 0 ]"
"insured" 1.0 0 -10899396 true "" "ifelse insurance-take-up-rate != 0 [ plot total-budget-insured / insured-households ] [ plot 0 ]"
"uninsured" 1.0 0 -2674135 true "" "ifelse (insurance-take-up-rate = 1 OR fraction-active-uninsured = 0) [ plot 0 ] [ plot total-budget-uninsured / ((number-households - insured-households) * fraction-active-uninsured) ]"
"expected value" 1.0 2 -7500403 true "" "plot (1 - consumption-lvl - shock-prob * shock-intensity) * ticks"

PLOT
1360
520
1875
785
transfer
NIL
transfer given per time step
0.0
100.0
0.0
0.1
true
false
"" ""
PENS
"active" 1.0 0 -16777216 true "" "plot sum [current-flow] of links"
"insured" 1.0 0 -10899396 true "" "let mylist []\nask households with [insured = 1] [ set mylist lput (sum [current-flow] of my-out-directed-edges) mylist]\nplot sum mylist"
"uninsured" 1.0 0 -2674135 true "" "let mylist []\nask households with [insured = 0] [ set mylist lput (sum [current-flow] of my-out-directed-edges) mylist]\nplot sum mylist"

PLOT
1625
45
1875
250
GINI
NIL
NIL
0.0
100.0
0.0
1.0
false
false
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plot get-gini"
"insured" 1.0 0 -10899396 true "" "plot get-gini-insured"
"uninsured" 1.0 0 -2674135 true "" "plot get-gini-uninsured"

TEXTBOX
1370
20
1520
38
all households\n
11
0.0
0

TEXTBOX
1455
20
1605
38
insured households
11
55.0
1

TEXTBOX
1565
20
1715
38
uninsured households
11
15.0
1

SWITCH
105
75
212
108
set-seed?
set-seed?
0
1
-1000

MONITOR
155
185
212
230
ratio
precision (-(income-lvl - consumption-lvl) / (income-lvl - consumption-lvl - shock-intensity)) 3
17
1
11

MONITOR
220
185
277
230
1/ratio
precision (-(income-lvl - consumption-lvl - shock-intensity) / (income-lvl - consumption-lvl)) 2
17
1
11

TEXTBOX
110
55
260
73
model seed
11
0.0
1

INPUTBOX
220
50
290
110
model-seed
261.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

The fight against poverty is an urgent global challenge. Microinsurance is promoted as a valuable instrument for buffering income losses due to health or climate-related risks of low-income households in developing countries. However, apart from direct positive effects they can have unintended side effects when insured households lower their contribution to traditional arrangements where risk is shared through private monetary support. 

*RiskNetABM* is an agent-based model that captures dynamics between **income losses**, **insurance payments** and **informal risk-sharing**. The model explicitly includes decisions about informal transfers. It can be used to assess the impact of insurance products and informal risk-sharing arrangements on the resilience of smallholders. Specifically, it allows to analyze whether and how **economic needs** (i.e. level of living costs) and **characteristics of extreme events** (i.e. frequency, intensity and type of shock) influence the ability of insurance and informal risk-sharing to buffer income shocks. **Two types of behavior** with regard to private monetary transfers are explicitly distinguished: (1) all households provide transfers whenever they can afford it and (2) insured households do not show solidarity with their uninsured peers.

The model is stylized and is not used to analyze a particular case study, but represents conditions from several regions with different risk contexts where informal risk-sharing networks between smallholder farmers are prevalent.

## HOW IT WORKS

### Yearly processes

There is a single type of agents representing smallholder households. Each household is linked to other households in an **undirected small-world network** (generated using the generate-watts-strogatz primitive in the NetLogo Nw Extension) with given number of neighbors and rewiring probability. Households are exposed to income shocks whose occurrence is determined stochastically.

Every **tick** is divided into two phases. In the first phase, households execute processes without interaction in the network. The processes run sequentially and in the following order: **regular earning, regular expenses, insurance premium payment, budget loss due to shocks, and insurance payout**. In the second phase, after all households have completed the first one, households are selected in random order to **execute transfer requests** if necessary. Budgets of households in need and households providing transfers are updated after each transfer according to the amount received and provided.

### Model parameters

Parameter: Standard value / range

- timesteps: 50
- number-households: 50
- neighborhood-size: 2, 4, 8
- rewire-prob: 0.2, 0.8
- income-lvl: 1
- budget-init: 0
- insurance-take-up-rate: 0, 0.3, 0.6
- insurance-coverage: 1
- consumption-lvl: 0.7–0.9
- shock-prop: 0.1–0.3
- covariate-shock-prob-vlg: covariate-shock-prob-vlg = shock-prob * covariate-shock-prob-hh
- covariate-shock-prob-hh: 0.8, 1
- shock-intensity: 0.2–1

### A detailed description of the model and its processes can be found in the ODD+D protocol.
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
NetLogo 6.1.1
@#$#@#$#@
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

dashed-curve
0.8
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

link-curve
0.8
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
