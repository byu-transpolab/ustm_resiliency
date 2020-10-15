;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEO MATO[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_DEST_HBC.MAT"
FILEI LOOKUPI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\DESTCHOICE_PARAMETERS.DBF"
FILEI ZDATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\se_classified_2012A.dbf"
FILEI MATI[2] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_HIGHWAY_SKIMS.MAT"
FILEI MATI[1] = "C:\Users\mbarnes7\Documents\Projects\ustm_resiliency\Base\01_MCLS_COMBINED.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

ENDRUN
