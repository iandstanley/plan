*================================================================*
      * COPYBOOK: TODOREC  - MASTER TASK VSAM KSDS RECORD (332 BYTES)  *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  TODO-PRIMARY-KEY.
               10  TODO-OWNER-ID           PIC X(08).
               10  TODO-TASK-ID            PIC 9(08).
           05  TODO-ALT-KEY.
               10  TODO-ALT-OWNER-ID       PIC X(08).
               10  TODO-ALT-DUE-DATE       PIC 9(08).
               10  TODO-ALT-PRIORITY       PIC 9(01).
           05  TODO-DATA.
               10  TODO-TITLE              PIC X(60).
               10  TODO-CATEGORY           PIC X(10).
               10  TODO-STATUS             PIC X(01).
                   88  TODO-STAT-OPEN          VALUE 'O'.
                   88  TODO-STAT-INPROG        VALUE 'I'.
                   88  TODO-STAT-WAITING       VALUE 'W'.
                   88  TODO-STAT-DONE          VALUE 'C'.
                   88  TODO-STAT-CANCEL        VALUE 'X'.
                   88  TODO-IS-ACTIVE          VALUE 'O' 'I' 'W'.
                   88  TODO-IS-CLOSED          VALUE 'C' 'X'.
                   88  VALID-TODO-STATUS       VALUE 'O' 'I' 'W' 'C' 'X'.
               10  TODO-PRIORITY           PIC 9(01).
                   88  TODO-PRI-URGENT         VALUE 1.
                   88  TODO-PRI-HIGH           VALUE 2.
                   88  TODO-PRI-NORMAL         VALUE 3.
                   88  TODO-PRI-LOW            VALUE 4.
                   88  TODO-PRI-DEFER          VALUE 5.
                   88  VALID-TODO-PRIORITY     VALUE 1 THRU 5.
               10  TODO-DUE-DATE           PIC 9(08).
                   88  TODO-NO-DUE-DATE        VALUE ZERO.
               10  TODO-CREATED-DATE       PIC 9(08).
               10  TODO-CREATED-BY         PIC X(08).
               10  TODO-DONE-DATE          PIC 9(08).
                   88  TODO-NO-DONE-DATE       VALUE ZERO.
               10  TODO-NOTES-BLOCK.
                   15  TODO-NOTE-LINE-1    PIC X(60).
                   15  TODO-NOTE-LINE-2    PIC X(60).
                   15  TODO-NOTE-LINE-3    PIC X(60).
           05  TODO-CONTROL.
               10  TODO-REC-VERSION        PIC S9(04) COMP SYNC.
               10  TODO-FILLER             PIC X(13).