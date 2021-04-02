;; OfficeMoves v.1.0.0


;; Create Breeds

breed [ workers worker ]
breed [ shirkers shirker ]
breed [ posers poser ]


;; Create Global Variables

globals [

  %_posers
  %_happy
  %_happy_workers
  %_happy_shirkers
  %_happy_posers
  mean-perf
  mean-perf-workers
  mean-perf-shirkers
  mean-perf-posers
  mean-neighborhood-perf
  null-iqv

]


;; Create Agent Variables

patches-own [

  neighborhood-perf          ;; the total performance of the neighborhood for occupied patches
  neighborhood-perf-last     ;; the total performance of the neighborhood for the previous round
  neighborhood-perf-change   ;; equals neighborhood-perf minus neighborhood-perf-last
  p-neighborhood-perf        ;; the total performance of neighborhood, whether the patch is occupied or not
  nperf-list                 ;; this is a list of neighborhood-perf by round
  pperf-list                 ;; this is a list of the potential neighborhood performance by round
  pchange-list               ;; this is a list of neighborhood-perf-change by round

]

turtles-own [

  happy?                ;; does the turtle's situation meet its decision rule
  performance           ;; this is the turtle's peformance effect plus the performance effects of its two step neighborhood
  perf                  ;; This is the turtle's performance effect on its patch.
  neighborhood-workers  ;; The number of workers in the agent's two-step neighborhood.
  neighborhood-shirkers ;; The number of shirkers in the agent's two-step neighborhood.
  neighborhood-posers   ;; The number of posers in the agent's two-step neighborhood.
  vacant                ;; The number of vacant patches in the agent's two-step neighborhood.
  iqv                   ;; Index of Qualitative Variation.

]


;; Initialize the Simulation

to setup

  clear-all

  ;; Set number of poser and check distribution of personalities

  set %_posers ( 100 - ( %_workers + %_shirkers ) )

  ;; Stop if parameters are set incorrectly.

  if %_posers < 0 [ print "Distribution exceeds 100%."    ;; This is a safety to ensure that the distribution of personalities does not exceed 100%
    stop

  ]

  if ( window < 1 or max_move < 1 ) [ print "Window and max_move must be greater than zero."
    stop ]

  ;; create one agent per patch at the given population density

  ask patches [

    if random 100 < density [

      sprout 1 [

        set size 1

        set color yellow

        ;; Assign breeds
        let value (1 + random 100 )
        if value <= %_workers [ set breed workers ]
        if ( ( value >= %_workers + 1 ) and ( value <= ( %_workers + %_shirkers ) ) ) [ set breed shirkers ]
        if ( value >= ( %_workers + %_shirkers + 1) ) [ set breed posers ]

      ]

    ]

    set pcolor white

  ]

  ;; Assign shapes to indicate personality

  ask workers [ set shape "triangle" ]
  ask shirkers [ set shape "x" ]
  ask posers [ set shape "star" ]


  ;; Initialize variables

  ;; Set previous neighborhood performance to 0.
  ask patches [ set neighborhood-perf-last 0 ]

  ;; Set neighborhood perfomance lists
  ask patches [ set nperf-list (n-values window [ 0 ] )      ;; The simulation needs to begin with a list that is of sufficient
    set pchange-list ( n-values window [ 0 ] )               ;; length to calculate the moving averages for neighborhood performance,
    set pperf-list ( n-values window [ 0 ] )                 ;; potential neighborhood performance, and the change in neighborhood performance.
  ]


  ;; Set perf
  ask turtles [ if ( breed = workers ) [ set perf w_perf_eff ]
    if ( breed = shirkers ) [ set perf s_perf_eff ]
    if ( breed = posers ) [ set perf p_perf_eff ] ]



  ;; Calculate performance for turtles and patches
  calc-performance
  calc-neighborhood-performance
  calc-iqv
  update-perf-lists


  ;; Set patch color by  performance or change in performance
  if visualization = "by performance" [ color-patches ]
  if visualization = "by change in performance" [ color-patches-by-change ]


  ;; Set agent happiness
  ask turtles [ set happy? one-of [ true false ] ]     ;; Sensitivity tests showed that the model is not sensitive to the
                                                       ;; distribution of happiness at the start of a run.

  ask turtles [ ifelse happy? [ set color yellow ]     ;; Set color by happiness: yellow (true), grey (false).
    [ set color grey ] ]

  ;; Update global variables
    update-globals


  ;; Calculate Global Index of Qualitative Variation (IQV)

  ;; The purpose of the global IQV is to determine how much the neighborhood IQVs depart from the global during the
  ;; course of the simulation.

  set null-iqv ( 1 - ( ( 1 - ( 0.01 * density ) ) ^ 2 + ( 0.01 * %_workers * 0.01 * density ) ^ 2 + ( 0.01 * %_shirkers * 0.01 * density ) ^ 2 +
    ( 0.01 * %_posers * 0.01 * density ) ^ 2 ) ) / 0.75

  reset-ticks

end


;; Simulation Run


to go

  ;; Move unhappy turtles. All unhappy turtles move during a round of the simulation in a random order.
  ask turtles with [ not happy? ] [ move-turtle ]


  ;; Update performance statistics
  calc-performance
  calc-neighborhood-performance
  calc-iqv
  update-perf-lists


  ;; Update agent happiness
  if decision_rule = "by change" [ update-happiness ]
  if decision_rule = "by performance" [ update-happiness-II ]
  if decision_rule = "change window" [ update-happiness-III ]
  if decision_rule = "performance window" [ update-happiness-IV ]

  ;; Set agent color by happiness
  ask turtles [ ifelse happy? [ set color yellow ]
    [ set color grey ] ]


  ;; Update patch visualization
  if visualization = "by performance" [ color-patches ]
  if visualization = "by change in performance" [ color-patches-by-change ]


  ;; Update global statistics
  update-globals


  ;; Stop run if all the turtles are happy.
  if all? turtles [ happy? ] [ stop ]


  ;; Stop run if the run_termination is num_rounds and ticks equal the max_rounds.
  if ( ticks = max_rounds ) and ( run_termination = "num_rounds" ) [ stop ]

  tick

