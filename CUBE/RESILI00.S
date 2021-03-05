; Script for program HIGHWAY in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_HIGHWAY.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY MSG='Whole Network'
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = D, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\BY_2015.NET"

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


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\Base\01_HBW_MCLS.S"
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBW_MCLS.PRN" MSG='HBW MCLS'
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[2] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=HBWlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_UTILITY.MAT",
   MO=111-113, DEC=D,NAME=HBWauto_util,HBWnonmot_util,HBWtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_PROBABILITY.MAT",
  MO=31-33, DEC=D, NAME=HBWauto_prob,HBWnonmot_prob,HBWtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1        ;Walk bus time


; Progress Bar update for evey 100 zones
zonemsg=50
    
; Declare arrays to hold alternative specific constants
;        ARRAY PARK=2578
 ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1 
 ARRAY TYPE=C30 MARKET_NAME=1
    
; Read alternative specific Constants
LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=3, INTERPOLATE=N, , LIST=Y, LOOKUPI=2
    
; Read mode choice coefficients
LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=3, INTERPOLATE=N, LIST=Y, LOOKUPI=1 

IF (i=FirstZone)

  ; constants
   K_AUT  = CONSTANTS(1,1)                 ; auto 
   K_SR  = CONSTANTS(1,1)                  ; shared-ride 2 & 3+
   K_TRN  = CONSTANTS(1,2)                 ; transit
   K_NMOT = CONSTANTS(1,3)                 ; non-motorized (walk & bike)
     
; Mode-specific constants 
   K_PREM = CONSTANTS(1,4)                 ; premium transit
                                        
; Nesting coefficients
   NC_1        = COEFF(1,14)               ; Level 1 - auto, trn, non-mot
   NC_2        = COEFF(1,15)               ; Level 2 - transit sub mode choice
   NC_3        = COEFF(1,16)               ; Level 3 - not used
   ;NCP = NC_1 * NC_2

   ; Level of Service Coefficients
  COEFF_IVTT   = COEFF(1,1)                ; In-vehicle travel time coefficient
  COEFF_SWAIT  = COEFF(1,2)                ; Short wait(<5 minutes)
  COEFF_LWAIT  = COEFF(1,3)                ; Long wait (>5 minutes)
  COEFF_XWAIT  = COEFF(1,4)                ; Xfer wait
  COEFF_DRIVE  = COEFF(1,6)                ; Drive access
  COEFF_TERML  = COEFF(1,7)                ; Terminal time
  COEFF_WALK   = COEFF(1,8)                ; Walk access
  COEFF_WALK1  = COEFF(1,9)                ; Walk time < 1
  COEFF_WALK2  = COEFF(1,10)               ; Walk time > 1
  COEFF_BIKE1  = COEFF(1,11)               ; Bike time < 1
  COEFF_BIKE2  = COEFF(1,12)               ; Bike time > 1
  DWalkBIKE    = COEFF(1,13)               ; Walk and Bike threshold
  AUTOCOST     = COEFF(1,19)               ; Auto Operating Costs in Cents
  OCC          = COEFF(1,20)               ; Cost Sharing Factor for Shared Ride

; Cost coefficients
  COEFF_COST  = COEFF(1,5)                 ; Cost 
  
; Calibration specific
COEFF_NXFER   = COEFF(1,18)                ; number of xfers 

ENDIF

      ; Non motorized
; distance portion that is 1 mile or less
MW[18] = MIN(MW[2],1)
  
; Distance portion that is longer than 1 mile
  JLOOP
      IF (MW[2][J] > 1)
          MW[19] = MW[2][J] - 1
      ELSE
          MW[19] = 0
      ENDIF

  ENDJLOOP
  
  ;TODO: get minimum transit time, but include out-of-vehicle time as separate matrix
   

;;;;;;Begin HBW MCLS Calculation;;;;;
      
      ; calculate travel time of non-motorized modes
      MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr
 
      ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
      MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
      MW[111] = MW[11] * 100                                                    ;Printed auto utility
      MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
      MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
      MW[13] = (K_TRN * MW[3])                                                  ;transit utility
      MW[113] = MW[13] * 100                                                    ;Printed transity utility
      
     ; Exponentiate Utilities and adjust for zones which do not exist
     MW[21] = exp(MW[11]) ;Exponentiated auto utility
        JLOOP
      IF (MW[2] > 50) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 50 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 50 miles
      ENDIF
        ENDJLOOP
        
      JLOOP
      IF (MW[3] = 0) ;transit walk time
          MW[23] = 0 ;transit walk time equals zero if it equals zero
      ELSE
        MW[23] = exp(MW[13]) ;exponentiated transit utilty
      ENDIF
      ENDJLOOP
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23] ;create denominator for probability calculation
      
      ; Adjust for areas with a denominator equal to 0
      JLOOP     
      IF(MW[30] = 0)
      MW[30] = 1
      ENDIF
      ENDJLOOP
      
      ; Probabilities

      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
    
      ; LOGSUM
      MW[40] = ln(MW[30])    

      ; Calculate logit average of the mode choice logsums
   JLOOP
     MW[41] = MW[41] + EXP(MW[40])
      IF (MW[41]> 0) 
        MW[41] = Ln(MW[41])
      ELSE 
        MW[41] = 0
     ENDIF
   ENDJLOOP
ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\Base\01_HBO_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBO_MCLS.PRN" MSG='HBO MCLS'
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI MATI[2] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_PROBABILITY.MAT",
  MO=31-33, DEC=D,NAME=HBOauto_prob,HBOnonmot_prob,HBOtransit_prob
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_UTILITY.MAT",
  MO=11-13, DEC=D,NAME=HBOauto_util,HBOnonmot_util,HBOtransit_util
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=HBOlogsum

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  FILLMW MW[1]=MI.1.TIME ;AM highway time
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1 ;Walk bus time
  

