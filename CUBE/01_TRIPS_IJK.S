;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Calculate Trips_ijk'
FILEO MATO[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_TRIPS_IJK.MAT",
  MO = 40-47,100, 200,300,400,110,210,310,410,510,120,220,320,420,520 DEC = 30, NAME = HBWTrips,HBOTrips,NHBTrips,HBCTrips,RECTrips,autoTrips,nmotTrips,transitTrips,HBWauto,HBOauto,NHBauto,HBCauto,RECauto,HBWnmot,HBOnmot,NHBnmot,HBCnmot,RECnmot,HBWtransit,HBOtransit,NHBtransit,HBCtransit,RECtransit
FILEI MATI[1] = "{CATALOG_DIR}\CUBE\01_TRIPS_IJ.MAT"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED_PROBABILITY.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.
	

 ;Fill Trips into matrices
		MW[1] = MI.1.6 ;HBW
		MW[2] = MI.1.7 ;HBO
    MW[3] = MI.1.8 ;NHB
    MW[4] = MI.1.9 ;HBC
	  MW[5] = MI.1.10 ;REC
    
 ;Fill MC auto_prob into matrices
    MW[11] = MI.2.1 ;HBW
		MW[12] = MI.2.2 ;HBO
    MW[13] = MI.2.3 ;NHB
    MW[14] = MI.2.4 ;HBC
	  MW[15] = MI.2.5 ;REC
    
  ;Fill MC nmot_prob into matrices
    MW[21] = MI.2.6 ;HBW
		MW[22] = MI.2.7 ;HBO
    MW[23] = MI.2.8 ;NHB
    MW[24] = MI.2.9 ;HBC
	  MW[25] = MI.2.10 ;REC
  
  ;Fill MC transit_prob into matrices
    MW[31] = MI.2.11 ;HBW
		MW[32] = MI.2.12 ;HBO
    MW[33] = MI.2.13 ;NHB
    MW[34] = MI.2.14 ;HBC
	  MW[35] = MI.2.15 ;REC   
    
    ;JLOOP
    ;Compute trips by mode choice and purpose
    MW[100] = MW[1] * MW[11] ;HBWauto
    MW[200] = MW[2] * MW[12] ;HBOauto
    MW[300] = MW[3] * MW[13] ;NHBauto
    MW[400] = MW[4] * MW[14] ;HBCauto
    MW[500] = MW[5] * MW[15] ;RECauto
    MW[110] = MW[1] * MW[21] ;HBWnmot
    MW[210] = MW[2] * MW[22] ;HBOnmot
    MW[310] = MW[3] * MW[23] ;NHBnmot
    MW[410] = MW[4] * MW[24] ;HBCnmot
    MW[510] = MW[5] * MW[25] ;RECnmot
    MW[120] = MW[1] * MW[31] ;HBWtransit
    MW[220] = MW[2] * MW[32] ;HBOtransit
    MW[320] = MW[3] * MW[33] ;NHBtransit
    MW[420] = MW[4] * MW[34] ;HBCtransit
    MW[520] = MW[5] * MW[35] ;RECtransit
    ;ENDJLOOP
    
    ;JLOOP
    ;Compute trips by trip purpose
    MW[40] = MW[100] + MW[110] + MW[120] ;HBW
    MW[41] = MW[200] + MW[210] + MW[220] ;HBO
    MW[42] = MW[300] + MW[310] + MW[320] ;NHB
    MW[43] = MW[400] + MW[410] + MW[420] ;HBC
    MW[44] = MW[500] + MW[510] + MW[520] ;REC
    ;ENDJLOOP
    
    ;JLOOP
    ;Compute total trips by mode choice
    MW[45] = MW[100] + MW[200] + MW[300] + MW[400] + MW[500] ;auto
    MW[46] = MW[110] + MW[210] + MW[310] + MW[410] + MW[510] ;nmot
    MW[47] = MW[120] + MW[220] + MW[320] + MW[420] + MW[520] ;transit
   
    ;ENDJLOOP
    
ENDRUN
