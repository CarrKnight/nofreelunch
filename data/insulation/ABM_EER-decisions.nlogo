  breed [homeowners homeowner]
  breed [owners owner]
  breed [houses house]
houses-own [
  class                         ;house class
  houseage                      ;house age
  happy-with-location?]         ;parameter for clustering procedure
owners-own [
  lifestyle-nr                  ;lifestyle number
  lifestyle-cl lifestyle-cl_self;lifestyle values for clustering    
  happy-with-location?]         ;parameter for clustering procedure
homeowners-own [
  class                         ;house class
  lifestyle-nr                  ;lifestyle number
  lifestyle-net milie-net_self  ;lifestyle values for network formation
  lifestyle-neighbors           ;number of neighbors with same lifestyle
  houseage                      ;age of house
  age                           ;age of homeowners
  income                        ;income of homeowners
  attitude                      ;attitude of homeowners
  status-eff-ren                ;weighted status of EER
  wall-ins?                     ;is the wall insulated? 
  wall-rend?                    ;does the wall has an exterior rendering?
  roof-ins?                     ;is the roof is insulated? 
  floor-ins?                    ;is the floor is insulated? 
  windows-triple?               ;are the windows triple glazed?
  attic-ext?                    ;is the attic extended?
  cellar-ext?                   ;is cellar extended?
  time-since-purchase           ;time [a] since last house purchase
  nr-wall-ins                   ;total nr of times homeowners insulated the wall
  nr-roof-ins                   ;total nr of times homeowners insulated the roof
  nr-floor-ins                  ;total nr of times homeowners insulated the floor
  nr-triple-windows             ;total nr of times homeowners put in triple glazed windows
  nr-heat-sys                   ;total nr of times homeowners renewed heating systems
  av-nr-ins                     ;overall weighted insulations activity 
  pos-as-inf neg-as-inf         ;assessed information for <0=negative for >0=positive
  as-inf                        ;sum of positive and negative assessed information
  time-since-dec                ;time since last decision-process [a]
  age-wall-ins                  ;age of wall insulation [a]
  age-roof-ins                  ;age of roof insulation [a]
  age-floor-ins                 ;age of floor insulation [a]
  age-heating-sys               ;age of heating system [a]
  age-windows                   ;age of windows [a]
  age-wall-paint                ;age of facade painting [a]
  age-wall-rend                 ;age of exterior rendering [a]
  age-roofing                   ;age of roof renewal [a]
  life-wall-ins                 ;expected lifetime of wall insulation
  life-roof-ins                 ;expected lifetime of roof insulation
  life-floor-ins                ;expected lifetime of floor insulation
  life-heating-sys              ;expected lifetime of heating system
  life-windows                  ;expected lifetime of windows
  life-wall-paint               ;expected lifetime of facade painting
  life-wall-rend                ;expected lifetime of exterior rendering of wall
  life-roofing                  ;expected lifetime of roofing
  time-to-dec                   ;time to decision
  time-of-dec                   ;time-of-dec
  in-process?                   ;boolean, is homeowner in decision-process?
  dec-purchase?                 ;renovation occasion
  dec-maintenance?              ;renovation occasion
  dec-attic-ext?                ;renovation occasion
  dec-cellar-ext?               ;renovation occasion
  ]
globals [
  i  a                                          ;aid-variables
  tol                                           ;tolerance of homeowners               
  class-counter                                 ;building class counter
  lifestyle-counter                             ;lifestyle counter
  index                                         ;list index
  data-lifestyle                                ;load data from file
  year-counter                                  ;year counter
  tot-EER-rate                                  ;weighted annual EER rate
  tot-EER                                       ;weighted annual number of EER
  av-EER-rate                                   ;average weighted EER
  tot-nr-wall-ins  rate-wall-ins                ;nr and rate wall insulations per year          
  tot-nr-roof-ins rate-roof-ins                 ;nr and rate roof insulations per year  
  tot-nr-floor-ins  rate-floor-ins              ;nr and rate floor insulations per year 
  tot-nr-heating-sys  rate-heating-sys          ;nr and rate heating systems per year 
  tot-nr-windows rate-windows                   ;nr and rate windows per year 
  tot-nr-triple-windows rate-triple-windows     ;nr and rate triple glazed windows per year 
  tot-nr-wall-paint   rate-wall-paint           ;nr and rate facade painting per year 
  tot-nr-wall-rend rate-wall-rend               ;nr and rate wall rendering per year      
  tot-nr-roofing  rate-roofing                  ;nr and rate roofing per year
  tot-EER-M1 tot-EER-M2 tot-EER-M3              ;insulation measures per lifestyle per year
  tot-EER-M4 tot-EER-M5 tot-EER-M6              ;insulation measures per lifestyle per year
  tot-EER-M7 tot-EER-M8 tot-EER-M9              ;insulation measures per lifestyle per year
  av-EER-rate-M1 av-EER-rate-M2 av-EER-rate-M3  ;average EER rate per lifestyle
  av-EER-rate-M4 av-EER-rate-M5 av-EER-rate-M6  ;average EER rate per lifestyle
  av-EER-rate-M7 av-EER-rate-M8 av-EER-rate-M9  ;average EER rate per lifestyle
  tot-ins-backlog                               ;insulation backlog
  ins-wall-when-built ins-wall-later            ;share walls insulated when built and insulated later
  ins-roof-when-built ins-roof-later            ;share roofs insulated when built and insulated later   
  ins-floor-when-built ins-floor-later          ;share floors insulated when built and insulated later   
  house-age                                     ;list for house age             
  income-av                                     ;average income of homeowners
  mean_life-heat-sys dev_life-heat-sys          ;mean and deviation for normal distribution lifetime heating system       
  mean_life-wind dev_life-wind                  ;mean and deviation for normal distribution lifetime windows
  mean_life-wall-paint dev_life-wall-paint      ;mean and deviation for normal distribution lifetime facade painting
  mean_life-wall-rend dev_life-wall-rend        ;mean and deviation for normal distribution lifetime wall rendering
  mean_life-roofing dev_life-roofing            ;mean and deviation for normal distribution lifetime roofing
  mean_life-wall-ins dev_life-wall-ins          ;mean and deviation for normal distribution lifetime wall insulation
  mean_life-roof-ins dev_life-roof-ins          ;mean and deviation for normal distribution lifetime roof insulation
  mean_life-floor-ins dev_life-floor-ins        ;mean and deviation for normal distribution lifetime floor insulation
  cons-pos work-pos dome-pos hedo-pos ente-pos  ;network contacts of lifestyles to conv,libe,main,refl
  backlog-roof-ins backlog-wall-ins             ;backlog roof and wall insulation     
  backlog-floor-ins backlog-windows             ;backlog floor insulation and windows
  ]                                      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to Setup
   setagents                                                 ;set owners set houses merge houses and owners
   resetagecomponents                                        ;reset age of  heating system, windows, wall painting, roof renewal, wall rendering, and extended attics
   setinsulationsharesandage                                 ;set insulation shares and age to status of base year (after! resetagecompontents)
   setNetw                                                   ;create artificital spatial structure
   repeat 50 [Go]                                            ;run initialisation phase of model
   ResetSimulation                                           ;reset the simulation
   calc                                                      ;calculation of insulation rate etc.                                   
   reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; ;SET AGENTS ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setagents
  sethouses                                                   ;distribute houses
  setowners                                                   ;distribute owners
  create-homeowners count houses [                            ;merge houses and owners to "homeowners"
    move-to one-of patches with [count houses-here = 1 and count other homeowners-here = 0]   
    set shape "circle"  set size 1 set color blue             ;set design attributes
    set time-since-dec 1 / 12 * random 12  set as-inf 0       ;set decision-process variables
    set age 0  set windows-triple? false                      ;reset attributes for setup
    set dec-purchase? false set dec-maintenance? false        ;reset attributes for setup
    set dec-attic-ext? false set dec-cellar-ext? false        ;reset attributes for setup
    set time-to-dec 0   set in-process?  false                ;reset attributes for setup
    set wall-rend? false set attic-ext? false                 ;reset attributes for setup
    set cellar-ext? false                                     ;reset attributes for setup
    set nr-wall-ins 0 set nr-roof-ins 0 set nr-floor-ins 0    ;reset attributes for setup
    set nr-triple-windows 0  set nr-heat-sys 0                ;reset attributes for setup  
    ask owners-here [let mn lifestyle-nr ask myself [set lifestyle-nr mn]]                        ;inherit variables from owners
    ask houses-here [let hc class let ha houseage ask myself [set class hc set houseage ha]]]     ;inherit variables from houses
    ask owners [die] ask houses [die]                                                             ;delete houses and owners

