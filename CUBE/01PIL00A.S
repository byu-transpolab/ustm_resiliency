; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.

IF (FeedBack_ITER=1) 
FB_ITER = 1
*COPY  {SCENARIO_DIR}\Output\01_ROWSUMS.DBF  {SCENARIO_DIR}\nonloaded_results\01_ROWSUMS.DBF 
*COPY  {SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT  {SCENARIO_DIR}\nonloaded_results\01_HIGHWAY_SKIMS.MAT

*IF EXIST DEL {SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT
*COPY  {SCENARIO_DIR}\Output\01_LOADED_HIGHWAY_SKIMS.MAT  {SCENARIO_DIR}\Output\01_HIGHWAY_SKIMS.MAT

ENDIF
