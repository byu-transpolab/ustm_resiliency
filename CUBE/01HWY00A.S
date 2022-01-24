;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY PRNFILE="C:\projects\ustm_resiliency\Base\intermediate_outputs\01_LOADED_NETWORK.PRN" MSG='Congested Network'
FILEI MATI[3] = "{CATALOG_DIR}\Inputs\USTM_Passenger_XX.mtx"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\LH_Truck.mtx"
FILEO NETO = "{SCENARIO_DIR}\Output\loaded_network.NET"
FILEI NETI = "{SCENARIO_DIR}\scenario_network.NET"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT"

;Set run PARAMETERS and Controls
PARAMETERS MAXITERS=100, COMBINE=EQUI, GAP= 0.0, RELATIVEGAP = 0.00001

PHASE=LINKREAD

   T0 = 60* (LI.DISTANCE/LI.FF_SPD)
   C  = LI.AM_CAP
   LW.COSTa = T0 + 0.25*LI.DISTANCE
 
ENDPHASE

PHASE=ILOOP
  ; HBW PA to OD
  HBW_ToD = 0.2746
  HBW_Dir = 0.9301
  MW[1] = MI.1.7 * HBW_ToD * HBW_Dir
  
  ; HBO
  HBO_ToD = 0.0755
  HBO_Dir = 0.7847
  MW[2] = MI.1.8 * HBO_ToD * HBO_Dir
  
  ; NHB
  NHB_ToD = 0.0641
  NHB_Dir = 0.5000
  MW[3] = MI.1.9 * NHB_ToD * NHB_Dir
  
  ; Freight, PCE_HV PA to OD
  FREIGHT_ToD = 0.1590
  FREIGHT_Dir = 0.5000
  PCE_HV = 2.0
  MW[4] = MI.2.1 * PCE_HV * FREIGHT_ToD * FREIGHT_Dir
  
  ; External Passenger PA to OD
  XXP_ToD = 0.1236
  XXP_Dir = 0.7262
  MW[5] = MI.3.2 * XXP_ToD * XXP_Dir
  
  ; Count Daily OD Trips
  MW[6] = MW[1] + MW[2] + MW[3] + MW[4] + MW[5]
 
  ; Assign trips 
  PATHLOAD PATH=LW.COSTa, VOL[1] = MW[6]
                                                                         
ENDPHASE


; Report to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='OD Trips TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST ='\n HBW OD                                 ', MW[1] 
      PRINT PRINTO=1 CSV=F LIST ='\n HBO OD                                 ', MW[2]
	  	PRINT PRINTO=1 CSV=F LIST ='\n NHB OD                                 ', MW[3] 
      PRINT PRINTO=1 CSV=F LIST ='\n Freight OD                             ', MW[4] 
      PRINT PRINTO=1 CSV=F LIST ='\n XX Passenger OD                        ', MW[5]
      PRINT PRINTO=1 CSV=F LIST ='\n Daily OD Trips                         ', MW[6] 
 
   ENDIF
     
 ENDJLOOP

ENDRUN