;set lifetime of buildings elements
  set mean_life-heat-sys 20        set dev_life-heat-sys 2.5      ;of heating system
  set mean_life-wind 30            set dev_life-wind 5            ;of windows    
  set mean_life-wall-paint 15      set dev_life-wall-paint 2.5    ;of facade painting
  set mean_life-wall-rend 50       set dev_life-wall-rend 7.5     ;of wall rendering
  set mean_life-roofing 50         set dev_life-roofing 5         ;of roofing
  set mean_life-wall-ins 40        set dev_life-wall-ins 5        ;of wall insulation
  set mean_life-roof-ins 40        set dev_life-roof-ins 5        ;of roof insulation
  set mean_life-floor-ins 40       set dev_life-floor-ins 5       ;of floor insulation

;distribute life of buildings elements among homeowners   
  ask homeowners [
    set life-heating-sys random-normal mean_life-heat-sys dev_life-heat-sys     ;of heating system    
    set life-windows random-normal mean_life-wind dev_life-wind                 ;of windows
    set life-wall-paint random-normal mean_life-wall-paint dev_life-wall-paint  ;of facade painting
    set life-wall-rend random-normal mean_life-wall-rend dev_life-wall-rend     ;of wall rendering
    set life-roofing random-normal mean_life-roofing dev_life-roofing           ;of roofing
    set life-wall-ins random-normal mean_life-wall-ins dev_life-wall-ins        ;of wall insulation
    set life-roof-ins random-normal mean_life-roof-ins dev_life-roof-ins        ;of roof insulation
    set life-floor-ins random-normal mean_life-floor-ins dev_life-floor-ins]    ;of floor insulation
     
;distribute attitude amongst homeowners
    let attitude-distr [-0.25 0.25 -0.25 0.5 0.25 -0.25 0.25 -0.25 -0.5]        ;list of mean attitude of lifestlyes (1 to 9)
    set index 0
    repeat 9 [ask homeowners with [lifestyle-nr = index + 1][
       set attitude random-normal item index attitude-distr 0.2]                ;normal distribution with deviation 0.2
       set index index + 1]
    repeat 10 [ask homeowners [set attitude attitude - 
        (sum [attitude] of homeowners / count homeowners - av-att)]]            ;adapt to average attitude
 
;distribute age among homeowners
  let x 10 let y 15                                                             ;set mean and deviation
  repeat 10 [ask homeowners with [age < 18 or age > 100] [
    if lifestyle-nr = 1 [set age random-normal (57.5 + x) y]
    if lifestyle-nr = 2 [set age random-normal (53.7 + x) y]
    if lifestyle-nr = 3 [set age random-normal (58.6 + x) y]
    if lifestyle-nr = 4 [set age random-normal (46.4 + x) y]
    if lifestyle-nr = 5 [set age random-normal (43.8 + x) y]
    if lifestyle-nr = 6 [set age random-normal (45.1 + x) y]
    if lifestyle-nr = 7 [set age random-normal (36.7 + x) y]
    if lifestyle-nr = 8 [set age random-normal (33.2 + x) y]
    if lifestyle-nr = 9 [set age random-normal (33.6 + x) y]]]

;distribute income among homeowners
  set x 1100 set y 1700                                               ;set mean and deviation
  ask homeowners [set income 0]
  repeat 10 [ask homeowners with [income < 400] [
    if lifestyle-nr = 1 [set income random-normal (4847 / 2 + x) y]   ;/2 for DM->EUR
    if lifestyle-nr = 2 [set income random-normal (3913 / 2 + x) y]
    if lifestyle-nr = 3 [set income random-normal (2779 / 2 + x) y]
    if lifestyle-nr = 4 [set income random-normal (5177 / 2 + x) y]
    if lifestyle-nr = 5 [set income random-normal (4055 / 2 + x) y]
    if lifestyle-nr = 6 [set income random-normal (3149 / 2 + x) y]
    if lifestyle-nr = 7 [set income random-normal (4733 / 2 + x) y]
    if lifestyle-nr = 8 [set income random-normal (3582 / 2 + x) y]
    if lifestyle-nr = 9 [set income random-normal (3195 / 2 + x) y]]]
  ask homeowners with [class = 0][die]                                ;delete potential homeowners without class
  ask homeowners with [lifestyle-nr = 0][die]                         ;delete potential homeowners without lifestyle
  set income-av sum [income] of homeowners / count homeowners
end

