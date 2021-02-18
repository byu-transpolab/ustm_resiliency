;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJ'
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT",
MO = 10,20,30,40,50,100,200,300,400,500,98,99 DEC = D, NAME = HBWDCProbability, HBODCProbability, NHBDCProbability, HBCDCProbability, RECDCProbability, HBWTrips,HBOTrips,NHBTrips,HBCTrips,RECTrips,CheckRowsum, CheckProd
FILEI ZDATI[2] = "{SCENARIO_DIR}\Output\01_ROWSUMS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
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
    MW[4] = MI.1.4 ;HBC
	  MW[5] = MI.1.5 ;REC

    
    JLOOP
    ;Compute probability
    MW[10] = ((exp(MW[1]))/(exp(ZI.2.LNHBW[J]))) ;HBW
    MW[20] = ((exp(MW[2]))/(exp(ZI.2.LNHBO[J]))) ;HBO
    MW[30] = ((exp(MW[3]))/(exp(ZI.2.LNNHB[J]))) ;NHB
    MW[40] = ((exp(MW[4]))/(exp(ZI.2.LNHBC[J]))) ;HBC
    MW[50] = ((exp(MW[5]))/(exp(ZI.2.LNREC[J]))) ;REC
    ENDJLOOP
    
    
    JLOOP
	  ; Compute Trips
    MW[98] = ZI.2.LNHBW[J]
    MW[99] = ZI.1.HBWP[J]
		MW[100] = MW[10] * ZI.1.HBWP[J] 
    MW[200] = MW[20] * ZI.1.HBOP[J] 
    MW[300] = MW[30] * ZI.1.NHBP[J] 
    MW[400] = MW[40] * ZI.1.HBSCP[J] 
    MW[500] = MW[50] * ZI.1.RECP[J] 
       
    ENDJLOOP
    ;Print Probability Values * 100 to check accuracy
    MW[10] = ((exp(MW[1]))/(exp(ZI.2.LNHBW[J])))*1000 ;HBW
    MW[20] = ((exp(MW[2]))/(exp(ZI.2.LNHBO[J])))*1000 ;HBO
    MW[30] = ((exp(MW[3]))/(exp(ZI.2.LNNHB[J])))*1000 ;NHB
    MW[40] = ((exp(MW[4]))/(exp(ZI.2.LNHBC[J])))*1000 ;HBC
    MW[50] = ((exp(MW[5]))/(exp(ZI.2.LNREC[J])))*1000 ;REC
    
    MW[100] = MW[10] * ZI.1.HBWP[J] /1000
    MW[200] = MW[20] * ZI.1.HBOP[J] /1000
    MW[300] = MW[30] * ZI.1.NHBP[J] /1000
    MW[400] = MW[40] * ZI.1.HBSCP[J] /1000
    MW[500] = MW[50] * ZI.1.RECP[J] /1000

ENDRUN