end


;; Supporting Procedures

to move-turtle

  left random-float 360
  forward random-float max_move
  if any? other turtles-here [ move-turtle ]     ;; If the patch is occupied, the agent keeps moving
  move-to patch-here                             ;; If the patch is unoccupied, the agent moves to the center of the patch

end


to calc-performance

  ;; This procedure calculates the performance total for each agent.
  ;; Total agent performance equals the sum of the agent's performance effect, its one-step neighbors perf_eff1, and its two-step negihbors perf_eff2.


  ;; Sum the performance effects
  ;; The radii of 1.9 and 2.9 are used to ensure that the corners are included.
  ask turtles [ set performance ( ( count neighbors with [ any? workers-here ] * w_perf_eff1 ) +
    ( count neighbors with [ any? shirkers-here ] * s_perf_eff1 ) +
    ( count neighbors with [ any? posers-here ] * p_perf_eff1 ) ) +                                ;; Sums the performance effects in the one-step neighborhood
    ( ( ( count workers in-radius 2.9 ) - ( count workers in-radius 1.9 ) ) * w_perf_eff2 ) +
    ( ( ( count shirkers in-radius 2.9 ) - ( count shirkers in-radius 1.9 ) ) * s_perf_eff2 ) +
    ( ( ( count posers in-radius 2.9 ) - ( count posers in-radius 1.9 ) ) * p_perf_eff2 ) +        ;; Sums the performance effects in the two-step neighborhood
    perf
  ]


end

to calc-neighborhood-performance

  ;; This procedure calculates the neighbor performance for each patch. Neighborhood performance equals the sum of the agents' performance in the two step
  ;; neighborhood. This procedure should only be used after calc-performance.


  ;; Set neighborhood-perf-last to neighborhood-perf. This is necessary to measure change in neighborhood performance.
  ask patches [ set neighborhood-perf-last neighborhood-perf ]
  ask patches [ set neighborhood-perf 0 ]      ;; This resets the performance of the patch to zero. Without this previous rounds carry over.


  ;; Sum the performance in the patches' two-step neighborhood.
  ask patches with [ any? turtles-here ] [ set neighborhood-perf ( sum [ performance ] of turtles in-radius 2.9 ) ]  ;; This is actual performance.
  ask patches [ set p-neighborhood-perf ( sum [ performance ] of turtles in-radius 2.9 ) ]                           ;; This is potential performance.


  ;; Calculate change in performance
  ask patches [ set neighborhood-perf-change ( neighborhood-perf - neighborhood-perf-last ) ]


end

to calc-iqv

  ;; Index of Qualitative Variation (IQV). This is a measure of the heterogeneity of the agent's two step neighborhood.
  ;; At 0, the neighborhood consists of a single breed of agent - vacant, worker, shirker, or poser.
  ;; At 1, the neighbors are evenly spread across vacant and all three breeds.

  ask turtles [

    set neighborhood-workers ( ( count workers in-radius 2.9 ) - ( count workers in-radius 0.9 ) )
    set neighborhood-shirkers ( ( count shirkers in-radius 2.9 ) - ( count shirkers in-radius 0.9 ) )
    set neighborhood-posers ( ( count posers in-radius 2.9 ) - ( count posers in-radius 0.9 ) )
    set vacant ( ( 24 - neighborhood-workers - neighborhood-shirkers - neighborhood-posers ) )

    set iqv ( ( 1 - ( ( ( neighborhood-workers / 24 ) ^ 2 ) + ( ( neighborhood-shirkers / 24 ) ^ 2 ) +
      ( ( neighborhood-posers / 24 ) ^ 2 ) + ( ( vacant / 24 ) ^ 2 ) ) ) / 0.75 )

  ]


end


to update-perf-lists

  ask patches [

    ;; Append the current neighborhood performance to nperf-list
    set nperf-list lput neighborhood-perf nperf-list
    set nperf-list ( sublist nperf-list  (length nperf-list - window ) ( length nperf-list ) )  ;; Trims the list to the length window.

    ;; Append the current potential neighborhood performance to pperf-list
    set pperf-list lput p-neighborhood-perf pperf-list
    set pperf-list ( sublist pperf-list ( length pperf-list - window ) ( length pperf-list ) )  ;; Trims the list to the length window.


    ;; Append the current change in neighborhood performance to pchange-list
    set pchange-list lput neighborhood-perf-change pchange-list
    set pchange-list ( sublist pchange-list ( length pchange-list - window ) ( length pchange-list ) )  ;; Trims the list to the length window.

  ]

end



to-report flatten-list [ xs ]

  ;; This reduces a list of lists to a list. It is used in the update-happiness-III and IV procedures to calculate the mean of the vacant patches
  ;; neighborhood performance.

  let ys reduce sentence xs
  report ifelse-value (reduce or map is-list? ys) [ flatten-list ys ] [ ys ]

end


to update-color

  ;; Set agent color by happiness
  ask turtles [ ifelse happy? [ set color yellow ]
    [ set color grey ] ]

end