to setinsulationsharesandage                                          ;set insulation shares and age to status of base year
  ask homeowners           [set roof-ins? false set wall-ins? false set floor-ins? false]
  set ins-wall-when-built  [0.03 0.02 0.03 0.07 0.25 0.33 0.41 0.57 0.54]
  set ins-roof-when-built  [0.04 0.06 0.09 0.15 0.43 0.52 0.72 0.91 0.88]
  set ins-floor-when-built [0.03 0.04 0.06 0.11 0.32 0.35 0.59 0.73 0.82] 
  set ins-wall-later       [0.32 0.28 0.3 0.28 0.16 0.13 0.06 0.03 0.1]
  set ins-roof-later       [0.55 0.54 0.6 0.57 0.39 0.33 0.2 0.06 0.1]
  set ins-floor-later      [0.2 0.13 0.15 0.11 0.06 0.06 0.03 0.02 0.02] 

  set class-counter 1
  repeat 2 [                                                           ;1) house class 1 - 9  and 2) house class 10-18
    set index 0
    repeat 9 [ask homeowners with [class = class-counter] [   
    ;insulated when built
       if random-float 1 < item index ins-roof-when-built [
         set roof-ins? true ifelse houseage < life-roof-ins [
                             set age-roof-ins houseage][set age-roof-ins random life-roof-ins]]
       if random-float 1 < item index ins-wall-when-built [
         set wall-ins? true ifelse houseage < life-wall-ins [
                             set age-wall-ins houseage][set age-wall-ins random life-wall-ins]]
       if random-float 1 < item index ins-floor-when-built [
         set floor-ins? true ifelse houseage < life-floor-ins [
                             set age-floor-ins houseage][set age-floor-ins random life-floor-ins]] 
    ;insulated later
       if random-float (1 - item index ins-roof-when-built) < item index ins-roof-later and roof-ins? = false [
         set roof-ins? true ifelse houseage < life-roof-ins [set age-roof-ins houseage][set age-roof-ins random life-roof-ins]]
       if random-float (1 - item index ins-wall-when-built) < item index ins-wall-later and wall-ins? = false [
         set wall-ins? true ifelse houseage < life-wall-ins [set age-wall-ins houseage][set age-wall-ins random life-wall-ins]]
       if random-float (1 - item index ins-floor-when-built) < item index ins-floor-later and floor-ins? = false [
         set floor-ins? true ifelse houseage < life-floor-ins [set age-floor-ins houseage][set age-floor-ins random life-floor-ins]]]
    set class-counter class-counter + 1 set index index + 1]]
  ;set share of triple-glazed windows
    ask n-of (0.1 * count homeowners with [houseage <= 5]) homeowners with [houseage <= 5] [set windows-triple? true]
  ;set age of insulations of houses without insulation to "NA"
    ask homeowners with [wall-ins? = false]  [set age-wall-ins "NA"]
    ask homeowners with [roof-ins? = false]  [set age-roof-ins "NA"]
    ask homeowners with [floor-ins? = false] [set age-floor-ins "NA"]
end


to adjustinsulationsharesandage  ;adjust insulation shares and age to 2010 level, leave distribution within lifestyles
  set class-counter 1
  repeat 2 [                     ;1) house class 1 - 9  and 2) house class 10-18
    set index 0
    repeat 9 [   
  ;adjust insulation share roof  
       let wanted-percentage  (item index ins-roof-when-built + item index ins-roof-later)                                       ;wanted percentage in class and category
       let wanted-number wanted-percentage * count homeowners with [class = class-counter]                                       ;wanted number of homeowners with insulation in class and category
       while [wanted-number < count homeowners with [class = class-counter and roof-ins? = true]][                               ;while more insulated than wanted
       ask one-of homeowners with [class = class-counter and roof-ins? = true][
         set roof-ins? false set age-roof-ins "NA"]]
  ;set age of roof insulation
       ask homeowners with [class = class-counter and roof-ins? = true][      
       ifelse random-float 1 < item index ins-roof-when-built / (item index ins-roof-when-built + item index ins-roof-later)[    ;share insulation when built
          set age-roof-ins item (index + 1) house-age + random (item index house-age - item (index + 1) house-age)][             ;set age of insulation to house age
          set age-roof-ins random item index house-age ]]                                                                        ;insulated later
  ;adjust insulation share wall    
       set wanted-percentage  (item index ins-wall-when-built + item index ins-wall-later)                                       ;wanted percentage in class and category
       set wanted-number wanted-percentage * count homeowners with [class = class-counter]                                       ;wanted number of homeowners with insulation in class and category
       while [wanted-number < count homeowners with [class = class-counter and wall-ins? = true]][                               ;while more insulated than wanted
       ask one-of homeowners with [class = class-counter and wall-ins? = true][ 
         set wall-ins? false set age-wall-ins "NA"]]
  ;set age of wall insulation
       ask homeowners with [class = class-counter and wall-ins? = true][
       ifelse random-float 1 < item index ins-wall-when-built / (item index ins-wall-when-built + item index ins-wall-later)[    ;share insulation when built
         set age-wall-ins item (index + 1) house-age + random (item index house-age - item (index + 1) house-age)][              ;set age of insulation to house age
         set age-wall-ins random item index house-age ]]                                                                         ;insulated later    
  ;adjust insulation share floor  
       set wanted-percentage  (item index ins-floor-when-built + item index ins-floor-later)                                     ;wanted percentage in class and category
       set wanted-number wanted-percentage * count homeowners with [class = class-counter]                                       ;wanted number of homeowners with insulation in class and category
       while [wanted-number < count homeowners with [class = class-counter and floor-ins? = true]][                              ;while more insulated than wanted
       ask one-of homeowners with [class = class-counter and floor-ins? = true][ 
         set floor-ins? false set age-floor-ins "NA"]] 
  ;set age of floor insulation
       ask homeowners with [class = class-counter and floor-ins? = true][
       ifelse random-float 1 < item index ins-floor-when-built / (item index ins-floor-when-built + item index ins-floor-later)[ ;share insulation when built
         set age-floor-ins item (index + 1) house-age + random (item index house-age - item (index + 1) house-age)][             ;set age of insulation to house age
         set age-floor-ins random item index house-age ]]                                                                        ;insulated later  
    set class-counter class-counter + 1 set index index + 1]]
;adjust share of triple-glazed windows
  ask homeowners [set windows-triple? false]
  ask n-of (0.1 * count homeowners with [houseage <= 5]) homeowners with [houseage <= 5] [set windows-triple? true]
end

to sethouses
  clear-all
  reset-ticks
  ask patches [set pcolor white]
;create houses
  create-houses (density * ((max-pxcor + 1) * (max-pycor + 1) - 1) * 1.1) [set hidden? true set class "NA"] ;+50  
;distribute housetypes and age amongst houses
      let building-shares-EFH [0.1397 0.1071 0.1020 0.1211 0.0995 0.0504 0.1095 0.1062 0.0357] ;EFH
      let building-shares-RH [0.0077 0.0174 0.0123 0.0185 0.0275 0.0108 0.0150 0.0152 0.0044]  ;RH
      set house-age [110 90 60 50 40 30 25 15 10 0]
;EFH - distrubute housetypes and age      
    set index 0 set class-counter 1
    repeat 9 [ask n-of  (item index building-shares-EFH * count houses) houses with [class = "NA"] [
          set class class-counter    
          set houseage item (index + 1) house-age + random ((item index house-age) - (item (index + 1) house-age))]
          set class-counter class-counter + 1 
          set index index + 1] 
;RH - distrubute housetypes and age  
    set index 0 set class-counter 10
    repeat 9 [ask n-of  (item index building-shares-RH * count houses) houses with [class = "NA"] [
          set class class-counter    
          set houseage item (index + 1) house-age + random ((item index house-age) - (item (index + 1) house-age))]
          set class-counter class-counter + 1 
          set index index + 1]
