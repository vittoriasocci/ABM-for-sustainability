extensions[csv
           gis]

globals [new-node
         number-of-nodes_2
         old-node
         world
         ]

breed [nodes node]

nodes-own [age
           sex
           educational-level
           kind
           terzo
           location
           lat
           long
           indifferent?
           score
           cooperate?
           old-cooperate?
           awareness
           color-class
           ]
links-own [rewired?]

to setup
  ca ;; clear all
  ask patches [set pcolor grey]
  set-default-shape nodes "circle"
  set number-of-nodes_2 int(sqrt(total-number-of-agents))
  set total-number-of-agents number-of-nodes_2 * number-of-nodes_2

  import-siena-map

  create-nodes total-number-of-agents
  ask nodes [set size nodes-size set color white]

  setup-age
  setup-sex
  setup-educational-level
  setup-terzo
  setup-location
  setup-lat
  setup-long
  setup-type
  setup-awareness

  move-nodes

  create-graph

  ask nodes with [label = "ACT" or label = "DEN"] [set indifferent? False]
  ask nodes with [label = "ACT"] [setup-cooperation True set shape "circle 3" set color blue set color-class 1]
  ask nodes with [label = "DEN"] [setup-cooperation False set shape "circle 3" set color red set color-class 2]
  ask nodes with [label = "SH" or label = "HD" or label = "PD"] [
    set indifferent? True
    ifelse random-float 1.0 < (initial-cooperation / 100)
        [setup-cooperation True]
        [setup-cooperation False]
  ]
  ask nodes with [label = "SH" or label = "HD" or label = "PD"] [establish-color]
  ask nodes [update-plot]
  reset-ticks
end

to import-siena-map
  set world gis:load-dataset "roads.shp"
  ;Set the world envelope
  ;gis:set-world-envelope (gis:envelope-of world) ;the entire Italian road network
  gis:set-world-envelope (list 11.32315 11.34110 43.31153 43.32800) ;zoom on the road network in the center of Siena
  gis:set-drawing-color white  ; Set roads color
  gis:draw world 1  ; Draw the road layer
  gis:load-coordinate-system "roads.prj" ;set the coordinat system
end

; Use gis:project-lat-lon to convert latitude and longitude values
; into an xcor and a ycor.
to move-nodes
  ask nodes [
    let loc gis:project-lat-lon lat long
    let loc-xcor item 0 loc
    let loc-ycor item 1 loc
    set xcor loc-xcor
    set ycor loc-ycor
    ]
end

to create-graph

  ask nodes [create-links-with other nodes in-radius 10 [set color black set rewired? false]]

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

to setup-age
  let li []
  file-open "age_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li lput _line li]
  let lis reduce sentence li
  set lis remove "age" lis
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set age item i lis]
   set i i + 1]
  file-close
end

to setup-sex
  let li1 []
  file-open "gender_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li1 lput _line li1]
  let lis1 reduce sentence li1
  set lis1 remove "gender" lis1
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set sex item i lis1]
   set i i + 1]
  file-close
end

to setup-educational-level
  let li2 []
  file-open "education_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li2 lput _line li2]
  let lis2 reduce sentence li2
  set lis2 remove "education" lis2
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set educational-level item i lis2]
   set i i + 1]
  file-close
end

to setup-location
  let li3 []
  file-open "coordinates.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li3 lput _line li3]
  let lis3 reduce sentence li3
  set lis3 remove "address" lis3
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set location item i lis3]
   set i i + 1]
  file-close
end

to setup-type
  let li4 []
  file-open "agent_type.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li4 lput _line li4]
  let lis4 reduce sentence li4
  set lis4 remove "TYPE1" lis4
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [
    set kind item i lis4
    ifelse kind = "A"
        [set label-color black set label "ACT"]
    [ifelse kind = "N"
      [set label-color black set label "DEN"]
      [ifelse kind = "SH"
        [set label-color black set label "SH"]
        [ifelse kind = "HD"
          [set label-color black set label "HD"]
          [set label-color black set label "PD"]]]]
  ]set i i + 1]
  file-close
end

to setup-awareness
  let li5 []
  file-open "awareness_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li5 lput _line li5]
  let lis5 reduce sentence li5
  set lis5 remove "awareness" lis5
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set awareness item i lis5 / 10]
    set i i + 1]
  file-close
end

