; Script for program HIGHWAY in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_HIGHWAY.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY MSG='Whole Network'
FILEO MATO[1] = "{SCENARIO_DIR}\01_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = 8, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\highway.NET"

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


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_PROCESSING.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Process Skims'
FILEO MATO[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT",
  MO=1-2,DEC=12,NAME=TIME,DISTANCE
FILEI MATI[1] = "{SCENARIO_DIR}\01_HIGHWAY_SKIMS.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

FILLMW MW[1]=MI.1.1(2)                ; highway skims

; Reset invalid values to zero
  JLOOP
      IF (MW[1] > 1000)
          MW[1] = 0
      ENDIF

      IF (MW[2] > 1000)
          MW[2] = 0
      ENDIF


      ENDJLOOP

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\Base\01_HBW_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBW_MCLS.PRN" MSG='HBW MCLS'
FILEO MATO[3] = "{SCENARIO_DIR}\01_MC_HBW_PROBABILITY.MAT",
  MO=31-33, DEC=12,NAME=TIME,DISTANCE,HBWauto_prob,HBWnonmot_prob,HBWtransit_prob
FILEO MATO[2] = "{SCENARIO_DIR}\01_MC_HBW_UTILITY.MAT",
  MO=111-113, DEC=12,NAME=HBWauto_util,HBWnonmot_util,HBWtransit_util
FILEO MATO[1] = "{SCENARIO_DIR}\01_MC_HBW_LOGSUM.MAT",
  MO =41,DEC=12, NAME=HBWlogsum
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.WBUS     ;Walk bus time


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
          
      ; Exponentiate Utilities
      MW[21] = exp(MW[11])
      MW[22] = exp(MW[12])
      MW[23] = exp(MW[13])
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
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
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"
FILEO MATO[3] = "{SCENARIO_DIR}\01_MC_HBO_PROBABILITY.MAT",
  MO=31-33, DEC=10,NAME=HBOauto_prob,HBOnonmot_prob,HBOtransit_prob
FILEO MATO[2] = "{SCENARIO_DIR}\01_MC_HBO_UTILITY.MAT",
  MO=11-13, DEC=10,NAME=HBOauto_util,HBOnonmot_util,HBOtransit_util
FILEO MATO[1] = "{SCENARIO_DIR}\01_MC_HBO_LOGSUM.MAT",
  MO = 41,DEC=10, NAME=HBOlogsum

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
 
      ; Calculate Utilities
      MW[11] = 0 + COEFF_IVTT + COEFF_TERML + COEFF_COST * AUTOCOST * MW[1]    ;auto utility
      ;MW[11] = 0 + -0.025 + -0.0625 + -0.00158 * 13.6 * MW[1]    ;auto utility
      MW[12] = K_NMOT + COEFF_WALK1 * 20 + COEFF_WALK2 * 20 * MW[4] ;non-motorized utility
      ;MW[12] = (-1.2258 + -0.0625 * 20 + -0.09375 * 20) * MW[4] ;non-motorized utility
      MW[13] = (K_TRN + COEFF_WALK + COEFF_SWAIT + (COEFF_LWAIT - COEFF_SWAIT) + COEFF_IVTT + COEFF_COST + COEFF_NXFER) * MW[3] ;transit utility
      ;MW[13] = (-0.3903 + -0.0625 + -0.05625 + (-0.025- -0.05625) + -0.0625 + -0.025 + -0.00158 + 0) * MW[3] ;transit utility
      
      ; Exponentiate Utilities
      MW[21] = exp(MW[11])
      MW[22] = exp(MW[12])
      MW[23] = exp(MW[13])
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
      ; Probabilities
      MW[31] =  MW[21] / MW[30]       ;auto probability
      MW[32] =  MW[22] / MW[30]       ;non-motorized probability
      MW[33] =  MW[23] / MW[30]       ;transit probability
      
      ; LOGSUM
      MW[40] = log(MW[30])
      

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
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\01_MC_NHB_LOGSUM.MAT",
  MO = 41,DEC=12, NAME=NHBlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\01_MC_NHB_UTILITY.MAT",
  MO=111-113, DEC=12,NAME=NHBauto_util,NHBnonmot_util,NHBtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\01_MC_NHB_PROBABILITY.MAT",
 MO=31-33, DEC=12,NAME=NHBauto_prob,NHBnonmot_prob,NHBtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.WBUS     ;Walk bus time


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
          
      ; Exponentiate Utilities
      MW[21] = exp(MW[11])
      MW[22] = exp(MW[12])
      MW[23] = exp(MW[13])
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
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
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBC_MCLS.PRN" MSG='HBC MCLS'
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\01_MC_HBC_LOGSUM.MAT",
  MO = 41,DEC=8, NAME=HBClogsum
FILEO MATO[2] = "{SCENARIO_DIR}\01_MC_HBC_UTILTIY.MAT",
  MO=111-113, DEC=12,NAME=HBCauto_util,HBCnonmot_util,HBCtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\01_MC_HBC_PROBABILITY.MAT",
 MO=31-33, DEC=10,NAME=HBCauto_prob,HBCnonmot_prob,HBCtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.WBUS     ;Walk bus time


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
          
      ; Exponentiate Utilities
      MW[21] = exp(MW[11])
      MW[22] = exp(MW[12])
      MW[23] = exp(MW[13])
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
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
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\01_MC_REC_LOGSUM.MAT",
  MO = 41,DEC=8, NAME=REClogsum
FILEO MATO[2] = "{SCENARIO_DIR}\01_MC_REC_UTILITY.MAT",
  MO=111-113, DEC=12,NAME=RECauto_util,RECnonmot_util,RECtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\01_MC_REC_PROBABILITY.MAT",
 MO=31-33, DEC=10,NAME=RECauto_prob,RECnonmot_prob,RECtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  MW[150] = MW[1] * 100      ;AM highway time * 100
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.WBUS     ;Walk bus time


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
          
      ; Exponentiate Utilities
      MW[21] = exp(MW[11])
      MW[22] = exp(MW[12])
      MW[23] = exp(MW[13])
      
      ; Sum demonominator
      MW[30] = MW[21] + MW[22] + MW[23]
      
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
FILEO MATO[1] = "{SCENARIO_DIR}\01_MCLS_COMBINED.MAT",
  MO = 1-5, DEC = 8, NAME = HBWlogsum, HBOlogsum, NHBlogsum, HBClogsum, REClogsum
FILEI MATI[5] = "{SCENARIO_DIR}\01_MC_REC_LOGSUM.MAT"
FILEI MATI[4] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MC_HBC_LOGSUM.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\01_MC_NHB_LOGSUM.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\01_MC_HBO_LOGSUM.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_MC_HBW_LOGSUM.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  FILLMW MW[1]=MI.1.1 ;HBW Logsum
  FILLMW MW[2]=MI.2.1 ;HBO Logsum
  FILLMW MW[3]=MI.3.1 ;NHB Logsum
  FILLMW MW[4]=MI.4.1 ;HBC Logsum
  FILLMW MW[5]=MI.5.1 ;REC Logsum
  
  

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\projects\ustm_resiliency\CUBE\01_DLCS.S"
 ;;<<Default Template>><<MATRIX>><<Default>>;;

;;;;;;In this code, HBW related data are labeled in the 100's, HBO in the 200's, NHB in the 300's, HBC in the 400's and REC in the 500's;;;;;;

; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Calculate Destination Choice Logsum'
FILEI LOOKUPI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\DESTCHOICE_PARAMETERS.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\01_MCLS_COMBINED.MAT"
FILEO PRINTO[3] = "{SCENARIO_DIR}\01_HBW_ZONAL_TRIPS.CSV"
FILEO PRINTO[2] = "{SCENARIO_DIR}\01_DEST_CHOICE_DEBUG.TXT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\01_DEST_CHOICE.RPT"
FILEO RECO[1] = "{SCENARIO_DIR}\01_DCLS_ROWSUM.DBF",
  FIELDS = A, lnHBW, lnHBO, lnNHB, lnHBC, lnREC
FILEO MATO[1] = "{SCENARIO_DIR}\01_DEST_HBW.MAT",
  MO = 112, 212, 313, 412, 523, 100, 200, 300, 400, 500, DEC = 8, NAME = HBWSizeTerm, HBOSizeTerm, 
    NHBSizeTerm, HBCSizeTerm, RECSizeTerm, HBWUtil, HBOUtil, NHBUtil, HBCUtil, RECUtil
FILEI ZDATI[2] = "{SCENARIO_DIR}\se_classified_2012A.dbf"

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
		  MW[112] = Coeff_HH * ZI.2.HH[J] + Coeff_OFF_EMP * ZI.2.OFF[J] + Coeff_RET_EMP * (ZI.2.RET[J] + ZI.2.HTRET[J]) + Coeff_OTH_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.OFF[J]  - ZI.2.RET[J] - ZI.2.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.RET[J] - ZI.2.HTRET[J])
      
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
 
