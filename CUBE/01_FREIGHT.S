;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="C:\projects\ustm_resiliency\CUBE\resi0021.PRN"
FILEO PRINTO[1] = "C:\projects\ustm_resiliency\Base\logs\freight_cost.txt"
FILEI MATI[1] = "{CATALOG_DIR}\Inputs\01_HIGHWAY_SKIMS_INITIAL.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[5] = "{CATALOG_DIR}\Inputs\OD_rec_DY.mat"
FILEI MATI[4] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT",
  MO = 103,203,303,403,503,603,703,803,903, DEC = D, NAME = IIF, IXF, XXF, XIF, XXP, HBW, HBO, NHB, REC
FILEI MATI[3] = "{CATALOG_DIR}\Inputs\USTM_Passenger_XX.mtx"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\IIIXXIXX_LH_Ton_Truck_Utah.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

;REC VOT = 7.8 $/hr
;Freight VOT = 24 $/hr

;Fill matrices
  MW[1]=MI.2.13 ;Total Freight
  MW[20]=MI.3.2 ;XXPassenger
  MW[21]=MI.3.3 ;XXBus
  MW[22]=MI.3.4 ;XXREC
  MW[23]=MI.3.5 ;XXOther
  MW[3]=MI.5.1 ;REC Trips
  MW[4]=MI.1.1 ;Initial Time Skim
  MW[5]=MI.4.4 ;HBW Trips
  MW[6]=MI.4.5 ;HBO Trips
  MW[7]=MI.4.6 ;NHB Trips
  MW[8]=MI.6.1 ;Broken Time Skim
  
;Compute travel time diff
  MW[9] = MW[8] - MW[4]
  
;Compute IIFreight Values
IF(I = 1-27 && J >= 31) 
  MW[100] = (MW[1])/365
  MW[101] = (MW[9])/60
  MW[102] = MW[100] * MW[101]
  MW[103] = MW[102] * 24
ENDIF

;Compute IXFreight Values
IF(I >= 31 && J <= 27)
  MW[200] = (MW[1])/365
  MW[201] = (MW[9])/60
  MW[202] = MW[200] * MW[201]
  MW[203] = MW[202] * 24 
ENDIF

;Compute XXFreight Values
IF(I < 28 && J < 28)
  MW[300] = (MW[1])/365
  MW[301] = (MW[9])/60
  MW[302] = MW[300] * MW[301]
  MW[303] = MW[302] * 24
ENDIF

;Compute XIFreight Values
IF(I < 28 && J > 28)
  MW[400] = (MW[1])/365
  MW[401] = (MW[9])/60
  MW[402] = MW[400] * MW[401]
  MW[403] = MW[402] * 24
ENDIF

;Compute HBW Values internal
IF(I > 28 && J > 28)
  MW[500] = (MW[5])/365
  MW[501] = (MW[9])/60
  MW[502] = MW[500] * MW[501]
  MW[503] = MW[502] * 7.8
ENDIF

;Compute HBO Values internal
IF(I > 28 && J > 28)
  MW[600] = (MW[6])/365
  MW[601] = (MW[9])/60
  MW[602] = MW[600] * MW[601]
  MW[603] = MW[602] * 7.8
ENDIF

;Compute NHB Values internal
IF(I > 28 && J > 28)
  MW[700] = (MW[7])/365
  MW[701] = (MW[9])/60
  MW[702] = MW[700] * MW[701]
  MW[703] = MW[702] * 7.8
ENDIF

;Compute REC Values internal
IF(I > 28 && J > 28)
  MW[800] = (MW[3])/365
  MW[801] = (MW[9])/60
  MW[802] = MW[800] * MW[801]
  MW[803] = MW[802] * 7.8
ENDIF

;Compute Total XX Passenger
  MW[2] = MW[20] + MW[21] + MW[22] + MW[23]
  
  ;Compute XXPassenger Values
IF(I < 28 && J < 28)
  MW[14] = (MW[3] * (MW[9]/60))*7.8 
  
    MW[900] = (MW[1])/365
  MW[901] = (MW[9])/60
  MW[902] = MW[900] * MW[901]
  MW[903] = MW[902] * 24
  
ENDIF

; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='FREIGHTCOST TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' FREIGHTCOST \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n IIFreight                                 ', MW[10] 
      PRINT PRINTO=1 CSV=F LIST ='\n IXFreight                                 ', MW[11] 
      PRINT PRINTO=1 CSV=F LIST ='\n XXFreight                                 ', MW[12]
      PRINT PRINTO=1 CSV=F LIST ='\n XIFreight                                 ', MW[13]
      PRINT PRINTO=1 CSV=F LIST ='\n XXPassenger                               ', MW[14]
      PRINT PRINTO=1 CSV=F LIST ='\n HBW Values                                ', MW[15]
      PRINT PRINTO=1 CSV=F LIST ='\n HBO Values                                ', MW[16]
      PRINT PRINTO=1 CSV=F LIST ='\n NHB Values                                ',MW[17]
		  PRINT PRINTO=1 CSV=F LIST ='\n REC Values                                ', MW[18]  

   ENDIF
     
 ENDJLOOP


ENDRUN
