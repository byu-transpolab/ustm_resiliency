;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\{SCENARIO_DIR}\intermediate_outputs\resi0021.PRN" MSG='Compute Costs'
FILEI MATI[1] = "C:\projects\ustm_resiliency\Base\Output\01_LOADED_HIGHWAY_SKIMS.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT"
FILEI MATI[4] = "C:\projects\ustm_resiliency\Base\intermediate_outputs\01_TRIPS_IJK.MAT"
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_COMBINED_TRIPS.MAT",
  MO = 1, 901, 3,5,6,7,4,8,9 DEC = D, NAME = Freight, Pass, REC, HBW, HBO, NHB, ITime, BTime, TDiff
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\freight_cost.txt"
FILEI MATI[5] = "{CATALOG_DIR}\Inputs\OD_rec_DY.mat"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRAVELTIME_COSTS.MAT",
  MO = 103,203,303,403,503,603,803,903,9, DEC = D, NAME = IIF, XXF, IXF, HBW, HBO, NHB, REC, XXP, Timediff
FILEI MATI[3] = "{CATALOG_DIR}\Inputs\USTM_Passenger_XX.mtx"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\LH_Truck.mtx"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

;Fill matrices
  MW[1]=MI.2.1 ;Total Freight
  MW[20]=MI.3.2 ;XXPassenger
  MW[21]=MI.3.3 ;XXBus
  MW[22]=MI.3.4 ;XXREC
  MW[23]=MI.3.5 ;XXOther
  MW[3]=MI.5.1 ;REC Trips
  MW[4]=MI.1.1 ;Initial Time Skim
  MW[5]=MI.4.7 ;HBW Trips from Base
  MW[6]=MI.4.8 ;HBO Trips from Base
  MW[7]=MI.4.9 ;NHB Trips from Base
  MW[8]=MI.6.1 ;Broken Time Skim
  
;Compute travel time diff
  MW[9] = MW[8] - MW[4]
  
 ;Compute all freight
   MW[80] = ((MW[1]) * (MW[9])) * 156.73 ; vehicles/day * minutes * cents = cents/day
   MW[90] = MW[9] * 29.45 ; Minutes * cents/min = cents
    
   MW[300] = 0 ;XXF
   MW[100] = 0 ;IIF
   MW[200] = 0 ;XIF & IXF
  JLOOP
   IF (I<28 && J<28) ;referencing only external zones
    MW[200] = 1
   ELSEIF (I<28 | J<28) ;referencing external zones in I or J
    MW[300] = 1
   ELSE ;referencing all zones
    MW[100] = 1
   ENDIF
  ENDJLOOP
     
   MW[103] = MW[80] * MW[100] ;IIF
   MW[203] = MW[80] * MW[200] ;XXF
   MW[303] = MW[80] * MW[300] ;IXF
   
   ;HBW
   MW[403] = MW[5] * MW[90] ;vehicles * cents = total cents per day
   ;HBO
   MW[503] = MW[6] * MW[90] ;vehicles * cents = total cents per day
   ;NHB
   MW[603] = MW[7] * MW[90] ;vehicles * cents = total cents per day
   ;REC
   MW[803] = MW[3] * MW[90] ;vehicles * cents = total cents per day

   ;XXPassenger
   MW[901] = MW[20] + MW[21] + MW[22] + MW[23]
   MW[903] = MW[901] * MW[90] 
   


; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='FREIGHTCOST TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' FREIGHTCOST \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n IIFreight                                 ', MW[100] 
      PRINT PRINTO=1 CSV=F LIST ='\n IXXIFreight                               ', MW[200] 
      PRINT PRINTO=1 CSV=F LIST ='\n XXFreight                                 ', MW[300]
      PRINT PRINTO=1 CSV=F LIST ='\n XXPassenger                               ', MW[903]
      PRINT PRINTO=1 CSV=F LIST ='\n HBW Values                                ', MW[403]
      PRINT PRINTO=1 CSV=F LIST ='\n HBO Values                                ', MW[503]
      PRINT PRINTO=1 CSV=F LIST ='\n NHB Values                                ', MW[603]
		  PRINT PRINTO=1 CSV=F LIST ='\n REC Values                                ', MW[803]  

   ENDIF
     
 ENDJLOOP


ENDRUN