; Progress Bar update for evey 100 zones
zonemsg=50
    
; Declare arrays to hold alternative specific constants
;        ARRAY PARK=2578
 ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1 
 ARRAY TYPE=C30 MARKET_NAME=1
    
; Read alternative specific Constants
LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=4, INTERPOLATE=N, , LIST=Y, LOOKUPI=2
    
; Read mode choice coefficients
LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=4, INTERPOLATE=N, LIST=Y, LOOKUPI=1 

IF (i=FirstZone)

  ; constants
   K_AUT  = CONSTANTS(1,1)           ; auto 
   K_SR  = CONSTANTS(1,1)             ; shared-ride 2 & 3+
   K_TRN  = CONSTANTS(1,2)            ; transit
   K_NMOT = CONSTANTS(1,3)            ; non-motorized (walk & bike)
     
; Mode-specific constants 
   K_PREM = CONSTANTS(1,4)                        ; premium transit
                                        
; Nesting coefficients
   NC_1        = COEFF(1,14)                          ; Level 1 - auto, trn, non-mot
   NC_2        = COEFF(1,15)                          ; Level 2 - transit sub mode choice
   NC_3        = COEFF(1,16)                          ; Level 3 - not used
   ;NCP = NC_1 * NC_2

   ; Level of Service Coefficients
  COEFF_IVTT   = COEFF(1,1)                ; In-vehicle travel time coefficient
  COEFF_SWAIT  = COEFF(1,2)                ; Short wait(<5 minutes)
  COEFF_LWAIT  = COEFF(1,3)                ; Long wait (>5 minutes)
  COEFF_XWAIT  = COEFF(1,4)                ; Xfer wait
  COEFF_DRIVE  = COEFF(1,6)                ; Drive access
  COEFF_TERML  = COEFF(1,7)                ; Terminal time
  COEFF_WALK   = COEFF(1,8)                ; Walk access
  COEFF_WALK1  = COEFF(1,9)                ; Walk time < 1
  COEFF_WALK2  = COEFF(1,10)               ; Walk time > 1
  COEFF_BIKE1  = COEFF(1,11)               ; Bike time < 1
  COEFF_BIKE2  = COEFF(1,12)               ; Bike time > 1
  DWalkBIKE    = COEFF(1,13)               ; Walk and Bike threshold
  AUTOCOST     = COEFF(1,19)               ; Auto Operating Costs in Cents
  OCC          = COEFF(1,20)               ; Cost Sharing Factor for Shared Ride

; Cost coefficients
  COEFF_COST  = COEFF(1,5)                ; Cost 
  
; Calibration specific
COEFF_NXFER   = COEFF(1,18)              ; number of xfers 

ENDIF
  
  
  ;TODO: get minimum transit time, but include out-of-vehicle time as separate matrix

;;;;;;Begin HBW MCLS Calculation;;;;;
      
            ; calculate travel time of non-motorized modes
      MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr
 
      ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
      MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
      MW[111] = MW[11] * 100                                                    ;Printed auto utility
      MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
      MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
      MW[13] = (K_TRN * MW[3])                                                  ;transit utility
      MW[113] = MW[13] * 100                                                    ;Printed transity utility
      
     ; Exponentiate Utilities and adjust for zones which do not exist
     MW[21] = exp(MW[11]) ;Exponentiated auto utility
        JLOOP
      IF (MW[2] > 50) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 50 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 50 miles
      ENDIF
        ENDJLOOP
        
      JLOOP
      IF (MW[3] = 0) ;transit walk time
          MW[23] = 0 ;transit walk time equals zero if it equals zero
      ELSE
        MW[23] = exp(MW[13]) ;exponentiated transit utilty
      ENDIF
      ENDJLOOP
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23] ;create denominator for probability calculation
      
      ; Adjust for areas with a denominator equal to 0
      JLOOP     
      IF(MW[30] = 0)
      MW[30] = 1
      ENDIF
      ENDJLOOP
      
      ; Probabilities

      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
    
      ; LOGSUM
      MW[40] = ln(MW[30]) 

      ; Calculate logit average of the mode choice logsums
   JLOOP
     MW[41] = MW[41] + EXP(MW[40])
      IF (MW[41]> 0) 
        MW[41] = Ln(MW[41])
      ELSE 
        MW[41] = 0
     ENDIF
   ENDJLOOP



ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_NHB_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_NHB_MCLS.PRN" MSG='NHB MCLS'
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI MATI[2] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=NHBlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_UTILITY.MAT",
  MO=111-113, DEC=D,NAME=NHBauto_util,NHBnonmot_util,NHBtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=NHBauto_prob,NHBnonmot_prob,NHBtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1     ;Walk bus time


; Progress Bar update for evey 100 zones
zonemsg=50
    
