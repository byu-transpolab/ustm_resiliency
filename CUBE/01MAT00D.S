; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="D:\projects\ustm_resiliency\CUBE\mcls.PRN" MSG='Calculate Mode Choice Logsums'
FILEI MATI[1] = "{SCENARIO_DIR}\Output\matrix1.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\PK_Transit.MAT"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\MC_Coefficients.csv"
FILEI LOOKUPI[2] = "{SCENARIO_DIR}\MC_Constants.csv"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\mcls.MAT"
FILEO MATO[2] = "{SCENARIO_DIR}\Output\mcutil.MAT"
FILEO MATO[3] = "{SCENARIO_DIR}\Output\mcprob.MAT"
ENDRUN
