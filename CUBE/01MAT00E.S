; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Process Skims'
FILEI MATI[1] = "{SCENARIO_DIR}\Output\skims.mat"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\matrix1.MAT"
ENDRUN