to update-happiness

  ;; Set happy? to true for all turtles. This avoid multiple lines of code or ifelse statements, and it ensures that no previous values are carried forward.
  ask turtles [ set happy? true ]

  ;; Workers leave their patch when the performance change drops below zero.
  ask workers with [ [ neighborhood-perf-change ] of patch-here < 0 ] [ set happy? false ]

  ;; Shirkers leave their patch when the performance change is greater than zero.
  ask shirkers with [ [ neighborhood-perf-change ] of patch-here > 0 ] [ set happy? false ]

  ;; Posers leave their patch when a vacant patch has higher performance.
  ask posers with [ ( [ neighborhood-perf ] of patch-here ) < ( mean [ p-neighborhood-perf ] of patches with [ count turtles-here = 0 ] ) ] [ set happy? false ]

end


to update-happiness-II

  ;; Set happiness based on performance instead of change in performance.

  ;; Set happy? to true for all turtles. This avoid multiple lines of code or ifelse statements, and it ensures that no previous values are carried forward.
  ask turtles [ set happy? true ]

  ;; Workers leaves their patch when performance is below the median.
  ask workers with [ [ neighborhood-perf ] of patch-here > mean [ neighborhood-perf ] of patches with [ count turtles-here > 0 ] ] [ set happy? false ]

  ;; Shirkers leave their patch when their patch performance is above the median.
  ask shirkers with [ [ neighborhood-perf ] of patch-here < mean [ neighborhood-perf ] of patches with [ count turtles-here > 0 ] ] [ set happy? false ]

  ;; Posers leave their patch when a vacant patch has higher performance.
  ask posers with [ ( [ neighborhood-perf ] of patch-here ) < ( mean [ p-neighborhood-perf ] of patches with [ count turtles-here = 0 ] ) ] [ set happy? false ]

end


to update-happiness-III

  ;; Set happiness using a moving average of window length on the change in neighborhood performance.

  ;; Set happy? to true for all turtles. This avoid multiple lines of code or ifelse statements, and it ensures that no previous values are carried forward.
  ask turtles [ set happy? true ]

  ;; Workers leave their patch when the performance change drops below zero.
  ask workers with [ mean [ pchange-list ] of patch-here < 0 ] [ set happy? false ]

  ;; Shirkers leave their patch when the performance change is greater than zero.
  ask shirkers with [ mean [ pchange-list ] of patch-here > 0 ] [ set happy? false ]

  ;; Posers leave their patch when a vacant patch has higher performance.
  let pperf ( [ pperf-list ] of patches with [ count turtles-here = 0 ] )
  ask posers with [ ( mean [ nperf-list ] of patch-here ) < ( mean ( flatten-list ( pperf ) ) ) ] [ set happy? false ]

end


to update-happiness-IV

  ;; Set happiness using a moving average of window length on neighborhood performance.

    ;; Set happy? to true for all turtles. This avoid multiple lines of code or ifelse statements, and it ensures that no previous values are carried forward.
  ask turtles [ set happy? true ]

  ;; Workers leave their patch when the performance change drops below zero.
  ask workers with [ mean [ nperf-list ] of patch-here < 0 ] [ set happy? false ]

  ;; Shirkers leave their patch when the performance change is greater than zero.
  ask shirkers with [ mean [ nperf-list ] of patch-here > 0 ] [ set happy? false ]

  ;; Posers leave their patch when a vacant patch has higher performance.
  let pperf ( [ pperf-list ] of patches with [ count turtles-here = 0 ] )
  ask posers with [ ( mean [ nperf-list ] of patch-here ) < ( mean ( flatten-list ( pperf ) ) ) ] [ set happy? false ]

end


to color-patches

  ;; Set the patches' color by the neighborhood-perf patch variable

  ask patches [ if neighborhood-perf = 0 [ set pcolor white ] ]
  ask patches [ if neighborhood-perf > 0 [ set pcolor scale-color green neighborhood-perf ( ( max [ neighborhood-perf ] of patches ) +
    ( 0.1 * ( max [ neighborhood-perf ] of patches ) ) ) 1 ] ]
  ask patches [ if neighborhood-perf < 0 [ set pcolor scale-color red neighborhood-perf ( ( min [ neighborhood-perf ] of patches ) +
    ( 0.1 * ( min [ neighborhood-perf ] of patches ) ) ) -1 ] ]


end

to color-patches-by-change

  ;; Set the patches' color by the neighborhood-perf-change patch variable

  ask patches [ if neighborhood-perf-change = 0 [ set pcolor white ] ]
  ask patches [ if neighborhood-perf-change > 0 [ set pcolor scale-color green neighborhood-perf-change ( ( max [ neighborhood-perf-change ] of patches ) +
    ( 0.1 * ( max [ neighborhood-perf-change ] of patches ) ) ) 1 ] ]
  ask patches [ if neighborhood-perf-change < 0 [ set pcolor scale-color red neighborhood-perf-change ( ( min [ neighborhood-perf-change ] of patches ) +
    ( 0.1 * ( min [ neighborhood-perf-change ] of patches ) ) ) -1 ] ]

end