;distribute houses in the Environment
  set class-counter 1
  ask houses [set happy-with-location? false]
  repeat 9 [
         ask houses with [class = class-counter or class = class-counter + 9][
         set hidden? false 
         move-to one-of patches with [count houses-here = 0]]  
         ask houses with [class = class-counter or class = class-counter + 9 and count other houses in-radius 1 = 0][
         move-to one-of patches with [count houses-here = 0 and count other houses in-radius 1 > 0 ]] 
     while [count houses with [class = class-counter or class = class-counter + 9 and happy-with-location? = false] > 0][ 
     ask houses with [class = class-counter or class = class-counter + 9 and happy-with-location? = false][ set i 0
       ask other houses in-radius 1 [
         let neighbor-class class set a 0
         ask myself  [
            ifelse (neighbor-class = class or neighbor-class = class + 9 or neighbor-class = class - 9 )[set a 1][set a 0]
            set i i + a]]                            ;sum the likelihood (dependent on houseclass) 
       if count other houses in-radius 1 > 0[        ;radius = 1     
        set i i / count other houses in-radius 1]    ;i represents possibility to be happy and stay
       ifelse random-float 1 < i  [set happy-with-location? true] 
        [move-to one-of patches with [count houses-here = 0 and (count other houses in-radius 1) > 0]]]]
        set class-counter class-counter + 1] 
ask houses [if class = "NA" [die]]                   ;delete potential houses without class
end 

to setowners
set tol 0
ask owners [die] ;reset
;create owners
  create-owners density * ((max-pxcor + 1) * (max-pycor + 1) - 1) [set lifestyle-nr "NA" move-to one-of patches with [count owners-here = 0]]   
;lifestyle shares
  let lifestyle-nr-shares [0.057 0.099 0.066 0.159 0.269 0.147 0.069 0.10 0.0340] 
  set lifestyle-counter 1 set index 0
  repeat 9 [ask n-of (item index lifestyle-nr-shares * count owners) owners with [lifestyle-nr = "NA"] [
          set lifestyle-nr lifestyle-counter]
          set lifestyle-counter lifestyle-counter + 1 set index index + 1]
  ask owners [if lifestyle-nr = "NA" [die]]                   ;delete houses without lifestyle
read-in-data-cl                                               ;read in data on clustering
;distribute owners in the Environment
ask owners [set happy-with-location? false
              move-to one-of patches with [count owners-here = 0 and count houses-here = 1]] 
            ask owners [if radius = 0 [set happy-with-location? true]]    
         ask owners with [happy-with-location? = false and count other owners in-radius radius = 0][
         move-to one-of patches with [count owners-here = 0 and count houses-here = 1 and count other owners in-radius radius > 0 ]]               
     while [count owners with [happy-with-location? = false] > 0] [
     set tol tol + 0.001
     ask owners with [happy-with-location? = false][          ;and count other owners in-radius radius > 0][ 
       set i 0
       ask other owners in-radius radius [
         set index (lifestyle-nr - 1)                         ;index to read (imported) list
         ask myself  [
            set i i +  1 - item index lifestyle-cl / 100  ]]  ;sum the likelihood (dependent on lifestyle) 
       if count other owners in-radius radius > 0[  
        set i i / count other owners in-radius radius]        ;i represents possibility to be happy and stay
       ifelse tol > (1 - i)  [set happy-with-location? true]  ;tol > 
        [move-to one-of patches with [count owners-here = 0 and count houses-here = 1 and (count other owners in-radius radius) > 0]] ]]
ask houses [if not any? owners-on patch-here [die]]           ;delete potential empty houses
end

to resetagecomponents  ;reset age of heating system, windows, wall painting, roof renewal, wall rendering, and extended attics
;reset wall rendering
  if int(count homeowners * 0.7) > count homeowners with [wall-rend? = true][
    ask n-of int(count homeowners * 0.7) homeowners [set wall-rend? true]] 
  
  ask homeowners [ifelse (wall-rend? = true)[
                    if houseage <= life-wall-rend [set age-wall-rend houseage]
                    if houseage > life-wall-rend  [set age-wall-rend random life-wall-rend]][
                  set age-wall-rend "NA"]]

;reset attic-ext
  if int(count homeowners * 0.424) > count homeowners with [attic-ext? = true][
    ask n-of int(count homeowners * 0.424) homeowners [set attic-ext? true]]
;reset cellar-ext
  if int(count homeowners * 0.255) > count homeowners with [cellar-ext? = true][
    ask n-of int(count homeowners * 0.255) homeowners [set cellar-ext? true]]

ask homeowners [ 
  ;age of components max the age of the house
  if houseage <= life-windows     [set age-windows houseage]
  if houseage <= life-heating-sys [set age-heating-sys houseage]
  if houseage <= life-wall-paint  [set age-wall-paint houseage]
  if houseage <= life-roofing     [set age-roofing houseage]
  if ticks = 0[ ;not run after initialisation phase of model
   ;age of components when houseage is older than the life expectancy of components
   if houseage > life-windows       [set age-windows random life-windows]
   if houseage > life-heating-sys   [set age-heating-sys random life-heating-sys]
   if houseage > life-wall-paint    [set age-wall-paint random life-wall-paint]
   if houseage > life-roofing       [set age-roofing random life-roofing]]]
  ;set time since purchase of house
  ask homeowners [  
    if age <= 47.8                [set time-since-purchase (age - 32)]   
    if age <= 63.6 and age > 47.8 [set time-since-purchase (age - 47.8)]
    if age <= 79.4 and age > 63.6 [set time-since-purchase (age - 63.8)] 
    if age <= 95.2 and age > 79.4 [set time-since-purchase (age - 79.4)] 
    if age > 95.2                 [set time-since-purchase (age - 95.2)]]
end

to setNetw
read-in-data-net ;read in data for network formation    
ask links[die]
   while [count homeowners with [count link-neighbors = 0] > 0][       ;min. 1 link / homeowner
   ask homeowners with [count link-neighbors = 0] [
     ask other homeowners in-radius (max-pxcor / 2)  [ 
         set index (lifestyle-nr - 1)                                  ;index to read list
         ask myself [
           set i item index lifestyle-net                              
           set i i / (distance myself ^ 2)                             ;likelihood / distance between homeowners ^ 2
           if random-float 1 < i   [create-link-with myself]]]] 
   ]
end

to ResetSimulation
  set year-counter 0
  clear-all-plots
  ;reset number of performed measures
  ask homeowners [set nr-wall-ins 0 set nr-roof-ins 0  set nr-floor-ins 0 set nr-triple-windows 0 set nr-heat-sys 0]
  resetagecomponents                       ;reset age of  heating system, windows, wall painting, roof renewal, wall rendering, and extended attics  
  adjustinsulationsharesandage             ;adust insulation shares to status of base years while keeping the shares within the lifestyles  
  ask homeowners [update-status-eff-ren]
  ;reset analysis
  set tot-EER 0 set tot-EER-M1 0 set tot-EER-M2 0 set tot-EER-M3 0 set tot-EER-M4 0 
  set tot-EER-M5 0 set tot-EER-M6 0 set tot-EER-M7 0 set tot-EER-M8 0 set tot-EER-M9 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUN MODEL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to Go
  repeat 12 [                                                                 ;one year = 12 ticks
    ask homeowners[
    aging                                                                     ;components get 1/12 year older, time since decision passes by
    ifelse     
    in-process? = false [opportunity][                                        ;Opportunity
    if in-process? = true and time-to-dec >= time-of-dec [dec-process         ;Decision making
      ]]]] 
  set year-counter year-counter + 1
  calc                                                                        ;calc rates and backlog
  ask homeowners [visualise] tick                                             ;visualisation 
