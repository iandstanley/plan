*================================================================*
      * COPYBOOK: TODOVLNK - LINKAGE CONTRACT FOR TODOVAL (120 BYTES)  *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  VLNK-INPUT.
               10  VLNK-FUNC-CODE          PIC X(04).
                   88  VLNK-CHECK-ALL          VALUE 'ALL '.
                   88  VLNK-CHECK-DATE         VALUE 'DATE'.
                   88  VLNK-CHECK-TASK         VALUE 'TASK'.
               10  VLNK-STATUS             PIC X(01).
               10  VLNK-PRIORITY           PIC 9(01).
               10  VLNK-DATE-FIELD         PIC 9(08).
               10  VLNK-ALLOW-ZERO-DATE    PIC X(01).
                   88  VLNK-ZERO-DATE-OK       VALUE 'Y'.
                   88  VLNK-ZERO-DATE-NO       VALUE 'N'.
               10  VLNK-OWNER-ID           PIC X(08).
               10  VLNK-TITLE              PIC X(60).
           05  VLNK-OUTPUT.
               10  VLNK-VALID-SW           PIC X(01).
                   88  VLNK-IS-VALID           VALUE 'Y'.
                   88  VLNK-HAS-ERROR          VALUE 'N'.
               10  VLNK-ERR-CODE           PIC X(04).
                   88  VLNK-ERR-NONE           VALUE '0000'.
                   88  VLNK-ERR-TITLE          VALUE 'E001'.
                   88  VLNK-ERR-STATUS         VALUE 'E002'.
                   88  VLNK-ERR-PRIORITY       VALUE 'E003'.
                   88  VLNK-ERR-DATE           VALUE 'E004'.
                   88  VLNK-ERR-OWNER          VALUE 'E005'.
               10  VLNK-ERR-MSG            PIC X(32).
			   