;;;;;BEGIN HBO DCLS;;;;;

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

		

JLOOP		  
		  ; Compute size term
		  MW[212] = Coeff_HH * ZI.2.HH[J] + Coeff_OFF_EMP * ZI.2.OFF[J] + Coeff_RET_EMP * (ZI.2.RET[J] + ZI.2.HTRET[J]) + Coeff_OTH_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.OFF[J]  - ZI.2.RET[J] - ZI.2.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.RET[J] - ZI.2.HTRET[J])
      
		  ; Log (sizeTerm)
		  IF(MW[212] > 0)   MW[213] = Ln(MW[212])  
		
		  ; Intrazonal boolean
		  IF(J == I) MW[211] = 1
		
		  ; Hwy distance
		  IF (MI.2.Distance < DISTCAP)  MW[2] = MI.2.Distance  
		  IF (MI.2.Distance > 0)  MW[214] = Ln(MI.2.Distance) 
		  		
		  ; Distance calibration constants          
		  IF(MW[2] > 0 && MW[2] <=1) MW[215] = KDIST01    ; Calibration constant for distance 0-1 bin
		  IF(MW[2] > 1 && MW[2] <=2) MW[215] = KDIST12    ; Calibration constant for distance 1-2 bin
		  IF(MW[2] > 2 && MW[2] <=3) MW[215] = KDIST23    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[215] = KDIST34    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[215] = KDIST45    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[215] = KDIST56    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[215] = KDIST67    ; Calibration constant for distance 2-5 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[200] =  CLSUM * MW[201] +                ; modechoice logsum
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[214] + 						; log(distance)  
		             MW[213] + 											; log(sizeterm)  
		             KINTRAZ * MW[211] +            ; intrazonal        
		             MW[215] +                      ; calibration distance  
		             MW[216]                        ; Shadow Price 
