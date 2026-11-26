*================================================================*
      * COPYBOOK: TODOLLNK - LINKAGE CONTRACT FOR TODOLOCK (20 BYTES)  *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  LLNK-ACTION                 PIC X(04).
               88  LLNK-LOCK-EXCL              VALUE 'ENQ '.
               88  LLNK-UNLOCK                 VALUE 'DEQ '.
           05  LLNK-RNAME                  PIC X(08).
           05  LLNK-RC                     PIC S9(04) COMP SYNC.
               88  LLNK-OK                     VALUE +0.
               88  LLNK-BAD-FUNC               VALUE +8.
               88  LLNK-SYS-ERR                VALUE +16.
           05  LLNK-FILLER                 PIC X(06).
		   