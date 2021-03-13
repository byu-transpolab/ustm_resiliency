;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY MSG='Mode and Destination Choice Model'
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = D, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\scenario_network.net"

PROCESS PHASE=LINKREAD
; Use this phase to obtain initial values from the input network (LI.varname) and compute 
; link values (LW.varname) that can be used in other phases.

; Use congested Time for initial skim
 AM_TIME = 1
 T0=LI.AM_TIME

ENDPROCESS

PROCESS PHASE=ILOOP
; This phase performs a zonal loop (I=1,Zones).  This phase is required and must contain
; at least 1 PATHLOAD statement.  Almost all MATRIX operation are available in this phase
; and the PATHLOAD statement can be used to build and load paths for assignment

;# skim network for time and distance
  PATHLOAD PATH=TIME,MW[1]=PATHTRACE(TIME),MW[2]=PATHTRACE(LI.DISTANCE)
  MW[1][I] = rowmin(1) * 0.5 ; Intrazonal time is half of the time to the nearest zone.
  MW[2][I] = 0                ; Set Intrazonal Dist = 0

  ;# Total Impedance including terminal times
  MW[3] = MW[1]+MW[2]
   
ENDPROCESS

ENDRUN
