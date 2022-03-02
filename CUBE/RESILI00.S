; Script for program HIGHWAY in file "C:\projects\ustm_resiliency\CUBE\01_HIGHWAY.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY MSG='Mode and Destination Choice Model'
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = D, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\scenario_network.net"

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


LOOP AMLoop_1 = 1, 1

  IF (AMLoop_1=1)
    *Copy "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT" "C:\PROJECTS\USTM_RESILIENCY\CUBE\01LOO00B.MAT"
  ELSE
    *Copy "{SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT" "C:\PROJECTS\USTM_RESILIENCY\CUBE\01LOO00B.MAT"
  ENDIF

; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_HBW_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\logs\01_HBW_MCLS.PRN" MSG='HBW MCLS'
FILEI MATI[3] = "{CATALOG_DIR}\Base\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\transit_skim.MAT"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_LOGSUM.MAT",
  MO = 40,DEC=D, NAME=HBWlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_UTILITY.MAT",
  MO=11-13, DEC=D,NAME=HBWauto_util,HBWnonmot_util,HBWtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=HBWauto_prob,HBWnonmot_prob, HBWtransit_prob
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\hbw_modechoice_trace.txt"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.


  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1        ;Walk bus time
  FILLMW MW[5]=MI.3.2        ;NMOT Distance

  ; Progress Bar update for evey 100 zones
  zonemsg=100

  ; Declare arrays to hold alternative specific constants
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
   COEFF_NXFER   = COEFF(1,18)              ; number of xfers

ENDIF

  ; Non motorized
  ; distance portion that is 1 mile or less
  MW[18] = MIN(MW[5],1)

  ; Distance portion that is longer than 1 mile
  JLOOP
    IF (MW[5][J] > 1)
        MW[19] = MW[5][J] - 1
    ELSE
        MW[19] = 0
    ENDIF
  ENDJLOOP


  ; calculate travel time of non-motorized modes
  MW[4] = (MW[5] / 3) * 60 ; miles / 3mph * 60 min/hr

  ; Calculate Utilities
  MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])           ;Drive alone auto utility
  MW[12] = (K_NMOT + 20 * (COEFF_WALK1 * MW[18] + COEFF_WALK2 * MW[19]))    ;non-motorized utility, multiplied by 20 for time
  MW[13] = K_TRN + (COEFF_IVTT * MW[3]) + (COEFF_SWAIT * MW[3] * 0.1)       ;transit utility, assume 10% is waiting

  ; Exponentiate Utilities and adjust for zones which do not exist
  MW[21] = exp(MW[11]) ;Exponentiated auto utility

  JLOOP
      IF (MW[5] > 2.5) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 2.5 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 2.5 miles
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
          PRINT PRINTO=1 CSV=F LIST ='MODE CHOICE TRACE HBO','\n\n'
     	  	PRINT PRINTO=1 CSV=F LIST =' Mode choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
     	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  @PURP@  '
          PRINT PRINTO=1 CSV=F LIST ="\n Auto IVTT                                           ", MW[1]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Equation                               ", COEFF_IVTT, ' * ', MW[1], ' + ', COEFF_COST, ' * ', AUTOCOST, ' * ', MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Value                                  ", MW[11]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Exponentiated Utility Value                    ", MW[21]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Equation                               ", K_NMOT, ' +  20 * (', COEFF_WALK1, ' + ', MW[18], ' + ', COEFF_WALK2, ' * ', MW[19],')
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Value                                  ", MW[12]
          PRINT PRINTO=1 CSV=F LIST ="\n WAlk Exponentiated Utility Value (0 if impossible)  ", MW[22]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Travel Time Value                           ", MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Equation                            ", K_TRN, ' + ', COEFF_IVTT, ' * ', MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Values                              ", MW[13]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Exonentiated Utility Value (0 if impossible)", MW[23]

          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
     		  PRINT PRINTO=1 CSV=F LIST ='\n Sum of exp(U)                                       ', MW[30]
          PRINT PRINTO=1 CSV=F LIST ='\n P(auto)                                             ', MW[31]
          PRINT PRINTO=1 CSV=F LIST ='\n P(walk)                                             ', MW[32]
          PRINT PRINTO=1 CSV=F LIST ='\n P(transit)                                          ', MW[33]
          PRINT PRINTO=1 CSV=F LIST ='\n Ln(sum)                                             ', MW[40]

        ENDIF
       ENDJLOOP
ENDRUN


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_HBO_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_HBO_MCLS.PRN" MSG='HBO MCLS'
FILEI MATI[3] = "{CATALOG_DIR}\Base\Output\01_HIGHWAY_SKIMS.MAT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\hbo_modechoice_trace.txt"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\transit_skim.mat"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_LOGSUM.MAT",
  MO = 40,DEC=D, NAME=HBOlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_UTILITY.MAT",
 MO=11-13, DEC=D,NAME=HBOauto_util,HBOnonmot_util, HBOtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=HBOauto_prob,HBOnonmot_prob, HBOtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1     ;Walk bus time
  FILLMW MW[5]=MI.3.2        ;NMOT Distance

  ; Progress Bar update for evey 100 zones
  zonemsg=100

  ; Declare arrays to hold alternative specific constants
  ARRAY TYPE=F K_AUT=1, K_SR=1, K_TRN=1, K_NMOT=1
  ARRAY TYPE=C30 MARKET_NAME=1

  ; Read alternative specific Constants
  LOOKUP, NAME=CONSTANTS, LOOKUP[1]=1, RESULT=4, INTERPOLATE=N, , LIST=Y, LOOKUPI=2

  ; Read mode choice coefficients
  LOOKUP, NAME=COEFF, LOOKUP[1]=1, RESULT=4, INTERPOLATE=N, LIST=Y, LOOKUPI=1

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
   COEFF_NXFER   = COEFF(1,18)              ; number of xfers

