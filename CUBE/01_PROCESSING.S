;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX MSG='Process Skims'
FILEO MATO[1] = "{SCENARIO_DIR}\01_PROCESSED_SKIMS.MAT",
  MO=1-2,DEC=12,NAME=TIME,DISTANCE
FILEI MATI[1] = "{SCENARIO_DIR}\01_HIGHWAY_SKIMS.MAT"

; The MATRIX module does not have any explicit phases.  The module does run within an implied ILOOP
; where I is the origin zones.  All user statements in the module are processed once for each origin.
; Matrix computation (MW[#]=) are solved for all values of J for each I.  Thus for a given origin zone I
; the values for all destination zones J are automatically computed.  The user can control the computations
; at each J by using a JLOOP.

FILLMW MW[1]=MI.1.1(2)                ; highway skims

; Reset invalid values to zero
  JLOOP
      IF (MW[1] > 1000)
          MW[1] = 0
      ENDIF

      IF (MW[2] > 1000)
          MW[2] = 0
      ENDIF


      ENDJLOOP

ENDRUN
