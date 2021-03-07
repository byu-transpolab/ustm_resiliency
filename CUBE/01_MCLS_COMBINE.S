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
FILEO MATO[1] = "{SCENARIO_DIR}\Output\01_MCLS_COMBINED.MAT",
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