ENDIF

  ; Non motorized
  ; distance portion that is 1 mile or less
  MW[18] = MIN(MW[5],1)

  ; Distance portion that is longer than 1 mile
  JLOOP
    IF (MW[5][J] > 1)
        MW[19] = MW[5][J] - 1
    ELSE
        MW[19] = 0
    ENDIF
  ENDJLOOP


  ; calculate travel time of non-motorized modes
  MW[4] = (MW[5] / 3) * 60 ; miles / 3mph * 60 min/hr

  ; Calculate Utilities
  MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])           ;Drive alone auto utility
  MW[12] = (K_NMOT + 20 * (COEFF_WALK1 * MW[18] + COEFF_WALK2 * MW[19]))    ;non-motorized utility, multiplied by 20 for time
  MW[13] = K_TRN + (COEFF_IVTT * MW[3]) + (COEFF_SWAIT * MW[3] * 0.1)       ;transit utility, assume 10% is waiting

  ; Exponentiate Utilities and adjust for zones which do not exist
  MW[21] = exp(MW[11]) ;Exponentiated auto utility

  JLOOP
      IF (MW[5] > 2.5) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 2.5 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 2.5 miles
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
          PRINT PRINTO=1 CSV=F LIST ='MODE CHOICE TRACE HBO','\n\n'
     	  	PRINT PRINTO=1 CSV=F LIST =' Mode choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
     	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  @PURP@  '
          PRINT PRINTO=1 CSV=F LIST ="\n Auto IVTT                                           ", MW[1]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Equation                               ", COEFF_IVTT, ' * ', MW[1], ' + ', COEFF_COST, ' * ', AUTOCOST, ' * ', MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Value                                  ", MW[11]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Exponentiated Utility Value                    ", MW[21]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Equation                               ", K_NMOT, ' +  20 * (', COEFF_WALK1, ' + ', MW[18], ' + ', COEFF_WALK2, ' * ', MW[19],')
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Value                                  ", MW[12]
          PRINT PRINTO=1 CSV=F LIST ="\n WAlk Exponentiated Utility Value (0 if impossible)  ", MW[22]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Travel Time Value                           ", MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Equation                            ", K_TRN, ' + ', COEFF_IVTT, ' * ', MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Values                              ", MW[13]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Exonentiated Utility Value (0 if impossible)", MW[23]

          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
     		  PRINT PRINTO=1 CSV=F LIST ='\n Sum of exp(U)                                       ', MW[30]
          PRINT PRINTO=1 CSV=F LIST ='\n P(auto)                                             ', MW[31]
          PRINT PRINTO=1 CSV=F LIST ='\n P(walk)                                             ', MW[32]
          PRINT PRINTO=1 CSV=F LIST ='\n P(transit)                                          ', MW[33]
          PRINT PRINTO=1 CSV=F LIST ='\n Ln(sum)                                             ', MW[40]

        ENDIF
       ENDJLOOP
ENDRUN


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_NHB_MCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\01_NHB_MCLS.PRN" MSG='NHB MCLS'
FILEI MATI[3] = "{CATALOG_DIR}\Base\Output\01_HIGHWAY_SKIMS.MAT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\nhb_modechoice_trace.txt"
FILEI LOOKUPI[2] = "{CATALOG_DIR}\params\MC_Constants.csv"
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\MC_Coefficients.csv"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\transit_skim.mat"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_LOGSUM.MAT",
  MO = 40,DEC=D, NAME=NHBlogsum
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_UTILITY.MAT",
  MO=11-13, DEC=D,NAME=NHBauto_util,NHBnonmot_util,NHBtransit_util
FILEO MATO[3] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_PROBABILITY.MAT",
 MO=31-33, DEC=D,NAME=NHBauto_prob,NHBnonmot_prob,NHBtransit_prob

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  
  FILLMW MW[1]=MI.1.TIME     ;AM highway time
  FILLMW MW[2]=MI.1.DISTANCE ;AM highway distance
  FILLMW MW[3]=MI.2.1     ;Walk bus time
  FILLMW MW[5]=MI.3.2        ;NMOT Distance

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
   COEFF_NXFER   = COEFF(1,18)              ; number of xfers

