;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="C:\projects\ustm_resiliency\CUBE\resi0021.PRN"
FILEI MATI[4] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT"
FILEO PRINTO[1] = "C:\projects\ustm_resiliency\Base\logs\freight_cost.txt"
FILEI MATI[1] = "{CATALOG_DIR}\Inputs\01_HIGHWAY_SKIMS_INITIAL.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[5] = "{CATALOG_DIR}\Inputs\OD_rec_DY.mat"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT",
  MO = 103,203,303,403,503,603,703,803,903,9, DEC = D, NAME = IIF, XXF, IXF, HBW, HBO, NHB, REC, XXP, Timediff
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
  MW[5]=MI.4.9 ;HBW Trips
  MW[6]=MI.4.10 ;HBO Trips
  MW[7]=MI.4.11 ;NHB Trips
  MW[8]=MI.6.1 ;Broken Time Skim
  
;Compute travel time diff
  MW[9] = MW[8] - MW[4]
  
 ;Compute all freight
   MW[80] = ((MW[1])/365 * (MW[9])/60) * 24
   MW[90] = 1;MW[9]/60 * 7.8
    
   MW[300] = 0 ;XXF
   MW[100] = 0 ;IIF
   MW[200] = 0 ;XIF & IXF
   JLOOP
   IF (I<28 && J<28)
    MW[200] = 1
   ELSEIF (I<28 | J<28)
    MW[300] = 1
   ELSE
    MW[100] = 1
   ENDIF
    ENDJLOOP
    
   MW[103] = MW[80] * MW[100]
   MW[203] = MW[80] * MW[200]
   MW[303] = MW[80] * MW[300]
   
   ;HBW
   MW[403] = MW[5] * MW[90]
   ;NHB
   MW[603] = MW[6] * MW[90]
   ;HBO
   MW[503] = MW[7] * MW[90]
   ;REC
   MW[803] = MW[3] * MW[90]

   ;XXPassenger
   MW[901] = MW[20] + MW[21] + MW[22] + MW[23]
   MW[903] = MW[901] * MW[9]/60 * 7.8


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
