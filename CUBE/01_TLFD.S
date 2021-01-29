;;<<PROCESS TEMPLATE>><<MATRIX>><<Matrix>><<Summary>>;;
;{note1,note,12,"Create Trip Length Frequency report"}   >>>
;{note2,note,10,"The script will generate a DBF file with records containing the total number of trips (from matrix 1)"}  >>>
;{note3,note,10,"summarised accordingly to the costs from matrix 2"}>>>
;Input Matrix File: {mati1,filename,"Enter Input Trip Matrix",x,"{CATALOG_DIR}\CUBE\01_TRIPS_IJ.MAT","Trip Matrix (*.mat)|*.mat"}
;Input Matrix File: {mati2,filename,"Enter Input Cost Matrix",x,"{CATALOG_DIR}\Base\Auto_Skim.mtx","Cost Matrix (*.mat)|*.mat"}
;Output DFB File: {reco1,filename,"Enter Output DBF File",x,"{CATALOG_DIR}\Base\01_TLFD_HBW.DBF","DBase File (*.dbf)|*.dbf"}
;Output Print Data File: {printo1,filename,"Enter Output PRINTO Data File 1",x,"C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_TLFD.PRN","PRINTO File (*.prn)|*.prn"}
;Max val group:{MVG,editbox,"Maximum Number of Groups",N,"10"}
;Time interval in Min:{intv,editbox,"time interval in min",N,"5"}
;;<<End Parameters>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{CATALOG_DIR}\Base\01_TLFD.PRN" MSG='Create TLFD'
FILEO PRINTO[1] = {PRINTO1.Q}
FILEI MATI[1] = {MATI1.Q}
FILEI MATI[2] = {MATI2.Q}
FILEO RECO[1] = {RECO1.Q},
   FIELDS= time, TRIPS(16.8)

MW[1]=MI.1.6
MW[2]=MI.2.4

gps=25-1

array tl1=25

jloop
;group = min(max(round(mw[2]),1),25)
group = min(INT(mw[2]/5),gps) + 1
tl1[group]=tl1[group]+mw[1]

endjloop

if (i=zones)
  loop group=1,100
   ro.time=group
   ro.TRIPS=tl1[group]
   write reco=1
   print printo=1 list=ro.time(6.0), ro.trips(16.8)
  endloop
endif


FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-5   

ENDRUN