ENDJLOOP

;;;;;BEGIN NHB DCLS;;;;;

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

		
JLOOP
		  ; Compute size term
		  MW[312] = Coeff_HH * ZI.2.HH[J] + Coeff_OFF_EMP * ZI.2.OFF[J] + Coeff_RET_EMP * (ZI.2.RET[J] + ZI.2.HTRET[J]) + Coeff_OTH_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.OFF[J]  - ZI.2.RET[J] - ZI.2.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.RET[J] - ZI.2.HTRET[J])
      
		  ; Log (sizeTerm)
		  IF(MW[312] > 0)   MW[313] = Ln(MW[312])  
		
		  ; Intrazonal boolean
		  IF(J == I) MW[311] = 1
		
		  ; Hwy distance
		  IF (MI.2.Distance < DISTCAP)  MW[2] = MI.2.Distance  
		  IF (MI.2.Distance > 0)  MW[314] = Ln(MI.2.Distance) 
		  		
		  ; Distance calibration constants          
		  IF(MW[2] > 0 && MW[2] <=1) MW[315] = KDIST01    ; Calibration constant for distance 0-1 bin
		  IF(MW[2] > 1 && MW[2] <=2) MW[315] = KDIST12    ; Calibration constant for distance 1-2 bin
		  IF(MW[2] > 2 && MW[2] <=3) MW[315] = KDIST23    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[315] = KDIST34    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[315] = KDIST45    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[315] = KDIST56    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[315] = KDIST67    ; Calibration constant for distance 2-5 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[300] =  CLSUM * MW[301] +                ; modechoice logsum
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[314] + 						; log(distance)  
		             MW[313] + 											; log(sizeterm)  
		             KINTRAZ * MW[311] +            ; intrazonal        
		             MW[315] +                      ; calibration distance  
		             MW[316]                        ; Shadow Price 