end

to aging
    if roof-ins? = true [set age-roof-ins  age-roof-ins + 1 / 12]         ;age of roof insulation if any
    if wall-ins? = true [set age-wall-ins  age-wall-ins + 1 / 12]         ;age of wall insulation if any
    if floor-ins? = true [set age-floor-ins  age-floor-ins + 1 / 12]      ;age of floor insulation if any
    if wall-rend? = true [set age-wall-rend age-wall-rend + 1 / 12]       ;age of wall rendering if any
    set age-heating-sys age-heating-sys + 1 / 12                          ;age of heating system
    set age-windows age-windows + 1 / 12                                  ;age of windows
    set age-wall-paint age-wall-paint + 1 / 12                            ;age of facade painting
    set age-roofing  age-roofing + 1 / 12                                 ;age of roofing    
    set time-since-dec time-since-dec + 1 / 12                            ;time since decision passes by
    set time-since-purchase time-since-purchase + 1 / 12                  ;time since last purchase passes by
    if in-process? = true [set time-to-dec time-to-dec + 1 / 12]          ;time until decision decrease
end

to opportunity
   ifelse time-since-purchase >= random-normal 15.8 1 [time-between set in-process? true set dec-purchase? true][                                           ;purchase
   set i first shuffle ["maintenance" "extension"]
   if i = "maintenance" and random 100 < (100 - absolute-value (age - 60)) [time-between set in-process? true set dec-maintenance? true]                    ;maintenance
   if i = "extension" and random 100 < (100 - absolute-value (age - 35)) and attic-ext? = false [time-between set in-process? true set dec-attic-ext? true] ;attic extension 
    ]                                                              
end 

to dec-process
  if dec-maintenance? = true  [set time-to-dec 0 one-of_maintenance-measures set dec-maintenance? false]  ;maintenance
  if dec-attic-ext? = true    [set time-to-dec 0 attic-ext set dec-attic-ext? false]                      ;attic extension
  if dec-cellar-ext? = true   [set time-to-dec 0 meas-floor-ins set dec-cellar-ext? false]                ;cellar extension -> floor insulation?
  if dec-purchase? = true     [set time-to-dec 0 purchase set dec-purchase? false ]                       ;purchase
set in-process? false
end

to time-between      ;calculate time between renovation opportunity and deicsion-making (in years)
   set time-of-dec fin-con * 0.5 * ( income-av / income)
end

to-report absolute-value [num]
  ifelse num > 0 or num = 0
    [report num]
    [report (- num) ]
end

to one-of_maintenance-measures
  set i first shuffle ["roof" "paint" "window" "render" "heating"]
  if i = "heating" [if age-heating-sys > life-heating-sys [meas-heating-sys]]  
  if i = "roof"    [if age-roofing > life-roofing [meas-roofing meas-roof-ins ]]
  if i = "paint"   [if age-wall-paint > life-wall-paint [meas-wall-paint as-information if as-inf > 0 [meas-wall-ins]]]
  if i = "window"  [if age-windows > life-windows [meas-eff-windows]]
  if i = "render"  [if wall-rend? = true and age-wall-rend > life-wall-rend [meas-wall-rend meas-wall-ins ]]
end

to attic-ext
  if age-roofing > life-roofing [   
    meas-roofing meas-roof-ins ]                                 ;renew roofing and decide on roof insulation
end

to purchase
  set time-since-purchase 0
  repeat random 3 [one-of_maintenance-measures]                  ;consider max 3 randomly chosen maintenance measures 
  if time-since-dec > 0 and cellar-ext? = false  
  [time-between set in-process? true set dec-cellar-ext? true]   ;consider cellar extension -> floor insulation if no maintenance measure was carried out
end

to meas-heating-sys                              ;renew heating system
   set time-since-dec 0 set age-heating-sys 0 
   set life-heating-sys random-normal mean_life-heat-sys dev_life-heat-sys  
   set tot-nr-heating-sys tot-nr-heating-sys + 1
   set nr-heat-sys nr-heat-sys + 1
   ;consider other queuing maintenance measures
     if age-roofing > life-roofing [meas-roofing  meas-roof-ins]
     if age-wall-paint > life-wall-paint [meas-wall-paint as-information if as-inf > 0 [meas-wall-ins]]
     if age-windows > life-windows [meas-eff-windows]
     if wall-rend? = true and age-wall-rend > life-wall-rend [meas-wall-rend meas-wall-ins]
end

to meas-wall-paint                               ;paint the walls
  set time-since-dec 0 set age-wall-paint 0
  set life-wall-paint random-normal mean_life-wall-paint dev_life-wall-paint
  set tot-nr-wall-paint tot-nr-wall-paint + 1
end

to meas-wall-rend                                ;renew exterior rendering
  if wall-rend? = true[
  set time-since-dec 0 set age-wall-rend 0
  set life-wall-rend random-normal mean_life-wall-rend dev_life-wall-rend
  set tot-nr-wall-rend tot-nr-wall-rend + 1]
end

to meas-roofing                                  ;renew roofing
  set time-since-dec 0  set age-roofing 0
  set life-roofing random-normal mean_life-roofing dev_life-roofing   
  set tot-nr-roofing tot-nr-roofing + 1
end

to meas-wall-ins
as-information                            ;assess information
if attitude  + as-inf > 0 [               ;necessary condition
  if wall-ins? = false [                  ;install wall insulation
    set wall-ins? true set age-wall-ins 0
    set life-wall-ins random-normal mean_life-wall-ins dev_life-wall-ins
    meas-wall-paint meas-wall-rend        ;new paint and renew exterior rendering (if any)
    set time-since-dec 0
    set tot-nr-wall-ins tot-nr-wall-ins + 1
    set nr-wall-ins nr-wall-ins + 1]
  if age-wall-ins > life-wall-ins [       ;renew wall insulation
     set life-wall-ins random-normal mean_life-wall-ins dev_life-wall-ins
     meas-wall-paint meas-wall-rend       ;new paint and renew exterior rendering (if any)
     set time-since-dec 0 set age-wall-ins 0  
     set tot-nr-wall-ins tot-nr-wall-ins + 1
     set nr-wall-ins nr-wall-ins + 1]
  update-status-eff-ren]
end