to update-globals

  ;; Percent of happy agents

  set %_happy ( ( ( count turtles with [ happy? = true ] ) / count turtles ) * 100 )
  if ( count workers > 0 ) [ set %_happy_workers ( ( ( count workers with [ happy? = true ] ) / count workers ) * 100 ) ]
  if ( count shirkers > 0 ) [ set %_happy_shirkers ( ( ( count shirkers with [ happy? = true ] ) / count shirkers ) * 100 ) ]
  if ( count posers > 0 ) [ set %_happy_posers ( ( ( count posers with [ happy? = true ] ) / count posers ) * 100 ) ]

  ;; Mean neighborhood performance

  set mean-perf ( mean [ neighborhood-perf ] of patches with [ count turtles-here > 0 ] )
  if ( count workers > 0 ) [ set mean-perf-workers ( mean [ neighborhood-perf ] of patches with [ any? workers-here ] ) ]
  if ( count shirkers > 0 ) [ set mean-perf-shirkers ( mean [ neighborhood-perf ] of patches with [ any? shirkers-here ] ) ]
  if ( count posers > 0 ) [ set mean-perf-posers ( mean [ neighborhood-perf ] of patches with [ any? posers-here ] ) ]


end
@#$#@#$#@
GRAPHICS-WINDOW
445
10
882
448
-1
-1
13.0
1
10
1
1
1
0
1
1
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

SLIDER
5
45
150
78
density
density
1
99
50.0
1
1
NIL
HORIZONTAL

BUTTON
80
490
150
523
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
5
490
75
523
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

CHOOSER
5
275
150
320
run_termination
run_termination
"default" "num_rounds"
1

MONITOR
560
465
620
510
All
count turtles
0
1
11

MONITOR
625
465
685
510
Workers
count workers
17
1
11

MONITOR
690
465
750
510
Shirkers
count shirkers
17
1
11

MONITOR
755
465
815
510
Posers
count posers
17
1
11

INPUTBOX
175
45
245
105
w_perf_eff
2.0
1
0
Number

INPUTBOX
175
110
245
170
w_perf_eff1
1.0
1
0
Number

INPUTBOX
175
175
245
235
w_perf_eff2
1.0
1
0
Number

TEXTBOX
190
30
262
71
Worker
11
0.0
1

INPUTBOX
250
45
320
105
s_perf_eff
1.0
1
0
Number

INPUTBOX
250
110
320
170
s_perf_eff1
-1.0
1
0
Number

INPUTBOX
250
175
320
235
s_perf_eff2
0.0
1
0
Number

INPUTBOX
325
45
390
105
p_perf_eff
2.0
1
0
Number

INPUTBOX
325
110
390
170
p_perf_eff1
-1.0
1
0
Number

INPUTBOX
325
175
390
235
p_perf_eff2
-1.0
1
0
Number

TEXTBOX
265
30
342
66
Shirker
11
0.0
1

TEXTBOX
340
30
415
71
Poser
11
0.0
1

INPUTBOX
80
325
150
385
max_move
10.0
1
0
Number

BUTTON
80
525
150
558
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

INPUTBOX
5
325
75
385
max_rounds
1000.0
1
0
Number

INPUTBOX
5
80
75
140
%_workers
30.0
1
0
Number

INPUTBOX
80
80
150
140
%_shirkers
20.0
1
0
Number

MONITOR
40
145
110
190
NIL
%_posers
17
1
11

PLOT
890
10
1220
160
Percent Happy
Time
Percent Happy
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plot %_happy"
"workers" 1.0 0 -13791810 true "" "if count workers > 0 [ plot %_happy_workers ]"
"shirkers" 1.0 0 -1184463 true "" "if count shirkers > 0 [ plot %_happy_shirkers ]"
"posers" 1.0 0 -955883 true "" "if count posers > 0 [ plot %_happy_posers ]"

CHOOSER
5
390
150
435
visualization
visualization
"by performance" "by change in performance"
0

PLOT
890
165
1220
315
Histogram of Neighborhood Performance
Performance
NIL
0.0
10.0
0.0
10.0
true
false
"" "set-plot-x-range ( min [ neighborhood-perf ] of patches ) ( max [ neighborhood-perf ] of patches )"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ neighborhood-perf ] of patches with [ any? turtles-here ]"

CHOOSER
175
275
320
320
decision_rule
decision_rule
"change window" "performance window" "by change" "by performance"
3

MONITOR
560
515
620
560
All
%_happy
2
1
11

MONITOR
625
515
685
560
Workers
%_happy_workers
2
1
11

PLOT
890
320
1220
470
Mean Neighborhood Performance
Time
Performance
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plot mean-perf"
"workers" 1.0 0 -13791810 true "" "if count workers > 0 [ plot mean-perf-workers ]"
"shirkers" 1.0 0 -1184463 true "" "if count shirkers > 0 [ plot mean-perf-shirkers ]"
"posers" 1.0 0 -2674135 true "" "if count posers > 0 [ plot mean-perf-posers ]"

MONITOR
690
515
750
560
Shirkers
%_happy_shirkers
2
1
11

MONITOR
755
515
815
560
Posers
%_happy_posers
2
1
11

TEXTBOX
480
470
560
496
Population by\nPersonality
11
0.0
1

TEXTBOX
475
530
560
548
Percent Happy
11
0.0
1

PLOT
175
360
395
510
Histogram of Variation
Neighborhood IQV
NIL
0.0
1.0
0.0
10.0
true
false
"set-plot-pen-interval 0.01" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ iqv ] of turtles"

TEXTBOX
210
10
360
28
Agent Performance Effects
11
0.0
1

MONITOR
300
515
395
560
Expected IQV
null-iqv
2
1
11

BUTTON
5
525
75
558
clear
ca
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
325
275
395
335
window
5.0
1
0
Number

TEXTBOX
15
25
145
43
Population Composition
11
0.0
1

TEXTBOX
15
255
145
273
Simulation Parameters
11
0.0
1

TEXTBOX
245
255
325
273
Decision Rules
11
0.0
1

TEXTBOX
220
340
370
358
Neighborhood Variation
11
0.0
1