ENDJLOOP

;;;;;BEGIN HBC DCLS;;;;;

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

		
JLOOP
		  ; Compute size term
		  MW[412] = Coeff_HH * ZI.2.HH[J] + Coeff_OFF_EMP * ZI.2.OFF[J] + Coeff_RET_EMP * (ZI.2.RET[J] + ZI.2.HTRET[J]) + Coeff_OTH_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.OFF[J]  - ZI.2.RET[J] - ZI.2.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.RET[J] - ZI.2.HTRET[J])
      
		  ; Log (sizeTerm)
		  IF(MW[412] > 0)   MW[413] = Ln(MW[412])  
		
		  ; Intrazonal boolean
		  IF(J == I) MW[411] = 1
		
		  ; Hwy distance
		  IF (MI.2.Distance < DISTCAP)  MW[2] = MI.2.Distance  
		  IF (MI.2.Distance > 0)  MW[414] = Ln(MI.2.Distance) 
		  		
		  ; Distance calibration constants          
		  IF(MW[2] > 0 && MW[2] <=1) MW[415] = KDIST01    ; Calibration constant for distance 0-1 bin
		  IF(MW[2] > 1 && MW[2] <=2) MW[415] = KDIST12    ; Calibration constant for distance 1-2 bin
		  IF(MW[2] > 2 && MW[2] <=3) MW[415] = KDIST23    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[415] = KDIST34    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[415] = KDIST45    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[415] = KDIST56    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[415] = KDIST67    ; Calibration constant for distance 2-5 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[400] =  CLSUM * MW[401] +                ; modechoice logsum
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[414] + 						; log(distance)  
		             MW[413] + 											; log(sizeterm)  
		             KINTRAZ * MW[411] +            ; intrazonal        
		             MW[415] +                      ; calibration distance  
		             MW[416]                        ; Shadow Price 
ENDJLOOP