to meas-roof-ins
as-information                            ;assess information
if attitude  + as-inf > 0 [               ;necessary condition
  if roof-ins? = false [                  ;install roof insulation
    set roof-ins? true set age-roof-ins 0
    set life-roof-ins random-normal mean_life-roof-ins dev_life-roof-ins  
    meas-roofing                          ;renew roofing 
    set time-since-dec 0
    set tot-nr-roof-ins tot-nr-roof-ins + 1 
    set nr-roof-ins nr-roof-ins + 1]
  if age-roof-ins > life-roof-ins [       ;renew roof insulation
    set age-roof-ins 0
    set life-roof-ins random-normal mean_life-roof-ins dev_life-roof-ins  
    meas-roofing                          ;renew roofing 
    set time-since-dec 0
    set tot-nr-roof-ins tot-nr-roof-ins + 1 
    set nr-roof-ins nr-roof-ins + 1]
  update-status-eff-ren]  
end

to meas-floor-ins
as-information                            ;assess information
if attitude  + as-inf > 0 [               ;necessary condition
  if floor-ins? = false [                 ;install floor insulation
     set floor-ins? true set age-floor-ins 0
     set life-floor-ins random-normal mean_life-floor-ins dev_life-floor-ins
     set time-since-dec 0
     set tot-nr-floor-ins tot-nr-floor-ins + 1 
     set nr-floor-ins nr-floor-ins + 1]
  if age-floor-ins > life-floor-ins [     ;renew floor insulation
     set age-floor-ins 0
     set life-floor-ins random-normal mean_life-floor-ins dev_life-floor-ins
     set time-since-dec 0
     set tot-nr-floor-ins tot-nr-floor-ins + 1 
     set nr-floor-ins nr-floor-ins + 1]
  update-status-eff-ren]
  
end
to meas-eff-windows
as-information                            ;assess information
ifelse attitude + as-inf > 0 [            ;necessary condition
  if age-windows > life-windows [         ;install triple glazed windows
    set windows-triple?  true
    set age-windows 0
    set life-windows random-normal mean_life-wind dev_life-wind
    set time-since-dec 0    
    set tot-nr-triple-windows tot-nr-triple-windows + 1 
    set nr-triple-windows nr-triple-windows + 1
    set tot-nr-windows tot-nr-windows + 1
    update-status-eff-ren]][
; else put "normal windows" only
  if age-windows > life-windows [ 
    set windows-triple?  false
    set age-windows 0 
    set life-windows random-normal mean_life-wind dev_life-wind
    set time-since-dec 0
    set tot-nr-windows tot-nr-windows + 1 ]] 
end

to as-information
  if count link-neighbors > 0 [
set pos-as-inf 0             
if count link-neighbors with [attitude + as-inf > 0] > 0 [     
  ask link-neighbors with    [attitude + as-inf > 0][
    if time-since-dec > 0 [                                    
      set i 1 / time-since-dec 
      ask myself [set pos-as-inf pos-as-inf + (i * count link-neighbors ^ 0.6) ]]]]

set neg-as-inf 0  
if count link-neighbors with [attitude + as-inf < 0] > 0 [    
  ask link-neighbors with    [attitude + as-inf < 0][
    if time-since-dec > 0 [                                    
    set i 1 / time-since-dec
    ask myself [set neg-as-inf neg-as-inf + (i * count link-neighbors ^ 0.6) ]]]]

set as-inf ((pos-as-inf - neg-as-inf) * weight-soc-ben / count link-neighbors) ]        ;assessed information
end

to update-status-eff-ren    ;insulation status of homeowners
  set status-eff-ren 0 
  if wall-ins? = true       [set status-eff-ren status-eff-ren + 0.5] 
  if roof-ins? = true       [set status-eff-ren status-eff-ren + 0.25]   
  if floor-ins? = true      [set status-eff-ren status-eff-ren + 0.12]
  if windows-triple? = true [set status-eff-ren status-eff-ren + 0.13]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; CALCULATE RENOVATION RATES AND INSULATION BACKLOG ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calc
  calc-backlog                         ;calc insulation backlog
  calc-rate                            ;calc renovation rates
end

to calc-backlog
  if count homeowners with [roof-ins? = true] > 0 [
    set backlog-roof-ins 0.25 * (count homeowners with [roof-ins? = true and age-roof-ins > life-roof-ins] + count homeowners with [roof-ins? = false]) / count homeowners] ;with [roof-ins? = true]]  
  ;show backlog-roof-ins
  
  if count homeowners with [wall-ins? = true] > 0 [
    set backlog-wall-ins 0.5 * (count homeowners with [wall-ins? = true and age-wall-ins > life-wall-ins] + count homeowners with [wall-ins? = false]) / count homeowners] ;with [wall-ins? = true]]
  if count homeowners with [floor-ins? = true] > 0 [
    set backlog-floor-ins 0.12 * (count homeowners with [floor-ins? = true and age-floor-ins > life-floor-ins] + count homeowners with [floor-ins? = false]) / count homeowners] ;with [floor-ins? = true]]
  if count homeowners with [windows-triple? = true] > 0 [
    set backlog-windows 0.13 * (count homeowners with [windows-triple? = true and age-windows > life-windows] + count homeowners with [windows-triple? = false]) / count homeowners] ;with [windows-triple? = true]]

set tot-ins-backlog backlog-roof-ins + backlog-wall-ins + backlog-floor-ins + backlog-windows
end

to calc-rate
  if year-counter > 0 and count homeowners > 0 [
;annual renovation rates [%]
  set rate-wall-ins       tot-nr-wall-ins / count homeowners * 100
  set rate-roof-ins       tot-nr-roof-ins / count homeowners * 100
  set rate-floor-ins      tot-nr-floor-ins / count homeowners * 100
  set rate-heating-sys    tot-nr-heating-sys / count homeowners * 100
  set rate-windows        tot-nr-windows  / count homeowners * 100
  set rate-triple-windows tot-nr-triple-windows  / count homeowners * 100
  set rate-wall-paint     tot-nr-wall-paint  / count homeowners * 100
  set rate-wall-rend      tot-nr-wall-rend / count homeowners * 100
  set rate-roofing        tot-nr-roofing  / count homeowners * 100
  set tot-EER-rate        0.25 * rate-roof-ins + 0.5 * rate-wall-ins + 0.12 * rate-floor-ins + 0.13 * rate-triple-windows
  
;total number of weighted insulations per lifestyle
  set tot-EER-M1 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 1] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 1] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 1] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 1] * 0.13 
  set tot-EER-M2 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 2] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 2] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 2] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 2] * 0.13 
  set tot-EER-M3 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 3] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 3] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 3] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 3] * 0.13 
  set tot-EER-M4 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 4] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 4] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 4] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 4] * 0.13 
  set tot-EER-M5 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 5] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 5] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 5] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 5] * 0.13 
  set tot-EER-M6 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 6] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 6] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 6] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 6] * 0.13 
  set tot-EER-M7 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 7] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 7] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 7] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 7] * 0.13 
  set tot-EER-M8 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 8] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 8] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 8] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 8] * 0.13 
  set tot-EER-M9 sum [nr-roof-ins] of homeowners with [lifestyle-nr = 9] * 0.25 + sum [nr-wall-ins] of homeowners with [lifestyle-nr = 9] * 0.5 + sum [nr-floor-ins] of homeowners with [lifestyle-nr = 9] * 0.12 + sum [nr-triple-windows] of homeowners with [lifestyle-nr = 9] * 0.13   