; Declare arrays to hold alternative specific constants
;        ARRAY PARK=2578
 ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1 
 ARRAY TYPE=C30 MARKET_NAME=1
    
; Read alternative specific Constants
LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=5, INTERPOLATE=N, , LIST=Y, LOOKUPI=2
    
; Read mode choice coefficients
LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=5, INTERPOLATE=N, LIST=Y, LOOKUPI=1 

IF (i=FirstZone)

  ; constants
   K_AUT  = CONSTANTS(1,1)                 ; auto 
   K_SR  = CONSTANTS(1,1)                  ; shared-ride 2 & 3+
   K_TRN  = CONSTANTS(1,2)                 ; transit
   K_NMOT = CONSTANTS(1,3)                 ; non-motorized (walk & bike)
     
; Mode-specific constants 
   K_PREM = CONSTANTS(1,4)                 ; premium transit
                                        
; Nesting coefficients
   NC_1        = COEFF(1,14)               ; Level 1 - auto, trn, non-mot
   NC_2        = COEFF(1,15)               ; Level 2 - transit sub mode choice
   NC_3        = COEFF(1,16)               ; Level 3 - not used
   ;NCP = NC_1 * NC_2

   ; Level of Service Coefficients
  COEFF_IVTT   = COEFF(1,1)                ; In-vehicle travel time coefficient
  COEFF_SWAIT  = COEFF(1,2)                ; Short wait(<5 minutes)
  COEFF_LWAIT  = COEFF(1,3)                ; Long wait (>5 minutes)
  COEFF_XWAIT  = COEFF(1,4)                ; Xfer wait
  COEFF_DRIVE  = COEFF(1,6)                ; Drive access
  COEFF_TERML  = COEFF(1,7)                ; Terminal time
  COEFF_WALK   = COEFF(1,8)                ; Walk access
  COEFF_WALK1  = COEFF(1,9)                ; Walk time < 1
  COEFF_WALK2  = COEFF(1,10)               ; Walk time > 1
  COEFF_BIKE1  = COEFF(1,11)               ; Bike time < 1
  COEFF_BIKE2  = COEFF(1,12)               ; Bike time > 1
  DWalkBIKE    = COEFF(1,13)               ; Walk and Bike threshold
  AUTOCOST     = COEFF(1,19)               ; Auto Operating Costs in Cents
  OCC          = COEFF(1,20)               ; Cost Sharing Factor for Shared Ride

; Cost coefficients
  COEFF_COST  = COEFF(1,5)                 ; Cost 
  
; Calibration specific
COEFF_NXFER   = COEFF(1,18)                ; number of xfers 

ENDIF

      ; Non motorized
; distance portion that is 1 mile or less
MW[18] = MIN(MW[2],1)
  
; Distance portion that is longer than 1 mile
  JLOOP
      IF (MW[2][J] > 1)
          MW[19] = MW[2][J] - 1
      ELSE
          MW[19] = 0
      ENDIF

  ENDJLOOP
  
  ;TODO: get minimum transit time, but include out-of-vehicle time as separate matrix

;;;;;;Begin NHB MCLS Calculation;;;;;
      
            ; calculate travel time of non-motorized modes
      MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr
 
      ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
      MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
      MW[111] = MW[11] * 100                                                    ;Printed auto utility
      MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
      MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
      MW[13] = (K_TRN * MW[3])                                                  ;transit utility
      MW[113] = MW[13] * 100                                                    ;Printed transity utility
      
     ; Exponentiate Utilities and adjust for zones which do not exist
     MW[21] = exp(MW[11]) ;Exponentiated auto utility
        JLOOP
      IF (MW[2] > 50) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 50 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 50 miles
      ENDIF
        ENDJLOOP
        
      JLOOP
      IF (MW[3] = 0) ;transit walk time
          MW[23] = 0 ;transit walk time equals zero if it equals zero
      ELSE
        MW[23] = exp(MW[13]) ;exponentiated transit utilty
      ENDIF
      ENDJLOOP
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23] ;create denominator for probability calculation
      
      ; Adjust for areas with a denominator equal to 0
      JLOOP     
      IF(MW[30] = 0)
      MW[30] = 1
      ENDIF
      ENDJLOOP
      
      ; Probabilities

      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
    
      ; LOGSUM
      MW[40] = ln(MW[30]) 

      ; Calculate logit average of the mode choice logsums
   JLOOP
     MW[41] = MW[41] + EXP(MW[40])
      IF (MW[41]> 0) 
        MW[41] = Ln(MW[41])
      ELSE 
        MW[41] = 0
     ENDIF
   ENDJLOOP
ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_HBC_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBC_MCLS.PRN" MSG='Freight MCLS'
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI MATI[2] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBC_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=HBClogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBC_UTILTIY.MAT",
  MO=111-113, DEC=D,NAME=HBCauto_util,HBCnonmot_util,HBCtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBC_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=HBCauto_prob,HBCnonmot_prob,HBCtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1     ;Walk bus time


; Progress Bar update for evey 100 zones
zonemsg=50
    
; Declare arrays to hold alternative specific constants
;        ARRAY PARK=2578
 ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1 
 ARRAY TYPE=C30 MARKET_NAME=1
    
; Read alternative specific Constants
LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=6, INTERPOLATE=N, , LIST=Y, LOOKUPI=2
    
