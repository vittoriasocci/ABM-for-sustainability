globals [new-node
         number-of-nodes_2
         old-node
         n-of-age-14-25
         n-of-age-25-40
         n-of-age-40-60
         n-of-age-Over60
         n-of-sex-F
         n-of-sex-M
         n-of-sex-Other
         n-of-sex-I-prefer-not-to-specify
         n-of-education-MiddleSchool
         n-of-education-HighSchool
         n-of-education-Degree
         n-of-education-I-prefer-not-to-specify
         ]

breed [nodes node]

nodes-own [age
           sex
           educational-level
           indifferent?
           score
           cooperate?
           old-cooperate?
           awareness
           color-class ;;numeric value from 1= blue, 2= red, 3= green, 4= yellow.
           ]
links-own [rewired?]

to setup
  ca ;; clear all
  if n-of-deniers + n-of-indifferents-SH + n-of-activists + n-of-indifferents-HD + n-of-indifferents-PD != total-number-of-agents
     [set total-number-of-agents n-of-deniers + n-of-indifferents-SH + n-of-activists + n-of-indifferents-HD + n-of-indifferents-PD
      output-print "Pay attention: the total sum is not equal to total-number-of-agents, therefore the total number of agents is changed"]
  ask patches [set pcolor grey]
  set-default-shape nodes "circle"
  set number-of-nodes_2 int(sqrt(total-number-of-agents))
  set total-number-of-agents number-of-nodes_2 * number-of-nodes_2
  SW-lattice-2D
  set n-of-age-14-25 43
  set n-of-age-25-40 75
  set n-of-age-40-60 112
  set n-of-age-Over60 total-number-of-agents - ( n-of-age-14-25 + n-of-age-25-40 + n-of-age-40-60 )
  set n-of-sex-F 182
  set n-of-sex-M 142
  set n-of-sex-Other 0
  set n-of-sex-I-prefer-not-to-specify total-number-of-agents - ( n-of-sex-F + n-of-sex-M + n-of-sex-Other )
  set n-of-education-MiddleSchool 28
  set n-of-education-HighSchool 135
  set n-of-education-Degree 161
  set n-of-education-I-prefer-not-to-specify total-number-of-agents - ( n-of-education-MiddleSchool + n-of-education-HighSchool + n-of-education-Degree )
  setup-age
  setup-sex
  setup-educational-level
  setup-type
  ask nodes with [label = "ACT" or label = "DEN"] [set indifferent? False]
  ask nodes with [label = "ACT"] [setup-cooperation True set awareness one-of [0.7 0.8 0.9 1.0] set shape "circle 3" set color blue set color-class 1]
  ask nodes with [label = "DEN"] [setup-cooperation False set awareness one-of [0.1 0.2 0.3 0.4] set shape "circle 3" set color red set color-class 2]
  ask nodes with [label = "SH" or label = "HD" or label = "PD"] [
    set indifferent? True
    set awareness one-of [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
    ifelse random-float 1.0 < (initial-cooperation / 100)
        [setup-cooperation True]
        [setup-cooperation False]
  ]
  ask nodes with [label = "SH" or label = "HD" or label = "PD"] [establish-color]
  ask nodes [update-plot]
  reset-ticks
end

to SW-lattice-2D

  let step-x (2 * max-pxcor / (number-of-nodes_2 + 1))   ;;These reporters (max-pxcor and max-pycor) provide the maximum x-coordinate and the maximum y-coordinate,
  let step-y (2 * max-pycor / (number-of-nodes_2 + 1))   ;;(respectively) for patches, which determine the size of the world.

  let xx (- max-pxcor + step-x)
  let yy (max-pycor - step-y)
  repeat number-of-nodes_2  ;;repeat number [ commands ] --> Runs commands number times.
  [
    repeat number-of-nodes_2
    [
      make-node
      ask new-node
      [setxy xx yy ;;setxy x y --> The turtle sets its x-coordinate to x and its y-coordinate to y.
      ]
      set old-node new-node
      set xx (xx + step-x)
    ]
    set xx (- max-pxcor + step-x)
    set yy (yy - step-y)
  ]

  let node-flag-x false
  let node-flag-y false
  let ii 0
  repeat number-of-nodes_2
  [
    repeat number-of-nodes_2
    [
      ask node ii
      [
       if node-flag-x [
          create-link-with (node (ii - 1)) [ set color black set rewired? false]
        ]
       if node-flag-y [
          create-link-with (node (ii - number-of-nodes_2)) [ set color black set rewired? false]
        ]
      ]
      set node-flag-x true
      set ii (ii + 1)
    ]
    set node-flag-x false
    set node-flag-y true
  ]

  let pp 0
  repeat number-of-nodes_2 - 1
  [
    repeat number-of-nodes_2 - 1
    [
      ask node pp
      [
        create-link-with (node (pp + number-of-nodes_2 + 1)) [set color black set rewired? false]
      ]
      set pp (pp + 1)
    ]
    set pp (pp + 1)
  ]

  let qq number-of-nodes_2
  repeat number-of-nodes_2 - 1
  [
    repeat number-of-nodes_2 - 1
    [
      ask node qq
      [
        create-link-with (node (qq - (number-of-nodes_2 - 1))) [set color black set rewired? false]
      ]
      set qq (qq + 1)
    ]
    set qq (qq + 1)
  ]

  if torus = "yes" [make-torus]

  ask links with [rewired? = false]
  [
  ;      without-interruption
;      [
        ;; whether to rewire it or not?
        if (random-float 1) < SW-rewiring-prob ;rewiring-probability
        [
          let node1 end1
          let old_node2 end2
          ;; find a link that does not have node1 as an estremum
          if any? links with [ (rewired? = false) and (end1 != node1) and (end2 != node1) and (end1 != old_node2) and (end2 != old_node2)   ]
          [ask one-of links with [ (rewired? = false) and (end1 != node1) and (end2 != node1) and (end1 != old_node2) and (end2 != old_node2) ]
             [
             let new_node2 end1
             let new_node3 end2
             ;; rewire the two edges
             ask node1 [ create-link-with new_node2 [ set color black set rewired? true ]]
             ask old_node2 [ create-link-with new_node3 [ set color black set rewired? true ] ]
             ask links with [(end1 = node1 and end2 = old_node2) or (end1 = old_node2 and end2 = node1)] [die]; ask node1 [ remove-link-with old_node2 ]
             ask links with [(end1 = new_node2 and end2 = new_node3) or (end1 = new_node3 and end2 = new_node2)] [die] ;ask new_node2 [ remove-link-with new_node3 ]
             ]
           ]
        ]
     ; ]
   ]


end

;; used for creating a new node
to make-node
  create-nodes 1
  [
    set color gray - 3
    set size nodes-size
    set new-node self ;; set the new-node global
  ]
end

to make-torus
  let jj 0
  repeat number-of-nodes_2
  [
    ask node jj
    [
      create-link-with (node (jj + number-of-nodes_2 - 1)) [set color black set rewired? false]
    ]
    set jj (jj + number-of-nodes_2)
  ]

  let kk 0
  repeat number-of-nodes_2
  [
    ask node kk
    [
      create-link-with (node (kk + ((number-of-nodes_2 - 1) * number-of-nodes_2))) [set color black set rewired? false]
    ]
    set kk (kk + 1)
  ]

  let hh 0
  repeat number-of-nodes_2 - 1
  [
    ask node hh
    [
      create-link-with (node (hh + (((number-of-nodes_2 - 1) * number-of-nodes_2) + 1))) [set color black set rewired? false]
    ]
    set hh (hh + 1)
  ]

  let gg 1
  repeat number-of-nodes_2 - 1
  [
    ask node gg
    [
      create-link-with (node (gg + (((number-of-nodes_2 - 1) * number-of-nodes_2) - 1))) [set color black set rewired? false]
    ]
    set gg (gg + 1)
  ]

  let rr 0
  repeat number-of-nodes_2 - 1
  [
    ask node rr
    [
      create-link-with (node (rr + number-of-nodes_2 + (number-of-nodes_2 - 1))) [set color black set rewired? false]
    ]
    set rr (rr + number-of-nodes_2)
  ]

  let ff number-of-nodes_2
  repeat number-of-nodes_2 - 1
  [
    ask node ff
    [
      create-link-with (node (ff - 1)) [set color black set rewired? false]
    ]
    set ff (ff + number-of-nodes_2)
  ]

  ask node 0 [create-link-with (node (total-number-of-agents - 1)) [set color black set rewired? false]]
  let uu number-of-nodes_2 - 1
  ask node uu [create-link-with (node (number-of-nodes_2 * (number-of-nodes_2 - 1))) [set color black set rewired? false]]
end

to setup-age
  let agents-selected n-of n-of-age-14-25 nodes
  ask agents-selected [set age "14-25"]
  let remaining-agents nodes with [not member? self agents-selected]
  let agents-selected1 n-of n-of-age-25-40 remaining-agents
  ask agents-selected1 [set age "25-40"]
  let remaining-agents1 remaining-agents with [not member? self agents-selected1]
  let agents-selected2 n-of n-of-age-40-60 remaining-agents1
  ask agents-selected2 [set age "40-60"]
  let remaining-agents2 remaining-agents1 with [not member? self agents-selected2]
  let agents-selected3 n-of n-of-age-Over60 remaining-agents2
  ask agents-selected3 [set age "Over 60"]
end

to setup-sex
  let nodes-selected n-of n-of-sex-F nodes
  ask nodes-selected [set sex "F"]
  let rem-nodes nodes with [not member? self nodes-selected]
  let nodes-selected1 n-of n-of-sex-M rem-nodes
  ask nodes-selected1 [set sex "M"]
  let rem-nodes1 rem-nodes with [not member? self nodes-selected1]
  let nodes-selected2 n-of n-of-sex-Other rem-nodes1
  ask nodes-selected2 [set sex "Other"]
  let rem-nodes2 rem-nodes1 with [not member? self nodes-selected2]
  let nodes-selected3 n-of n-of-sex-I-prefer-not-to-specify rem-nodes2
  ask nodes-selected3 [set sex "I prefer not to specify"]
end

to setup-educational-level
  let nod-sel n-of n-of-education-MiddleSchool nodes
  ask nod-sel [set educational-level "Middle School"]
  let rem-agents nodes with [not member? self nod-sel]
  let nod-sel1 n-of n-of-education-HighSchool rem-agents
  ask nod-sel1 [set educational-level "High School"]
  let rem-agents1 rem-agents with [not member? self nod-sel1]
  let nod-sel2 n-of n-of-education-Degree rem-agents1
  ask nod-sel2 [set educational-level "Degree"]
  let rem-agents2 rem-agents1 with [not member? self nod-sel2]
  let nod-sel3 n-of n-of-education-I-prefer-not-to-specify rem-agents2
  ask nod-sel3 [set educational-level "I prefer not to specify"]
end

to setup-type
  let act-agents-selected n-of n-of-activists nodes
  ask act-agents-selected [set label-color black set label "ACT"]
  let remaining-nodes nodes with [not member? self act-agents-selected]
  let den-agents-selected n-of n-of-deniers remaining-nodes
  ask den-agents-selected [set label-color black set label "DEN"]
  let remaining-nodes1 remaining-nodes with [not member? self den-agents-selected]
  let indSH-agents-selected n-of n-of-indifferents-SH remaining-nodes1
  ask indSH-agents-selected [set label-color black set label "SH"]
  let remaining-nodes2 remaining-nodes1 with [not member? self indSH-agents-selected]
  let indHD-agents-selected n-of n-of-indifferents-HD remaining-nodes2
  ask indHD-agents-selected [set label-color black set label "HD"]
  let remaining-nodes3 remaining-nodes2 with [not member? self indHD-agents-selected]
  let indPD-agents-selected n-of n-of-indifferents-PD remaining-nodes3
  ask indPD-agents-selected [set label-color black set label "PD"]
end

to setup-cooperation [value]
  set cooperate? value
  set old-cooperate? value
end

to go
  tick
  ;;ask agents to interact with each other
  ask nodes with [indifferent?] [interact]   ;;only indifferent players of the three types have a score != 0
  ask nodes with [label = "SH"] [play-SH-game]
  ask nodes with [label = "HD"] [play-HD-game]
  ask nodes with [label = "PD"] [play-PD-game]
  ask nodes [update-plot]
end

to update-plot
  set-current-plot "Cooperation/Defection Frequency"
  plot-histogram-helper "cc" blue
  plot-histogram-helper "dd" red
  plot-histogram-helper "cd" green
  plot-histogram-helper "dc" yellow
end

to plot-histogram-helper [pen-name color-name]
  set-current-plot-pen pen-name
  histogram [color-class] of nodes with [color = color-name]
end

to interact
  let total-cooperaters count link-neighbors with [cooperate?]
  ifelse cooperate?
    [set score total-cooperaters]
    [set score defection-award * total-cooperaters]
end

to play-SH-game
  set old-cooperate? cooperate?
  let total-cooperaters count link-neighbors with [cooperate?]
  ifelse total-cooperaters >= count link-neighbors / 2
    [set cooperate? True
     update-awareness-cooperate]
    [set cooperate? False
     update-awareness-defect]
  establish-color
end

to play-HD-game
  set old-cooperate? cooperate?
  let total-cooperaters count link-neighbors with [cooperate?]
  ifelse total-cooperaters >= count link-neighbors / 2
    [set cooperate? False
     update-awareness-defect]
    [set cooperate? True
     update-awareness-cooperate]
  establish-color
end

to play-PD-game
  set old-cooperate? cooperate?
  ifelse max([score] of link-neighbors) = 0  ;; max list reports the max value of the list
    []
    [ifelse score > [score] of max-one-of link-neighbors with [indifferent?] [score]
      [ifelse cooperate? = True
           [update-awareness-cooperate]
           [update-awareness-defect]
      ]
      [set cooperate? [cooperate?] of max-one-of link-neighbors with [indifferent?] [score]
         ifelse cooperate? = True
           [update-awareness-cooperate]
           [update-awareness-defect]
      ]
     ]
  establish-color
end

to update-awareness-cooperate
  ifelse ((age = "40-60" or age = "25-40") and educational-level = "Degree" and sex = "F")
  [set awareness awareness + 0.01]
  [ifelse (((age = "40-60" or age = "25-40") and educational-level = "Degree") or ((age = "40-60" or age = "25-40") and sex = "F") or ((educational-level = "Degree" and sex = "F")))
    [set awareness awareness + 0.008]
    [ifelse (age = "40-60" or age = "25-40" or educational-level = "Degree" or sex = "F")
      [set awareness awareness + 0.006]
      [ifelse (age = "14-25" and educational-level = "High School" and sex = "M")
        [set awareness awareness + 0.004]
        [ifelse (age = "Over 60" and educational-level = "High School" and sex = "M")
          [set awareness awareness + 0.002]
          [set awareness awareness + 0.001]
        ]
      ]
    ]
   ]
end

to update-awareness-defect
  ifelse ((age = "40-60" or age = "25-40") and educational-level = "Degree" and sex = "F")
  [set awareness awareness - 0.001]
  [ifelse (((age = "40-60" or age = "25-40") and educational-level = "Degree") or ((age = "40-60" or age = "25-40") and sex = "F") or ((educational-level = "Degree" and sex = "F")))
    [set awareness awareness - 0.002]
    [ifelse (age = "40-60" or age = "25-40" or educational-level = "Degree" or sex = "F")
      [set awareness awareness - 0.004]
      [ifelse (age = "14-25" and educational-level = "High School" and sex = "M")
        [set awareness awareness - 0.006]
        [ifelse (age = "Over 60" and educational-level = "High School" and sex = "M")
          [set awareness awareness - 0.008]
          [set awareness awareness - 0.01]
        ]
      ]
    ]
   ]
end

to establish-color
  ifelse old-cooperate?
    [ifelse cooperate?
       [set color blue
        set color-class 1]
       [set color green
        set color-class 3]
    ]
    [ifelse cooperate?
       [set color yellow
        set color-class 4]
       [set color red
        set color-class 2]
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
218
14
772
569
-1
-1
6.0
1
10
1
1
1
0
0
0
1
-45
45
-45
45
0
0
1
ticks
30.0

BUTTON
11
15
74
48
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
76
15
139
48
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
1

SLIDER
11
55
183
88
total-number-of-agents
total-number-of-agents
0
1000
324.0
1
1
NIL
HORIZONTAL

SLIDER
11
92
183
125
n-of-activists
n-of-activists
0
1000
33.0
1
1
NIL
HORIZONTAL

SLIDER
12
128
184
161
n-of-deniers
n-of-deniers
0
1000
15.0
1
1
NIL
HORIZONTAL

SLIDER
12
164
185
197
n-of-indifferents-SH
n-of-indifferents-SH
0
1000
92.0
5
1
NIL
HORIZONTAL

SLIDER
12
200
185
233
n-of-indifferents-HD
n-of-indifferents-HD
0
1000
92.0
5
1
NIL
HORIZONTAL

SLIDER
13
236
186
269
n-of-indifferents-PD
n-of-indifferents-PD
0
1000
92.0
5
1
NIL
HORIZONTAL

SLIDER
772
14
944
47
defection-award
defection-award
0
3
1.34
0.01
1
x
HORIZONTAL

SLIDER
944
14
1116
47
initial-cooperation
initial-cooperation
0
100
40.0
0.1
1
%
HORIZONTAL

SLIDER
944
50
1116
83
nodes-size
nodes-size
0
5
4.0
1
1
NIL
HORIZONTAL

SLIDER
772
50
944
83
SW-rewiring-prob
SW-rewiring-prob
0
0.5
0.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
17
275
181
387
ACT = Activist agent\nDEN = Denier agent\nSH = Indifferent agent playing Stug-Hunt game\nHD = Indifferent agent playing Hawk-Dove game\nPD = Indifferent agent playing Prisoner-Dilemma game
11
0.0
1

PLOT
775
88
1067
275
Cooperation/Defection over time
time
counter
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Cooperators" 1.0 0 -13345367 true "" "plot count nodes with [color = blue or label = \"ACT\"]"
"Defectors" 1.0 0 -2674135 true "" "plot count nodes with [color = red or label = \"DEN\"]"
"Green nodes" 1.0 0 -10899396 true "" "plot count nodes with [color = green]"
"Yellow nodes" 1.0 0 -1184463 true "" "plot count nodes with [color = yellow]"

MONITOR
777
454
925
499
SH players now cooperating
count nodes with [label = \"SH\" and color = blue]
17
1
11

MONITOR
777
505
925
550
SH players now defecting
count nodes with [color = red and label = \"SH\"]
17
1
11

MONITOR
932
454
1080
499
HD players now cooperating
count nodes with [color = blue and label = \"HD\"]
17
1
11

MONITOR
933
506
1081
551
HD players now defecting
count nodes with [color = red and label = \"HD\"]
17
1
11

MONITOR
1086
454
1233
499
PD players now cooperating
count nodes with [color = blue and label = \"PD\"]
17
1
11

MONITOR
1088
505
1235
550
PD players now defecting
count nodes with [color = red and label = \"PD\"]
17
1
11

BUTTON
141
15
216
48
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
1

PLOT
777
554
1094
707
awareness level
time
awareness
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"average awareness of SH players" 1.0 0 -5825686 true "" "plot mean [awareness] of nodes with [label = \"SH\"]"
"average awareness of HD players" 1.0 0 -13791810 true "" "plot mean [awareness] of nodes with [label = \"HD\"]"
"average awareness of PD players" 1.0 0 -955883 true "" "plot mean [awareness] of nodes with [label = \"PD\"]"

TEXTBOX
22
406
172
532
Color Coordination to Strategy\n                              Round \n                   Previous    Current\nBlue                C                 C\nRed                D                 D\nGreen             C                 D\nYellow             D                C\n                        C = Cooperate \n                        D = Defect
11
0.0
1

MONITOR
777
279
928
324
Total number of Cooperators
count nodes with [color = blue or label = \"ACT\"]
17
1
11

MONITOR
932
279
1084
324
Total number of Defectors
count nodes with [color = red or label = \"DEN\"]
17
1
11

CHOOSER
1121
22
1219
67
torus
torus
"yes" "no"
1

PLOT
1203
328
1413
450
PD behavior
time
counter
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"PD cooperating" 1.0 0 -13345367 true "" "plot count nodes with [label = \"PD\" and color = blue]"
"PD defecting" 1.0 0 -2674135 true "" "plot count nodes with [label = \"PD\" and color = red]"
"PD green" 1.0 0 -10899396 true "" "plot count nodes with [label = \"PD\" and color = green]"
"PD yellow" 1.0 0 -1184463 true "" "plot count nodes with [label = \"PD\" and color = yellow]"

PLOT
990
328
1200
450
HD behavior
time
counter
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"HD cooperating" 1.0 0 -13345367 true "" "plot count nodes with [label = \"HD\" and color = blue]"
"HD defecting" 1.0 0 -2674135 true "" "plot count nodes with [label = \"HD\" and color = red]"
"HD green" 1.0 0 -10899396 true "" "plot count nodes with [label = \"HD\" and color = green]"
"HD yellow" 1.0 0 -1184463 true "" "plot count nodes with [label = \"HD\" and color = yellow]"

PLOT
778
328
988
450
SH behavior
time
counter
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"SH cooperating" 1.0 0 -13345367 true "" "plot count nodes with [label = \"SH\" and color = blue]"
"SH defecting" 1.0 0 -2674135 true "" "plot count nodes with [label = \"SH\" and color = red]"
"SH green" 1.0 0 -10899396 true "" "plot count nodes with [label = \"SH\" and color = green]"
"SH yellow" 1.0 0 -1184463 true "" "plot count nodes with [label = \"SH\" and color = yellow]"

PLOT
1071
88
1363
275
Cooperation/Defection Frequency
Class
Frequency (%)
1.0
5.0
0.0
1.0
true
false
"" ""
PENS
"cc" 1.0 1 -13345367 true "" ""
"dd" 1.0 1 -2674135 true "" ""
"cd" 1.0 1 -10899396 true "" ""
"dc" 1.0 1 -1184463 true "" ""

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

circle 3
false
0
Circle -1 true false 0 0 300
Circle -7500403 true true 105 105 90

circle 4
false
0
Circle -7500403 true true 0 0 300
Circle -1 true false 30 30 240

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
NetLogo 6.3.0
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
