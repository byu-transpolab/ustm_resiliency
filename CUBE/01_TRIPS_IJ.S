;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJ'
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\trips_ij_trace.txt"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT",
MO = 10,20,30,40,50,100,200,300,400,500,98,99 DEC = D, NAME = HBWDCProbability, HBODCProbability, NHBDCProbability, HBCDCProbability, RECDCProbability, HBWTrips,HBOTrips,NHBTrips,HBCTrips,RECTrips,CheckRowsum, CheckProd
FILEI ZDATI[2] = "{SCENARIO_DIR}\Output\01_ROWSUMS.DBF"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINED.MAT"


; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

;equation here is probability = (e^u)/rowsum(e^u)


ZONES = {TOTAL_ZONES}
		ARRAY personTrips = TOTAL_ZONES
    
    	;Fill DC Utility into matrices
		MW[1] = MI.1.1 ;HBW
		MW[2] = MI.1.2 ;HBO
    MW[3] = MI.1.3 ;NHB
    ;MW[4] = MI.1.4 ;HBC
	  MW[5] = MI.1.5 ;REC

    
    JLOOP
    ;Compute probability
    MW[10] = ((exp(MW[1]))/(exp(ZI.2.LNHBW[J]))) ;HBW
    MW[20] = ((exp(MW[2]))/(exp(ZI.2.LNHBO[J]))) ;HBO
    MW[30] = ((exp(MW[3]))/(exp(ZI.2.LNNHB[J]))) ;NHB
    ;MW[40] = ((exp(MW[4]))/(exp(ZI.2.LNHBC[J]))) ;HBC
    MW[50] = ((exp(MW[5]))/(exp(ZI.2.LNREC[J]))) ;REC
    ENDJLOOP
    
    
    JLOOP
	  ; Compute Trips
    MW[98] = ZI.2.LNHBW[J]
    MW[99] = ZI.1.HBWP[J]
		MW[100] = MW[10] * ZI.1.HBWP[J] 
    MW[200] = MW[20] * ZI.1.HBOP[J] 
    MW[300] = MW[30] * ZI.1.NHBP[J] 
    ;MW[400] = MW[40] * ZI.1.HBSCP[J] 
    MW[500] = MW[50] * ZI.1.RECP[J] 
       
    ENDJLOOP

    ; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='TRIPS IJ TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' Trips IJ Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -                   @PURP@  '	  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n HBW Utility                                         ', MW[1]  
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Utility                                         ', MW[2]  
		  PRINT PRINTO=1 CSV=F LIST ='\n NHB Utility                                         ', MW[3] 
		  ;PRINT PRINTO=1 CSV=F LIST ='\n Freight Utility                                     ', MW[4]
		  PRINT PRINTO=1 CSV=F LIST ='\n REC Utility                                         ', MW[5]
		  PRINT PRINTO=1 CSV=F LIST ='\n HBW Probability  								                   ', MW[10],'=(',exp(MW[1]),')/e^',ZI.2.LNHBW[J]          
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Probability                                     ', MW[20],'=(',exp(MW[2]),')/e^',ZI.2.LNHBO[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n NHB Probability                                     ', MW[30],'=(',exp(MW[3]),')/e^',ZI.2.LNNHB[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n Freight Probability                                 ', MW[40],'=(',exp(MW[4]),')/e^',ZI.2.LNHBC[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n REC Probability                                     ', MW[50],'=(',exp(MW[5]),')/e^',ZI.2.LNREC[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n HBW Trips                                           ', MW[100],'=', ZI.1.HBWP[J]      , ' * ' , MW[10] 		  
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Trips                                           ', MW[200],'=', ZI.1.HBOP[J]      , ' * ' , MW[20] 
      PRINT PRINTO=1 CSV=F LIST ='\n NHB Trips                                           ', MW[300],'=', ZI.1.NHBP[J]      , ' * ' , MW[30] 		  
		  ;PRINT PRINTO=1 CSV=F LIST ='\n FREIGHT Trips                                       ', MW[400],'=', ZI.1.FREIGHTP[J]  , ' * ' , MW[40]
      PRINT PRINTO=1 CSV=F LIST ='\n REC Trips                                           ', MW[500],'=', ZI.1.RECP[J]      , ' * ' , MW[50]

   ENDIF
     
 ENDJLOOP
    
    
ENDRUN