@#$#@#$#@
# OfficeMoves: Personalities and Performance in an Interdependent Environment (v.1.0.0, May 9th, 2020)

## WHAT IS IT?

After a little work experience, we realize that different kinds of people prefer different work environments: some enjoy a fast-paced challenge; some want to get by; and, others want to show off.

From that experience, we also realize that different kinds of people affect their work environments differently: some increase the pace; some slow it down; and, others make it about themselves.

This model concerns how three different kinds of people affect their work environment and how that work environment affects them in return. The model explores how this circular relation between people's preferences and their environment creates patterns of  association and performance over time.

The purpose of this model is to study the interaction of different agent strategies and their effects on the performance environment. By doing so, the model helps the user build theories about homophily, office place norms, and organizational patterns.

## HOW IT WORKS

The model provides researchers with a mean to study homophily and office place norms by changing the simulation's parameters, especially the distribution of the types of people in the population. The model achieves this by using three personalities, which are defined by their preferences for performance in their two-step neighborhoods and how they affect performance in their two-step neighborhoods. The effects of the interactions between the personalities and their environment are measured by agent happiness and neighborhood performance.

The model takes inspiration from Schelling’s segregation model: the agents move around the simulation space to find local regions that suit their individual preferences. This model departs from the segregation model in three ways. First, the different types of agents have different decision rules that rest on different ways of perceiving their environment: the level of current performance and the rate of change in performance. Second, the different kinds of agents have different effects on neighborhood performance. Third, performance effects have spillover: those effects go beyond the adjacent spaces.

Before describing the simulation environment and the agents in detail, two key terms need description: performance and two-step neighborhood.

_Performance_. The work environment is defined in terms of performance, which is an abstraction that captures the results of the agents' activities. People affect the performance of their local neighborhood and the performance in the local neighborhood affects each individual’s choice to stay or move. For the sake of simplicity, performance has universal meaning.

_Two-Step Neighborhood_. The neighborhood of an agent (or turtle) and a space (or patch) is defined as the agents or spaces within two steps of the specified agent or space. For example, the two-step neighborhood comprises a patch, the patches adjacent to it, and the patches adjacent to those. Thus, the neighborhood comprises 25 patches: the one in the center, its eight neighbors, and the sixteen neighbors next to those eight. In short, the neighborhood comprises the patches within two steps of its center.

### Simulation Environment

The default world comprises 1089 patches on a toroid. The grid displayed in the interface is 33 by 33 patches with vertical and horizontal wrapping enabled. The simulation environment has the following variables:

* _Population Density_. This is the percentage of the patches occupied by agents and can vary from 1% to 99%, as set by the user.
* _Population Distribution_. Three kinds of agents constitute the population: workers, shirkers, and posers. The user sets the percentage of the population for the workers and shirkers. The percentage of posers is calculated by the setup procedure.
* _Run Termination_. If all the agents are happy, the run will terminate. The user may also choose "num_rounds" which will terminate the run when the number of rounds selected by the user is reached.
* _Maximum Rounds_. If the user set run termination to "num_rounds," the run terminates after reaching this number of rounds.
* _Maximum Move_. This is the furthest distance that an unhappy turtle will travel in a single move.

### Performance Spaces

The segments of the performance space (patches) represent jobs or positions in the organization. Each patch may only have one occupant. Each patch has one state variable.

* _Neighborhood Performance_. This is the sum of the performance of all the agents within the patch's two-step neighborhood and the agent occupying the patch. If no agent occupies the patch, its neighborhood performance is zero.

Potential performance is used to measure the neighborhood performance on unoccupied patches. Potential performance is used for the poser's decision rule.

### Agents in the Performance Space

The agents (turtles) in the performance space have four state variables:

* _Happiness_. The agent is happy if the neighborhood performance of the patch occupied by the agent meets its decision rule. Otherwise, the agent is unhappy.
* _Performance Effects_. This indicates the amount of performance that each agent adds to its own patch, the patches in its first-step neighborhood, and the patches in its second-step neighborhood. The default settings for each personality follow from the plain language description of the personalities given above. For the purposes of investigation, the user is allowed to change the default settings but should do so for sound theoretical reasons.
* _Performance_. This is the sum of the agent's performance effects and the performance effects of all the agents in the selected agent's two-step neighborhood.
* _Index of Qualitative Variation_. This measures the degree of heterogeneity in the agent's two-step neighborhood. At zero, the two-step neighborhood comprises personalities of a single type. At one, the two-step neighborhood is evenly distributed across the different personality types represented in that neighborhood.

Each agent is assigned one of three personalities: worker, shirker, or poser. The user sets the distribution of personalities in the population. Each personality has performance effects on its two-step neighborhood and preferences regarding neighborhood performance that determine the agent's happiness. The decision rules follow from the agents' performance preferences. For a detailed discussion of the decision rules, see the discussion under "How to Use It" below.

#### Worker

The worker thrives in a challenging environment and its motivation is infectious.

_Performance Effects_. The worker adds performance to the environment and adds to the performance of its neighbors. Worker's positive performance effects decrease over distance in the two-step neighborhood.

_Performance Preferences_. The worker likes challenge, which is defined in terms of the rate of change in neighborhood performance. The worker will move to another job when the rate of change in performance is negative. This is a repulsion mechanism that uses local knowledge.

#### Shirker

The shirker puts in the minimum effort and thereby places burdens on its neighbors.

_Performance Effects_. The shirker adds the minimum necessary performance to its space but costs performance in its two-step neighborhood, as the shirker puts burdens on the people around it. Its direct effects lack the reach of the worker or the poser.