;;;;;BEGIN REC DCLS;;;;;

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

	
JLOOP
		  ; Compute size term
		  MW[512] = Coeff_HH * ZI.2.HH[J] + Coeff_OFF_EMP * ZI.2.OFF[J] + Coeff_RET_EMP * (ZI.2.RET[J] + ZI.2.HTRET[J]) + Coeff_OTH_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.OFF[J]  - ZI.2.RET[J] - ZI.2.HTRET[J]) + Coeff_OTH_OFF_EMP * (ZI.2.EMP_NOSG[J] - ZI.2.RET[J] - ZI.2.HTRET[J])
      
		  ; Log (sizeTerm)
		  IF(MW[512] > 0)   MW[513] = Ln(MW[512])  
		
		  ; Intrazonal boolean
		  IF(J == I) MW[511] = 1
		
		  ; Hwy distance
		  IF (MI.2.Distance < DISTCAP)  MW[2] = MI.2.Distance  
		  IF (MI.2.Distance > 0)  MW[514] = Ln(MI.2.Distance) 
		  		
		  ; Distance calibration constants          
		  IF(MW[2] > 0 && MW[2] <=1) MW[515] = KDIST01    ; Calibration constant for distance 0-1 bin
		  IF(MW[2] > 1 && MW[2] <=2) MW[515] = KDIST12    ; Calibration constant for distance 1-2 bin
		  IF(MW[2] > 2 && MW[2] <=3) MW[515] = KDIST23    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[515] = KDIST34    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[515] = KDIST45    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[515] = KDIST56    ; Calibration constant for distance 2-5 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[515] = KDIST67    ; Calibration constant for distance 2-5 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[500] =  CLSUM * MW[501] +                ; modechoice logsum
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[514] + 						; log(distance)  
		             MW[513] + 											; log(sizeterm)  
		             KINTRAZ * MW[511] +            ; intrazonal        
		             MW[515] +                      ; calibration distance  
		             MW[516]                        ; Shadow Price 
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
  SeHBO = SeHBO + exp(MW[200])
  SeNHB = SeNHB + exp(MW[300])
  SeHBC = SeHBC + exp(MW[400])
  SeREC = SeREC + exp(MW[500])
ENDJLOOP
  Ro.A = A
  Ro.lnHBW = ln(SeHBW)
  Ro.lnHBO = ln(SeHBO)
  Ro.lnNBH = ln(SeNHB)
  Ro.lnHBC = ln(SeHBC)
  Ro.lnREC = ln(SeREC)

WRITE RECO = 1
    
 ;Write in stuff that computes the dcls ,using the utilities 
 ;create another matrix thta writes out the utilites for each matrix (HBW)

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBO_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI ZDATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\se_classified_2012A.dbf"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_NHB_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI LOOKUPI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\se_classified_2012A.dbf"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBC_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI ZDATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\se_classified_2012A.dbf"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_HIGHWAY_SKIMS.MAT"

LOOKUP LOOKUPI=1,
       NAME=DESTCHOICE_PARA,
         LOOKUP[1]=NVAR, RESULT=HBW,
         LOOKUP[2]=NVAR, RESULT=HBO,
         LOOKUP[3]=NVAR, RESULT=HBC,
         LOOKUP[4]=NVAR, RESULT=REC,
         LOOKUP[5]=NVAR, RESULT=NHB,
       FAIL[3]=0
; example of use: v=DESTCHOICE_PARA(5,25)
; look for 25 in the NVAR field and returns the NHB value


LOOKUP LOOKUPI=1,
       NAME=DESTCHOICE_PARA,
         LOOKUP[1]=NVAR, RESULT=HBW,
         LOOKUP[2]=NVAR, RESULT=HBO,
         LOOKUP[3]=NVAR, RESULT=HBC,
         LOOKUP[4]=NVAR, RESULT=REC,
         LOOKUP[5]=NVAR, RESULT=NHB,
       FAIL[3]=0
; example of use: v=DESTCHOICE_PARA(5,25)
; look for 25 in the NVAR field and returns the NHB value


LOOKUP LOOKUPI=1,
       NAME=DESTCHOICE_PARA,
         LOOKUP[1]=NVAR, RESULT=HBW,
         LOOKUP[2]=NVAR, RESULT=HBO,
         LOOKUP[3]=NVAR, RESULT=HBC,
         LOOKUP[4]=NVAR, RESULT=REC,
         LOOKUP[5]=NVAR, RESULT=NHB,
       FAIL[3]=0
; example of use: v=DESTCHOICE_PARA(5,25)
; look for 25 in the NVAR field and returns the NHB value

FILEI MATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_REC_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI ZDATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\se_classified_2012A.dbf"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_DCLS_COMBINE.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_HBW_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN


