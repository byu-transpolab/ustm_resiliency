; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY MSG='Whole Network'
FILEI NETI = "{SCENARIO_DIR}\highway.net"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\skims.mat"
ENDRUN