_Performance Preferences_. The shirker likes minimum effort, which is defined by the rate of change in performance. The shirker will move to another job is the rate of change in performance is positive. This is a repulsion mechanism that uses local knowledge. 

#### Poser

The poser likes to be in the spotlight and adds to the performance environment. By making the organization all about itself, the poser places performance burdens on the members of its two-step neighborhood

_Performance Effects_. Poser adds performance to its space but costs performance in its two-step neighborhood by making the environment all about itself. The cost decreases over distance.

_Performance Preferences_. Poser will move when better options are available. If its neighborhood performance is less than the mean of the performance of the vacant patches, poser will move. This is an attraction mechanism that uses global knowledge.

### Simulation Sequence

#### Set Simulation Parameters

* _Set Population Composition_. These include population density, the percentage of workers, and the percentage of shirkers.
* _Set Simulation Parameters_. These include run termination conditions, the maximum rounds for a run, the distance of the maximum move for unhappy agents, and the visualization of the world.
* _Set Agent Performance Effects_. For each personality - worker, shirker, and poser - set the performance effect of the agent, its one-step neighbors, and its two-step neighbors.
* _Set Decision Rules_. Choose one of the four decision rule sets and set the length of the window for the decision rules that use a moving average.

#### Initialize Simulation
* Creates the number of turtles using the population density. Turtles are assigned randomly and no more than one per patch.
* Assigns a breed - worker, shirker, or poser - to each agent randomly using the population composition.
* Sets the attributes for visualization of the run and initializes variables.
* Randomly sets the agents' happiness.

#### Simulation Run
* Unhappy turtles move in a random direction for a distance from zero to the maximum move. Unhappy turtles repeat this until they land on an empty patch.
* Update performance statistics.
* Update turtles' happiness by applying the selected set of decision rules.
* Update visualization and statistics.
* Stop simulation if all the turtles are happy or if the maximum rounds are met.

#### Comment: Initial Agent Happiness
The code sets each agent's happiness randomly giving each agent an equal chance of being happy or unhappy. Since happiness is determined, for some agents, by the change in neighborhood performance, happiness cannot be set for the first round of a run.

Sensitivity tests showed that very high and very low percentages of unhappy agents at the beginning of a simulation run had no effect on the simulation after the first round. Thus, the 50/50 random assignment was used.

## HOW TO USE IT

### Overview

This model supports theory building concerning homophily and workplace norms. It accomplishes this through the interaction of three different personalities - defined by the performance effects and performance preferences - in a finite space and over time. The fundamental parameters for these thought experiments are the population density, the distribution of personalities, and the decision rules.

The population density and distribution of personalities should be straight forward. The decision rules require some explanation. There are four sets of decision rules. The primary set follows from the abstract personality descriptions above and it is the set intended for theory building. The set uses a moving average of the change in neighborhood performance or neighborhood performance. The length of the moving average's window is set by the user. This allows the user to explore the differences between the effects of short-term change and long-term change. Using the moving average, agent happiness is determined as follows.

* The worker is unhappy if the rate of change in its neighborhood's performance is negative.
* The shirker is unhappy if the rate of change in its neighborhood's performance is positive.
* The poser is unhappy if its neighborhood performance is less than the mean of the potential neighborhood performance of the vacant patches.

The second set of decision rules uses performance instead of the rate of change in performance for the worker and shirker decision rules. Our theoretical understanding of the personalities suggests the first rule. This second rule is used to examine the differences between populations that respond to rates of change in performance and those that respond to the level of performance itself.

The third and fourth decision rules are identical to the first and second, respectively. However, the third and fourth rules do not use moving averages. They speed up the simulation and remain for convenience.

Once the population density, the distribution of personalities, and the decision rule set are selected, click on the setup button and then the go button located in the bottom left of the user interface.

### User Interface - In Detail

The user interface allows the user to set the initial parameters, run the simulation and observe the results. Ensure that view updates is set to "on ticks" to observe the simulation. If it is set to "continuous," the visualization becomes misleading.

The description of the interface that follows starts in the top left of the interface and describes it from top to bottom and left to right.

#### Population Composition

_density_ (varies from 1 to 99)
This sets the number of agents as a percent of the total possible number of agents, which is determined by the size of the world.

_% workers_ (varies from 0 to 100)
This is the percentage of the population that will be workers.

_% shirkers_ (varies from 0 to 100)
This is the percentage of the population that will be shirkers.

_% posers_
This is the percentage of poser in the population. The setup procedure calculates the percentage of posers using the % workers and % shirkers set by the user.

#### Simulation Parameters

_run termination_ (default, num_rounds)
This tells Netlogo when to stop a run of the simulation: "default" means that the run will stop if all of the agents are happy; "num_rounds" means that the run will terminate when is reaches the max_rounds determined by the user or if all the agents are happy.

_max move_
Each time an agent moves, it will move a random distance from zero to the maximum distance allows, or max_move.

_max rounds_
This determines the maximum length of a run of the simulation. If run_termination is set to num_rounds, the run ends when the number of ticks equals max_rounds.

_visualization_ (by performance, by change in performance)
Patch color indicates the neighborhood performance or the change in neighborhood performance by round depending on the user's selection. Green indicates positive values. Red indicates negative values.

#### Agent Performance Effects

Each breed - worker, shirker, and poser - has a performance effect on their environment. The prefixes "w_", "s_", and "p_" indicate which breed has the performance effect.

_perf eff._
This is the amount of performance the agent adds to its patch.

_perf eff1._
This is the amount of performance the agent adds to the patches in its one-step neighborhood.

_perf eff2._
This is the amount of performance the agent adds to the patches in its two-step neighborhood.

