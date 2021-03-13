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
FILEO PRINTO[1] = "C:\projects\ustm_resiliency\Base\Output\tlfd.log"
FILEO PRINTO[2] = "C:\projects\ustm_resiliency\Base\Output\tlfd.csv"
FILEI MATI[1] = "C:\projects\ustm_resiliency\Base\intermediate_outputs\01_TRIPS_IJ.MAT"
FILEI MATI[2] = "C:\projects\ustm_resiliency\Base\Output\01_HIGHWAY_SKIMS.MAT"
FILEO RECO[1] = "C:\projects\ustm_resiliency\Base\Output\test_tlfd.dbf",
  FIELDS= time, HBW(16.8), HBO(16.8), NHB(16.8), HBC(16.8), REC(16.8)

MW[1]=MI.1.6 ;HBW
MW[2]=MI.2.2 ;Distance
MW[3]=MI.1.7 ;HBO
MW[4]=MI.1.8 ;NHB
MW[5]=MI.1.9 ;HBC
MW[6]=MI.1.10 ;REC

gps=25-1

array tll=25
array tl2=25
array tl3=25
array tl4=25
array tl5=25

IF (i = 1)
  print printo = 2 CSV = TRUE, list = "DISTBIN", "HBW", "HBO", "NHB", "HBC", "REC"
ENDIF

jloop
  ;group = min(max(round(mw[2]),1),26)
  group = min(INT(mw[2]/5),gps) + 1
  group1 = min(INT(mw[2]/5),gps) + 1
  group2 = min(INT(mw[2]/5),gps) + 1
  group3 = min(INT(mw[2]/5),gps) + 1
  group4 = min(INT(mw[2]/5),gps) + 1

  tll[group]=tll[group]+mw[1]
  tl2[group]=tl2[group]+mw[3]
  tl3[group]=tl3[group]+mw[4]
  tl4[group]=tl4[group]+mw[5]
  tl5[group]=tl5[group]+mw[6]
endjloop

if (i=zones)
  LOOP group=1,100
   ro.DISTANCE=group
   ro.HBW=tll[group];+MW[1]
   ro.HBO=tl2[group];+MW[3]
   ro.NHB=tl3[group];+MW[4]
   ro.HBC=tl4[group];+MW[5]
   ro.REC=tl5[group];+MW[6]
   print printo=1 list=ro.DISTANCE(6.0), ro.HBW(16.8),ro.HBO(16.8),ro.NHB(16.8),ro.HBC(16.8),ro.REC(16.8)
   print printo=2 CSV = TRUE list = ro.DISTANCE(6.0), ro.HBW(16.8),ro.HBO(16.8),ro.NHB(16.8),ro.HBC(16.8),ro.REC(16.8)
  endloop
endif


FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-5   


ENDRUN

