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