As with the decision rules, the agents' performance effects follow from the abstract understanding of the personalities. The worker adds performance and inspires others yielding performance effects equal to (2,1,1). The shirker puts in minimum effort leaving others to fill in yielding performance effects equal to (1,-1,0). The poser adds to performance while leeching its neighborhood yielding performance effects equal to (2,-1,-1). The simulation allows the user to change the performance effects of the different personalities. However, it is recommended that the user do so only for sound theoretical reasons.

#### Decision Rules

Each rule set determines whether an agent is happy in its neighborhood during each round of the simulation. The primary decision rule, change window, follows from the definitions of the personalities above. The secondary decision rule, performance window, uses performance instead of the change in performance. This rule gives the researcher a way to compare processes and results to aid theory building. The third and fourth rules sets are simplifications of the first two and execute quickly. 

_change window_ (primary decision rule set)

* A worker is unhappy if the moving average of change in neighborhood performance over the length of the window is less than zero.
* A shirker is unhappy if the moving average of the change in neighborhood performance over the length of the window is greater than zero.
* A poser is unhappy if the neighborhood performance averaged over the length of the window is less than the moving average of the neighborhood performance of unoccupied patches over the length of the window.

_performance window_

* A worker is unhappy if the moving average of neighborhood performance over the length of the window is less than zero.
* A shirker is unhappy if the moving average of neighborhood performance over the length of the window is greater than zero.
* A poser is unhappy if the neighborhood performance averaged over the length of the window is less than the moving average of the neighborhood performance of unoccupied patches over the length of the window.

_by change_
This decision rule set is the same as change window, except a moving average is not used. Only the current values are used. This decision rule is less demanding computationally.

_by performance_
This decision rule set is the same as performance window, except a moving average is not used. Only the current values are used. This decision rule is less demanding computationally.

_window_
This is the length of the moving average window used by the change window and performance window decision rules.

#### Neighborhood Variation

_Histogram of Neighborhood Variation_
Neighborhood variation is the index of qualitative variation (IQV) calculated for each agent using its two-step neighborhood. IQV is a measure of the heterogeneity of the agent's two-step neighborhood. At 0, the neighborhood consists of a single category of neighbor - vacant, worker, shirker, or poser. At 1, the neighbors are evenly spread across the four categories.

_Expected IQV_
The expected IQV (eIQV) is the value of the IQV calculated using the population density and the distribution of personalities selected by the user. The purpose of the eIQV is to determine to what degree the neighborhoods depart from randomness.

#### Interface Tab - World
The world depicts the personality of the agent which occupies a patch, whether the agent is happy, and either the patch's neighborhood performance or the change in neighborhood performance.

_Agent Shape_

* _Triangle._  Worker
* _X._         Shirker
* _Star._      Poser

_Agent Color_

*_Yellow._    Happy
*_Grey._      Unhappy

_Patch Color_

* _White._     Vacant patch or zero performance
* _Green._     Shaded by positive performance, white (zero) to dark green (max)
* _Red._       Shaded by negative performance, white (zero) to dark red (min)

_Population by Personality_
These give the actual number of agents by breed: all, workers, shirkers, and posers.

_Percent Happy_
These give the percentage of the agents that are happy in the current round of the simulation.

#### Monitors

_Percent Happy_
The plot shows the change in the percent happy by breed over time. The monitors below the plot give the percent happy by breed for the current round of the simulation.

When using the change window and performance window decision rules, the percent of workers and the percent of shirkers who are happy should be ignored until the round after the length of the window.

_Histogram of Neighborhood Performance_
This displays the frequency of neighborhood performance by patch by round of the simulation.

_Mean Neighborhood Performance_
This shows the mean neighborhood performance for all patches and by the breed occupying the patch.

The user should exercise caution interpreting this plot. The default agent performance effects, for example, make the workers the most productive. The relative fluctuations are of more interest than the relative levels.

## THINGS TO NOTICE

### Agent Behavior

Under the change window decision rule, workers and shirkers quickly reach 100% happiness if one or the other constitutes the entire population and a moving average with a window of greater than or equal to two is used. In contrast, a population composed of posers alone will not reach a state of complete happiness. Posers are naturally disruptive.

Under the by change decision rule, neither workers nor shirkers reach 100% happiness quickly, implying that looking to the short-term is naturally disruptive.

### Interpreting Population Happiness

If the change window or performance window decision rule is used, the statistic used by the decision rule begins a run with a vector of zeros with a length of the user defined window. Therefore, the measure of population happiness should not be interpreted until after the number of rounds (ticks) is greater than the moving average window.

### Interpreting Mean Neighborhood Performance

The default settings for the agents' performance effects result in a mean neighborhood performance for workers that is always higher than the mean neighborhood performance for either shirker or poser. The user should not attribute too much meaning to this. Instead the user should compare the fluctuations over time between the types of agents, neighborhood performance compared to happiness, etc.

## THINGS TO TRY

The purpose of this model is to study the interactions of different agent strategies with each other by way of their effects on the agents' performance environment. For the purposes of theory building, the user is encouraged to experiment with different values of the following parameters: population density, distribution of personalities, the window length, and the decision rule set.

## NETLOGO FEATURES

Ensure that "view updates" is set to "on ticks." When set to "continuous," the visualization becomes misleading.

## RELATED MODELS

Feliciani, T., Flache, A., & Tolsma, J. (2016). _Segregation and Opinion Polarization_ (Version 1.0.0) [Computer software]. CoMSES Computational Model Library. https://www.comses.net/codebases/4979/releases/1.0.0/

