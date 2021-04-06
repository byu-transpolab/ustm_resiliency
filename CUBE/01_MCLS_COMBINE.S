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
