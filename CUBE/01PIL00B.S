; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.

*COPY  {SCENARIO_DIR}\Output\01_ROWSUMS.DBF  {SCENARIO_DIR}\{SA_ITER}\01_ROWSUMS.DBF 
*COPY  {CATALOG_DIR}\param\{SA_ITER}\MC_Coefficients.csv  {SCENARIO_DIR}\params\MC_Coefficients.csv 
*COPY  {CATALOG_DIR}\param\{SA_ITER}\DC_PARAM.csv  {SCENARIO_DIR}\params\DC_PARAM.csv 

{SA_ITER} = FB_ITER + 1
