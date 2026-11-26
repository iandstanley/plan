*================================================================*
      * COPYBOOK: TODOCTRL - USER CONTROL & PREFERENCES (64 BYTES)     *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  CTRL-KEY.
               10  CTRL-USER-ID            PIC X(08).
           05  CTRL-DATA.
               10  CTRL-LAST-TASK-ID       PIC 9(08).
               10  CTRL-DAILY-PRINT-SW     PIC X(01).
                   88  CTRL-PRINT-YES          VALUE 'Y'.
                   88  CTRL-PRINT-NO           VALUE 'N'.
                   88  VALID-CTRL-PRINT-SW     VALUE 'Y' 'N'.
               10  CTRL-DEFAULT-PRI        PIC 9(01).
                   88  VALID-CTRL-PRI          VALUE 1 THRU 5.
               10  CTRL-USER-NAME          PIC X(24).
               10  CTRL-ACTIVE-COUNT       PIC S9(04) COMP SYNC.
               10  CTRL-LAST-LOGIN-DATE    PIC 9(08).
               10  CTRL-FILLER             PIC X(12).