; Script for program MATRIX in file "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\CUBE\01_TLFD.S"
;Input Matrix File: {mati2,filename,"Enter Input Cost Matrix",x,"{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT","Cost Matrix (*.mat)|*.mat"}
;Output DFB File: {reco1,filename,"Enter Output DBF File",x,"{SCENARIO_DIR}\intermediate_outputs\01_TLFD_HBW.DBF","DBase File (*.dbf)|*.dbf"}
;Output Print Data File: {printo1,filename,"Enter Output PRINTO Data File 1",x,"C:\USERS\MBARNES7\DOCUMENTS\PROJECTS\USTM_RESILIENCY\BASE\01_TLFD.PRN","PRINTO File (*.prn)|*.prn"}
;Max val group:{MVG,editbox,"Maximum Number of Groups",N,"10"}
;Time interval in Min:{intv,editbox,"time interval in min",N,"5"}
;;<<End Parameters>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_TLFD.PRN" MSG='Create TLFD'
FILEO PRINTO[2] = "{SCENARIO_DIR}\intermediate_outputs\01_TLFD.CSV"
FILEO PRINTO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TLFD.PRN"
FILEI MATI[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT"
FILEO RECO[1] = "{SCENARIO_DIR}\intermediate_outputs\01_TLFD.DBF",
   FIELDS= DISTANCE, HBW, HBO, NHB, HBC, REC

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

zones = 8775

;first group
JLOOP
;group = min(max(round(mw[2]),1),25)
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

ENDJLOOP

IF (i= zones)
  LOOP group=1,100
   ro.DISTANCE=group
   ro.HBW=tll[group];+MW[1]
   ro.HBO=tl2[group];+MW[3]
   ro.NHB=tl3[group];+MW[4]
   ro.HBC=tl4[group];+MW[5]
   ro.REC=tl5[group];+MW[6]
   write reco=1
   print printo=1 list=ro.DISTANCE(6.0), ro.HBW(16.8), ro.HBO(16.8), ro.NHB(16.8), ro.HBC(16.8). ro.REC(16.8)
  ENDLOOP
ENDIF

FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-5   

;DISTANCE=ro.DISTANCE
;HBW=ro.HBW
;HBO=ro.HBO
;NHB=ro.NHB
;HBC=ro.HBC
;REC=ro.REC

;write a header file for tlfd counts
IF (I=1) 
print CSV=T,list='Distance','HBW','HBO','NHB','HBC','REC' printo=2

;write out counts
print CSV=T list=DISTANCE(6.0),HBW(16.8),HBO(16.8),NHB(16.8),HBC(16.8),REC(16.8), printo=2

ENDIF

PRINT CSV = T LIST=ro.DISTANCE(1), ro.REC(16.8), tl2(16.8), tl3(16.8), tl4(16.8), tl5(16.8), printo=2

;PRINT FORM = 10.10, CSV = T, LIST = Z, P[6], p1v0, p1v1, p1v2, p1v3, p2v0,
  ;p2v1, p2v2, p2v3, p3v0, p3v1, p3v2, p3v3, p4v0, p4v1, p4v2, p4v3, all,
  ;PRINTO = 1

ENDRUN


