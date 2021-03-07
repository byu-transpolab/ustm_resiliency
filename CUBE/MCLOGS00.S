; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_HBW_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\logs\01_HBW_MCLS.PRN" MSG='HBW MCLS'
FILEI MATI[1] = "{SCENARIO_DIR}\scenario_network.net"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\transit_skim.mat"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_LOGSUM.MAT",
  MO = 41,DEC=D, NAME=HBWlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_UTILITY.MAT",
  MO=111-113, DEC=D,NAME=HBWauto_util,HBWnonmot_util,HBWtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=HBWauto_prob,HBWnonmot_prob, HBWtransit_prob
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\hbw_modechoice_trace.txt"

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
  zonemsg=100

  ; Declare arrays to hold alternative specific constants
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


  ; calculate travel time of non-motorized modes
  MW[4] = (MW[2] / 3) * 60 ; miles / 3mph * 60 min/hr

  ; Calculate Utilities, multiplied by 100 to display correct numbers at the wrong magnitude
  MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])          ;Drive alone auto utility
  MW[111] = MW[11] * 100                                                    ;Printed auto utility
  MW[12] = (K_NMOT + COEFF_WALK1 * 20 * MW[18] + COEFF_WALK2 * 20 * MW[19]) ;non-motorized utility
  MW[112] = MW[12] * 100                                                    ;Printed non-motorized utility
  MW[13] = K_TRN + (COEFF_IVTT * MW[3]) + (COEFF_SWAIT * MW[3] * 0.1)       ;transit utility, assume 10% is waiting
  MW[113] = MW[13] * 100                                                    ;Printed transity utility

  ; Exponentiate Utilities and adjust for zones which do not exist
  MW[21] = exp(MW[11]) ;Exponentiated auto utility

  JLOOP
      IF (MW[2] > 50) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 50 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 50 miles
      ENDIF

      ; Transit path reasonableness
      IF (MW[3] = 0) ;transit walk time
          MW[23] = 0 ;exponentiated U is zero if impossible
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

      ; Report coefficient values to summary file and debug file;
         JLOOP
     		 ;Debug Mode choice

     	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest})
          PRINT PRINTO=1 CSV=F LIST ='MODE CHOICE TRACE HBW','\n\n'
     	  	PRINT PRINTO=1 CSV=F LIST =' Mode choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
     	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  @PURP@  '
          PRINT PRINTO=1 CSV=F LIST ="\n Auto IVTT                                           ", MW[1]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Equation                               ", COEFF_IVTT, ' * ', MW[1], ' + ', COEFF_COST, ' * ', AUTOCOST, ' * ', MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Value                                  ", MW[11],
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Exponentiated Utility Value                    ", MW[21],
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Equation                               ", K_NMOT, ' + ', COEFF_WALK1, ' * 20 * ', MW[18], ' + ', COEFF_WALK2, ' * 20 * ', MW[19])
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Value                                  ", MW[12],
          PRINT PRINTO=1 CSV=F LIST ="\n WAlk Exponentiated Utility Value (0 if impossible)  ", MW[22],
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Travel Time Value                           ", MW[3],
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Equation                            ", K_TRN, ' + ', COEFF_IVTT, ' * ', MW[3],  ' + ', COEFF_SWAIT, ' * ', 0.1 * MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Values                              ", MW[13]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Exonentiated Utility Value (0 if impossible)", MW[23]

          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
     		  PRINT PRINTO=1 CSV=F LIST ='\n Sum of exp(U)                                       ', MW[30]
          PRINT PRINTO=1 CSV=F LIST ='\n P(auto)                                             ', MW[31]
          PRINT PRINTO=1 CSV=F LIST ='\n P(walk)                                             ', MW[32]
          PRINT PRINTO=1 CSV=F LIST ='\n P(transit)                                          ', MW[33]
          PRINT PRINTO=1 CSV=F LIST ='\n Ln(sum)                                             ', MW[40]
                		  
        ENDIF
ENDRUN


; Script for program MATRIX in file "C:\projects\ustm_resiliency\Base\01_HBO_MCLS.S"
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


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_NHB_MCLS.S"
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


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_HBC_MCLS.S"
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


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_REC_MCLS.S"
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


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_MCLS_COMBINE.S"
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
FILEO MATO[1] = "{SCENARIO_DIR}\Outputs\01_MCLS_COMBINED.MAT",
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


