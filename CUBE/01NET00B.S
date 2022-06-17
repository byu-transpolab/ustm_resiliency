;>>>
;>>> 
;Input  Highway Network File 1: 
;Input  Highway Network File 2: 
;Output Highway Network File:   
;;<<End Parameters>>;;

; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK MSG='Loaded Network Compare - Base to Broken'

FILEI LINKI[2] = "{SCENARIO_DIR}\Output\loaded_network.NET"
FILEI LINKI[1] = "{CATALOG_DIR}\Base\Output\loaded_network.NET"
FILEO NETO = "{SCENARIO_DIR}\Output\network_compare.NET",
     INCLUDE=A B LOAD1 LOAD2 LOADCHG ABSLOADCHG PRCLOADCHG, 
            CSPD1 CSPD2 CSPDCHG ABSCSPDCHG PRCCSPDCHG,
            TIME1 TIME2 TIMECHG ABSTIMECHG PRCTIMECHG,
            VC1 VC2 VCCHG ABSVCCHG PRCVCCHG


   LOAD1=LI.1.V_1

   LOAD2=LI.2.V_1

   LOADCHG=(LOAD2-LOAD1)

   ABSLOADCHG=ABS(LOAD2-LOAD1)

if (load1>0) PRCLOADCHG=LOADCHG/LOAD1

   CSPD1=LI.1.CSPD_1

   CSPD2=LI.2.CSPD_1

   CSPDCHG=(CSPD1-CSPD2)

   ABSCSPDCHG=ABS(CSPD1-CSPD2)

if (CSPD1>0) PRCCSPDCHG=CSPDCHG/CSPD1

   TIME1=LI.1.TIME_1

   TIME2=LI.2.TIME_1

   TIMECHG=(TIME1-TIME2)

   ABSTIMECHG=ABS(TIME1-TIME2)

if (TIME1>0) PRCTIMECHG=TIMECHG/TIME1

   VC1=LI.1.VC_1

   VC2=LI.2.VC_1

   VCCHG=(VC1-VC2)

   ABSVCCHG=ABS(VC1-VC2)

if (VC1>0) PRCVCCHG=VCCHG/VC1


ENDRUN
