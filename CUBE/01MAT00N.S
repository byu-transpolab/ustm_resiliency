;;<<PROCESS TEMPLATE>><<MATRIX>><<Matrix>><<Summary>>;;
;{note1,note,12,"Create Trip Length Frequency report"}   >>>
;{note2,note,10,"The script will generate a DBF file with records containing the total number of trips (from matrix 1)"}  >>>
;{note3,note,10,"summarised accordingly to the costs from matrix 2"}>>>
;Input Matrix File: {mati1,filename,"Enter Input Trip Matrix",x,"{SCENARIO_DIR}\intermediate_outputs\01_TRIPS_IJ.MAT","Trip Matrix (*.mat)|*.mat"}
;Input Matrix File: {mati2,filename,"Enter Input Cost Matrix",x,"{SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT","Cost Matrix (*.mat)|*.mat"}
;Output DFB File: {reco1,filename,"Enter Output DBF File",x,"{SCENARIO_DIR}\intermediate_outputs\01_TLFD_HBW.DBF","DBase File (*.dbf)|*.dbf"}
;Output Print Data File: {printo1,filename,"Enter Output PRINTO Data File 1",x,"C:\USERS\MBARNES7\DOCUMENTS\PROJECTS\USTM_RESILIENCY\BASE\01_TLFD.PRN","PRINTO File (*.prn)|*.prn"}
;Max val group:{MVG,editbox,"Maximum Number of Groups",N,"10"}
;Time interval in Min:{intv,editbox,"time interval in min",N,"5"}
;;<<End Parameters>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\intermediate_outputs\01_TLFD.PRN" MSG='Create TLFD'
FILEO PRINTO[1] = {PRINTO1.Q}
FILEI MATI[1] = {MATI1.Q}
FILEI MATI[2] = {MATI2.Q}
FILEO RECO[1] = {RECO1.Q},
   FIELDS= DISTANCE, HBW(16.8), HBW(16.8)

MW[1]=MI.1.6 ;HBW
MW[2]=MI.2.2 ;Distance
MW[3]=MI.1.7 ;HBO
MW[4]=MI.1.8 ;NHB
MW[5]=MI.1.9 ;HBC
MW[6]=MI.1.10 ;REC

gps=25-1

array tl1=25
ARRAY TT2=25
ARRAY TT3=25
ARRAY TT4=25
ARRAY TT5=25

zones = 8775

;first group
JLOOP
;group = min(max(round(mw[2]),1),25)
group = min(INT(mw[2]/5),gps) + 1
tl1[group]=tl1[group]+mw[1]
tt2[group]=tt2[group]+mw[3]
tt3[group]=tt3[group]+mw[4]
tt4[group]=tt4[group]+mw[5]
tt5[group]=tt5[group]+mw[6]

ENDJLOOP

IF (i= zones)
  LOOP group=1,100
   ro.DISTANCE=group
   ro.hbw=tl1[group]
   ro.hbo=tt2[group]
   ro.nhb=tt3[group]
   ro.hbc=tt4[group]
   ro.rec=tt5[group]
   write reco=1
   print printo=1 list=ro.distance(6.0), ro.hbw(16.8), ro.hbo (16.8), ro.nhb (16.8), ro.hbc (16.8). ro.rec (16.8)
  ENDLOOP
ENDIF


FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-5   

ENDRUN