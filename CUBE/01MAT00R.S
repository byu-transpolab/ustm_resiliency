;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Get whole Productions file'
FILEO RECO[1] = "{CATALOG_DIR}\Inputs\HH_PROD_1.DBF",
  FIELDS = TAZ, HBWP, HBOP, NHBP, RECP
FILEI MATI[1] = "{CATALOG_DIR}\Inputs\IIIXXIXX_LH_Ton_Truck_Utah.MAT"
FILEI ZDATI[1] = "{CATALOG_DIR}\Inputs\HH_PROD.DBF"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

	FILLMW MW[1] = MI.1.13 ;Freight Trips

  FREIGHTAUTO = 0
  
  JLOOP
    TAZ = ZI.1.TAZ
    HBWP = ZI.1.HBW_P
    HBOP = ZI.1.HBO_P + ZI.1.HBSC_PR_P + ZI.1.HBSC_SC_P + ZI.1.HBSHP_P
    NHBP =  ZI.1.NHBW_P + ZI.1.NHBNW_P
    RECP = ZI.1.REC_P
  ENDJLOOP
    Ro.TAZ = TAZ
    Ro.HBWP = HBWP
    Ro.HBOP = HBOP
    Ro.NHBP = NHBP
    Ro.RECP = RECP
    
  
WRITE RECO = 1

  
ENDRUN