; Read mode choice coefficients
LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=6, INTERPOLATE=N, LIST=Y, LOOKUPI=1 

IF (i=FirstZone)

  ; constants
   K_AUT  = CONSTANTS(1,1)                 ; auto 
   K_SR  = CONSTANTS(1,1)                  ; shared-ride 2 & 3+
   K_TRN  = CONSTANTS(1,2)                 ; transit
   K_NMOT = CONSTANTS(1,3)                 ; non-motorized (walk & bike)
     
; Mode-specific constants 
   K_PREM = CONSTANTS(1,4)                 ; premium transit
                                        
; Nesting coefficients
   NC_1        = COEFF(1,14)               ; Level 1 - auto, trn, non-mot
   NC_2        = COEFF(1,15)               ; Level 2 - transit sub mode choice
   NC_3        = COEFF(1,16)               ; Level 3 - not used
   ;NCP = NC_1 * NC_2

   ; Level of Service Coefficients
  COEFF_IVTT   = COEFF(1,1)                ; In-vehicle travel time coefficient
  COEFF_SWAIT  = COEFF(1,2)                ; Short wait(<5 minutes)
  COEFF_LWAIT  = COEFF(1,3)                ; Long wait (>5 minutes)
  COEFF_XWAIT  = COEFF(1,4)                ; Xfer wait
  COEFF_DRIVE  = COEFF(1,6)                ; Drive access
  COEFF_TERML  = COEFF(1,7)                ; Terminal time
  COEFF_WALK   = COEFF(1,8)                ; Walk access
  COEFF_WALK1  = COEFF(1,9)                ; Walk time < 1
  COEFF_WALK2  = COEFF(1,10)               ; Walk time > 1
  COEFF_BIKE1  = COEFF(1,11)               ; Bike time < 1
  COEFF_BIKE2  = COEFF(1,12)               ; Bike time > 1
  DWalkBIKE    = COEFF(1,13)               ; Walk and Bike threshold
  AUTOCOST     = COEFF(1,19)               ; Auto Operating Costs in Cents
  OCC          = COEFF(1,20)               ; Cost Sharing Factor for Shared Ride

; Cost coefficients
  COEFF_COST  = COEFF(1,5)                 ; Cost 
  
; Calibration specific
COEFF_NXFER   = COEFF(1,18)                ; number of xfers 

ENDIF

      ; Non motorized
; distance portion that is 1 mile or less
MW[18] = MIN(MW[2],1)
  
; Distance portion that is longer than 1 mile
  JLOOP
      IF (MW[2][J] > 1)
          MW[19] = MW[2][J] - 1
      ELSE
          MW[19] = 0
      ENDIF

  ENDJLOOP
  
  ;TODO: get minimum transit time, but include out-of-vehicle time as separate matrix

;;;;;;Begin Fregiht MCLS Calculation;;;;;
      
      ; calculate travel time of non-motorized modes
      MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr
 
      ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
      MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
      MW[111] = MW[11] * 100                                                    ;Printed auto utility
      MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
      MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
      MW[13] = (K_TRN * MW[3])                                                  ;transit utility
      MW[113] = MW[13] * 100                                                    ;Printed transity utility
          
        ; Exponentiate Utilities and adjust for zones which do not exist
        ; Need to account for these zones that don't exist in DCLS so they don't get chosen
      
        MW[21] = exp(MW[11])
        MW[22] = 0 ;exponentiated utility is zero because freight must take auto mode
        MW[23] = 0 ;exponentiated utility is zero because freight must take auto mode
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
      ; Adjust for areas with a denominator equal to 0
      JLOOP     
      IF(MW[30] = 0)
      MW[30] = 1
      ENDIF
      ENDJLOOP
      
      ; Probabilities
      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
    
      ; LOGSUM
      MW[40] = ln(MW[30]) 
      

      ; Calculate logit average of the mode choice logsums
   JLOOP
     MW[41] = MW[41] + EXP(MW[40])
      IF (MW[41]> 0) 
        MW[41] = Ln(MW[41])
      ELSE 
        MW[41] = 0
     ENDIF
   ENDJLOOP

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_REC_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_REC_MCLS.PRN" MSG='REC MCLS'
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI MATI[2] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_REC_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=REClogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_REC_UTILITY.MAT",
  MO=111-113, DEC=D,NAME=RECauto_util,RECnonmot_util,RECtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_REC_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=RECauto_prob,RECnonmot_prob,RECtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1    ;Walk bus time


; Progress Bar update for evey 100 zones
zonemsg=50
    
; Declare arrays to hold alternative specific constants
;        ARRAY PARK=2578
 ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1 
 ARRAY TYPE=C30 MARKET_NAME=1
    
; Read alternative specific Constants
LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=7, INTERPOLATE=N, , LIST=Y, LOOKUPI=2
    
; Read mode choice coefficients
LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=7, INTERPOLATE=N, LIST=Y, LOOKUPI=1 

IF (i=FirstZone)

  ; constants
   K_AUT  = CONSTANTS(1,1)                 ; auto 
   K_SR  = CONSTANTS(1,1)                  ; shared-ride 2 & 3+
   K_TRN  = CONSTANTS(1,2)                 ; transit
   K_NMOT = CONSTANTS(1,3)                 ; non-motorized (walk & bike)
     
