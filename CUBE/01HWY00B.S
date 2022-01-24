;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = D, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\Output\loaded_network.NET"

PROCESS PHASE=LINKREAD

 TIME_1 = 1
 T0=LI.TIME_1

ENDPROCESS

PROCESS PHASE=ILOOP


; skim network for time and distance
  PATHLOAD PATH=TIME,MW[1]=PATHTRACE(TIME),MW[2]=PATHTRACE(LI.DISTANCE)
  MW[1][I] = rowmin(1) * 0.5 ; Intrazonal time is half of the time to the nearest zone.
  MW[2][I] = 0                ; Set Intrazonal Dist = 0

  ; Total Impedance including terminal times
  MW[3] = MW[1]+MW[2]
   
ENDPROCESS

ENDRUN
