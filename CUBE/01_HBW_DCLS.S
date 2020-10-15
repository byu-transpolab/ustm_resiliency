;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEO RECO[1] = "{SCENARIO_DIR}\01_HBW_DCLS_ROWSUM.DBF",
  FIELDS = A, lnHBW, lnHBO, lnNHB, lnHBC, lnREC
FILEO PRINTO[3] = "{SCENARIO_DIR}\01_HBW_ZONAL_TRIPS.CSV"
FILEO PRINTO[2] = "{SCENARIO_DIR}\01_HBW_DEST_CHOICE_DEBUG.TXT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\01_HBW_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\01_DEST_HBW.MAT",
  MO = 112, 212, 313, 412, 523, 100, 200, 300, 400, 500, DEC = 8, NAME = HBWSizeTerm, HBOSizeTerm, 
    NHBSizeTerm, HBCSizeTerm, RECSizeTerm, HBWUtil, HBOUtil, NHBUtil, HBCUtil, RECUtil
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{SCENARIO_DIR}\se_classified_2012A.dbf"
FILEI MATI[2] = "{SCENARIO_DIR}\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_MCLS_COMBINED.MAT"


; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {Total ZONES}
		ARRAY personTrips = ZONES

		; READ IN MODEL PARAMETERS
		LOOKUP, NAME=COEFF, LOOKUP[1]=NVAR, RESULT=HBW, INTERPOLATE=N, LIST=Y, LOOKUPI=1
    
		Coeff_HH = COEFF(1,1)              ; SizeTerm = household coefficient
		Coeff_OTH_OFF_EMP = COEFF(1,2)     ; SizeTerm = Other + Office Emp coefficient
		Coeff_OFF_EMP = COEFF(1,3)         ; SizeTerm = Office Emp coefficient
		Coeff_OTH_EMP = COEFF(1,4)         ; SizeTerm = Other Emp coefficient
		Coeff_RET_EMP = COEFF(1,5)         ; SizeTerm = Retail Emp coefficient
		DISTCAP       = COEFF(1,6)         ; Capped distance (this is a value, not coefficient) ?
		CLSUM         = COEFF(1,7)         ; Logsum coefficient
		CDIST         = COEFF(1,8)         ; distance coefficient 
		CDISTSQ       = COEFF(1,9)         ; distance square coeffficient
		CDISTCUB      = COEFF(1,10)        ; distance cube coefficient
		CDISTLN       = COEFF(1,11)        ; distance log coefficient		
		KINTRAZ       = COEFF(1,12)        ; Intrazonal constant
		KDIST01       = COEFF(1,13)        ; distance calibration constant (0-1 Mile)
		KDIST12       = COEFF(1,14)        ; distance calibration constant (1-2 Mile)
		KDIST23       = COEFF(1,15)        ; distance calibration constant (2-3 Mile)
		KDIST34       = COEFF(1,16)        ; distance calibration cOnstant (3-4 Mile)
		KDIST45       = COEFF(1,17)        ; distance calibration constant (4-5 Mile)
		KDIST56       = COEFF(1,18)        ; distance calibration constant (5-6 Mile)
		KDIST67       = COEFF(1,19)        ; distance calibration constant (6-7 Mile)

		; Mode choice logsums
		MW[101] = MI.1.1 ;HBW logsum
    MW[201] = MI.1.2 ;HBO logsum
		MW[301] = MI.1.3 ;NHB logsum
    MW[401] = MI.1.4 ;HBC logsum
    MW[501] = MI.1.5 ;REC logsum
    
		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN HBW DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		  MW[112] = Coeff_HH * ZI.1.HH[J] + Coeff_OFF_EMP * ZI.1.OFF[J] + Coeff_RET_EMP * (ZI.1.RET[J] + ZI.1.HTRET[J]) + Coeff_OTH_EMP * (ZI.1.EMP_NOSG[J] - ZI.1.OFF[J]  - ZI.1.RET[J] - ZI.1.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.1.EMP_NOSG[J] - ZI.1.RET[J] - ZI.1.HTRET[J])
      
		  ; Log (sizeTerm)
		  IF(MW[112] > 0)   MW[113] = Ln(MW[112])  
		
		  ; Intrazonal boolean
		  IF(J == I) MW[111] = 1
		
		  ; Hwy distance
		  IF (MI.2.Distance < DISTCAP)  MW[2] = MI.2.Distance  
		  IF (MI.2.Distance > 0)  MW[114] = Ln(MI.2.Distance) 
		  		
		  ; Distance calibration constants          
		  IF(MW[2] > 0 && MW[2] <=1) MW[115] = KDIST01    ; Calibration constant for distance 0-1 bin
		  IF(MW[2] > 1 && MW[2] <=2) MW[115] = KDIST12    ; Calibration constant for distance 1-2 bin
		  IF(MW[2] > 2 && MW[2] <=3) MW[115] = KDIST23    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[115] = KDIST34    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[115] = KDIST45    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[115] = KDIST56    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[115] = KDIST67    ; Calibration constant for distance 2-5 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[100] =  CLSUM * MW[101] +                ; modechoice logsum
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[114] + 						; log(distance)  
		             MW[113] + 											; log(sizeterm)  
		             KINTRAZ * MW[111] +            ; intrazonal        
		             MW[115] +                      ; calibration distance  
		             MW[116]                        ; Shadow Price 
		ENDJLOOP

  	; Destination choice model 
  	XCHOICE,  
  	ALTERNATIVES = All, 
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{Total ZONES},
  	STARTMW = 119 
    
; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='DESTINTION CHOICE TRACE @PURP@','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' Destination Choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -                   @PURP@  '
	  	PRINT PRINTO=1 CSV=F LIST ='\n Size Term is computed on the Destination '	  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = household coefficient                    ', Coeff_HH          , ' * ' , ZI.2.HH[J]  
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Other + Office Emp coefficient           ', Coeff_OTH_OFF_EMP , ' * ' , ZI.2.EMP[J], ZI.2.RET[J] ,ZI.2.HTRET[J]   
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Office Emp coefficient                   ', Coeff_OFF_EMP     , ' * ' , ZI.2.OFF[J] 
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Other Emp coefficient                    ', Coeff_OTH_EMP     , ' * ' , ZI.2.EMP[J],  ZI.2.OFF[J], ZI.2.RET[J], ZI.2.HTRET[J] 
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Retail Emp coefficient                   ', Coeff_RET_EMP     , ' * ' , ZI.2.RET[J] , ZI.2.HTRET[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n Capped distance (this is a value)  								 ', DISTCAP             
		  PRINT PRINTO=1 CSV=F LIST ='\n Logsum coefficient                                  ', CLSUM             , ' * ' , MW[101]   
		  PRINT PRINTO=1 CSV=F LIST ='\n distance coefficient                                ', CDIST             , ' * ' , MW[2]  
		  PRINT PRINTO=1 CSV=F LIST ='\n distance square coeffficient                        ', CDISTSQ           , ' * ' , POW(MW[2],2)    
		  PRINT PRINTO=1 CSV=F LIST ='\n distance cube coefficient                           ', CDISTCUB          , ' * ' , POW(MW[2],3)   
		  PRINT PRINTO=1 CSV=F LIST ='\n distance log coefficient                            ', CDISTLN           , ' * ' , MW[114] 		  
		  PRINT PRINTO=1 CSV=F LIST ='\n Intrazonal constant                                 ', KINTRAZ           , ' * ' , MW[111]  
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (0-1 Mile)            ', KDIST01           
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (1-2 Mile)            ', KDIST12            
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (2-3 Mile)            ', KDIST23            
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (3-4 Mile)            ', KDIST34            
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (4-5 Mile)            ', KDIST45            
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (5-6 Mile)            ', KDIST56            
		  PRINT PRINTO=1 CSV=F LIST ='\n distance calibration constant (6-7 Mile)            ', KDIST67            
		  PRINT PRINTO=1 CSV=F LIST ='\n Applied  calibration constant                       ', MW[113]
      PRINT PRINTO=1 CSV=F LIST ='\n Size Term                                           ', MW[112] 
      PRINT PRINTO=1 CSV=F LIST ='\n Ln(Size Term)                                       ', MW[113]     
		  PRINT PRINTO=1 CSV=F LIST ='\n Computed Utility                                    ', MW[100]            	  
		  PRINT PRINTO=1 CSV=F LIST ='\n Total Productions in Origin                         ', personTrips[I]     			  
		  PRINT PRINTO=1 CSV=F LIST ='\n Trip Attractions                                    ', MW[119]            		  
   ENDIF
    
   ; Report total intrazonals 
    IF(I = J)  INTRAZONAL_sum = INTRAZONAL_sum + MW[119]
    IF (I = ZONES && J = ZONES) PRINT PRINTO=1 CSV=F LIST ='\n Intrazonal Sum            ', INTRAZONAL_sum 
 ENDJLOOP


;SeU = 0
SeHBW = 0
SeHBO = 0
SeHBC = 0
SeNHB = 0
SeREC = 0
;A = 1
JLOOP
 ;SeU = SeU + exp(MW[100])
 ;Ro.SeU = SeU
 ;Ro.lnS = ln(SeU)
  A = ZI.1.TAZ
  SeHBW = SeHBW + exp(MW[100])
  ;SeHBO = SeHBO + exp(MW[200])
  ;SeNHB = SeNHB + exp(MW[300])
  ;SeHBC = SeHBC + exp(MW[400])
  ;SeREC = SeREC + exp(MW[500])
ENDJLOOP
  Ro.A = A
  Ro.lnHBW = ln(SeHBW)
  ;Ro.lnHBO = ln(SeHBO)
  ;Ro.lnNBH = ln(SeNHB)
  ;Ro.lnHBC = ln(SeHBC)
  ;Ro.lnREC = ln(SeREC)

WRITE RECO = 1
    
 ;Write in stuff that computes the dcls ,using the utilities 
 ;create another matrix thta writes out the utilites for each matrix (HBW)

ENDRUN
