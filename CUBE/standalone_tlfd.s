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

  ;fill initial matrices with trip_ij by purpose, and distance
MW[1]=MI.1.6 ;HBW
MW[2]=MI.2.2 ;Distance

;MW[3]=MI.1.7 ;HBO
;MW[4]=MI.1.8 ;NHB
;MW[5]=MI.1.9 ;HBC
;MW[6]=MI.1.10 ;REC

;set value equal to maximum number of groups, MVG, ustm uses 25
gps={MVG}-1

;assign trip length arrays (trip length 1 = tl1)
array tl1={MVG}
;array tl2=26
;array tl3=26
;array tl4=26
;array tl5=26

;create header for csv file
IF (i = 1)
  print printo = 2 CSV = TRUE, list = "DISTBIN", "HBW", "HBO", "NHB", "HBC", "REC"
ENDIF

;create distance bins with {intv} as the divisor (i.e. increments of 5 miles etc.), ustm uses 5 mile increments
jloop
  ;group = min(max(round(mw[2]),1),{MVG})
  group = min(INT(mw[2]/{intv}),gps) + 1
  ;group1 = min(INT(mw[2]/5),gps) + 1
  ;group2 = min(INT(mw[2]/5),gps) + 1
  ;group3 = min(INT(mw[2]/5),gps) + 1
  ;group4 = min(INT(mw[2]/5),gps) + 1

 ;fill group arrays with group + trip purpose matrix values
  tl1[group]=tl1[group]+mw[1]
  ;tl2[group]=tl2[group]+mw[3]
  ;tl3[group]=tl3[group]+mw[4]
  ;tl4[group]=tl4[group]+mw[5]
  ;tl5[group]=tl5[group]+mw[6]
endjloop

if (i=zones)
  LOOP group=1,100 ;{MVG}
   ro.DISTANCE=group
   ro.HBW=tl1[group]
   ;ro.HBO=tl2[group]
   ;ro.NHB=tl3[group]
   ;ro.HBC=tl4[group]
   ;ro.REC=tl5[group]
   WRITE RECO = 1
   print printo=1 list=ro.DISTANCE(6.0), ro.HBW(16.8);,ro.HBO(16.8),ro.NHB(16.8),ro.HBC(16.8),ro.REC(16.8)
   print printo=2 CSV = TRUE list = ro.DISTANCE(6.0), ro.HBW(16.8);,ro.HBO(16.8),ro.NHB(16.8),ro.HBC(16.8),ro.REC(16.8)
  endloop
endif


FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-{intv},
TITLE='** HBW **'
;FREQUENCY BASEMW=2 VALUEMW=3 RANGE=0-1000-10,
;TITLE='** HBO **'
;FREQUENCY BASEMW=2 VALUEMW=4 RANGE=0-1000-10,
;TITLE='** NHB **'
;FREQUENCY BASEMW=2 VALUEMW=5 RANGE=0-1000-10,
;TITLE='** HBC **'
;FREQUENCY BASEMW=2 VALUEMW=6 RANGE=0-1000-10,
;TITLE='** REC **'

ENDRUN