; Mode-specific constants 
   K_PREM = CONSTANTS(1,4)                 ; premium transit
                                        
; Nesting coefficients
   NC_1        = COEFF(1,14)               ; Level 1 - auto, trn, non-mot
   NC_2        = COEFF(1,15)               ; Level 2 - transit sub mode choice
   NC_3        = COEFF(1,16)               ; Level 3 - not used
   ;NCP = NC_1 * NC_2

   ; Level of Service Coefficients
  COEFF_IVTT   = COEFF(1,1)                ; In-vehicle travel time coefficient
  COEFF_SWAIT  = COEFF(1,2)                ; Short wait(<5 minutes)
  COEFF_LWAIT  = COEFF(1,3)                ; Long wait (>5 minutes)
  COEFF_XWAIT  = COEFF(1,4)                ; Xfer wait
  COEFF_DRIVE  = COEFF(1,6)                ; Drive access
  COEFF_TERML  = COEFF(1,7)                ; Terminal time
  COEFF_WALK   = COEFF(1,8)                ; Walk access
  COEFF_WALK1  = COEFF(1,9)                ; Walk time < 1
  COEFF_WALK2  = COEFF(1,10)               ; Walk time > 1
  COEFF_BIKE1  = COEFF(1,11)               ; Bike time < 1
  COEFF_BIKE2  = COEFF(1,12)               ; Bike time > 1
  DWalkBIKE    = COEFF(1,13)               ; Walk and Bike threshold
  AUTOCOST     = COEFF(1,19)               ; Auto Operating Costs in Cents
  OCC          = COEFF(1,20)               ; Cost Sharing Factor for Shared Ride

; Cost coefficients
  COEFF_COST  = COEFF(1,5)                 ; Cost 
  
; Calibration specific
COEFF_NXFER   = COEFF(1,18)                ; number of xfers 

ENDIF

      ; Non motorized
; distance portion that is 1 mile or less
MW[18] = MIN(MW[2],1)
  
; Distance portion that is longer than 1 mile
  JLOOP
      IF (MW[2][J] > 1)
          MW[19] = MW[2][J] - 1
      ELSE
          MW[19] = 0
      ENDIF

  ENDJLOOP
  
  ;TODO: get minimum transit time, but include out-of-vehicle time as separate matrix

;;;;;;Begin REC MCLS Calculation;;;;;
      
            ; calculate travel time of non-motorized modes
      MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr
 
      ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
      MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
      MW[111] = MW[11] * 100                                                    ;Printed auto utility
      MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
      MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
      MW[13] = (K_TRN * MW[3])                                                  ;transit utility
      MW[113] = MW[13] * 100                                                    ;Printed transity utility
      
     ; Exponentiate Utilities and adjust for zones which do not exist
     MW[21] = exp(MW[11]) ;Exponentiated auto utility
        JLOOP
      IF (MW[2] > 50) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 50 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 50 miles
      ENDIF
        ENDJLOOP
        
      JLOOP
      IF (MW[3] = 0) ;transit walk time
          MW[23] = 0 ;transit walk time equals zero if it equals zero
      ELSE
        MW[23] = exp(MW[13]) ;exponentiated transit utilty
      ENDIF
      ENDJLOOP
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23] ;create denominator for probability calculation
      
      ; Adjust for areas with a denominator equal to 0
      JLOOP     
      IF(MW[30] = 0)
      MW[30] = 1
      ENDIF
      ENDJLOOP
      
      ; Probabilities

      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
    
      ; LOGSUM
      MW[40] = ln(MW[30]) 

      ; Calculate logit average of the mode choice logsums
   JLOOP
     MW[41] = MW[41] + EXP(MW[40])
      IF (MW[41]> 0) 
        MW[41] = Ln(MW[41])
      ELSE 
        MW[41] = 0
     ENDIF
   ENDJLOOP

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_MCLS_COMBINE.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Combine All MCLS Calculations'
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED_PROBABILITY.MAT",
  MO = 11-15, 21-25, 31-35 DEC = D, NAME = HBWauto_prob, HBOauto_prob, NHBauto_prob, HBCauto_prob, RECauto_prob, HBWnmot_prob, HBOnmot_prob, NHBnmot_prob, HBCnmot_prob, RECnmot_prob, HBWtran_prob, HBOtran_prob, NHBtran_prob, HBCtran_prob, RECtran_prob
FILEI MATI[10] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_REC_PROBABILITY.MAT"
FILEI MATI[9] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBC_PROBABILITY.MAT"
FILEI MATI[8] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_PROBABILITY.MAT"
FILEI MATI[7] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_PROBABILITY.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_PROBABILITY.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT",
  MO = 1-5  DEC = D, NAME = HBWlogsum, HBOlogsum, NHBlogsum, HBClogsum, REClogsum
