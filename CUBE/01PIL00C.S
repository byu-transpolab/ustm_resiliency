; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.

IF (FeedBack_ITER=0) 
*COPY  {SCENARIO_DIR}\Output\01_ROWSUMS.DBF  {SCENARIO_DIR}\nonloaded_results\01_ROWSUMS.DBF 
*COPY  {SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT  {SCENARIO_DIR}\nonloaded_results\01_HIGHWAY_SKIMS.MAT

EXIT
ENDIF