ENDIF

  ; Non motorized
  ; distance portion that is 1 mile or less
  MW[18] = MIN(MW[5],1)

  ; Distance portion that is longer than 1 mile
  JLOOP
    IF (MW[5][J] > 1)
        MW[19] = MW[5][J] - 1
    ELSE
        MW[19] = 0
    ENDIF
  ENDJLOOP


  ; calculate travel time of non-motorized modes
  MW[4] = (MW[5] / 3) * 60 ; miles / 3mph * 60 min/hr

  ; Calculate Utilities
  MW[11] = (COEFF_IVTT * MW[1]) + (COEFF_COST * AUTOCOST * MW[2])           ;Drive alone auto utility
  MW[12] = (K_NMOT + 20 * (COEFF_WALK1 * MW[18] + COEFF_WALK2 * MW[19]))    ;non-motorized utility, multiplied by 20 for time
  MW[13] = K_TRN + (COEFF_IVTT * MW[3]) + (COEFF_SWAIT * MW[3] * 0.1)       ;transit utility, assume 10% is waiting

  ; Exponentiate Utilities and adjust for zones which do not exist
  MW[21] = exp(MW[11]) ;Exponentiated auto utility

  JLOOP
      IF (MW[5] > 2.5) ;limit length of nonmot trips
        MW[22] = 0 ;change nmot exponentiated utility if longer than 2.5 miles
      ELSE
        MW[22] = exp(MW[12]) ;nonmotorized exponentiated utiltiy shorter than 2.5 miles
      ENDIF
        
      ;transit path reasonableness
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

      ; Report coefficient values to summary file and debug file;
         JLOOP
     		 ;Debug Mode choice

     	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest})
          PRINT PRINTO=1 CSV=F LIST ='MODE CHOICE TRACE HBO','\n\n'
     	  	PRINT PRINTO=1 CSV=F LIST =' Mode choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
     	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  @PURP@  '
          PRINT PRINTO=1 CSV=F LIST ="\n Auto IVTT                                           ", MW[1]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Equation                               ", COEFF_IVTT, ' * ', MW[1], ' + ', COEFF_COST, ' * ', AUTOCOST, ' * ', MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Utility Value                                  ", MW[11]
          PRINT PRINTO=1 CSV=F LIST ="\n Auto Exponentiated Utility Value                    ", MW[21]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Distance                                       ", MW[2]
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Equation                               ", K_NMOT, ' +  20 * (', COEFF_WALK1, ' + ', MW[18], ' + ', COEFF_WALK2, ' * ', MW[19],')
          PRINT PRINTO=1 CSV=F LIST ="\n Walk Utility Value                                  ", MW[12]
          PRINT PRINTO=1 CSV=F LIST ="\n WAlk Exponentiated Utility Value (0 if impossible)  ", MW[22]
          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Travel Time Value                           ", MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Equation                            ", K_TRN, ' + ', COEFF_IVTT, ' * ', MW[3]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Utility Values                              ", MW[13]
          PRINT PRINTO=1 CSV=F LIST ="\n Transit Exonentiated Utility Value (0 if impossible)", MW[23]

          PRINT PRINTO=1 CSV=F LIST ="\n -------------------------                           "
     		  PRINT PRINTO=1 CSV=F LIST ='\n Sum of exp(U)                                       ', MW[30]
          PRINT PRINTO=1 CSV=F LIST ='\n P(auto)                                             ', MW[31]
          PRINT PRINTO=1 CSV=F LIST ='\n P(walk)                                             ', MW[32]
          PRINT PRINTO=1 CSV=F LIST ='\n P(transit)                                          ', MW[33]
          PRINT PRINTO=1 CSV=F LIST ='\n Ln(sum)                                             ', MW[40]

        ENDIF
       ENDJLOOP
ENDRUN


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_MCLS_COMBINE.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Combine All MCLS Calculations'
FILEO MATO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED_PROBABILITY.MAT",
  MO = 11-13, 21-23, 31-33 DEC = D, NAME = HBWauto_prob, HBOauto_prob, NHBauto_prob, HBWnmot_prob, HBOnmot_prob, NHBnmot_prob, HBWtran_prob, HBOtran_prob, NHBtran_prob
FILEI MATI[8] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_NHB_PROBABILITY.MAT"
FILEI MATI[7] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBO_PROBABILITY.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\intermediate_outputs\01_MC_HBW_PROBABILITY.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_MCLS_COMBINED.MAT",
  MO = 1-3  DEC = D, NAME = HBWlogsum, HBOlogsum, NHBlogsum
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
  
  ;Fill Auto Probabilities
  FILLMW MW[11]=MI.6.1 ;HBW Auto Probability
  FILLMW MW[12]=MI.7.1 ;HBO Auto Probability
  FILLMW MW[13]=MI.8.1 ;NHB Auto Probability
  
  ;Fill Non-motorized Probability
  FILLMW MW[21]=MI.6.2 ;HBW NMOT Probability
  FILLMW MW[22]=MI.7.2 ;HBO NMOT Probability
  FILLMW MW[23]=MI.8.2 ;NHB NMOT Probability 
  
  ;Fill Transit Probability
  FILLMW MW[31]=MI.6.3 ;HBW Transit Probability
  FILLMW MW[32]=MI.7.3 ;HBO Transit Probability
  FILLMW MW[33]=MI.8.3 ;NHB Transit Probability 

ENDRUN


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_HBW_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='HBW DCLS'
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_MCLS_COMBINED.MAT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_HBW_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBW.MAT",
  MO = 112, 100 DEC = D, NAME = HBWSizeTerm, HBWUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"

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
		MW[101] = MI.1.HBWlogsum ;HBW logsum

		; Hwy distance skim
		MW[2] = DISTCAP
    
    ; Distance calibration
    MW[113] = 0
    
