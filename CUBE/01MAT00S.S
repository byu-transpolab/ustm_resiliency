;;<<PROCESS TEMPLATE>><<MATRIX>><<Matrix>><<Conversion>>;;
;{Title,note,12,"Convert a Binary Matrix File to DBF and CSV Files"}>>>
;{Description,note,10,"The script will convert a single Voyager table to CSV and DBF format"}>>>
;;{Example,note,8,"Example?"}>>>
;Input Matrix File 1:{mati1,filename,"Enter Input Matrix File Name",x,"{SCENARIO_DIR}\Output\01_TRAVELTIME_COSTS.MAT","Matrix File (*.mat)|*.mat"}
;Output CSV File:{mato1,filename,"Enter Output CSV File Name",x,"C:\projects\ustm_resiliency\Base\road38\Output\01_TRAVELTIME_COSTS.CSV","CSV File (*.csv)|*.csv"}
;**********************************************************************
;THIS SCRIPT READS A MAT FILE, CREATE TWO MATRICS IN CSV AND DBF      *  
;**********************************************************************
; BY CITILABS
;
;;<<End Parameters>>;;


; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Travel Times as CSV'

FILEI MATI[1] = {MATI1.Q}

FILEO MATO[1] = {MATO1.Q},
MO=1-9, FORMAT = CSV, PATTERN = IJM:V

MW[1]=mi.1.1
MW[2]=mi.1.2
MW[3]=mi.1.3
MW[4]=mi.1.4
MW[5]=mi.1.5
MW[6]=mi.1.6
MW[7]=mi.1.7
MW[8]=mi.1.8
MW[9]=mi.1.9

ENDRUN
