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
        JLOOP
      IF (MW[2] > 10000)
        MW[21] = 0
        MW[22] = 0
      ELSE
        MW[21] = exp(MW[11])
        MW[22] = exp(MW[12]) 
      ENDIF
        ENDJLOOP
        
      JLOOP
      IF (MW[3] = 0)
          MW[23] = 0
      ELSE
        MW[23] = exp(MW[13])
      ENDIF
      ENDJLOOP
      
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