Secchi, D. (2019). _The PARSO_demo Model_. CoMSES Computational Model Library. https://www.comses.net/codebases/d42216d3-f95e-49aa-a4b4-1044f30fdeca/releases/1.3.0/

Stoica, V., & Flache, A. (2013). _From Schelling to Schools_ (Version 1.0.0) [Computer software]. CoMSES Computational Model Library. https://www.comses.net/codebases/3842/releases/1.0.0/

Wilensky, U. (1997). _NetLogo Segregation Model_. Center for Connected Learning and Computer-Based Modeling, Northwestern University. http://ccl.northwestern.edu/netlogo/models/Segregation

Yavas, M., & Yucel, G. (2015). _Homophily-driven Network Evolution and Diffusion_ (Version 1.0.0) [Computer software]. CoMSES Computational Model Library. https://www.comses.net/codebases/4475/releases/1.0.0/

## CREDITS AND REFERENCES

This agent-based model was built in Netlogo 6.1.1.

Wilensky, U. (1999). _NetLogo_. Center for Connected Learning and Computer-Based Modeling, Northwestern University. http://ccl.northwestern.edu/netlogo/

### Credits

I would like to thank Adam Jonas for reviewing and providing comments on this model. An earlier version was submitted to the Sante Fe Institute's class on agent-based modeling. I would like to thank the four anonymous reviewers for their comments.

### Select Bibliography

Bretz, R. D., Boudreau, J. W., & Judge, T. A. (1994). Job Search Behavior of Employed Managers. _Personnel Psychology_, 47(2), 275–301.

Cable, D. M., & Judge, T. A. (1994). Pay Preferences and Job Search Decisions: A Person-Organization Fit Perspective. _Personnel Psychology_, 47(2), 317–348.

De Cooman, R., Mol, S. T., Billsberry, J., Boon, C., & Den Hartog, D. N. (2019). Epilogue: Frontiers in person–environment fit research. _European Journal of Work and Organizational Psychology_, 28(5), 646–652.

Doblhofer, D. S., Hauser, A., Kuonath, A., Haas, K., Agthe, M., & Frey, D. (2019). Make the best out of the bad: Coping with value incongruence through displaying facades of conformity, positive reframing, and self-disclosure. _European Journal of Work and Organizational Psychology_, 28(5), 572–593

Follmer, E. H. (2019). Prologue: Considering how fit changes. _European Journal of Work and Organizational Psychology_, 28(5), 567–571. 

Follmer, E. H., Talbot, D. L., Kristof-Brown, A. L., Astrove, S. L., & Billsberry, J. (2018). Resolution, Relief, and Resignation: A Qualitative Study of Responses to Misfit at Work. _Academy of Management Journal_, 61(2), 440–465.

Gilbert, N., & Troitzsch, K. G. (2005). _Simulation for the Social Scientist_ (2nd ed.). Open University Press.

Grimm, V., Berger, U., Bastiansen, F., Eliassen, S., Ginot, V., Giske, J., Goss-Custard, J., Grand, T., Heinz, S. K., Huse, G., Huth, A., Jepsen, J. U., Jørgensen, C., Mooij, W. M., Müller, B., Pe’er, G., Piou, C., Railsback, S. F., Robbins, A. M., … DeAngelis, D. L. (2006). A standard protocol for describing individual-based and agent-based models. _Ecological Modelling_, 198(1–2), 115–126.

Grimm, V., Berger, U., DeAngelis, D. L., Polhill, J. G., Giske, J., & Railsback, S. F. (2010). The ODD protocol: A review and first update. _Ecological Modelling_, 221(23), 2760–2768.

Hamstra, M. R. W., Van Vianen, A. E. M., & Koen, J. (2019). Does employee perceived person-organization fit promote performance? The moderating role of supervisor perceived person-organization fit. _European Journal of Work and Organizational Psychology_, 28(5), 594–601.

Hecht, T. D., & Allen, N. J. (2005). Exploring links between polychronicity and well-being from the perspective of person–job fit: Does it matter if you prefer to do only one thing at a time? _Organizational Behavior and Human Decision Processes_, 98(2), 155–178.

Morley, M. J. (2007). Person‐organization fit. _Journal of Managerial Psychology_, 22(2), 109–117.

Schelling, T. C. (1978). _Micromotives and Macrobehavior_. W.W. Norton and Company.

Sylva, H., Mol, S. T., Den Hartog, D. N., & Dorenbosch, L. (2019). Person-job fit and proactive career behaviour: A dynamic approach. _European Journal of Work and Organizational Psychology_, 28(5), 631–645.

van Vianen, A. E. M., De Pater, I. E., & Van Dijk, F. (2007). Work value fit and turnover intention: Same‐source or different‐source fit. _Journal of Managerial Psychology_, 22(2), 188–202.

Wheeler, A. R., Coleman Gallagher, V., Brouer, R. L., & Sablynski, C. J. (2007). When person‐organization (mis)fit and (dis)satisfaction lead to turnover: The moderating role of perceived job mobility. _Journal of Managerial Psychology_, 22(2), 203–219.
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
<experiments>
  <experiment name="Poser Null Model" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>%_happy_posers</metric>
    <enumeratedValueSet variable="s_perf_eff1">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_rounds">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max_move">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_perf_eff1">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="window">
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w_perf_eff1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="s_perf_eff2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w_perf_eff">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w_perf_eff2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_shirkers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_perf_eff2">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="run_termination">
      <value value="&quot;num_rounds&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;by performance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decision_rule">
      <value value="&quot;change window&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_perf_eff">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="s_perf_eff">
      <value value="1"/>
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
