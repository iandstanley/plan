*================================================================*
      * COPYBOOK: TODOCOMM - KICKS DFHCOMMAREA STATE CONTRACT (64 B)   *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / KICKS + IKFCBL00)      *
      *================================================================*
           05  CA-PROCESS-STAGE        PIC X(01).
               88  CA-STAGE-BROWSE         VALUE '1'.
               88  CA-STAGE-DETAIL         VALUE '2'.
               88  CA-STAGE-SETTINGS       VALUE '3'.
           05  CA-DETAIL-MODE          PIC X(01).
               88  CA-MODE-ADD             VALUE 'A'.
               88  CA-MODE-EDIT            VALUE 'E'.
           05  CA-FILTER-MODE          PIC X(01).
               88  CA-FILTER-ACTIVE        VALUE 'O'.
               88  CA-FILTER-WAIT          VALUE 'W'.
               88  CA-FILTER-ALL           VALUE 'A'.
           05  CA-VIEW-OWNER           PIC X(08).
           05  CA-SELECTED-TASK-ID     PIC 9(08).
           05  CA-PAGE-TOP-KEY.
               10  CA-TOP-OWNER        PIC X(08).
               10  CA-TOP-DUE-DATE     PIC 9(08).
               10  CA-TOP-PRIORITY     PIC 9(01).
               10  CA-TOP-TASK-ID      PIC 9(08).
           05  CA-SAVED-REC-VERSION    PIC S9(04) COMP SYNC.
           05  CA-FILLER               PIC X(18).