;;;;;BEGIN HBW DCLS;;;;;

		JLOOP
		  ; Compute size term
		  MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OFFI[J] + Coeff_RET_EMP * ZI.1.RETEMP[J] + Coeff_OTH_EMP * (ZI.1.ALLEMP[J] - ZI.1.OTHEMP[J] - ZI.1.RETEMP[J])

      
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
		  IF(MW[2] > 2 && MW[2] <=3) MW[115] = KDIST23    ; Calibration constant for distance 2-3 bin
		  IF(MW[2] > 3 && MW[2] <=4) MW[115] = KDIST34    ; Calibration constant for distance 3-4 bin
		  IF(MW[2] > 4 && MW[2] <=5) MW[115] = KDIST45    ; Calibration constant for distance 4-5 bin
		  IF(MW[2] > 5 && MW[2] <=6) MW[115] = KDIST56    ; Calibration constant for distance 5-6 bin
		  IF(MW[2] > 6 && MW[2] <=7) MW[115] = KDIST67    ; Calibration constant for distance 6-7 bin
		  

      
		  ; Utility expression--has the MCLS in the expression already
		  MW[100] =  CLSUM * MW[101] +              ; modechoice logsum (THIS IS THE PRIMARY IMPEDANCE). 
                 MW[113] + 											; log(sizeterm) 
		             CDIST * MW[2] +                ; distance
		             CDISTSQ * (POW(MW[2],2)) +     ; distance sq
		             CDISTCUB * (POW(MW[2],3)) +    ; distance cube
		             CDISTLN * MW[114] + 						; log(distance)  
		              
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
      PRINT PRINTO=1 CSV=F LIST ='DESTINTION CHOICE TRACE HBW','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' Destination Choice Model Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -                   @PURP@  '
	  	PRINT PRINTO=1 CSV=F LIST ='\n Size Term is computed on the Destination '	  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = household coefficient                    ', Coeff_HH          , ' * ' , ZI.1.TOTHH[J]  
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Other + Office Emp coefficient           ', Coeff_OTH_OFF_EMP , ' * ' , ZI.1.OFFI[J], ZI.1.RETEMP[J]   
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Office Emp coefficient                   ', Coeff_OFF_EMP     , ' * ' , ZI.1.OFFI[J] 
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Other Emp coefficient                    ', Coeff_OTH_EMP     , ' * ' , ZI.1.OTHEMP
		  PRINT PRINTO=1 CSV=F LIST ='\n SizeTerm = Retail Emp coefficient                   ', Coeff_RET_EMP     , ' * ' , ZI.1.RETEMP[J]
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
		  PRINT PRINTO=1 CSV=F LIST ='\n Applied  calibration constant                       ', MW[113] ;I'm not sure what this refers to...
      PRINT PRINTO=1 CSV=F LIST ='\n Size Term                                           ', MW[112] 
      PRINT PRINTO=1 CSV=F LIST ='\n Ln(Size Term)                                       ', MW[113]     
		  PRINT PRINTO=1 CSV=F LIST ='\n Computed Utility                                    ', MW[100]            	  
		  PRINT PRINTO=1 CSV=F LIST ='\n Total Productions in Origin                         ', personTrips[I]     			  
		  PRINT PRINTO=1 CSV=F LIST ='\n Trip Attractions                                    ', MW[119]
      PRINT PRINTO=1 CSV=F LIST ='\n Utility Equation                                    ', MW[100],' = ' ,CLSUM,'*',MW[101],'+',CDIST,'*',MW[2],'+',CDISTQ,'*'
      PRINT PRINTO=1 CSV=F LIST ='\n Utility Equation Part 2                             ',(POW(MW[2],2)),'+',CDISTCUB,'*',(POW(MW[2,3)),'+',CDISTLN,'*',MW[114]
      PRINT PRINTO=1 CSV=F LIST ='\n Utility Equation Part 3                             ','+',MW[113],'+',KINTRAZ,'*',MW[111],'+',MW[115],'+',MW[116]
   ENDIF
    
   ; Report total intrazonals 
    IF(I = J)  INTRAZONAL_sum = INTRAZONAL_sum + MW[119]
    IF (I = ZONES && J = ZONES) PRINT PRINTO=1 CSV=F LIST ='\n Intrazonal Sum            ', INTRAZONAL_sum 
 ENDJLOOP
 
ENDRUN


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_HBO_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='HBO DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_HBO_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBO.MAT",
  MO = 112, 100 DEC = D, NAME = HBOSizeTerm, HBOUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_MCLS_COMBINED.MAT"

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
		  MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OFFI[J] + Coeff_RET_EMP * ZI.1.RETEMP[J] + Coeff_OTH_EMP * (ZI.1.ALLEMP[J] - ZI.1.OTHEMP[J] - ZI.1.RETEMP[J])
      
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


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_NHB_DCLS.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='NHB DCLS'
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_NHB_DEST_CHOICE.RPT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_NHB.MAT",
  MO = 112, 100 DEC = D, NAME=HBWSizeTerm, HBWUtil
FILEI LOOKUPI[1] = "{CATALOG_DIR}\params\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\SE_USTM_BASE2015.DBF"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_MCLS_COMBINED.MAT"


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
		  MW[112] = Coeff_HH * ZI.1.TOTHH[J] + Coeff_OFF_EMP * ZI.1.OFFI[J] + Coeff_RET_EMP * ZI.1.RETEMP[J] + Coeff_OTH_EMP * (ZI.1.ALLEMP[J] - ZI.1.OTHEMP[J] - ZI.1.RETEMP[J])
      
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


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_DCLS_COMBINE.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINE.PRN" MSG='COMBINE UTILITIES'
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBW.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_HBO.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\intermediate_outputs\01_DEST_NHB.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINED.MAT",
  MO = 1-3, DEC = D, NAME = HBWDCUtility, HBODCUtility, NHBDCUtility

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

  FILLMW MW[1]=MI.1.2 ;HBW
  FILLMW MW[2]=MI.2.2 ;HBO
  FILLMW MW[3]=MI.3.2 ;NHB

ENDRUN


; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_DCLS_ROWSUM.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_DCLS_ROWSUM.PRN"
FILEO RECO[1] = "{SCENARIO_DIR}\Output\01_ROWSUMS.DBF",
  FIELDS = TAZ, lnHBW, lnHBO, lnNHB
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_DCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

FILLMW MW[100] = MI.1.1
FILLMW MW[200] = MI.1.2
FILLMW MW[300] = MI.1.3

SeHBW = 0
SeHBO = 0
SeNHB = 0

JLOOP
;change to an if statement to exclude rows/columns that don't exist i would need to set those values correctly to exclude them (its the column that matters)
  TAZ = i
  SeHBW = SeHBW + exp(MW[100])
  SeHBO = SeHBO + exp(MW[200])
  SeNHB = SeNHB + exp(MW[300])

ENDJLOOP
  Ro.TAZ = TAZ
  Ro.lnHBW = ln(SeHBW)
  Ro.lnHBO = ln(SeHBO)
  Ro.lnNHB = ln(SeNHB)

WRITE RECO = 1



ENDRUN


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_TRIPS_IJ.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJ'
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\trips_ij_trace.txt"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT",
MO = 10,20,30,100,200,300,98,99 DEC = D, NAME = HBWDCProbability, HBODCProbability, NHBDCProbability, HBWTrips,HBOTrips,NHBTrips,CheckRowsum, CheckProd
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

    ; The destination choice utility is too large to count at this point. We will
    ;  re-scale utility by subtracting the row average
    hbw_avg_utility = rowsum(mw[1]) / ZONES
    hbo_avg_utility = rowsum(mw[2]) / ZONES
    nhb_avg_utility = rowsum(mw[3]) / ZONES
    
    ; sum of all exponentiated utilities
    hbw_sum_utility = 0
    hbo_sum_utility = 0
    nhb_sum_utility = 0
      
    JLOOP
        ;exponentiated utility of the alternative
        MW[11] = exp(MW[1] - hbw_avg_utility)
        MW[12] = exp(MW[2] - hbo_avg_utility)
        MW[13] = exp(MW[3] - nhb_avg_utility)
        
        ; sum of all exponentiated utilities
        hbw_sum_utility = hbw_sum_utility + MW[11]
        hbo_sum_utility = hbo_sum_utility + MW[12]
        nhb_sum_utility = nhb_sum_utility + MW[13]

    ENDJLOOP
    
       ; choice probabilities
       MW[10] = MW[11]/hbw_sum_utility 
       MW[20] = MW[12]/hbo_sum_utility 
       MW[30] = MW[13]/nhb_sum_utility 

    JLOOP
	      ; Compute Trips
        MW[98]  = ZI.2.LNHBW[i]
        MW[99]  = ZI.1.HBWP[i]
		    MW[100] = MW[10] * ZI.1.HBWP[i] 
        MW[200] = MW[20] * ZI.1.HBOP[i] 
        MW[300] = MW[30] * ZI.1.NHBP[i] 
       
    ENDJLOOP
    

    ; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='TRIPS IJ TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' Trips IJ Trace \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'
	  	PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  HBW  ---------------                     '	  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n Original utility                                ', MW[1] 
      PRINT PRINTO=1 CSV=F LIST ='\n Average Utility                                 ', hbw_avg_utility 
      PRINT PRINTO=1 CSV=F LIST ='\n Exp(Utility - average)                          ', MW[11]
      PRINT PRINTO=1 CSV=F LIST ='\n Sum of exp(U - average)                         ', hbw_sum_utility
      PRINT PRINTO=1 CSV=F LIST ='\n Choice probability                              ', MW[10]
      PRINT PRINTO=1 CSV=F LIST ='\n Productions at i                                ', ZI.1.HBWP[J]
      PRINT PRINTO=1 CSV=F LIST ='\n TRIPS IJ                                        ', MW[100]
      PRINT PRINTO=1 CSV=F LIST ='\n PURPOSE -  HBO  ---------------                 ',
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Utility                                         ', MW[2]  
		  PRINT PRINTO=1 CSV=F LIST ='\n NHB Utility                                         ', MW[3] 
		  PRINT PRINTO=1 CSV=F LIST ='\n HBW Probability  								                   ', MW[10],'=(',exp(MW[1]),')/e^',ZI.2.LNHBW[J]          
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Probability                                     ', MW[20],'=(',exp(MW[2]),')/e^',ZI.2.LNHBO[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n NHB Probability                                     ', MW[30],'=(',exp(MW[3]),')/e^',ZI.2.LNNHB[J]
		  PRINT PRINTO=1 CSV=F LIST ='\n HBW Trips                                           ', MW[100],'=', ZI.1.HBWP[J]      , ' * ' , MW[10] 		  
		  PRINT PRINTO=1 CSV=F LIST ='\n HBO Trips                                           ', MW[200],'=', ZI.1.HBOP[J]      , ' * ' , MW[20] 
      PRINT PRINTO=1 CSV=F LIST ='\n NHB Trips                                           ', MW[300],'=', ZI.1.NHBP[J]      , ' * ' , MW[30] 		  
		

   ENDIF
     
 ENDJLOOP
    
    
ENDRUN


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_TRIPS_IJK.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Trips_IJK'
FILEO MATO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT",
 MO = 40-42, 45-47,100,200,300,110,210,310,120,220,320, DEC = D, NAME = HBWTrips,HBOTrips,NHBTrips,autoTrips,nmotTrips,transitTrips,HBWauto,HBOauto,NHBauto,HBWnmot,HBOnmot,NHBnmot,HBWtransit,HBOtransit,NHBtransit
FILEI MATI[2] = "{SCENARIO_DIR}\intermediate_outputs\01_MCLS_COMBINED_PROBABILITY.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

 ;Fill Trips into matrices
		MW[1] = MI.1.4 ;HBW
		MW[2] = MI.1.5 ;HBO
    MW[3] = MI.1.6 ;NHB
    
 ;Fill MC auto_prob into matrices
    MW[11] = MI.2.1 ;HBW
		MW[12] = MI.2.2 ;HBO
    MW[13] = MI.2.3 ;NHB
    
  ;Fill MC nmot_prob into matrices
    MW[21] = MI.2.4 ;HBW
		MW[22] = MI.2.5 ;HBO
    MW[23] = MI.2.6 ;NHB
  
  ;Fill MC transit_prob into matrices
    MW[31] = MI.2.7 ;HBW
		MW[32] = MI.2.8 ;HBO
    MW[33] = MI.2.9 ;NHB 
    
    ;Compute trips by mode choice and purpose
    MW[100] = MW[1] * MW[11] ;HBWauto
    MW[200] = MW[2] * MW[12] ;HBOauto
    MW[300] = MW[3] * MW[13] ;NHBauto
    MW[110] = MW[1] * MW[21] ;HBWnmot
    MW[210] = MW[2] * MW[22] ;HBOnmot
    MW[310] = MW[3] * MW[23] ;NHBnmot
    MW[120] = MW[1] * MW[31] ;HBWtransit
    MW[220] = MW[2] * MW[32] ;HBOtransit
    MW[320] = MW[3] * MW[33] ;NHBtransit

    ;Compute trips by trip purpose
    MW[40] = MW[100] + MW[110] + MW[120] ;HBW
    MW[41] = MW[200] + MW[210] + MW[220] ;HBO
    MW[42] = MW[300] + MW[310] + MW[320] ;NHB
    
    ;Compute total trips by mode choice
    MW[45] = MW[100] + MW[200] + MW[300] ;auto
    MW[46] = MW[110] + MW[210] + MW[310] ;nmot
    MW[47] = MW[120] + MW[220] + MW[320] ;transit
    
ENDRUN


; Script for program MATRIX in file "C:\Projects\ustm_resiliency\CUBE\01_MODESPLIT.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Create Mode Split Columns'
FILEO RECO[1] = "{SCENARIO_DIR}\Output\01_MODESPLIT.DBF",
  FIELDS = TAZ, HBWAUTO, HBWNMOT, HBWTRANSIT, HBOAUTO, HBONMOT, HBOTRANSIT, NHBAUTO, NHBNMOT, NHBTRANSIT 
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

;Fill matrices to condense into rows
FILLMW MW[100] = MI.1.7       ;HBW Auto matrix
FILLMW MW[110] = MI.1.10      ;HBW NMOT matrix
FILLMW MW[120] = MI.1.13      ;HBW Transit matrix
FILLMW MW[200] = MI.1.8      ;HBO Auto matrix
FILLMW MW[210] = MI.1.11      ;HBO NMOT matrix
FILLMW MW[220] = MI.1.14      ;HBO Transit matrix
FILLMW MW[300] = MI.1.9      ;NHB Auto matrix
FILLMW MW[310] = MI.1.12      ;NHB NMOT matrix
FILLMW MW[320] = MI.1.15    ;NHB Transit matrix

;Making columns filled with zeros
HBWAUTO = 0
HBWNMOT = 0
HBWTRANSIT = 0
HBOAUTO = 0
HBONMOT = 0
HBOTRANSIT = 0
NHBAUTO = 0
NHBNMOT = 0
NHBTRANSIT = 0

JLOOP
;filling columns with data from the above matrices
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

WRITE RECO = 1

ENDRUN


; Script for program HIGHWAY in file "C:\PROJECTS\USTM_RESILIENCY\CUBE\01HWY00A.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_LOADED_NETWORK.PRN" MSG='Congested Network'
;FILEO MATO[1] = "{SCENARIO_DIR}\Outputs\sl_assignmentvolumes.mat",
;MO=7-11, NAME=SL_HBW, SL_HBO, SL_NHB, SL_Freight, SL_XXPass
FILEI MATI[3] = "{CATALOG_DIR}\Inputs\USTM_Passenger_XX.mtx"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\LH_Truck.mtx"
FILEO NETO = "{SCENARIO_DIR}\Output\loaded_network.NET"
FILEI NETI = "{SCENARIO_DIR}\scenario_network.NET"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJK.MAT"

;Set run PARAMETERS and Controls
PARAMETERS MAXITERS=100, COMBINE=EQUI, RELATIVEGAP = 0.00001

PHASE=LINKREAD

   T0 = 60* (LI.DISTANCE/LI.FF_SPD)
   C  = LI.AM_CAP
   LW.COSTa = T0 + 0.25*LI.DISTANCE
 
; Group facility types
  IF(LI.FT=1)    LINKCLASS=1 ; Freeway
  IF(LI.FT=2)    LINKCLASS=2 ; Ramp
  IF(LI.FT=3)    LINKCLASS=3 ; Expressway
  IF(LI.FT=4)    LINKCLASS=4 ; Arterial
  IF(LI.FT=5)    LINKCLASS=5 ; Local & Connectors
  IF(LI.FT=6)    LINKCLASS=6 ; Managed Freeway
   
ENDPHASE

PHASE=ILOOP
  ; HBW PA to OD
  HBW_ToD = 0.2746
  HBW_Dir = 0.9301
  MW[1] = MI.1.7 * HBW_ToD * HBW_Dir
  
  ; HBO
  HBO_ToD = 0.0755
  HBO_Dir = 0.7847
  MW[2] = MI.1.8 * HBO_ToD * HBO_Dir
  
  ; NHB
  NHB_ToD = 0.0641
  NHB_Dir = 0.5000
  MW[3] = MI.1.9 * NHB_ToD * NHB_Dir
  
  ; Freight, PCE_HV AM
  FREIGHT_ToD = 0.1590
  PCE_HV = 2.0
  MW[4] = MI.2.1 * PCE_HV * FREIGHT_ToD
  
  ; External Passenger AM
  XXP_ToD = 0.1236
  MW[5] = (MI.3.1 + (MI.3.3*PCE_HV) + MI.3.4 + MI.3.5) * XXP_ToD   ;XXPass_MD + PassBUS * PCE + PassOTH + PassREC
  
  ; Count Daily OD Trips
  MW[6] = MW[1] + MW[2] + MW[3] + MW[4] + MW[5]
 
  ; Assign trips 
  PATHLOAD PATH=LW.COSTa, VOL[1] = MW[6]

                                                                         
ENDPHASE


PHASE=ADJUST

function {
    V=VOL[1] 
  
    TC[1] = Min(T0 * (1 + 0.6*(V/C)^8), T0*100)    ; Freeway        
    TC[2] = Min(T0 * (1 + 0.7*(V/C)^3), T0*100)    ; Ramp         
    TC[3] = Min(T0 * (1 + 0.6*(V/C)^6), T0*100)    ; Expressway   
    TC[4] = Min(T0 * (1 + 0.6*(V/C)^4), T0*100)    ; Arterial
    TC[5] = Min(T0 * (1 + 0.7*(V/C)^3), T0*100)    ; Local & Connectors
    TC[6] = Min(T0 * (1 + 0.6*(V/C)^8), T0*100)    ; Managed Freeway
    
   
    }

  LW.COSTa=TIME + 0.25*LI.DISTANCE
  
ENDPHASE

ENDRUN


; Script for program HIGHWAY in file "C:\PROJECTS\USTM_RESILIENCY\CUBE\01HWY00B.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT",
  MO = 1-2, DEC = D, NAME = TIME, DISTANCE
FILEI NETI = "{SCENARIO_DIR}\Output\loaded_network.NET"

PROCESS PHASE=LINKREAD

 TIME_1 = 1
 T0=LI.TIME_1

ENDPROCESS

PROCESS PHASE=ILOOP


; skim network for time and distance
  PATHLOAD PATH=TIME,MW[1]=PATHTRACE(TIME),MW[2]=PATHTRACE(LI.DISTANCE)
  MW[1][I] = rowmin(1) * 0.5 ; Intrazonal time is half of the time to the nearest zone.
  MW[2][I] = 0                ; Set Intrazonal Dist = 0

  ; Total Impedance including terminal times
  MW[3] = MW[1]+MW[2]
   
ENDPROCESS

ENDRUN


ENDLOOP

; Script for program MATRIX in file "C:\projects\ustm_resiliency\CUBE\01_FREIGHT.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\{SCENARIO_DIR}\intermediate_outputs\resi0021.PRN" MSG='Compute Costs'
FILEI MATI[1] = "C:\projects\ustm_resiliency\Base\Output\01_LOADED_HIGHWAY_SKIMS.MAT"
FILEI MATI[6] = "{SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT"
FILEI MATI[4] = "C:\projects\ustm_resiliency\Base\intermediate_outputs\01_TRIPS_IJK.MAT"
FILEO MATO[2] = "{SCENARIO_DIR}\Output\01_COMBINED_TRIPS.MAT",
  MO = 1, 901, 3,5,6,7,4,8,9 DEC = D, NAME = Freight, Pass, REC, HBW, HBO, NHB, ITime, BTime, TDiff
FILEO PRINTO[1] = "{SCENARIO_DIR}\logs\freight_cost.txt"
FILEI MATI[5] = "{CATALOG_DIR}\Inputs\OD_rec_DY.mat"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT",
  MO = 103,203,303,403,503,603,803,903,9, DEC = D, NAME = IIF, XXF, IXF, HBW, HBO, NHB, REC, XXP, Timediff
FILEI MATI[3] = "{CATALOG_DIR}\Inputs\USTM_Passenger_XX.mtx"
FILEI MATI[2] = "{CATALOG_DIR}\Inputs\LH_Truck.mtx"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

;Fill matrices
  MW[1]=MI.2.1 ;Total Freight
  MW[20]=MI.3.2 ;XXPassenger
  MW[21]=MI.3.3 ;XXBus
  MW[22]=MI.3.4 ;XXREC
  MW[23]=MI.3.5 ;XXOther
  MW[3]=MI.5.1 ;REC Trips
  MW[4]=MI.1.1 ;Initial Time Skim
  MW[5]=MI.4.7 ;HBW Trips from Base
  MW[6]=MI.4.8 ;HBO Trips from Base
  MW[7]=MI.4.9 ;NHB Trips from Base
  MW[8]=MI.6.1 ;Broken Time Skim
  
;Compute travel time diff
  MW[9] = MW[8] - MW[4]
  
 ;Compute all freight
   MW[80] = ((MW[1]) * (MW[9])) * 156.73 ; vehicles/day * minutes * cents = cents/day
   MW[90] = MW[9] * 29.45 ; Minutes * cents/min = cents
    
   MW[300] = 0 ;XXF
   MW[100] = 0 ;IIF
   MW[200] = 0 ;XIF & IXF
  JLOOP
   IF (I<28 && J<28) ;referencing only external zones
    MW[200] = 1
   ELSEIF (I<28 | J<28) ;referencing external zones in I or J
    MW[300] = 1
   ELSE ;referencing all zones
    MW[100] = 1
   ENDIF
  ENDJLOOP
     
   MW[103] = MW[80] * MW[100] ;IIF
   MW[203] = MW[80] * MW[200] ;XXF
   MW[303] = MW[80] * MW[300] ;IXF
   
   ;HBW
   MW[403] = MW[5] * MW[90] ;vehicles * cents = total cents per day
   ;HBO
   MW[503] = MW[6] * MW[90] ;vehicles * cents = total cents per day
   ;NHB
   MW[603] = MW[7] * MW[90] ;vehicles * cents = total cents per day
   ;REC
   MW[803] = MW[3] * MW[90] ;vehicles * cents = total cents per day

   ;XXPassenger
   MW[901] = MW[20] + MW[21] + MW[22] + MW[23]
   MW[903] = MW[901] * MW[90] 
   


; Report coefficient values to summary file and debug file;
    JLOOP
		 ;Debug destination choice
	  IF({DebugDC} = 1 && I = {SelOrigin} && J = {SelDest}) 
      PRINT PRINTO=1 CSV=F LIST ='FREIGHTCOST TRACE','\n\n'
	  	PRINT PRINTO=1 CSV=F LIST =' FREIGHTCOST \n\nSelected Interchange for Tracing:    ',{SelOrigin}(4.0),'-',{SelDest}(4.0),'\n'  	      
	  	PRINT PRINTO=1 CSV=F LIST ='\n IIFreight                                 ', MW[100] 
      PRINT PRINTO=1 CSV=F LIST ='\n IXXIFreight                               ', MW[200] 
      PRINT PRINTO=1 CSV=F LIST ='\n XXFreight                                 ', MW[300]
      PRINT PRINTO=1 CSV=F LIST ='\n XXPassenger                               ', MW[903]
      PRINT PRINTO=1 CSV=F LIST ='\n HBW Values                                ', MW[403]
      PRINT PRINTO=1 CSV=F LIST ='\n HBO Values                                ', MW[503]
      PRINT PRINTO=1 CSV=F LIST ='\n NHB Values                                ', MW[603]
		  PRINT PRINTO=1 CSV=F LIST ='\n REC Values                                ', MW[803]  

   ENDIF
     
 ENDJLOOP


ENDRUN


; Script for program MATRIX in file "C:\PROJECTS\USTM_RESILIENCY\CUBE\01MAT00S.S"
;;<<GENERATED SCRIPT>><<MATRIX>><<Matrix>><<Conversion>>;;
;>>>
;>>>
;;>>>
;Input Matrix File 1:{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT
;Output CSV File:C:\projects\ustm_resiliency\Base\road38\Output\01_TRAVELTIME_COSTS.CSV
;**********************************************************************
;THIS SCRIPT READS A MAT FILE, CREATE TWO MATRICS IN CSV AND DBF      *  
;**********************************************************************
; BY CITILABS
;
;;<<End Parameters>>;;


; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Travel Times as CSV'

FILEI MATI[1] = "{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT"

FILEO MATO[1] = "C:\projects\ustm_resiliency\Base\road38\Output\01_TRAVELTIME_COSTS.CSV",
MO=1-9, FORMAT = CSV, PATTERN = IJM:V

MW[1]=mi.1.1
MW[2]=mi.1.2
MW[3]=mi.1.3
MW[4]=mi.1.4
MW[5]=mi.1.5
MW[6]=mi.1.6
MW[7]=mi.1.7
MW[8]=mi.1.8
MW[9]=mi.1.9

ENDRUN