FILEI MATI[5] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_REC_LOGSUM.MAT"
FILEI MATI[4] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBC_LOGSUM.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_LOGSUM.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_LOGSUM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_LOGSUM.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  ;Fill MCLS
  FILLMW MW[1]=MI.1.1 ;HBW Logsum
  FILLMW MW[2]=MI.2.1 ;HBO Logsum
  FILLMW MW[3]=MI.3.1 ;NHB Logsum
  FILLMW MW[4]=MI.4.1 ;HBC Logsum
  FILLMW MW[5]=MI.5.1 ;REC Logsum
  
  ;Fill Auto Probabilities
  FILLMW MW[11]=MI.6.1 ;HBW Auto Probability
  FILLMW MW[12]=MI.7.1 ;HBO Auto Probability
  FILLMW MW[13]=MI.8.1 ;NHB Auto Probability
  FILLMW MW[14]=MI.9.1 ;HBC Auto Probability
  FILLMW MW[15]=MI.10.1 ;REC Auto Probability
  
  ;Fill Non-motorized Probability
  FILLMW MW[21]=MI.6.2 ;HBW NMOT Probability
  FILLMW MW[22]=MI.7.2 ;HBO NMOT Probability
  FILLMW MW[23]=MI.8.2 ;NHB NMOT Probability
  FILLMW MW[24]=MI.9.2 ;HBC NMOT Probability
  FILLMW MW[25]=MI.10.2 ;REC NMOT Probability  
  
  ;Fill Transit Probability
  FILLMW MW[31]=MI.6.3 ;HBW Transit Probability
  FILLMW MW[32]=MI.7.3 ;HBO Transit Probability
  FILLMW MW[33]=MI.8.3 ;NHB Transit Probability
  FILLMW MW[34]=MI.9.3 ;HBC Transit Probability
  FILLMW MW[35]=MI.10.3 ;REC Transit Probability 

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBO_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='HBO DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_HBO_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBO.MAT",
  MO = 112, 100 DEC = D, NAME = HBOSizeTerm, HBOUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {TOTAL_ZONES}
		ARRAY personTrips = ZONES

		; READ IN MODEL PARAMETERS
		LOOKUP, NAME=COEFF, LOOKUP[1]=NVAR, RESULT=HBO, INTERPOLATE=N, LIST=Y, LOOKUPI=1
    
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
		MW[101] = MI.1.2 ;HBO logsum
 
		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN HBO DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		   MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OTHEMP[J] + Coeff_RET_EMP * (ZI.1.RETEMP[J]) + Coeff_OTH_EMP * (ZI.1.TOTEMP[J] - ZI.1.OTHEMP[J]  - ZI.1.RETEMP[J]) + Coeff_OTH_OFF_EMP * (ZI.1.TOTEMP[J] - ZI.1.RETEMP[J])
      
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
    DEMAND = personTrips[I],
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{TOTAL_ZONES},
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

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_NHB_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='NHB DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_NHB_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_NHB.MAT",
  MO = 112, 100 DEC = D, NAME=HBWSizeTerm, HBWUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT"


; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {TOTAL_ZONES}
		ARRAY personTrips = ZONES

		; READ IN MODEL PARAMETERS
		LOOKUP, NAME=COEFF, LOOKUP[1]=NVAR, RESULT=NHB, INTERPOLATE=N, LIST=Y, LOOKUPI=1
    
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
		MW[101] = MI.1.3 ;NHB logsum
    
		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN NHB DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		   MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OTHEMP[J] + Coeff_RET_EMP * (ZI.1.RETEMP[J]) + Coeff_OTH_EMP * (ZI.1.TOTEMP[J] - ZI.1.OTHEMP[J]  - ZI.1.RETEMP[J]) + Coeff_OTH_OFF_EMP * (ZI.1.TOTEMP[J] - ZI.1.RETEMP[J])
      
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
    DEMAND = personTrips[I],
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{TOTAL_ZONES},
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


ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBC_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='HBC DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_HBC_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBC.MAT",
MO = 112, 100 DEC = D, NAME = HBCSizeTerm, HBCUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT"


; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {TOTAL_ZONES}
		ARRAY personTrips = ZONES

		; READ IN MODEL PARAMETERS
		LOOKUP, NAME=COEFF, LOOKUP[1]=NVAR, RESULT=HBC, INTERPOLATE=N, LIST=Y, LOOKUPI=1
    
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
		MW[101] = MI.1.4 ;HBC logsum
    
		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN HBC DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		   MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OTHEMP[J] + Coeff_RET_EMP * (ZI.1.RETEMP[J]) + Coeff_OTH_EMP * (ZI.1.TOTEMP[J] - ZI.1.OTHEMP[J]  - ZI.1.RETEMP[J]) + Coeff_OTH_OFF_EMP * (ZI.1.TOTEMP[J] - ZI.1.RETEMP[J])
      
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
    DEMAND = personTrips[I],
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{TOTAL_ZONES},
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

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_REC_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='REC DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_REC_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_REC.MAT",
  MO = 112, 100 DEC = D, NAME = RECSizeTerm, RECUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {TOTAL_ZONES}
		ARRAY personTrips = ZONES

		; READ IN MODEL PARAMETERS
		LOOKUP, NAME=COEFF, LOOKUP[1]=NVAR, RESULT=REC, INTERPOLATE=N, LIST=Y, LOOKUPI=1
    
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
		MW[101] = MI.1.5 ;REC logsum
    
		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN REC DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		   MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OTHEMP[J] + Coeff_RET_EMP * (ZI.1.RETEMP[J]) + Coeff_OTH_EMP * (ZI.1.TOTEMP[J] - ZI.1.OTHEMP[J]  - ZI.1.RETEMP[J]) + Coeff_OTH_OFF_EMP * (ZI.1.TOTEMP[J] - ZI.1.RETEMP[J])
      
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
    DEMAND = personTrips[I],
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{TOTAL_ZONES},
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

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_DCLS_COMBINE.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINE.PRN" MSG='COMBINE UTILITIES'
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINED.MAT",
  MO = 1-5, DEC = D, NAME = HBWDCUtility, HBODCUtility, NHBDCUtility, HBCDCUtility, RECDCUtility
