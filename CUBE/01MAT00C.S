; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="{SCENARIO_DIR}\dcls.prn" MSG='Calculate Destination Choice Logsums'
FILEI MATI[1] = "{SCENARIO_DIR}\Output\mcls.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\skims.mat"
FILEI ZDATI[1] = "{SCENARIO_DIR}\Output\HH_PROD.DBF"
FILEI ZDATI[2] = "{SCENARIO_DIR}\Output\se_classified_2012A.dbf"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\DESTCHOICE_PARAMETERS.DBF"
FILEO MATO[1] = "{SCENARIO_DIR}\output\DEST_HBW.mat"
FILEO RECO[1] = "D:\projects\ustm_resiliency\Base\Output\DCLS_ROWSUM.dbf"
FILEO PRINTO[1] = "{SCENARIO_DIR}\Output\DESTCHOICE_DEBUG.RPT"
FILEO PRINTO[2] = "{SCENARIO_DIR}\Output\DESTCHOICE_DEBUG.txt"
FILEO PRINTO[3] = "{SCENARIO_DIR}\Output\HBW_Zonal_Trips.csv"
ENDRUN
