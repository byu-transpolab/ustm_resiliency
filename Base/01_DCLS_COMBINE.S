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
