;;<<PROCESS TEMPLATE>><<MATRIX>><<Matrix>><<Conversion>>;;
;{Title,note,12,"Create Binary Matrix Table from CSV File"}>>>
;{Description,note,10,"The script will generate a single table starting from a I,J,V file"}>>>
;Input Matrix File 1:{mati1,filename,"Enter Input CSV File",x,"{CATALOG_DIR}\Inputs\USTM_transit_skim1.csv","CSV File (*.csv)|*.csv"}
;Output Matrix File:{mato,filename,"Enter Output Matrix File Name",x,"{CATALOG_DIR}\Base\Output\01_USTM_TRANSIT_SKIM.MAT","Matrix File (*.mat)|*.mat"}
;Maximum Zone number:{zones,editbox,"Enter Maximum Number of Zones",N,"8775"}
;**********************************************************************
;THIS SCRIPT READS A CSV MATRIX FILE, CREATE A MATRIX WITH THE RESULT *  
;**********************************************************************
; BY CITILABS
;
;;<<End Parameters>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Build Pk Transit Matrix'

FILEI MATI[1] = {MATI1.Q},
    PATTERN=IJM:V FIELDS=#1,2,3,4

FILEO MATO[1] = {MATO.Q},
 MO=1 NAME=TRANSIT_TIME

ZONES={TOTAL_ZONES}

MW[1]=MI.1.1


ENDRUN