to setup-terzo
  let li6 []
  file-open "terzo_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li6 lput _line li6]
  let lis6 reduce sentence li6
  set lis6 remove "terzo" lis6
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set terzo item i lis6]
    set i i + 1]
  file-close
end

to setup-lat
  let li7 []
  file-open "latitude_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li7 lput _line li7]
  let lis7 reduce sentence li7
  set lis7 remove "Lat" lis7
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set lat item i lis7]
    set i i + 1]
  file-close
end

to setup-long
  let li8 []
  file-open "longitude_list.csv"
  while [not file-at-end?]
  [let _line (csv:from-row file-read-line ",")
    set li8 lput _line li8]
  let lis8 reduce sentence li8
  set lis8 remove "Long" lis8
  let i 0
  while [i <= total-number-of-agents - 1]
  [ask node i [set long item i lis8]
    set i i + 1]
  file-close
end

to setup-cooperation [value]
  set cooperate? value
  set old-cooperate? value
end

to go
  tick
  ;;ask the agents to interact with each other
  ask nodes with [indifferent?] [interact]   ;;only the indifferent of the three types have a score != 0
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
224
10
958
745
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
-60
60
-60
60
0
0
1
ticks
30.0

BUTTON
12
16
75
49
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
79
16
142
49
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
191
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
966
11
1138
44
defection-award
defection-award
0
3
1.0
0.01
1
x
HORIZONTAL

SLIDER
1145
11
1317
44
initial-cooperation
initial-cooperation
0
100
50.0
0.1
1
%
HORIZONTAL

SLIDER
1146
48
1318
81
nodes-size
nodes-size
0
5
3.0
0.5
1
NIL
HORIZONTAL

SLIDER
967
49
1139
82
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
15
289
199
401
ACT = Activist agent\nDEN = Denier agent\nSH = Indifferent agent playing Stug-Hunt game\nHD = Indifferent agent playing Hawk-Dove game\nPD = Indifferent agent playing Prisoner-Dilemma game
11
0.0
1

PLOT
969
86
1334
300
Cooperation/Defection over time
time
counter
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"1" 1.0 0 -10899396 true "" "plot count nodes with [color = green]"
"2" 1.0 0 -2674135 true "" "plot count nodes with [color = red or label = \"DEN\"]"
"3" 1.0 0 -13345367 true "" "plot count nodes with [color = blue or label = \"ACT\"]"
"4" 1.0 0 -1184463 true "" "plot count nodes with [color = yellow]"

MONITOR
225
904
392
949
SH players now cooperating
count nodes with [label = \"SH\" and color = blue]
17
1
11

MONITOR
225
953
379
998
SH players now defecting
count nodes with [color = red and label = \"SH\"]
17
1
11

MONITOR
431
905
600
950
HD players now cooperating
count nodes with [color = blue and label = \"HD\"]
17
1
11

MONITOR
431
953
586
998
HD players now defecting
count nodes with [color = red and label = \"HD\"]
17
1
11

MONITOR
635
904
802
949
PD players now cooperating
count nodes with [color = blue and label = \"PD\"]
17
1
11

MONITOR
635
951
789
996
PD players now defecting
count nodes with [color = red and label = \"PD\"]
17
1
11

BUTTON
145
16
220
49
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
969
572
1336
776
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
15
415
165
541
Color Coordination to Strategy\n                              Round \n                   Previous    Current\nBlue                C                 C\nRed                D                 D\nGreen             C                 D\nYellow             D                C\n                        C = Cooperate \n                        D = Defect
11
0.0
1

MONITOR
969
523
1119
568
Total number of Cooperators
count nodes with [color = blue or label = \"ACT\"]
17
1
11

MONITOR
1124
523
1261
568
Total number of Defectors
count nodes with [color = red or label = \"DEN\"]
17
1
11

MONITOR
11
92
85
137
n-of-activists
count nodes with [label = \"ACT\"]
17
1
11

MONITOR
91
92
161
137
n-of-deniers
count nodes with [label = \"DEN\"]
17
1
11

MONITOR
11
140
135
185
n-of-indifferents-SH
count nodes with [label = \"SH\"]
17
1
11

MONITOR
11
187
136
232
n-of-indifferents-HD
count nodes with [label = \"HD\"]
17
1
11

MONITOR
11
234
135
279
n-of-indifferents-PD
count nodes with [label = \"PD\"]
17
1
11

PLOT
225
751
425
901
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
431
751
631
901
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
635
751
835
901
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
969
304
1334
519
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
