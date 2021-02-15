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
