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
