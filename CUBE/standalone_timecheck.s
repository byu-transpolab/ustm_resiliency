;   >>>
;  >>>
;>>>
;Input Matrix File: C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\intermediate_outputs\01_TRIPS_IJ.MAT
;Input Matrix File: C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\Output\01_HIGHWAY_SKIMS.MAT
;Output DFB File: C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\Output\test_tlfd.dbf
;Output Print Data File: C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\Output\test_tlfd.log
;Max val group:26
;Time interval in Min:5
;;<<End Parameters>>;;
RUN PGM=MATRIX 
FILEI MATI[1] = "D:\Base\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[2] = "D:\road34\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[3] = "D:\road39\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[4] = "D:\road43\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[5] = "D:\road44\Output\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[6] = "D:\road40\Output\01_HIGHWAY_SKIMS.MAT"

FILEO MATO[1] = "D:\investigation_results\base_34_timediff.MAT",
  MO = 30-39, NAME = Timediff34, timediff39, timediff43, timediff44, timediff40,dist34, dist39, dist43, dist44, dist40, DEC = D

  ;fill initial matrices with trip_ij by purpose, and distance
MW[1]=MI.1.1 ;base
MW[2]=MI.2.1 ;road34
MW[3]=MI.3.1 ;road39
MW[4]=MI.4.1 ;road43
MW[5]=MI.5.1 ;road44
MW[6]=MI.6.1 ;road40

MW[7]=MI.1.2 ;base
MW[8]=MI.2.2 ;road34
MW[9]=MI.3.2 ;road39
MW[10]=MI.4.2 ;road43
MW[11]=MI.5.2 ;road44
MW[12]=MI.6.2 ;road40

;find difference between two matrices
MW[30] = MW[2] - MW[1]
MW[31] = MW[3] - MW[1]
MW[32] = MW[4] - MW[1]
MW[33] = MW[5] - MW[1]
MW[34] = MW[6] - MW[1]

IF (MW[30][J] < -10000) 
  MW[30] = 0 
ENDIF
IF (MW[31][J] < -10000) 
  MW[31] = 0 
ENDIF
IF (MW[32][J] < -10000) 
  MW[32] = 0 
ENDIF
IF (MW[33][J] < -10000) 
  MW[33] = 0 
ENDIF
IF (MW[34][J] < -10000) 
  MW[34] = 0 
ENDIF

;find difference between distances
MW[35] = MW[8] - MW[7]
MW[36] = MW[9] - MW[7]
MW[37] = MW[10] - MW[7]
MW[38] = MW[11] - MW[7]
MW[39] = MW[12] - MW[7]

IF (MW[35][J] < -10000) 
  MW[35] = 0 
ENDIF
IF (MW[36][J] < -10000) 
  MW[36] = 0 
ENDIF
IF (MW[37][J] < -10000) 
  MW[37] = 0 
ENDIF
IF (MW[38][J] < -10000) 
  MW[38] = 0 
ENDIF
IF (MW[39][J] < -10000) 
  MW[39] = 0 
ENDIF

ENDRUN