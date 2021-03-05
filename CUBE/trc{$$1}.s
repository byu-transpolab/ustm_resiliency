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