;total number of insulations since start of simulation
  set tot-EER 0.5 * sum [nr-wall-ins] of homeowners + 0.25 * sum [nr-roof-ins] of homeowners + 0.12 * sum [nr-floor-ins] of homeowners + 0.13 * sum [nr-triple-windows] of homeowners

;average EER rate per lifestyle [%]
  set av-EER-rate-M1 tot-EER-M1 / count homeowners with [lifestyle-nr = 1] / year-counter * 100
  set av-EER-rate-M2 tot-EER-M2 / count homeowners with [lifestyle-nr = 2] / year-counter * 100
  set av-EER-rate-M3 tot-EER-M3 / count homeowners with [lifestyle-nr = 3] / year-counter * 100
  set av-EER-rate-M4 tot-EER-M4 / count homeowners with [lifestyle-nr = 4] / year-counter * 100
  set av-EER-rate-M5 tot-EER-M5 / count homeowners with [lifestyle-nr = 5] / year-counter * 100
  set av-EER-rate-M6 tot-EER-M6 / count homeowners with [lifestyle-nr = 6] / year-counter * 100
  set av-EER-rate-M7 tot-EER-M7 / count homeowners with [lifestyle-nr = 7] / year-counter * 100
  set av-EER-rate-M8 tot-EER-M8 / count homeowners with [lifestyle-nr = 8] / year-counter * 100
  set av-EER-rate-M9 tot-EER-M9 / count homeowners with [lifestyle-nr = 9] / year-counter * 100
;average EER rate [%]
  set av-EER-rate (tot-EER / year-counter) / count homeowners * 100
  
;reset values for annual EER-rate
  set tot-nr-wall-ins 0 set tot-nr-roof-ins 0 set tot-nr-floor-ins 0
  set tot-nr-heating-sys 0 set tot-nr-windows 0 set tot-nr-triple-windows 0
  set tot-nr-wall-paint 0 set tot-nr-wall-rend 0 set tot-nr-roofing 0
]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; IMPORT DATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to read-in-data-net       ;read in data needed for social network formation
  ifelse(file-exists? "lifestyle.network.txt" )[
    set lifestyle-counter 1
    file-open "lifestyle.network.txt"
    while [not file-at-end?][
      set i read-from-string (word "[" file-read-line "]")
      ask homeowners with [lifestyle-nr = lifestyle-counter][set lifestyle-net i]
      set lifestyle-counter lifestyle-counter + 1]
    file-close-all][
  user-message "There is no file lifestyle.network.txt in current directory!"]
end

