;; Implements Bilateral Exchange in a Samll World based on the article
;; by Wilhilte (2001).  The code implements the four network models
;; described in Wilhite and used the Netlogo Distribution Model -
;; Small Worlds - as a starting point for coding.  See Netlogo
;; copyright at the end of the code for permission to use their
;; code.

;; Developed by:
;; Mark E. McBride
;; Department of Economics
;; Miami University
;; Oxford, OH 45056
;; mark.mcbride@miamioh.edu
;; http://memcbride.net/
;;
;; Last updated:  January 2, 2014

extensions [array]

turtles-own
[
  node-clustering-coefficient
  distance-from-other-turtles   ;; list of distances of this node from other turtles
  group                         ;; id of group turtle belongs to
  g1                            ;; quantity of good 1 owned
  g2                            ;; quantity of good 2 owned
  utility                       ;; utility of agent = g1*g2 (CD utility function)
  mrs                           ;; marginal rate of substitution = g2/g1
  price-ij                      ;; last price paid or received
]


globals
[
  market-g1                            ;; market endowment of good 1
  market-g2                            ;; market endowment of good 2
  market-price                         ;; equilibrium market price (predicted)
  group-price                          ;; an array to hold the average price of each group
  total-searches                       ;; total searches undertaken in current run
  total-trades                         ;; total trades undertaken in current run
  round-trades                         ;; total trades undertaken in current round
  avg-price                            ;; current average global price
  std-price                            ;; standard deviation of global price
  old-avg-price                        ;; previous period average price
  debug                                ;; debug flag, set only via command window
  connected-network?                   ;; is the network connected?
  clustering-coefficient               ;; the clustering coefficient of the network; this is the
                                       ;; average of clustering coefficients of all turtles
  average-path-length                  ;; average path length of the network
  highlight-string                      ;; to indicate link values
  infinity                             ;; a very large number.
                                         ;; used to denote distance between two turtles which
                                         ;; don't have a connected or unconnected path between them
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set infinity 99999  ;; just an arbitrary choice for a large number
  set debug false
  set-default-shape turtles "circle"
  make-turtles

  ;; wire the groups together
  wire-groups

  ;; setup warnings
  if ( (network != "global") and (num-groups = 1) ) [
    user-message (word "Number of groups must be greater than 1 for a " network " network")
    reset-ticks
    stop
  ]
  ;; do a quick check.  If the num-groups > 1
  ;; then the network will be not be global
  if ( (network != "global") and (num-groups = 1) ) [
    set network "global"
  ]
  ;; setup additional connections if required
  ;; by the specific network structure
  ifelse (network = "locally connected") [
    local-connect
    if (debug) [show network]
  ] [
    ifelse (network = "small world") [
    small-world
    if (debug) [show network]
    ] [
      if (debug) [show "No special wiring needed"]
    ]
  ]

  ;; establish their initial endowments, utility levels, and mrs'
  initial-endowments

  ;; report network characteristics (cc and apl)
  let connected? do-calculations

  ;; reset counters
  set total-searches 0
  set total-trades 0
  set round-trades 0
  set group-price array:from-list n-values num-groups [0]
  set avg-price 0
  set old-avg-price 0

  ;; reset-ticks
  reset-ticks
end

to make-turtles
  let group-size num-agents / num-groups
  crt num-agents [
    set group int (who / group-size )
    if (debug) [show (word "who= " who " group=" group)]
    set color gray + ( group * 10 )
    set label who
  ]
  ;; arrange them in a circle in order by who number
  layout-circle (sort turtles) max-pxcor - 1
end

to setup-pens
    let step 0
    repeat num-groups [
      set-plot-pen-color gray + (step * 10)
      set step step + 1
    ]
end

to initial-endowments
  ask turtles [
    ;; pick random quantities of g1 and g2
    ;; Wilhite used the C++ code (rand % 1490) + 10
    ;; which gives an initial endowment between 10 and num-agents*1500
    ;; Because of the considerably smaller number of agents in
    ;; this model (<100 versus 500), we set the endowments considerably
    ;; higher than Wilhite.  This is done to get a predicted price
    ;; relatively close to 1 and make convergence work reasonably well
    set g1 random (endowment-per-good-agent - 10) + 10
    set g2 random (endowment-per-good-agent - 10) + 10
    set mrs g2 / g1
    set utility g1 * g2
    if (debug) [show (word "has g1=" g1 " g2=" g2 " U=" utility " mrs=" mrs) ]
  ]
  set market-g1 sum [g1] of turtles
  set market-g2 sum [g2] of turtles
  ;; set predicted market equilibirum
  set market-price market-g2 / market-g1

end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; ask the agents to trade
  do-trades
  ;; update average prices
  update-prices
  ;; advance the time counter
  ;; this is the Netlogo recommended
  ;; place to update the tick count
  tick
  ;; update the graphs
  do-plotting
  ;; check for convergence
  if (converged) [stop]
end

to reset
  ;; reset the model to default parameters
  set num-agents 50
  set num-groups 1
  set endowment-per-good-agent 1000
  set num-crossovers 2
  set network "global"
  set debug false
end

to do-trades
  set round-trades 0
  ;; pick an agent at random to implement basic trade procedure
  ask turtles [
    ;; which turtle is looking for trade partners
    let agenti turtle who
    if (debug) [
      show (word "has g1=" g1 " g2=" g2 " U=" utility " mrs=" mrs)
      show (word "Neighbor's and their mrs'")
    ]
    ;; see what trading partners look like
    foreach sort-by [ [?1 ?2] -> [mrs] of ?1 > [mrs] of ?2 ] link-neighbors [ ?1 ->
      ask ?1 [
        set price-ij ( ([g2] of agenti + g2) / ([g1] of agenti + g1) )
        if (debug) [show (word "has g1=" g1 " g2=" g2 " price=" price-ij " mrs=" mrs) ]
        set total-searches total-searches + 1
      ]
    ]
    ;; Wilhite picks the trade partner based on the price
    let agentj max-one-of link-neighbors [
       ( ([g2] of agenti + g2) / ([g1] of agenti + g1) )
    ]
    if (debug) [show (word "best trade deal is agent " agentj) ]
    ;; now send them off to trade
    trade agenti agentj
  ]
end

to trade [agenti agentj]
  let price 0
  let units-traded 0
  ;; agents trade whole units of good 1 for fractional units of good 2
  ;; turtle agenti is initiating the trades with turtle agentj
  ;; they trade one unit of good 1, repeatedly unitl one of their utility's will not increase
  ;; execute the trades if conditions met
  loop [
    ;; set the price
    set price ( ([g2] of agenti + [g2] of agentj) / ([g1] of agenti + [g1] of agentj) )
    ;; is agent i willing to pay more for a unit of g1?
    ;; if yes, agent i buys a unit of g1 from agent j for price
    ifelse ([mrs] of agenti > [mrs] of agentj) [
      if (debug) [show (word agenti " buying a unit of g1") ]
      ;; check to see if both agents better off if trade occurs
      ifelse ( (better? agenti 1 (- price) price) and (better? agentj -1 price price) ) [
        ;; update agent i
        ask agenti [
          set g1 g1 + 1
          set g2 g2 - price
          set utility g1 * g2
          set mrs g2 / g1
          set price-ij price
        ]
        ;; update agent j
        ;; decrease g1 and increase g2 for agent j
        ask agentj [
          set g1 g1 - 1
          set g2 g2 + price
          set utility g1 * g2
          set mrs g2 / g1
          set price-ij price
        ]
        set units-traded units-traded + 1
      ] [
        if (units-traded > 0) [
          if (debug) [show (word agenti agentj "traded " units-traded )]
          ;; increase total-trades and round-trades counters
          set round-trades round-trades + 1
          set total-trades total-trades + 1
        ]
        stop
      ]
    ] [
      ;; no, agent i sells a unit of g1 to agent j for price
      ;; check to see if both agents better off if trade occurs
      if (debug) [show (word agenti " selling a unit of g1") ]
      ifelse ( (better? agenti -1 price price) and (better? agentj 1 (- price) price) ) [
        ;; update agent i
        ask agenti [
          set g1 g1 - 1
          set g2 g2 + price
          set utility g1 * g2
          set mrs g2 / g1
          set price-ij price
        ]
        ;; update agent j
        ask agentj [
          set g1 g1 + 1
          set g2 g2 - price
          set utility g1 * g2
          set mrs g2 / g1
          set price-ij price
        ]
        set units-traded units-traded + 1
      ] [
        if (units-traded > 0) [
          if (debug) [show (word agenti agentj "traded " units-traded )]
          ;; increase total-trades and round-trades counters
          set round-trades round-trades + 1
          set total-trades total-trades + 1
        ]
        stop
      ]
    ]
  ]
end

to-report better? [agent good1 good2 price]
  ;; checks to see if the budget constraint is satisfied for
  ;; a potential trade.  The agent must be able to afford the
  ;; new bundle given the price and the change in quantity
  if (debug) [show (word agent " being tested")]
  let oldU [utility] of agent
  let newU ([g1] of agent + good1) * ([g2] of agent + good2)
  let oldBudget price * [g1] of agent + [g2] of agent
  let newBudget price * ([g1] of agent + good1) + ([g2] of agent + good2)
  if (debug) [show (word agent " BudgetDiff=" (newBudget - oldBudget) " UtilDiff=" (newU - oldU) )]
  ifelse ( (oldU < newU) and (oldBudget >= newBudget) )
    [if (debug) [show "Reporting true"]
     report true]
    [if (debug) [show "Reporting false"]
     report false]
end

to update-prices
  ;; average the prices within each group
  let step 0
  let avg-price-local 0
  repeat num-groups [
    set avg-price-local mean [price-ij] of turtles with [group = step]
    array:set group-price step avg-price-local
    if (debug) [show (word "group=" step " average price=" avg-price-local)]
    set step step + 1
  ]
  if (debug) [show group-price]
  ;; calculate average and std deviation of global price
  set old-avg-price avg-price
  set avg-price mean [price-ij] of turtles
  set std-price standard-deviation [price-ij] of turtles
end

to-report converged
  ifelse ( round-trades = 0)
  [report true]
  [report false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Network Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; these procedures are directly from the Netlogo
;; Distribution model "Small Worlds" by Uri Wilensky
;; See permission to use for non-commerical use below.

;; do-calculations reports true if the network is connected,
;;   and reports false if the network is disconnected.
;; (In the disconnected case, the average path length does not make sense,
;;   or perhaps may be considered infinite)
to-report do-calculations

  ;; set up a variable so we can report if the network is disconnected
  let connected? true

  ;; find the path lengths in the network
  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-turtles)] of turtles

  ;; In a connected network on N nodes, we should have N(N-1) measurements of distances between pairs,
  ;; and none of those distances should be infinity.
  ;; If there were any "infinity" length paths between nodes, then the network is disconnected.
  ;; In that case, calculating the average-path-length doesn't really make sense.
  ifelse ( num-connected-pairs != (count turtles * (count turtles - 1) ))
  [
      set average-path-length infinity
      ;; report that the network is not connected
      set connected? false
  ]
  [
    set average-path-length (sum [sum distance-from-other-turtles] of turtles) / (num-connected-pairs)
  ]
  ;; find the clustering coefficient and add to the aggregate for all iterations
  find-clustering-coefficient 0

  ;; report whether the network is connected or not
  report connected?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clustering computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient [agroup]
  ;; create agentset of this group's turtles
  let group-turtles turtles with [group = agroup ]
  ifelse all? group-turtles [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask group-turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask group-turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Path length computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Implements the Floyd Warshall algorithm for All Pairs Shortest Paths
;; It is a dynamic programming algorithm which builds bigger solutions
;; from the solutions of smaller subproblems using memoization that
;; is storing the results.
;; It keeps finding incrementally if there is shorter path through
;; the kth node.
;; Since it iterates over all turtles through k,
;; so at the end we get the shortest possible path for each i and j.

to find-path-lengths
  ;; reset the distance list
  ask turtles
  [
    set distance-from-other-turtles []
  ]

  let i 0
  let j 0
  let k 0
  let node1 one-of turtles
  let node2 one-of turtles
  let node-count count turtles
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 turtle i
      set node2 turtle j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [
          set distance-from-other-turtles lput 0 distance-from-other-turtles
        ]
      ]
      [
        ;; 1 from a node to it's neighbor
        ifelse [ link-neighbor? node1 ] of node2
        [
          ask node1 [
            set distance-from-other-turtles lput 1 distance-from-other-turtles
          ]
        ]
        ;; infinite to everyone else
        [
          ask node1 [
            set distance-from-other-turtles lput infinity distance-from-other-turtles
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [k < node-count]
  [
    set i 0
    while [i < node-count]
    [
      set j 0
      while [j < node-count]
      [
        ;; alternate path length through kth node
        set dummy ( (item k [distance-from-other-turtles] of turtle i) +
                    (item j [distance-from-other-turtles] of turtle k))
        ;; is the alternate path shorter?
        if dummy < (item j [distance-from-other-turtles] of turtle i)
        [
          ask turtle i [
            set distance-from-other-turtles replace-item j distance-from-other-turtles dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set k k + 1
  ]

end

;;;;;;;;;;;;;;;;
;;; Graphics ;;;
;;;;;;;;;;;;;;;;

to highlight
  if (count turtles > 0 ) [
    ;; remove any previous highlights
    ask turtles [ set color gray + 2 ]
    ask links [ set color gray + 2 ]
    if mouse-inside? [ do-highlight ]
    display
  ]
end

to do-highlight
  ;; getting the node closest to the mouse
  let min-d min [distancexy mouse-xcor mouse-ycor] of turtles
  let node one-of turtles with [count link-neighbors > 0 and distancexy mouse-xcor mouse-ycor = min-d]
  if node != nobody
  [
    ;; highlight the chosen node
    ask node
    [
      set color pink - 1
      let pairs (length remove infinity distance-from-other-turtles)
      let local-val (sum remove infinity distance-from-other-turtles) / pairs
      ;; show node's clustering coefficient
      set highlight-string (word "clustering coefficient = " precision node-clustering-coefficient 3
                                 " and avg path length = " precision local-val 3
                                 " (for " pairs " turtles )")
    ]
    let neighbor-nodes [ link-neighbors ] of node
    let direct-links [ my-links ] of node
    ;; highlight neighbors
    ask neighbor-nodes
    [
      set color blue - 1

      ;; highlight edges connecting the chosen node to its neighbors
      ask my-links [
        ifelse (end1 = node or end2 = node)
        [
          set color blue - 1 ;
        ]
        [
          if (member? end1 neighbor-nodes and member? end2 neighbor-nodes)
            [ set color yellow ]
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Edge Operations ;;;
;;;;;;;;;;;;;;;;;;;;;;;

;; wire the group members together
to wire-groups
  ;; iterate over the groups
  let n 0
  repeat num-groups [
    ask turtles with [group = n ] [
      create-links-with other turtles with [group = n]
    ]
  set n n + 1
  ]
end


;; Wilhite creates the locally connected network by
;; having each group share a trader.  When arranged
;; in a ring, the first agent in a group also become
;; part of the previous group.  The first agent (who=0)
;; then becomes part of the last group in the ring.
to local-connect
  ;; iterate over the groups
  let n 1
  repeat num-groups - 1 [
    let agente min-one-of turtles with [group = n]
      [who]
    if (debug) [show (word "Group=" n " agente=" agente)]
    ask agente [ create-links-with turtles with [group = n - 1] ]
    set n n + 1
  ]
  ;; now wire agent with who=0 to the last group
  ask turtle 0 [ create-links-with turtles with [group = n - 1] ]

end

;; Wilhite creates the small world by adding crossover agents
;; to the local-connect network.  There are two restrictions.
;; First, a crossover agent cannot be an agent that already links
;; neighboring groups.  Second, the crossover agent cannot link
;; two groups who already have a common trader (which would include
;; the common traders from the local-connect world and from any
;; previosuly created crossovers.
to small-world
  ;; first, local connect the world
  local-connect
  ;; now create the num-crossovers randomly
  if (num-crossovers > 0) [
    repeat num-crossovers [
      ;; randomly pick a turtle who is not a common trader in local-connect world
      let agent1 one-of turtles with [
        (self != min-one-of turtles with [group = [group] of self ] [who]) or
        (not any? link-neighbors with [group != [group] of self])
      ]
      if (debug) [
        show agent1
        show (word "group=" [group] of agent1)
      ]
      ;; now link that turtle with another randomly chosen turtle not in group or adjacent group
      ;; first, find the smaller numbered groups that are acceptable
      let a [group] of agent1 - 2
      if (a < 0) [set a a + num-groups]
      ;; now, find the larger numbered groups that are acceptable
      let b [group] of agent1 + 2
      if (b > num-groups - 1) [set b b - num-groups]
      ;; find groups not already linked to [group] of agent1
      let n 0
      let no-link-groups []
      while [n < num-groups] [
        ask turtles with [group = n] [
          let connected? any? link-neighbors with [group = [group] of agent1]
          if (connected?) [set no-link-groups lput group no-link-groups]
        ]
        set n n + 1
      ]
      set no-link-groups remove-duplicates no-link-groups
      if (debug) [show (word "groups not to link to are: " no-link-groups)]
      ;; pick the agent to cross over with
      let agent2 0
      ifelse (a < b) [
        set agent2 one-of turtles with [not (member? [group] of self no-link-groups)]
      ] [
        set agent2 one-of turtles with [not (member? [group] of self no-link-groups)]
      ]
      if (debug) [show (word "partner=" agent2 " in group=" [group] of agent2)]
      ;; make the connection of an agent2 was found
      if (agent2 != nobody) [ask agent1 [create-link-with agent2] ]
    ]
  ]
end

;;;;;;;;;;;;;;;;
;;; Plotting ;;;
;;;;;;;;;;;;;;;;

to do-plotting
  set-current-plot "Average Prices"
    let step 0
    repeat num-groups [
      set-current-plot-pen (word "group" step)
      plot array:item group-price step
      set step step + 1
    ]
end

;; Revision History
;;
;; November 16, 2019
;;
;; Updated model to work in Netlogo 6.1.1
;;
;; January 2, 2014
;;
;; Updated model to work in Netlogo 5.0.5

; Copyright notice for material created by Uri Wilensky

; The Netlogo Distribution Model:  Small Worlds was used as a starting point for this model.
; The procedures:  do-calculations, do-highlight, find-clustering-coefficient, find-path-lengths,
; highlight, in-neighborhood?, and wire-groups were retained, as is, from that model.  Here
; is the Netlogo Model Copyright covering there use herein:
;
; *** NetLogo 4.0.3 Model Copyright Notice ***
;
; Copyright 2005 by Uri Wilensky.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from Uri Wilensky.
; Contact Uri Wilensky for appropriate licenses for redistribution for
; profit.
;
; To refer to this model in academic publications, please use:
; Wilensky, U. (2005).  NetLogo Small Worlds model.
; http://ccl.northwestern.edu/netlogo/models/SmallWorlds.
; Center for Connected Learning and Computer-Based Modeling,
; Northwestern University, Evanston, IL.
;
; In other publications, please use:
; Copyright 2005 Uri Wilensky.  All rights reserved.
; See http://ccl.northwestern.edu/netlogo/models/SmallWorlds
; for terms of use.
;
; *** End of NetLogo 4.0.3 Model Copyright Notice ***
@#$#@#$#@
GRAPHICS-WINDOW
331
10
689
369
-1
-1
10.0
1
10
1
1
1
0
0
0
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

SLIDER
14
42
320
75
num-agents
num-agents
10
100
50.0
10
1
NIL
HORIZONTAL

BUTTON
15
249
81
282
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

SLIDER
12
79
320
112
num-groups
num-groups
1
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
13
119
321
152
endowment-per-good-agent
endowment-per-good-agent
1000
20000
4000.0
1000
1
NIL
HORIZONTAL

MONITOR
341
405
410
450
Total-G1
market-g1
0
1
11

MONITOR
408
405
478
450
Total-G2
market-g2
0
1
11

BUTTON
84
249
147
282
Go
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

PLOT
10
340
317
595
Average Prices
ticks
Price
0.0
1.0
0.75
1.25
true
false
"" ""
PENS
"group0" 1.0 0 -16777216 true "" ""
"group1" 1.0 0 -2064490 true "" ""
"group2" 1.0 0 -5825686 true "" ""
"group3" 1.0 0 -8630108 true "" ""
"group4" 1.0 0 -13345367 true "" ""
"group5" 1.0 0 -13791810 true "" ""
"group6" 1.0 0 -11221820 true "" ""
"group7" 1.0 0 -14835848 true "" ""
"group8" 1.0 0 -13840069 true "" ""
"group9" 1.0 0 -10899396 true "" ""

TEXTBOX
18
13
168
31
Basic Setup
14
0.0
1

CHOOSER
15
162
189
207
network
network
"global" "locally disconnected" "locally connected" "small world"
3

MONITOR
477
405
567
450
Predicted Price
market-price
5
1
11

MONITOR
340
460
428
505
Searches
total-searches
0
1
11

MONITOR
427
461
517
506
Total Trades
total-trades
0
1
11

MONITOR
507
461
567
506
Rounds
ticks
0
1
11

MONITOR
339
513
441
558
Global Avg Price
avg-price
5
1
11

MONITOR
440
513
534
558
Global Std Price
std-price
5
1
11

MONITOR
567
461
662
506
Current Trades
round-trades
0
1
11

TEXTBOX
16
219
166
237
Controls
14
0.0
1

TEXTBOX
13
307
163
325
Monitors and Data
14
0.0
1

BUTTON
155
250
220
283
Reset
reset
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
545
513
602
558
cc
clustering-coefficient
4
1
11

MONITOR
601
513
658
558
apl
average-path-length
4
1
11

BUTTON
230
250
318
283
Highlight
highlight
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
199
170
321
203
num-crossovers
num-crossovers
0
5
2.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model implements bilateral exchange in small world networks based on the model described by Wilhite (2001).  Wilhite studied the impact of network formation on key elements of the trade process:  search, negotiation, and exchange.  In particular, he focused on the implication of small world networks on trade.  In a small world network, an agent is only a few connections away from any other agent.  Small world networks were popularized in the game "six degrees of Kevin Bacon" where participants try to link any one actor/actress to another actor/actress through other actors/actresses that they have shared a movie with (ending with Kevin Bacon).

## HOW IT WORKS

This model is an adaptation of a model developed by Allen Wilhite (2001). In Wilhite's model, 500 agents are placed in one of four network structures (described below).  Each agent is given a random endowment of each of two goods.  Good 1 can only be held and traded in integer units while good two is perfectly divisible.  Each agent has a Cobb-Douglas utility function dependent on the two goods and all trades must satisfy their budget constraint.  Prices are specified in terms of amount of good 2 paid for a unit of good 1.  

In each round of the model, every agent (in random order) is given the opportunity to search among all agents to which he has a network connection to find the best agent to trade with.  The pair of agents then trade using bilateral exchange until further trade would not improve both agent's welfare. Rounds of trading continue until a round occurs with no trades.

The four network structures Wilhite implements are:

global:  All agents are connected to every other agents.  Thus each agent is able to trade with every other agent.

locally disconnected:  The agents are split into distinct groups.  Agents are connected only to other agents in their group.  Thus each agent can only trade with agents in their group and no trade takes place across groups.

locally connected:  The agents are split into distinct groups as in the locally disconnected network.  The groups are then arranged in a circle and each group overlaps its neighboring groups by sharing one member.  Thus every group has two agents who are common to different adjacent groups.  The common agents can trade with members of either group while the rest of the members of a group can only trade within the group.

small world:  The agents are formed into a locally connected network.  Then a small number of agents are randomly selected to connect with agents in other groups.  There are two restrictions on these crossover connections.  First, a crossover agent cannot be one of the common traders shared between adjacent groups. Second, the new connection cannot connect two groups who already have a common agent.

This model implements the major features of Wilhite's model.  The number of agents is smaller due to limitations in clearly graphing the alternative network structures.  In addition, this model allows you to specify experiments with alternative values for key parameters:  number of agents, number of groups, number of crossover agents, and the maximum endowment that can be randomly set for each good for each agent.

## HOW TO USE IT

To run the model, select the number of agents, the number of groups, the maximum amount of endowment per good per agent, the type of network, and the number of cross over agents. Next press the setup button to initialize the model.  The network is drawn on the landscape and the links between agents are shown. The agents do not move around or use the landscape in any significant way.  Click the highlight button and then hover the mouse over an agent.  All agents in the same trading group (given the network specified) are highlighted.  Press the highlight button a second time to turn it off.  The go button starts the simulation.  The model graphs the average prices each round (tick of the simulation) for each group.  The monitors are updated.  The model will end automatically when the convergence criteria is met (a round with no trades).

Here's a more complete description of each interface element:

Buttons:  
go:
    starts the model running

setup: clears out any previous runs, initializes all variables, and creates the specified network for the number of agents and groups.

reset: resets all sliders to their default values

highlight:  when clicked allows you to hover over an agent in the landscape and see all agents linked to the selected agent.  The model will not run until the highlight button is not selected.

Sliders:  
num-agents:
    number of agents in network ranging from 10 to 100

num-groups:   number of groups to split the agents into ranging from 10 to 200

endowment-per-good-agent:
     maximum value an agent may have for each good ranging from 1000 to 10000.  Actual endowments of the two goods is randomly determined for each agent between 10 and endowment-per-good-agent.

num-crossovers:
      number of crossover agents in small world network ranging from 1 to 5.  Value is ignored for all other network models.  Note that if value is >= number of groups then not all crossovers may be created.

network:
     type of network to form:  global, locally disconnected, locally connected, and small world.

Graphs:  
Average Price: Displays the average prices of each group per round (tick) of trading.

Monitors:  
total-g1:
       total endowment of good 1 held by all agents

total-g2:
       total endowment of good 2 held by all agents

predicted price: predicted equilibrium price given total endowments of good 1 and good 2

searches:
       total number of searches conducted by agents to find trading trading partners

total trades:   total trades undertaken between pairs of agents

rounds:
         number of rounds completed (a complete round means each agent had the opportunity, in random order, to find a trade partner.

current trades: number of trades in the current round

global average price:  average of all prices paid in the current round by agents who traded

global std dev: standard deviation of all prices paid in the current round by agents who traded

cc:
       clustering coefficient of network

apl:
      average path length of network.  If 9999 means network is disconnected


## THINGS TO NOTICE

For a given number of agents and a given network structure, how closely did global prices converge to the predicted price?  How much dispersion occurred in the prices?  How many rounds did it take for the model to converge (no more trades)?

Was there significant differences in the number of searches, total trades, and number of rounds for the model to converge for the different network structures?

How do the different network structures affect the clustering coefficient (cc) and the average path length (apl)?  How do cc and apl vary with the number of crossover agents in the small world network?

## THINGS TO TRY

Using behavior space in Netlogo, re-run Wilhite's experimental design (pp. 55-56, Table 1) for 50 agents; for 100.  Did you get the relative results?  What might be leading to the differences?

Using behavior space in Netlogo, design and run an experiment to test if the maximum endowment per good per agent affects the speed of convergence.

## EXTENDING THE MODEL

Change the convergence criteria of the model.

Design additional hypotheses for the model.  Implement an experimental design to test the hypotheses using behavior space in Netlogo.

Implement an alternative network structure:  giant components, directed networks, or preferential networks.

## RELATED MODELS

See the Small World model in the Networks section of the Models Library which provides an excellent overview of small world models, additional resources about small world models, and further explanation of the network concepts of clustering coefficients and average path length.

## REFERENCES

Allen Wilhite.  2001.  Bilateral Trade and 'Small-World' Networks.  Computational Economics.  18 (August)1: 49-64.

Leigh Tesfatsion has very good summary notes on Wilhite's model.  See http://www.econ.iastate.edu/classes/econ308/tesfatsion/WilhiteNotes.LT.pdf (pdf,236K). ON-LINE/CLASS PRESENTATION.  NOTE: These presentation slides summarize key points from the article by Wilhite (2001), linked here. http://www.econ.iastate.edu/tesfatsi/SmallWorldNetworksBilateralTrade.Wilhite.pdf, "Bilateral Trade and `Small-World' Networks" (pdf,181K), Computational Economics, Vol. 18, No. 1, August, pp. 49-64.

## Copyrights and Licenses

Copyright notice for material created by Uri Wilensky

The Netlogo Distribution Model:  Small Worlds was used as a starting point for this model.  
The procedures:  do-calculations, do-highlight, find-clustering-coefficient, find-path-lengths,
highlight, in-neighborhood?, and wire-groups were retained, as is, from that model.  Here
is the Netlogo Model Copyright covering there use herein:

*** NetLogo 4.0.3 Model Copyright Notice ***

Copyright 2005 by Uri Wilensky.  All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) this copyright notice is included.
b) this model will not be redistributed for profit without permission from Uri Wilensky.

Contact Uri Wilensky for appropriate licenses for redistribution for profit.

To refer to this model in academic publications, please use: 
Wilensky, U. (2005).  
NetLogo Small Worlds model. 
http://ccl.northwestern.edu/netlogo/models/SmallWorlds.
Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:
Copyright 2005 Uri Wilensky.  All rights reserved.
See http://ccl.northwestern.edu/netlogo/models/SmallWorlds for terms of use.

*** End of NetLogo 4.0.3 Model Copyright Notice ***

*** Original Material Copyright Notice***

Developed by:  
Mark E. McBride  
Department of Economics  
Miami University  
Oxford, OH 45056  
mark.mcbride@miamioh.edu  
http://memcbride.net/

Last updated:  November 16, 2019

Material created by Mark E. McBride is copyright 2008-2019

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Mark E McBride at mcbridme@miamioh.edu.
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
setup
repeat 5 [rewire-one]
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
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225
@#$#@#$#@
0
@#$#@#$#@