FILEI MATI[5] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_REC.MAT"
FILEI MATI[4] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBC.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_NHB.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBO.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBW.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  FILLMW MW[1]=MI.1.2 ;HBW 
  FILLMW MW[2]=MI.2.2 ;HBO 
  FILLMW MW[3]=MI.3.2 ;NHB 
  FILLMW MW[4]=MI.4.2 ;HBC 
  FILLMW MW[5]=MI.5.2 ;REC 

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBW_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='HBW DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_HBW_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBW.MAT",
  MO = 112, 100 DEC = D, NAME = HBWSizeTerm, HBWUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED.MAT"


; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ZONES = {TOTAL_ZONES}
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

		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
    
;;;;;BEGIN HBW DCLS;;;;;

		JLOOP
		  ; Compute size term
        ;MW[112] = Coeff_HH + Coeff_OFF_EMP + Coeff_OTH_EMP + Coeff_OTH_OFF_EMP
		  MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OTHEMP[J] + Coeff_RET_EMP * (ZI.1.RETEMP[J]) + Coeff_OTH_EMP * (ZI.1.TOTEMP[J] - ZI.1.OTHEMP[J]  - ZI.1.RETEMP[J]) + Coeff_OTH_OFF_EMP * (ZI.1.TOTEMP[J] - ZI.1.RETEMP[J])
      
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
    DEMAND = personTrips[I],
  	UTILITIESMW = 100,
  	ODEMANDMW = 118,
  	DESTSPLIT= TOTAL All, INCLUDE=1-{TOTAL_ZONES},
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

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_DCLS_ROWSUM.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_DCLS_ROWSUM.PRN"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
FILEO RECO[1] = "{SCENARIO_DIR}\Output\01_ROWSUMS.DBF",
  FIELDS = TAZ, lnHBW, lnHBO, lnNHB, lnHBC, lnREC
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

FILLMW MW[100] = MI.1.1
FILLMW MW[200] = MI.1.2
FILLMW MW[300] = MI.1.3
FILLMW MW[400] = MI.1.4
FILLMW MW[500] = MI.1.5

SeHBW = 0
SeHBO = 0
SeHBC = 0
SeNHB = 0
SeREC = 0

JLOOP
;change to an if statement to exclude rows/columns that don't exist i would need to set those values correctly to exclude them (its the column that matters)
  TAZ = ZI.1.TAZ
  SeHBW = SeHBW + exp(MW[100])
  SeHBO = SeHBO + exp(MW[200])
  SeNHB = SeNHB + exp(MW[300])
  SeHBC = SeHBC + exp(MW[400])
  SeREC = SeREC + exp(MW[500])
ENDJLOOP
  Ro.TAZ = TAZ
  Ro.lnHBW = ln(SeHBW)
  Ro.lnHBO = ln(SeHBO)
  Ro.lnNHB = ln(SeNHB)
  Ro.lnHBC = ln(SeHBC)
  Ro.lnREC = ln(SeREC)