to read-in-data-cl       ;read in data for lifestlye clustering
  ifelse(file-exists? "lifestyle.clustering.txt" )[ 
    set lifestyle-counter  1
    file-open "lifestyle.clustering.txt"
    while [not file-at-end?][
      set i read-from-string (word "[" file-read-line "]")
      ask owners with [lifestyle-nr = lifestyle-counter][set lifestyle-cl i]
      set lifestyle-counter lifestyle-counter + 1]
    file-close-all][
  user-message "There is no file lifestyle.clustering.txt in current directory!" ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; VISUALISATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to visualise
  ifelse view = "nothing"       [set color blue][
  if view = "roof_ins"          [ifelse roof-ins? = true [set color green][set color red]]
  if view = "wall_ins"          [ifelse wall-ins? = true [set color green]  [set color red]]
  if view = "floor_ins"         [ifelse floor-ins? = true [set color green]  [set color red]]
  if view = "eff_wind"          [ifelse windows-triple? = true [set color green][set color red]]
  if view = "age-owners"        [set color scale-color blue age 100 18]
  if view = "age-houses"        [set color scale-color blue houseage 110 0]
  if view = "income"            [set color scale-color blue income 5000 0]
  if view = "attitude"          [set color scale-color blue attitude 1 -1]
  if view = "at + as-inf"       [set color scale-color blue (attitude + as-inf) 1 -1]
  if view = "assessed-inf"      [ifelse as-inf = 0 [set color white] [ set color scale-color blue as-inf 1 -1]]
  if view = "eff-ren"           [set color scale-color green status-eff-ren 1 0]
  if view = "lifestyle"         [set color scale-color blue lifestyle-nr 1 9]
  ifelse view = "network"       [set hidden? true][set hidden? false]
  ifelse view = "decisions"     [ifelse time-since-dec < 4 and time-since-dec > 0[
                                 set size 2 - (time-since-dec / 2)][set size 0]
                                 if as-inf >= 0 [set color green]
                                 if as-inf < 0 [set color red]][set size 1]]
end
@#$#@#$#@
GRAPHICS-WINDOW
12
14
466
489
-1
-1
7.4
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
59
0
59
1
1
1
ticks
30.0

SLIDER
504
29
688
62
density
density
0.2
0.4
0.3
0.05
1
NIL
HORIZONTAL

SLIDER
504
63
688
96
radius
radius
0
10
5
1
1
NIL
HORIZONTAL

BUTTON
504
268
596
302
NIL
Setup
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
595
268
687
302
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
697
29
999
166
age of insulation [a]
NIL
NIL
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"roof" 0.1 0 -14070903 true "" "histogram [age-roof-ins] of homeowners"
"wall" 0.1 0 -14439633 true "" "histogram [age-wall-ins] of homeowners"
"floor" 0.1 0 -2674135 true "" "histogram [age-floor-ins] of homeowners"

PLOT
487
521
647
641
links homeowners
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
"default" 1.0 0 -16777216 true "" "histogram [count link-neighbors] of homeowners"

PLOT
697
282
998
402
age wall [a]
NIL
ho
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"paint" 1.0 0 -14730904 true "" "histogram [age-wall-paint] of homeowners"
"rendering" 1.0 0 -5298144 true "" "histogram [age-wall-rend] of homeowners with [age-wall-rend !=\"NA\"]"
"insulation" 1.0 0 -14333415 true "" "histogram [age-wall-ins] of homeowners"

PLOT
697
162
998
282
age roof [a]
NIL
ho
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"roofing" 1.0 0 -16777216 true "" "histogram [age-roofing] of homeowners"
"insulation" 1.0 0 -14333415 true "" "histogram [age-roof-ins] of homeowners"

PLOT
697
402
998
522
age windows [a]
NIL
ho
0.0
60.0
0.0
10.0
true
true
"" ""
PENS
"windows" 1.0 0 -14730904 true "" "histogram [age-windows] of homeowners"

PLOT
997
282
1298
402
rate wall  [%]
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"paint" 1.0 0 -14070903 true "" "plot rate-wall-paint"
"rendering" 1.0 0 -5298144 true "" "plot rate-wall-rend"
"insulation" 1.0 0 -12087248 true "" "plot rate-wall-ins"

PLOT
997
162
1298
282
rate roof [%]
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"roofing" 1.0 0 -16777216 true "" "plot rate-roofing"
"insulation" 1.0 0 -15575016 true "" "plot rate-roof-ins"

PLOT
997
402
1297
522
rate windows [%]
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"windows" 1.0 0 -16777216 true "" "plot rate-windows"
"triple-windows" 1.0 0 -15040220 true "" "plot rate-triple-windows"

PLOT
697
520
998
640
age [a]
NIL
ho
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"floor insulation" 1.0 0 -16777216 true "" "histogram [age-floor-ins] of homeowners"
"heating system" 1.0 0 -7500403 true "" "histogram [age-heating-sys] of homeowners"

PLOT
997
520
1298
640
rate [%]
NIL
NIL
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"floor insulation" 1.0 0 -16777216 true "" "plot rate-floor-ins"
"heating system" 1.0 0 -7500403 true "" "plot rate-heating-sys"

PLOT
327
521
487
641
attitude homeowners
NIL
NIL
-1.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.01 1 -16777216 true "" "histogram [attitude] of homeowners"

PLOT
7
521
167
641
age homeowners
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [age] of homeowners"

PLOT
1296
215
1578
402
share pos soc-imp per lifestyle
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"1" 1.0 0 -16777216 true "" "plot count homeowners with [lifestyle-nr = 1 and as-inf > 0] / (count homeowners with [lifestyle-nr = 1] + 1)"
"2" 1.0 0 -7500403 true "" "plot count homeowners with [lifestyle-nr = 2 and as-inf > 0] / (count homeowners with [lifestyle-nr = 2] + 1)"
"3" 1.0 0 -2674135 true "" "plot count homeowners with [lifestyle-nr = 3 and as-inf > 0] / (count homeowners with [lifestyle-nr = 3] + 1)"
"4" 1.0 0 -955883 true "" "plot count homeowners with [lifestyle-nr = 4 and as-inf > 0] / (count homeowners with [lifestyle-nr = 4] + 1)"
"5" 1.0 0 -6459832 true "" "plot count homeowners with [lifestyle-nr = 5 and as-inf > 0] / (count homeowners with [lifestyle-nr = 5] + 1)"
"6" 1.0 0 -1184463 true "" "plot count homeowners with [lifestyle-nr = 6 and as-inf > 0] / (count homeowners with [lifestyle-nr = 6] + 1)"
"7" 1.0 0 -10899396 true "" "plot count homeowners with [lifestyle-nr = 7 and as-inf > 0] / (count homeowners with [lifestyle-nr = 7] + 1)"
"8" 1.0 0 -13840069 true "" "plot count homeowners with [lifestyle-nr = 8 and as-inf > 0] / (count homeowners with [lifestyle-nr = 8] + 1)"
"9" 1.0 0 -14835848 true "" "plot count homeowners with [lifestyle-nr = 9 and as-inf > 0] / (count homeowners with [lifestyle-nr = 9] + 1)"

PLOT
167
521
327
641
income homeowners
NIL
NIL
0.0
8000.0
0.0
10.0
true
false
"" ""
PENS
"default" 100.0 1 -16777216 true "" "histogram [income] of homeowners"

PLOT
997
29
1299
164
EER rate [%]
NIL
NIL
0.0
1.0
0.0
2.5
true
true
"" ""
PENS
"EER rate" 1.0 0 -16777216 true "" "plot tot-EER-rate"
"av. EER rate" 1.0 0 -9276814 true "" "plot av-EER-rate"
"wall-ins" 1.0 0 -11085214 true "" "plot rate-wall-ins"
"floor-ins" 1.0 0 -13791810 true "" "plot rate-floor-ins"
"triple-wind" 1.0 0 -7858858 true "" "plot rate-triple-windows"
"roof-ins" 1.0 0 -955883 true "" "plot rate-roof-ins"

PLOT
1297
402
1578
522
backlog insulation
NIL
NIL
0.0
10.0
0.0
0.2
true
true
"" ""
PENS
"roof" 1.0 0 -3844592 true "" "plot backlog-roof-ins * 4"
"wall" 1.0 0 -14439633 true "" "plot backlog-wall-ins * 2"
"floor" 1.0 0 -14454117 true "" "plot backlog-floor-ins * 1 / 0.12"
"windows" 1.0 0 -7858858 true "" "plot backlog-windows * 1 / 0.13"
"total" 1.0 0 -16777216 true "" "plot tot-ins-backlog"

MONITOR
506
346
624
391
annual EER rate [%]
round (100 * (0.25 * rate-roof-ins + 0.5 * rate-wall-ins + 0.12 * rate-floor-ins + 0.13 * rate-triple-windows)) / 100
17
1
11

PLOT
1298
520
1578
640
backlog rest
NIL
NIL
0.0
10.0
0.0
0.2
true
true
"" ""
PENS
"roofing" 1.0 0 -16777216 true "" "plot count homeowners with [age-roofing > life-roofing] / (1 + count homeowners)"
"wall-paint" 1.0 0 -14070903 true "" "plot count homeowners with [age-wall-paint > life-wall-paint] / (1 + count homeowners)"
"wall-rend" 1.0 0 -2674135 true "" "plot count homeowners with [wall-rend? = true and age-wall-rend > life-wall-rend] / (1 + count homeowners with [wall-rend? = true])"
"heating-sys" 1.0 0 -955883 true "" "plot count homeowners with [age-heating-sys > life-heating-sys] / (1 + count homeowners)"

TEXTBOX
505
105
641
141
DECISION MAKING
14
0.0
1

TEXTBOX
506
12
693
31
SPATIAL STRUCTURE
14
0.0
1

SLIDER
503
126
687
159
av-att
av-att
-1
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
503
158
687
191
weight-soc-ben
weight-soc-ben
0
10
5
1
1
NIL
HORIZONTAL

MONITOR
506
392
624
437
average EER rate [%]
round (100 * av-EER-rate) / 100
17
1
11

PLOT
1296
30
1578
216
average EER rate per lifestyle  [%]
NIL
NIL
0.0
10.0
0.0
0.01
true
true
"" ""
PENS
"1" 1.0 0 -16777216 true "" "plot av-EER-rate-M1"
"2" 1.0 0 -7500403 true "" "plot av-EER-rate-M2"
"3" 1.0 0 -2674135 true "" "plot av-EER-rate-M3"
"4" 1.0 0 -955883 true "" "plot av-EER-rate-M4"
"5" 1.0 0 -6459832 true "" "plot av-EER-rate-M5"
"6" 1.0 0 -1184463 true "" "plot av-EER-rate-M6"
"7" 1.0 0 -10899396 true "" "plot av-EER-rate-M7"
"8" 1.0 0 -13840069 true "" "plot av-EER-rate-M8"
"9" 1.0 0 -14835848 true "" "plot av-EER-rate-M9"

CHOOSER
506
444
644
489
view
view
"nothing" "roof_ins" "wall_ins" "floor_ins" "eff_wind" "age-owners" "age-houses" "income" "attitude" "assessed-inf" "at + as-inf" "eff-ren" "lifestyle" "network" "decisions"
12

SLIDER
504
206
688
239
fin-con
fin-con
0
10
5
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
##Model description##
The ODD protocol is available at www.openabm.org/model/4419
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
NetLogo 5.1.0
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

@#$#@#$#@
0
@#$#@#$#@
