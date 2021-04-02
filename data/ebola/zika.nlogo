extensions [vid]
globals [contact-rate-home contact-rate-hospital contact-rate-work-school vaccination-strategy-done vaccination-strategy-trigger
  delay-days _recording-save-file-name
  infected
  dead
  recovered
]

;breed定義
breed [people person]
breed [mosquitos mosquito]

;turtles-own [
people-own [
  town          ;タウン
  adult         ;大人
  medical-staff ;病院勤務者
  destination   ;通勤通学先
  contagious    ;感染
  hxc           ;homeのx座標
  hyc           ;homeのy座標
  cdays         ;感染日数
  place         ;現在地 0:home, 1:train, 2:work or school, 3:hospital, 10:morg
  vaccination  ;ワクチン接種
  contact-record  ;quenched-strategyの準備開始
  quanched-delay-days        ;quenched-strategyの遅れ日数
]

mosquitos-own [
  contagious    ;感染
  days          ;生存日数
  area          ;発生場所
  place         ;現在地
  cdays         ;感染日数
]

to make-movie
  ;; prompt user for movie location
  user-message "First, save your new movie file (choose a name ending with .mov)"
  let path user-new-file
  if not is-string? path [ stop ]  ;; stop if user canceled

  ;; run the model
  setup
  set _recording-save-file-name path
  vid:start-recorder
  ;movie-grab-view
  vid:record-interface
  while [count turtles with [color = green or color = yellow or color = red or color = violet] > 0 ]
    [ go
      ;movie-grab-view
      vid:record-interface
    ]

  ;; export the movie
  vid:save-recording _recording-save-file-name
  user-message (word "Exported movie to " path)
end

to setup
  clear-all
  set contact-rate-home 1.0
  set contact-rate-hospital 1.0
  set contact-rate-work-school 0.3
  set vaccination-strategy-done false
  set vaccination-strategy-trigger false
  set delay-days 0
  ;set n-of-vaccine 0  ;隔離政策のワクチン接種数　病院勤務者10名

  if disease-type = "smallpox" [
    set contagious-rate 0.2
    set fatality-rate 0.3
  ]

  if disease-type = "ebola-fever" [
    set contagious-rate 0.2
    set fatality-rate 0.9
  ]

  if disease-type = "zika" [
    set contagious-rate 0.2
    set fatality-rate 0
  ]

  ask patches [
    if pxcor <= 0 and pycor >= 0 [ set pcolor 52 ]
    if pxcor <= 0 and pycor <= 0 [ set pcolor 82 ]
    if pxcor >= 0 and pxcor <= max-pxcor and pycor >= 0 [ set pcolor 53 ]
    if pxcor >= 0 and pxcor <= max-pxcor and pycor <= 0 [ set pcolor 83 ]
    if pxcor >= 10 and pxcor <=  20 and pycor >= -5 and pycor <= 5 [ set pcolor 7 ]
    if pxcor >= 22 and pxcor <=  32 and pycor >= -5 and pycor <= 5 [ set pcolor 5 ]
    if railway = true [
      ;鉄道
      if pxcor >= -35 and pxcor <= 5 and pycor >= -1 and pycor <= 1 [ set pcolor 25]
    ]
  ]

  ;square townの住民
  let xc 0
  let yc 0
  let iv1 3
  let iv2 1
  ;create-turtles 100 [
  create-people 100 [
    set color blue
    set shape "square"
    set town "square"
    set destination "square"
    set adult true
    set contagious 0
    set place 0
    set cdays -1
    setxy (min-pxcor + xc * iv1 + 5) (max-pycor - yc - 5)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    hatch 1 [
      setxy xcor + iv2 ycor
    ]
    hatch 1 [
      set color 106
      set adult false
      setxy xcor ycor - iv2
    ]
    hatch 1 [
      set color 106
      set adult false
      setxy xcor + iv2 ycor - iv2
    ]
  ]

  ;circle townの住民
  set xc 0
  set yc 0
  set iv1 3
  set iv2 1
  ;create-turtles 100 [
  create-people 100 [
    set color blue
    set shape "circle"
    set town "circle"
    set destination "circle"
    set adult true
    set contagious 0
    set place 0
    set cdays -1
    setxy (min-pxcor + xc * iv1 + 5) (0 - yc - 5)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    hatch 1 [
      setxy xcor + iv2 ycor
    ]
    hatch 1 [
      set color 106
      set adult false
      setxy xcor ycor - iv2
    ]
    hatch 1 [
      set color 106
      set adult false
      setxy xcor + iv2 ycor - iv2
    ]
  ]

  ;homeの位置を記憶
  ;ask turtles [
  ask people [
    set hxc xcor
    set hyc ycor
    set contagious 0
    set contact-record false
    set quanched-delay-days 0
    set vaccination false
    set medical-staff false
  ]

  ;医療従事者を設定
  ;ask n-of (num-of-medical-staff * 0.5) turtles with [adult = true and town = "square"][
  ask n-of (num-of-medical-staff * 0.5) people with [adult = true and town = "square"][
    set medical-staff true
  ]
  ;ask n-of (num-of-medical-staff * 0.5) turtles with [adult = true and town = "circle"][
  ask n-of (num-of-medical-staff * 0.5) people with [adult = true and town = "circle"][
    set medical-staff true
  ]

  ;隣町へ通う人を設定
  ;ask n-of 20 turtles with [adult = true and town = "square" and medical-staff = false][
  ask n-of 20 people with [adult = true and town = "square" and medical-staff = false][
    set destination "circle"
  ]
  ;ask n-of 20 turtles with [adult = true and town = "circle" and medical-staff = false][
  ask n-of 20 people with [adult = true and town = "circle" and medical-staff = false][
    set destination "square"
  ]

  ;Mosquito
  let n-mosquiots 200
  if disease-type = "zika" [
    if mq-place = "town" or mq-place = "all" or mq-place = "no-station" [
      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) - 15 (random-float 10) + 15
        set area "circle"
        set cdays -1
      ]
      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) - 15 (random-float 10) - 24
        set area "square"
        set cdays -1
      ]
    ]

    if mq-place = "school" or mq-place = "all" or mq-place = "no-station"[
      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) + 21 (random-float 10) + 15
        set area "c-school"
        set cdays -1
      ]

      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) + 21 (random-float 10) - 24
        set area "s-school"
        set cdays -1
      ]
    ]

    if mq-place = "office" or mq-place = "all" or mq-place = "no-station" [
      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) + 10 (random-float 10) + 15
        set area "c-office"
        set cdays -1
      ]

      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) + 10 (random-float 10) - 24
        set area "s-office"
        set cdays -1
      ]
    ]

    if mq-place = "station" or mq-place = "all" [
      create-mosquitos n-mosquiots [
        set color brown
        set shape "bug"
        set contagious 0
        setxy  (random-float 10) - 35 (random-float 8) - 3
        set area "station"
        set cdays -1
      ]
    ]

    if mq-place = "nowhere" [
      create-mosquitos 0
    ]

  ]


  ;1人が感染
  ;ask one-of turtles [
  ifelse disease-type = "zika" [
    ask one-of people with [xcor > -15 and ycor > 15 and ycor < 25] [
      set contagious 1
      set color green
      set cdays 0
    ]
  ][
    ask one-of people [
      set contagious 1
      set color green
      set cdays 0
    ]
  ]



  ;; start the clock
  reset-ticks
end


to go
  ;鉄道モデルなら駅に行って電車に乗る
  if railway = true [railway-commute
    ifelse disease-type = "zika" [
      ;蚊の移動と感染
      fly-mosquitos
      contagion-zika
    ][
      contagion
    ]
    display wait wait-t
  ]
  if quenched = true [contact-tracing]
  if serum != "none" [contact-tracing]

  ;職場か学校へ行く
  move2work-school
  ifelse disease-type = "zika" [
    ;蚊の移動と感染
    fly-mosquitos
    contagion-zika
  ][
    contagion
  ]
  display
  wait wait-t
  if quenched = true [contact-tracing]
  if serum != "none" [contact-tracing]

  ;鉄道モデルなら駅に行って電車に乗る
  if railway = true [railway-commute
    ifelse disease-type = "zika" [
      ;蚊の移動と感染
      fly-mosquitos
      contagion-zika
    ][
      contagion
    ]
    display wait wait-t
  ]

  ;帰宅する
  move2home
  ifelse disease-type = "zika" [
    ;蚊の感染
    fly-mosquitos
    contagion-zika
  ][
    contagion
  ]
  display
  wait wait-t
  if quenched = true [contact-tracing]
  if serum != "none" [contact-tracing]

  ;翌日
  add-days
  if vaccine = true [vaccination-strategy]
  if quenched = true [vaccine-injection]
  if serum != "none" [serum-injection]


  set dead (count people with [color = black] )
  set infected (count people with [color = green or color = yellow or color = red or color = orange])
  set recovered (count people with [color = white])

  ;終了条件
  ;if count turtles with [color = green or color = yellow or color = red or color = violet] = 0 [stop]
;  if count people with [color = green or color = yellow or color = red or color = violet] = 0
 ;   and count mosquitos with [color != brown] = 0 [stop]
  tick
end

to fly-mosquitos
  if mq-place = "town" or mq-place = "all" or mq-place = "no-station" [
    ;circleタウン
    ask mosquitos with [area = "circle"][
      right random 360
      if xcor > -5 or xcor < -15 or ycor > 25 or ycor < 15 [facexy -5 20]
      forward 1]

    ;squareタウン
    ask mosquitos with [area = "square"][
      right random 360
      if xcor > -5 or xcor < -15 or ycor > -14 or ycor < -24 [facexy -5 -19]
      forward 1]
  ]

  if mq-place = "school" or mq-place = "all" or mq-place = "no-station" [
    ;circle学校
    ask mosquitos with [area = "c-school"][
      right random 360
      if xcor > 31 or xcor < 21 or ycor > 25 or ycor < 15 [facexy 30 20]
      forward 1]

    ;square学校
    ask mosquitos with [area = "s-school"][
      right random 360
      if xcor > 31 or xcor < 21 or ycor > -14 or ycor < -24 [facexy 30 -19]
      forward 1]
  ]

  if mq-place = "office" or mq-place = "all" or mq-place = "no-station" [
    ;circleオフィス
    ask mosquitos with [area = "c-office"][
      right random 360
      if xcor > 20 or xcor < 10 or ycor > 25 or ycor < 15 [facexy 10 20]
      forward 1]

    ;squareオフィス
    ask mosquitos with [area = "s-office"][
      right random 360
      if xcor > 20 or xcor < 10 or ycor > -14 or ycor < -24 [facexy 10 -19]
      forward 1]
  ]

  if mq-place = "station" or mq-place = "all" [
    ;鉄道駅
    ask mosquitos with [area = "station"][
      right random 360
      if xcor > -25 or xcor < -35 or ycor > 4 or ycor < -3 [facexy -30 1]
      forward 1]
  ]
end

;鉄道を利用
to railway-commute
  ;ask turtles with [adult = true and medical-staff = false and place < 10 and color != yellow][
  ask people with [adult = true and medical-staff = false and place < 10 and color != yellow][
    setxy (random-float 40) - 35 (random-float 2) - 1
    set place 1
  ]
end

;職場か学校に通う
to move2work-school
  let xc 0
  let yc 0
  let iv1 1

  ;ask turtles with [destination = "square" and adult = true and medical-staff = false and place < 3 and color != yellow][
  ask people with [destination = "square" and adult = true and medical-staff = false and place < 3 and color != yellow][
    setxy (10 + xc * iv1 ) (max-pycor - 10 - yc)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    set place 2
  ]

  set xc 0
  set yc 0
  ;ask turtles with [destination = "square" and adult = false and place < 3 and color != yellow][
  ask people with [destination = "square" and adult = false and place < 3 and color != yellow][
    setxy (22 + xc * iv1 ) (max-pycor - 10 - yc)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    set place 2
  ]

  set xc 0
  set yc 0
  ;ask turtles with [destination = "circle" and adult = true and medical-staff = false and place < 3 and color != yellow][
  ask people with [destination = "circle" and adult = true and medical-staff = false and place < 3 and color != yellow][
    setxy (10 + xc * iv1 ) ( - 10 - yc)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    set place 2
  ]

  set xc 0
  set yc 0
  ;ask turtles with [destination = "circle" and adult = false and place < 3 and color != yellow][
  ask people with [destination = "circle" and adult = false and place < 3 and color != yellow][
    setxy (22 + xc * iv1 ) ( - 10 - yc)
    set xc xc + 1
    if xc >= 10 [
      set xc 0
      set yc yc + iv1
    ]
    set place 2
  ]

  ;病院へ通う
  ;ask turtles with [medical-staff = true and place < 10 and color != yellow][
  ask people with [medical-staff = true and place < 10 and color != yellow][
    setxy (random-float 10) + 10 (random-float 10) - 5
    set place 3
  ]

end

;自宅に戻る
to move2home
  ;ask turtles with [place < 10 and color != red and color != violet] [
  ask people with [place < 10 and color != red and color != violet] [
    setxy hxc hyc
    set place 0
  ]
end

;接触・感染
to contagion
  let contact-rate 0
  let cg-rate 0
  ;ask turtles with [contagious = 1][
  ask people with [contagious = 1][
    if disease-type = "smallpox" [
      ;感染して12日間は症状が出ない潜伏期（緑）
      if cdays >= 0 and cdays <= 11 [set color green]

      ;感染して4日目までにワクチンを打たないと罹患してしまう
      ;12日を過ぎると発熱症状が出て人に感染するが、天然痘かどうかは不明（黄）
      if cdays >= 12 and cdays <= 15 [set color yellow]

      ;15日を過ぎると発疹が出て、天然痘とわかる（赤）
      ;16日〜19日の感染率は、12日〜15日の感染率の2倍
      if cdays >= 15 and cdays <= 19 [set color red]

      ;この状態で翌日（12時間後）に病院に搬送される
      if cdays = 16 [set place 3] ;病院へ

      ;20日以降の感染率は、12日〜15日と同じ
      ;発疹の最終期は12日の伝染力の値に戻る
      if cdays >= 20 and cdays <= 23 [set color violet]

      ;16〜23日の死亡率は30％（黒）
      if cdays >= 16 and cdays <= 23 [
        if random-float 1 < (fatality-rate / 8) [
          set color black
          set place 10
          set contagious 2
          set cdays -1
        ]
      ]

      ;残りは回復して、免疫を持つ（白）
      if cdays = 24 and color != black [
        set color white
        ;自宅に戻る
        set place 0
        set cdays -1
      ]
    ]

    if disease-type = "ebola-fever" [
      ;感染して12日間は症状が出ない潜伏期、感染力はない（緑）
      if cdays >= 0 and cdays <= 6 [set color green]

      ;感染して血清を打たないと罹患してしまう
      ;発症後1-3日はインフルエンザに似た症状、エボラかどうかは不明（黄）
      if cdays >= 7 and cdays <= 9 [set color yellow]

      ;発症後4-7日で嘔吐・下痢出て、エボラとわかる（赤）
      ;感染率が高いかどうかは不明
      if cdays >= 10 and cdays <= 13 [set color red]

      ;この状態で翌日（12時間後）に病院に搬送される
      if cdays = 11 [set place 3] ;病院へ

      ;発症後7-10日末期症状
      if cdays >= 14 and cdays <= 16 [set color violet]

      ;16〜23日の死亡率は90％（黒）
      if cdays >= 14 and cdays <= 16 [
        if random-float 1 < (fatality-rate / 3) [
          set color black
          set place 10
          set contagious 2
          set cdays -1
        ]
      ]

      ;残りは回復して、免疫を持つ（白）
      if cdays = 17 and color != black [
        set color white
        ;自宅に戻る
        set place 0
        set cdays -1
      ]
    ]

    ;黄色の人は0.5の率で病院へ通う
    if color = yellow [
      if random-float 1 < 0.5 [
        setxy  (random-float 10) + 10 (random-float 10) - 5
        set place 3
      ]
    ]


    ;病院へ移動
    if place = 3 [
      setxy  (random-float 10) + 10 (random-float 10) - 5
    ]

    ;安置所へ移動
    if place = 10 [
      setxy  (random-float 10) + 22 (random-float 10) - 5
    ]

    ;場所によって接触率が異なる
    if place = 0 [set contact-rate contact-rate-home]
    if place = 1 [set contact-rate contact-rate-work-school]
    if place = 2 [set contact-rate contact-rate-work-school]
    if place = 3 [
      ifelse color = red or color = violet
        [set contact-rate (1 - hsptl-quar-rate)] ;症状が出たら病院で隔離する
        [set contact-rate contact-rate-hospital] ;症状前なら病院で隔離しない
    ]

    ;感染日数で感染率が異なる
    if color = green [set cg-rate 0]
    if color = yellow or color = violet [set cg-rate contagious-rate]
    if color = red [
      if disease-type = "smallpox" [set cg-rate contagious-rate * 2]
      if disease-type = "ebola-fever" [set cg-rate contagious-rate]
    ]

    ;ムーア近傍の人に感染
    ;ask turtles-on neighbors [
    ask people-on neighbors [
      if contagious = 0 [
        if vaccination = false [
          if (random-float 1) < contact-rate * cg-rate [
            set contagious 1
            set cdays 0
          ]
        ]
      ]
    ]
  ]

end

;接触・感染 Zika
to contagion-zika
  let contact-rate 0
  let cg-rate 0
  ;ask turtles with [contagious = 1][
  ask people with [contagious = 1][
    ;感染して3から9日間は症状が出ない潜伏期（緑）
    let latent-period 3 + random 9
    if cdays >= 0 and cdays <= latent-period [set color green]

    ;潜伏期間後，症状が出て病院ヘ行く
    if cdays >= latent-period + 1 [
      set color violet
      set place 3
    ]

    ;病院へ移動
    if place = 3 [
      setxy  (random-float 10) + 10 (random-float 10) - 5
    ]

    ;翌日に自宅に戻る，６日間（４〜７日）症状が持続する
    if cdays >= latent-period + 2 [
      set place 0
      setxy hxc hyc
    ]

    ;回復して、免疫を持つ（白）
    if cdays >= latent-period + 8 [
      set color white
      set cdays -1
      ;set contagious 0
    ]

    ;接触率　蚊は4日に1回刺す
    set contact-rate 0.2

    ;感染率　不顕性感染率が0.8でも感染する わからないので0.5にする
    ifelse color = green or color = violet [
      set cg-rate 0.5][
      set cg-rate 0
    ]

    ;ムーア近傍の蚊に感染
    ;show count mosquitos-on neighbors
    ;show count mosquitos-here
    ;ask mosquitos-on neighbors [
    ask mosquitos-here [
      if (random-float 1) < contact-rate [
        set contagious 1
        set color cyan
        set cdays 0
        ;show "mosquitos"
      ]
    ]
  ]

  ;感染している蚊から人が感染 蚊は感染してから10日（8-12日）で感染状態になり，感染できる
  ;これはデング熱を利用
  ask mosquitos with [contagious = 1 and cdays >= 10][
    ;show "m-cont"
    ;show count people-on neighbors
    set color yellow
    ;ask people-on neighbors [
    ask people-here [
        ;show "p0"
      if contagious = 0 [
        if color = green or color = red [set cg-rate 0.8]
        if (random-float 1) < contact-rate * cg-rate [
          set contagious 1
          set cdays 0
        ]
      ]
    ]
  ]
end


;感染者は経過日数を更新
to add-days
  ;ask turtles with [cdays >= 0][
  ask people with [cdays >= 0][
    set cdays cdays + 1
  ]
  ;蚊の寿命は30日
  ask mosquitos [
    set days days + 1
    if days > 30 [
      set contagious 0
      set color brown
      set days 0
      set cdays -1
    ]
    if cdays >= 0 [set cdays cdays + 1]
  ]
end

;全員にワクチン接種
to vaccination-strategy
  ;if count turtles with [color = red] >= 1 [set vaccination-strategy-trigger true]
  if count people with [color = red] >= 1 [set vaccination-strategy-trigger true]
  if vaccination-strategy-trigger = true and vaccination-strategy-done = false [
    ;遅れ時間
    ifelse delay-days >= trace-delay [
      ;全員へワクチン接種
      let i 0
      ;ask turtles [
      ask people [
        ;１回で投与できるワクチンの数
        if i > n-of-injection [stop]
        set i i + 1

        if random-float 1 < vaccination-rate [
          set vaccination true
          ;感染から4日以内なら治る
          if cdays <= 4 [
            set contagious 0
            set color blue
            set cdays -1
          ]
        ]
      ]
      set vaccination-strategy-done true
    ][
      set delay-days delay-days + 1
    ]
  ]
end

to contact-tracing
  ;病院勤務者へ接種 or 病院勤務者は防護服着用
  ;if count turtles with [color = red] >= 1 [
  if count people with [color = red] >= 1 [
    ;ask turtles with [medical-staff = true][
    ask people with [medical-staff = true][
    set vaccination true
    ]
  ]

  ;感染力の有る患者へ接触コンタクトした人をトレース
  ;電車通勤は急速に患者が増えるが、トレースした人を確実にケアするようだ
  ;ask turtles with [color = yellow or color = red or color = violet][
  ask people with [color = yellow or color = red or color = violet][
    if place = 0 [ ;家族は100％トレース
      ;ask turtles-on neighbors [set contact-record true]
      ask people-on neighbors [set contact-record true]
    ]
    if place = 2 [ ;職場・学校をtrace-rate率でトレース
      ;ask turtles-on neighbors [
      ask people-on neighbors [
        if random-float 1 < trace-rate [
          set contact-record true
        ]
      ]
    ]
    ;電車内は0％トレース
  ]
end

;接触した人にワクチン接種
to vaccine-injection
  let i 0
  ;ask turtles with [contact-record = true and vaccination = false][
  ask people with [contact-record = true and vaccination = false][
    ;１回で投与できるワクチンの数
    if i > n-of-injection [stop]
    set i i + 1
    ifelse quanched-delay-days >= trace-delay [
      set vaccination true
      ;set n-of-vaccine n-of-vaccine + 1
      ;感染から4日以内なら治る
      if cdays >= 0 and cdays <= 4 [
        set contagious 0
        set color blue
        set cdays -1
        set contact-record false
      ]
    ][
      set quanched-delay-days quanched-delay-days + 1
    ]
  ]
end

;接触した人に血清接種
to serum-injection
  let i 0
  ;トレース出来た人全員に血清投与
  if serum = "all-contact" [
    ;ask turtles with [contact-record = true and vaccination = false and color != black][
    ask people with [contact-record = true and vaccination = false and color != black][
      ;１回で投与できる血清の数
      if i > n-of-injection [stop]
      set i i + 1
      ifelse quanched-delay-days >= trace-delay [
        ;set n-of-vaccine n-of-vaccine + 1
        ;serum-effectで治るかどうか決まる
        if random-float 1 < serum-effect and color != violet [
          set vaccination true
          set contagious 0
          set color blue
          set cdays -1
        ]
        ;血清投与は１回だけ
        set contact-record false
      ][
        set quanched-delay-days quanched-delay-days + 1
      ]
    ]
  ]

  ;トレースした発症者に血清投与
  if serum = "symptoms" [
    ;ask turtles with [contact-record = true and vaccination = false
    ask people with [contact-record = true and vaccination = false
      and (color = yellow or color = red)][
      ;１回で投与できる血清の数
      if i > n-of-injection [stop]
      set i i + 1
      ifelse quanched-delay-days >= trace-delay [
        ;set n-of-vaccine n-of-vaccine + 1
        ;serum-effectで治るかどうか決まる
        if random-float 1 < serum-effect and color != violet [
          set vaccination true
          set contagious 0
          set color blue
          set cdays -1
        ]
        ;血清投与は１回だけ
        set contact-record false
      ][
        set quanched-delay-days quanched-delay-days + 1
      ]
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
295
10
870
586
-1
-1
7.0
1
24
1
1
1
0
1
1
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
80
115
146
148
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
10
115
76
148
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

PLOT
10
150
285
335
Number of infected people
Time
Rate
0.0
10.0
0.0
0.3
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plotxy ticks (count people with [color = green or color = yellow or color = red or color = orange])"
"Dead" 1.0 0 -16777216 true "" "plotxy ticks (count people with [color = black] )"
"Recovered" 1.0 0 -7500403 true "" "plotxy ticks (count people with [color = white])"

MONITOR
185
10
235
55
Days
ticks
17
1
11

SLIDER
10
10
180
43
num-of-medical-staff
num-of-medical-staff
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
45
182
78
contagious-rate
contagious-rate
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
120
470
290
503
vaccination-rate
vaccination-rate
0
1
1.0
0.01
1
NIL
HORIZONTAL

SWITCH
10
470
115
503
vaccine
vaccine
1
1
-1000

SWITCH
10
505
115
538
quenched
quenched
1
1
-1000

SLIDER
10
350
145
383
trace-delay
trace-delay
0
30
3.0
1
1
NIL
HORIZONTAL

MONITOR
235
10
290
55
Fatalities
count turtles with [color = black]
17
1
11

CHOOSER
185
65
285
110
disease-type
disease-type
"smallpox" "ebola-fever" "zika"
1

SLIDER
120
555
292
588
serum-effect
serum-effect
0
1
0.0
0.01
1
NIL
HORIZONTAL

MONITOR
120
505
212
550
n-of-vaccine
count turtles with [vaccination = true]
17
1
11

SLIDER
150
350
290
383
trace-rate
trace-rate
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
10
80
182
113
fatality-rate
fatality-rate
0
1
0.9
0.01
1
NIL
HORIZONTAL

TEXTBOX
10
540
160
558
ebola
11
0.0
1

TEXTBOX
10
455
160
473
smallpox
11
0.0
1

TEXTBOX
10
335
160
353
common
11
0.0
1

SWITCH
185
115
285
148
railway
railway
0
1
-1000

SLIDER
10
420
145
453
wait-t
wait-t
0
0.5
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
150
385
290
418
hsptl-quar-rate
hsptl-quar-rate
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
385
145
418
n-of-injection
n-of-injection
0
800
400.0
1
1
NIL
HORIZONTAL

CHOOSER
10
555
115
600
serum
serum
"none" "symptoms" "all-contact"
2

CHOOSER
150
420
288
465
mq-place
mq-place
"all" "town" "school" "office" "station" "no-station" "nowhere"
5

BUTTON
215
505
282
538
movie
make-movie
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?
天然痘(Smallpox）モデル
1950年〜1971年にヨーロッパで起きた49の感染発生を元にモデルを構築している。
感染後の病気の死亡率は30％で、患者との接触で感染が拡大する。

エボラ出血熱（Ebola fever）モデル
1900年〜2014年にアフリカで発生した　の感染発生を元にモデルを構築している。
感染後の病気の死亡率は90％で、患者との接触で感染が拡大する。

## HOW IT WORKS

スクエアタウンとサークルタウンという２つの町にそれぞれ100家族が居住している。
各家族は、職場に通う親２人と学校に通う子供２人の４人家族で、全人口は800人となる。
全員が昼間は、それぞれの住居のある町の職場および学校に通うが、大人の10％は隣の町に通っている。
病院は共同で一つあり、それぞれの町から5人、合計10人が病院で働いている。

各自は、自宅・職場・学校で他の人と交流（インタラクション）が発生する。自宅では家族との交流があり、
職場はいつも同じだが、席は毎日で異なる
各ラウンドで、全エージェントはインタラクションがある
ムーア8近傍の人を認識し、ランダムにインタラクションが発生する
1ラウンドでムーア近傍の中の1人とインタラクションする
1回のインタラクションで職場・学校なら0.3、家庭・病院なら1.0の確率でコンタクト発生する
1回のコンタクトで期間によって0.2、0.4の確率で感染する

## HOW TO USE IT

To use the model, set the NUMBER-STRATEGIES, OVERCROWDING-THRESHOLD and MEMORY size, press SETUP, and then GO.

The plot shows the average attendance at the bar over time.

## THINGS TO NOTICE

The green part of the world represents the homes of the patrons, while the blue part of the world represents the El Farol Bar.  Over time the attendance will increase and decrease but its mean value comes close to the OVERCROWDING-THRESHOLD.

## THINGS TO TRY

Try running the model with different settings for MEMORY-SIZE and NUMBER-STRATEGIES.  What happens to the variability in attendance as you decrease NUMBER-STRATEGIES?  What happens to the variability in the plot if you decrease MEMORY-SIZE?

## EXTENDING THE MODEL

Currently the weights that determine each strategy are randomly generated.  Try altering the weights so that they only reflect a mix of the following agent strategies:
- always predict the same as last week's attendance
- an average of the last several week's attendance
- the same as 2 weeks ago
Can you think of other simple rules one might follow?

At the end of Arthur's original paper, he mentions that though he uses a simple learning technique (the "bag of strategies" method) almost any other kind of machine learning technique would achieve the same results.  In fact Fogel et al. implemented a genetic algorithm and got different results.  Try implementing another machine learning technique and see what the results are.

## NETLOGO FEATURES

Lists are used to represent strategies and attendance histories.

`n-values` is useful for generating random strategies.

## RELATED MODELS

Arthur's original model has been generalized as the Minority Game which also exists in the Models Library.  In addition there is a model called El Farol Network Congestion that uses the El Farol Bar Problem as a model of how to choose the best path in a network.  Finally, there is an alternative implementation of this model with more parameters that is part of the NetLogo User Community Models.

## CREDITS AND REFERENCES

This model is inspired by a paper by W. Brian Arthur. "Inductive Reasoning and Bounded Rationality", W. Brian Arthur, The American Economic Review, 1994, v84n2, p406-411.

David Fogel et al. also built a version of this model using a genetic algorithm.  "Inductive reasoning and bounded rationality reconsidered", Fogel, D.B.; Chellapilla, K.; Angeline, P.J., IEEE Transactions on Evolutionary Computation, 1999, v3n2, p142-146.


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Rand, W. and Wilensky, U. (2007).  NetLogo El Farol model.  http://ccl.northwestern.edu/netlogo/models/ElFarol.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2007 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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
  <experiment name="base" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="n-of-injection" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="600-of-injection" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="n-of-injection-trace" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="n-of-injection-trace" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base-ebola" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base-ebola600" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base-ebola200" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trace-ebola100" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trace-ebola50" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trace-ebola20" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trace-ebola10" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trace-ebola5" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rail-trace-ebola50" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rail-trace-ebola200" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rail-trace-ebola400" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rail-trace-ebola600" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = black]</metric>
    <metric>count turtles with [color = grey]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base-ebola100回" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="400-of-injection" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="400-quenched" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="400-quenched-delay5" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;smallpox&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ebola対策なし" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ebola集団400-100回" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ebola集団400-上限600-100回" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ebola血清上限400-100回" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [color = black]</metric>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;ebola-fever&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-all-norail" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-rail-nostation-0611" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;no-station&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-rail-town" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;town&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-all-office" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;office&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-rail-office" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;office&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zika-rail-station" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count people with [color = white]</metric>
    <enumeratedValueSet variable="vaccine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fatality-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum-effect">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-medical-staff">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-injection">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contagious-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quenched">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="railway">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace-delay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-t">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mq-place">
      <value value="&quot;station&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaccination-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="serum">
      <value value="&quot;symptoms&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hsptl-quar-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disease-type">
      <value value="&quot;zika&quot;"/>
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
