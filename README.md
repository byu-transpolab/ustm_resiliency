# USTM Resiliency

This repository contains a Cube model designed to measure the
resiliency of links in the Utah statewide highway network by
considering the change in mode and destination choice
logsums resulting from a break in the highway network.


## Setup
This model runs using the CUBE travel demand modeling software. The
`ustm_resiliency.cat` Cube catalog will open an application manager in Cube
with the model. The other folders are as follows:

  - `Base/` Base scenario directory. Child scenarios will be created in this folder.
  - `Inputs/` Global inputs directory; contains transit, freight, and other files that do
    not change between scenarios. **It is necessary to download files in this folder from Box**. This folder 
    cannot be stored in the repository due to size; download 10 files from [https://byu.box.com/s/ynyoxg7snzhc7hu881lob40s6jbygfan] 
  - `CUBE/` Model script and application files
  - `params/` Model parameters
  - `Reports/` Calibration and fit report files for Cube.

## Background
In 2017, AEM completed a risk and resilience analysis for the I-15 corridor on behalf of the Utah Department of Transportation (UDOT). This analysis quantified risk as the probability of threats (earthquakes, floods, fires, etc.) multiplied by the criticality of the asset to the overall system were such threats to materialize. The criticality index consisted of the following elements:

- Average Annual Daily Traffic (AADT)
- Average Annual Daily Truck Traffic (AADTT)
- American Association of State Highway and Transportation Officials (AASHTO) Roadway Classification
- Tourism value in dollars
- Distance to the nearest UDOT maintenance crew

The report does not provide a methodology on how the analysis determined the tourism value of each assets, but otherwise the category definitions are straightforward. Each asset received a category score between 1 and 5, with 1 indicating “very low impact” and 5 indicating “very high impact.” Each of the five categories received equal weight. This methodology clearly identifies frequently used highway facilities; however, there are some limitations to this approach from a resilience or criticality perspective. First, AASHTO roadway classifications are likely to be highly collinear with both AADT and AADTT. But more importantly in the context of this project, the current index treats each UDOT asset – each bridge, highway segment, etc. – as an independent unit when in fact UDOT operates a system of transportation facilities. The criticality of a single bridge to the overall system is not determined by the volume of traffic it supports directly, but by how inconvenient it would be for that traffic to find another path were the bridge to fail. Resiliency must therefore be considered a function of network redundancy.

According to interviews with UDOT staff, AEM has provided a tool to incorporate redundancy and resiliency analysis, but this tool is proprietary and UDOT cannot therefore examine or adapt its methodology. The purpose of this project is to develop and test a methodology for estimating the network redundancy of critical UDOT infrastructure assets that UDOT can use and improve going forward. The research would rely on compound destination- and mode-choice accessibility logsums derived from a regional or statewide travel demand model to examine how disabling a transportation link affects overall transportation accessibility. In a logit-style  econometric mode choice model, the probability of choosing a specific mode k from the set of all choices K is described by the ratio

$$ P(k)=   \frac{\exp⁡(V_k)}{\Sum_{p\in K}(\exp⁡(V_p)}$$

where $V_k$ is the measured relative utility of alternative $k$. In a mode choice context, the utility for each mode is a weighted function of travel time, wait time, fare, traveler attributes, and calibration parameters. Thus the probability equation attempts to compare all meaningful attributes of the alternatives against each other – modes that take longer are less likely to be chosen when the fare and other attributes are the same. The logarithm of the sum in the denominator (called the logsum)

$$CS_K=\log⁡(\Sum_{p\in K}(\exp⁡(V_p))$$

has a special derived interpretation as the consumer surplus $CS$, or the total value of the choice set in $K$. A mode choice logsum represents the total value of traveling between a specific origin and destination pair by all modes. Destination choice models can then use the mode choice logsum as a generalized cost measure instead of travel times by a particular mode. For trips originating at $i$ the probability of choosing a destination $j$ from all possible destinations $J$, the probability of choosing $j$ is

$$P(j)=\frac{\exp (A_j-C_{ijK})}{\Sum_{l\in J}\exp⁡ (A_l-C_{ilK})}$$

where $A_j$ represents the attractiveness at $j$ and $C_{ijK}$ is the mode choice model logsum from $i$ to $j$. Formulating the destination choice model in this way means populations likely to use transit – both low-income groups as well as choice transit riders – are more likely to select destinations accessible by transit. The destination choice logsum
therefore functions as an accessibility term that appropriately weights the attractiveness of all potential destinations with how expensive it is to reach them by all modes. Locations with lower travel times to their available destinations will have higher logsum measures, with the difference scaled by how sensitive travelers in the region are to travel times and costs.

It is possible to compare infrastructure proposals by how much they change the destination choice logsum: proposals that result in a large positive change to the logsums are likely to benefit more people than proposals that change the logsums only modestly. An important benefit of this approach is that it implicitly considers how individuals may change their destination or mode choice as a result of the proposal. Moreover, because the logsum is available for each zone, it is possible to analyze where the individuals most impacted by the proposals live or work.
The converse analysis is also possible: by downgrading or eliminating a highway facility and observing the change in logsum statistics, one can evaluate the relative systemic importance of that facility to travel in the region. If removing a major bridge or highway link leaves the logsum relatively unchanged, then its systemic importance is minimal – individuals will simply travel around it or they can select a new destination or mode and accomplish the same activity. By comparing the effects of removing several different links on the logsum statistics, it is possible to determine which of the links is the most systemically critical from a resilience / redundancy perspective. This method was suggested by Cantillo et al. (2018), but further investigation of that work and a deeper literature search is necessary.