WRITE RECO = 1



ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_BUILD_PEAK_TRANSIT.S"
;;<<GENERATED SCRIPT>><<MATRIX>><<Matrix>><<Conversion>>;;
;>>>
;>>>
;Input Matrix File 1:{CATALOG_DIR}\Inputs\USTM_transit_skim1.csv
;Output Matrix File:{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT
;Maximum Zone number:8775
;**********************************************************************
;THIS SCRIPT READS A CSV MATRIX FILE, CREATE A MATRIX WITH THE RESULT *  
;**********************************************************************
; BY CITILABS
;
;;<<End Parameters>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Pk Transit Matrix'

FILEI MATI[1] = "{CATALOG_DIR}\Inputs\USTM_transit_skim1.csv",
    PATTERN=IJM:V FIELDS=#1,2,3,4

FILEO MATO[1] = "{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT",
 MO=1 NAME=TRANSIT_TIME

ZONES={TOTAL_ZONES}

MW[1]=MI.1.1


ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_TRIPS_IJ.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJ'
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT",
MO = 10,20,30,40,50,100,200,300,400,500,98,99 DEC = D, NAME = HBWDCProbability, HBODCProbability, NHBDCProbability, HBCDCProbability, RECDCProbability, HBWTrips,HBOTrips,NHBTrips,HBCTrips,RECTrips,CheckRowsum, CheckProd
FILEI ZDATI[2] = "{SCENARIO_DIR}\Output\01_ROWSUMS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD_1.DBF"
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
    ;Print Probability Values * 1000 to check accuracy
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


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_TRIPS_IJK.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJK'
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT",
 MO = 40-47,100,200,300,400,500,110,210,310,410,510,120,220,320,420,520 DEC = D, NAME = HBWTrips,HBOTrips,NHBTrips,HBCTrips,RECTrips,autoTrips,nmotTrips,transitTrips,HBWauto,HBOauto,NHBauto,HBCauto,RECauto,HBWnmot,HBOnmot,NHBnmot,HBCnmot,RECnmot,HBWtransit,HBOtransit,NHBtransit,HBCtransit,RECtransit
FILEI MATI[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED_PROBABILITY.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT"

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


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_MODESPLIT.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Create Mode Split Columns'
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\IIIXXIXX_LH_Ton_Truck_Utah.MAT"
FILEO RECO[1] = "{SCENARIO_DIR}\Output\01_MODESPLIT.DBF",
  FIELDS = TAZ, HBWAUTO, HBWNMOT, HBWTRANSIT, HBOATUO, HBONMOT, HBOTRANSIT, NHBAUTO, NHBNMOT, NHBTRANSIT, FREIGHTAUTO, FREIGHTNMOT, FREIGHTRANSIT, RECAUTO, RECNMOT, RECTRANSIT
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

FILLMW MW[100] = MI.1.9
FILLMW MW[110] = MI.1.14
FILLMW MW[120] = MI.1.19
FILLMW MW[200] = MI.1.10
FILLMW MW[210] = MI.1.15
FILLMW MW[220] = MI.1.20
FILLMW MW[300] = MI.1.11
FILLMW MW[310] = MI.1.16
FILLMW MW[320] = MI.1.21
;FILLMW MW[400] = MI.1.12
;FILLMW MW[410] = MI.1.17
;FILLMW MW[420] = MI.1.22
FILLMW MW[500] = MI.1.13
FILLMW MW[510] = MI.1.18
FILLMW MW[520] = MI.1.23
FILLMW MW[600] = MI.2.13



HBWAUTO = 0
HBWNMOT = 0
HBWTRANSIT = 0
HBOAUTO = 0
HBONMOT = 0
HBOTRANSIT   = 0
NHBAUTO = 0
NHBNMOT = 0
NHBTRANSIT = 0
FREIGHTAUTO = 0
FREIGHTNMOT = 0
FREIGHTTRANSIT = 0
RECAUTO = 0
RECNMOT = 0
RECTRANSIT = 0

JLOOP
;change to an if statement to exclude rows/columns that don't exist i would need to set those values correctly to exclude them (its the column that matters)
  TAZ = ZI.1.TAZ
  HBWAUTO = HBWAUTO + MW[100]
  HBWNMOT = HBWNMOT + MW[110]
  HBWTRANSIT = HBWTRANSIT + MW[120]
  HBOAUTO = HBOAUTO + MW[200]
  HBONMOT = HBONMOT + MW[210]
  HBOTRANSIT = HBOTRANSIT + MW[220]
  NHBAUTO = NHBAUTO + MW[300]
  NHBNMOT = NHBNMOT + MW[310]
  NHBTRANSIT = NHBTRANSIT + MW[320]
  FREIGHTAUTO = FREIGHTAUTO + MW[600]
  ;FREIGHTNMOT = FREIGHTNMOT + MW[410]
  ;FREIGHTTRANSIT = FREIGHTTRANSIT + MW[420]
  RECAUTO = RECAUTO + MW[500]
  RECNMOT = RECNMOT + MW[510]
  RECTRANSIT = RECTRANSIT + MW[520]
  
ENDJLOOP
  Ro.TAZ = TAZ
  Ro.HBWAUTO = HBWAUTO
  Ro.HBWNMOT = HBWNMOT
  Ro.HBWTRANSIT = HBWTRANSIT
  Ro.HBOAUTO = HBOAUTO
  Ro.HBONMOT = HBONMOT
  Ro.HBOTRANSIT = HBOTRANSIT
  Ro.NHBAUTO = NHBAUTO
  Ro.NHBNMOT = NHBNMOT
  Ro.NHBTRANSIT = NHBTRANSIT
  Ro.FREIGHTAUTO = FREIGHTAUTO
  ;Ro.FREIGHTNMOT = FREIGHTNMOT
  ;Ro.FREIGHTTRANSIT = FREIGHTTRANSIT
  Ro.RECAUTO = RECAUTO
  Ro.RECNMOT = RECNMOT
  Ro.RECTRANSIT = RECTRANSIT

WRITE RECO = 1




ENDRUN


; Script for program MATRIX in file "C:\USERS\MBARNES7\DOCUMENTS\PROJECTS\USTM_RESILIENCY\CUBE\01MAT00R.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Get whole Productions file'
FILEO RECO[1] = "{CATALOG_DIR}\Inputs\HH_PROD_1.DBF",
  FIELDS = HBWP, HBOP, NHBP, RECP
FILEI MATI[1] = "{CATALOG_DIR}\Inputs\IIIXXIXX_LH_Ton_Truck_Utah.MAT"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

	FILLMW MW[1] = MI.1.13 ;Freight Trips

  FREIGHTAUTO = 0
  
  JLOOP
    TAZ = ZI.1.TAZ
    HBWP = ZI.1.HBW_P
    HBOP = ZI.1.HBO_P + ZI.1.HBSC_PR_P + ZI.1.HBSC_SC_P + ZI.1.HBSHP_P
    NHBP =  ZI.1.NHBW_P + ZI.1.NHBNW_P
    RECP = ZI.1.REC_P
  ENDJLOOP
  
    Ro.HBWP = HBWP
    Ro.HBOP = HBOP
    Ro.NHBP = NHBP
    Ro.RECP = RECP
    
  
WRITE RECO = 1

  
ENDRUN


