# USTM Resiliency

This repository contains a Cube model designed to measure the
resiliency of links in the Utah statewide highway network by
considering the change in mode and destination choice
logsums resulting from a break in the highway network.

## Model Setup
This model runs using the CUBE travel demand modeling software. The
`ustm_resiliency.cat` Cube catalog will open an application manager in Cube
with the model. The other folders are as follows:

  - `Base/` Base scenario directory. Child scenarios will be created in this folder.
  - `Inputs/` Global inputs directory; contains transit, freight, and other files that do
    not change between scenarios. 
  - `CUBE/` Model script and application files
  - `params/` Model parameters
  - `Reports/` Calibration and fit report files for Cube.

View the [USTM Resiliency Wiki](https://github.com/byu-transpolab/ustm_resiliency/wiki/) for more details on the model and how to run scenarios.
