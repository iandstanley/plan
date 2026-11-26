IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOK02.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOK02                                          *
      * TITLE       : TODO MANAGER KICKS TASK ADD / EDIT / DELEGATE    *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : KICKS OLTP PSEUDO-CONVERSATIONAL (IKFCBL00)      *
      * TRANSID     : TODO   MAPSET: TODOM00   MAP: TODOM2             *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   DRIVES THE KICKS 3270 TASK DETAIL SCREEN (TODOM2) FOR ADDING *
      *   NEW TASKS, EDITING EXISTING TASKS, AND DELEGATING TASKS TO   *
      *   OTHER TSO USER IDS WITH OPTIMISTIC LOCKING & TODOLOCK ENQ.   *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. ENTRY DISPATCH (0000-MAIN-CONTROL): DETECTS XCTL ENTRY    *
      *      (EIBAID = LOW-VALUES OR INITIAL STAGE) VS. SCREEN SUBMIT. *
      *   2. ADD/EDIT SAVE (2100-SAVE-TASK): VALIDATES VIA TODOVAL,    *
      *      ALLOCATES SEQUENCE ID UNDER ENQ, WRITES/REWRITES VSAM,    *
      *      AND RETURNS TO TODOK01 VIA XCTL.                          *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOREC  (IN TODO.COPYLIB) : 332-BYTE MASTER TASK RECORD   *
      *   - TODOCTRL (IN TODO.COPYLIB) : 64-BYTE USER CONTROL RECORD   *
      *   - TODOCOMM (IN TODO.COPYLIB) : 64-BYTE DFHCOMMAREA CONTRACT  *
      *   - TODOVLNK (IN TODO.COPYLIB) : 120-BYTE VALIDATOR LINKAGE    *
      *   - TODOLLNK (IN TODO.COPYLIB) : 20-BYTE LOCK LINKAGE          *
      *   - TODOM00  (IN TODO.COPYLIB) : BMS SYMBOLIC MAPSET           *
      *   - DFHAID / DFHBMSCA          : KICKS ATTENTION & ATTRIBUTES  *
      *   - TODOLOCK / TODOVAL         : SHARED LOCK & VALIDATOR CALLS *
      *================================================================*
      * MODIFICATION HISTORY:                                          *
      * VER  DATE       CHANGE-ID AUTHOR DESCRIPTION                   *
      * ---- ---------- --------- ------ ----------------------------- *
      * 1.0  2026-11-26 INIT-001  IS     INITIAL BASELINE RELEASE      *
      *================================================================*

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       77  WS-CTRL-LOCK-RNAME          PIC X(08) VALUE 'CONTROL '.
       77  WS-CENTURY-19               PIC 9(02) VALUE 19.
       77  WS-CENTURY-20               PIC 9(02) VALUE 20.
       77  WS-Y2K-PIVOT                PIC 9(02) VALUE 79.

       01  WS-COMMAREA.
           COPY TODOCOMM.

       01  WS-COMMAREA-LENGTH          PIC S9(04) COMP SYNC VALUE +64.

       01  WS-KICKS-WORK-AREA.
           05  WS-RESP-CODE            PIC S9(08) COMP SYNC VALUE ZERO.
           05  WS-MAST-LEN             PIC S9(04) COMP SYNC VALUE +332.
           05  WS-CTRL-LEN             PIC S9(04) COMP SYNC VALUE +64.
           05  WS-USER-ID              PIC X(08) VALUE SPACES.
           05  WS-NEW-TASK-ID          PIC 9(08) VALUE ZERO.
           05  WS-MAST-RIDFLD.
               10  WS-MRID-OWNER       PIC X(08) VALUE SPACES.
               10  WS-MRID-ID          PIC 9(08) VALUE ZERO.

       01  WS-CONTROL-FLAGS.
           05  WS-LOCK-HELD-SW         PIC X(01) VALUE 'N'.
               88  LOCK-IS-HELD                  VALUE 'Y'.
               88  LOCK-NOT-HELD                 VALUE 'N'.
           05  WS-XCTL-DONE-SW         PIC X(01) VALUE 'N'.
               88  XCTL-WAS-ISSUED               VALUE 'Y'.
               88  NO-XCTL-ISSUED                VALUE 'N'.
           05  WS-SAVE-OK-SW           PIC X(01) VALUE 'Y'.
               88  SAVE-SUCCEEDED                VALUE 'Y'.
               88  SAVE-FAILED                   VALUE 'N'.

       01  WS-DATE-CALC-AREA.
           05  WS-SYS-DATE-6           PIC 9(06) VALUE ZERO.
           05  WS-SYS-DATE-PARTS REDEFINES WS-SYS-DATE-6.
               10  WS-SYS-YY           PIC 9(02).
               10  WS-SYS-MM           PIC 9(02).
               10  WS-SYS-DD           PIC 9(02).
           05  WS-TODAY-YYYYMMDD       PIC 9(08) VALUE ZERO.
           05  WS-TODAY-PARTS REDEFINES WS-TODAY-YYYYMMDD.
               10  WS-TODAY-CC         PIC 9(02).
               10  WS-TODAY-YY         PIC 9(02).
               10  WS-TODAY-MM         PIC 9(02).
               10  WS-TODAY-DD         PIC 9(02).

       01  WS-MASTER-REC.
           COPY TODOREC.

       01  WS-CONTROL-REC.
           COPY TODOCTRL.

       01  WS-VAL-PARM.
           COPY TODOVLNK.

       01  WS-LOCK-PARM.
           COPY TODOLLNK.

       COPY TODOM00.
       COPY DFHAID.
       COPY DFHBMSCA.

       LINKAGE SECTION.
       01  DFHCOMMAREA                 PIC X(64).

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * 0000-MAIN-CONTROL:                                             *
      *   ENTRY DISPATCHER FOR TODOK02 DETAIL SCREEN.                  *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-GET-USER-AND-DATE.
           IF EIBCALEN = WS-COMMAREA-LENGTH
               MOVE DFHCOMMAREA TO WS-COMMAREA
           ELSE
               PERFORM 3800-RETURN-TO-BROWSE.
           IF NOT XCTL-WAS-ISSUED
               IF EIBAID = LOW-VALUES
                   PERFORM 1100-INITIALIZE-DETAIL-MAP
               ELSE
                   PERFORM 2000-PROCESS-DETAIL-INPUT.
           IF NOT XCTL-WAS-ISSUED
               EXEC CICS RETURN
                   TRANSID('TODO')
                   COMMAREA(WS-COMMAREA)
                   LENGTH(WS-COMMAREA-LENGTH)
               END-EXEC.
           EXEC CICS RETURN END-EXEC.

      *----------------------------------------------------------------*
      * 1000-GET-USER-AND-DATE:                                        *
      *   OBTAINS TSO USERID FROM EIB AND FORMATS SYSTEM YYYYMMDD.     *
      *----------------------------------------------------------------*
       1000-GET-USER-AND-DATE.
           EXEC CICS ASSIGN USERID(WS-USER-ID)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL) OR WS-USER-ID = SPACES
               MOVE 'HERC01  ' TO WS-USER-ID.
           ACCEPT WS-SYS-DATE-6 FROM DATE.
           IF WS-SYS-YY < WS-Y2K-PIVOT
               MOVE WS-CENTURY-20 TO WS-TODAY-CC
           ELSE
               MOVE WS-CENTURY-19 TO WS-TODAY-CC.
           MOVE WS-SYS-YY TO WS-TODAY-YY.
           MOVE WS-SYS-MM TO WS-TODAY-MM.
           MOVE WS-SYS-DD TO WS-TODAY-DD.

      *----------------------------------------------------------------*
      * 1100-INITIALIZE-DETAIL-MAP:                                    *
      *   POPULATES TODOM2 FOR ADD MODE OR LOADS EXISTING RECORD.      *
      *----------------------------------------------------------------*
       1100-INITIALIZE-DETAIL-MAP.
           MOVE LOW-VALUES TO TODOM2O.
           IF CA-MODE-ADD
               MOVE 'MODE: ADD TASK  ' TO M2MODEO
               MOVE 'NEW     '         TO M2IDO
               MOVE CA-VIEW-OWNER      TO M2OWNRO
               MOVE 'O'                TO M2STATO
               MOVE '3'                TO M2PRIO
               MOVE '00000000'         TO M2DUEO
               MOVE WS-USER-ID         TO M2CBYO
               MOVE WS-TODAY-YYYYMMDD  TO M2CDTO
               MOVE 'ENTER TASK DETAILS AND PRESS ENTER TO SAVE'
                   TO M2MSGO
               MOVE -1 TO M2TITLL
               PERFORM 8100-SEND-DETAIL-ERASE
           ELSE
               PERFORM 1150-LOAD-EXISTING-TASK.

      *----------------------------------------------------------------*
      * 1150-LOAD-EXISTING-TASK:                                       *
      *   READS SELECTED RECORD FROM TODOMAST AND POPULATES TODOM2.    *
      *----------------------------------------------------------------*
       1150-LOAD-EXISTING-TASK.
           MOVE CA-VIEW-OWNER       TO WS-MRID-OWNER.
           MOVE CA-SELECTED-TASK-ID TO WS-MRID-ID.
           MOVE +332                TO WS-MAST-LEN.
           EXEC CICS READ DATASET('TODOMAST')
               INTO(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RIDFLD(WS-MAST-RIDFLD)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
               PERFORM 3800-RETURN-TO-BROWSE
           ELSE
               MOVE 'MODE: EDIT TASK ' TO M2MODEO
               MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M2IDO
               MOVE TODO-OWNER-ID OF WS-MASTER-REC TO M2OWNRO
               MOVE TODO-TITLE OF WS-MASTER-REC    TO M2TITLO
               MOVE TODO-CATEGORY OF WS-MASTER-REC TO M2CATO
               MOVE TODO-STATUS OF WS-MASTER-REC   TO M2STATO
               MOVE TODO-PRIORITY OF WS-MASTER-REC TO M2PRIO
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M2DUEO
               MOVE TODO-CREATED-BY OF WS-MASTER-REC
                   TO M2CBYO
               MOVE TODO-CREATED-DATE OF WS-MASTER-REC
                   TO M2CDTO
               MOVE TODO-NOTE-LINE-1 OF WS-MASTER-REC
                   TO M2NOT1O
               MOVE TODO-NOTE-LINE-2 OF WS-MASTER-REC
                   TO M2NOT2O
               MOVE TODO-NOTE-LINE-3 OF WS-MASTER-REC
                   TO M2NOT3O
               MOVE TODO-REC-VERSION OF WS-MASTER-REC
                   TO CA-SAVED-REC-VERSION
               MOVE 'EDIT FIELDS OR CHANGE OWNER TO DELEGATE'
                   TO M2MSGO
               MOVE -1 TO M2TITLL
               PERFORM 8100-SEND-DETAIL-ERASE.

      *----------------------------------------------------------------*
      * 2000-PROCESS-DETAIL-INPUT:                                     *
      *   HANDLES PF3/PF12 CANCEL OR VALIDATES & SAVES TASK ON ENTER.  *
      *----------------------------------------------------------------*
       2000-PROCESS-DETAIL-INPUT.
           IF EIBAID = DFHPF3 OR EIBAID = DFHPF12
               PERFORM 3800-RETURN-TO-BROWSE
           ELSE
               PERFORM 2100-VALIDATE-AND-SAVE-TASK.

      *----------------------------------------------------------------*
      * 2100-VALIDATE-AND-SAVE-TASK:                                   *
      *   RECEIVES TODOM2, CALLS TODOVAL, AND COMMITS ADD OR UPDATE.   *
      *----------------------------------------------------------------*
       2100-VALIDATE-AND-SAVE-TASK.
           MOVE LOW-VALUES TO TODOM2I.
           EXEC CICS RECEIVE MAP('TODOM2') MAPSET('TODOM00')
               INTO(TODOM2I)
               RESP(WS-RESP-CODE)
           END-EXEC.
           MOVE 'ALL '   TO VLNK-FUNC-CODE.
           MOVE M2STATI  TO VLNK-STATUS.
           IF M2PRII IS NUMERIC
               MOVE M2PRII TO VLNK-PRIORITY
           ELSE
               MOVE 9 TO VLNK-PRIORITY.
           IF M2DUEI IS NUMERIC
               MOVE M2DUEI TO VLNK-DATE-FIELD
           ELSE
               MOVE 99999999 TO VLNK-DATE-FIELD.
           MOVE 'Y'      TO VLNK-ZERO-DATE-OK.
           MOVE M2OWNRI  TO VLNK-OWNER-ID.
           MOVE M2TITLI  TO VLNK-TITLE.
           CALL 'TODOVAL' USING WS-VAL-PARM.

           IF VLNK-HAS-ERROR
               MOVE LOW-VALUES   TO TODOM2O
               MOVE VLNK-ERR-MSG TO M2MSGO
               MOVE -1           TO M2TITLL
               PERFORM 8200-SEND-DETAIL-DATA
           ELSE
               IF CA-MODE-ADD
                   PERFORM 2200-COMMIT-NEW-TASK
               ELSE
                   PERFORM 2300-COMMIT-EDIT-TASK.

      *----------------------------------------------------------------*
      * 2200-COMMIT-NEW-TASK:                                          *
      *   ALLOCATES SEQUENCE ID UNDER ENQ AND WRITES NEW MASTER REC.   *
      *----------------------------------------------------------------*
       2200-COMMIT-NEW-TASK.
           MOVE 'Y' TO WS-SAVE-OK-SW.
           PERFORM 9300-ALLOC-TARGET-ID.
           IF SAVE-SUCCEEDED
               PERFORM 2210-BUILD-AND-WRITE-NEW.
           IF SAVE-SUCCEEDED
               MOVE M2OWNRI TO CA-VIEW-OWNER
               PERFORM 3800-RETURN-TO-BROWSE.

      *----------------------------------------------------------------*
      * 2210-BUILD-AND-WRITE-NEW:                                      *
      *   POPULATES NEW MASTER RECORD FIELDS AND CALLS CICS WRITE.     *
      *----------------------------------------------------------------*
       2210-BUILD-AND-WRITE-NEW.
           MOVE SPACES   TO WS-MASTER-REC.
           MOVE M2OWNRI  TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE M2OWNRI  TO TODO-ALT-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-NEW-TASK-ID
               TO TODO-TASK-ID OF WS-MASTER-REC.
           MOVE M2TITLI  TO TODO-TITLE OF WS-MASTER-REC.
           MOVE M2CATI   TO TODO-CATEGORY OF WS-MASTER-REC.
           MOVE M2STATI  TO TODO-STATUS OF WS-MASTER-REC.
           MOVE M2PRII   TO TODO-PRIORITY OF WS-MASTER-REC.
           MOVE M2DUEI   TO TODO-DUE-DATE OF WS-MASTER-REC.
           MOVE M2DUEI   TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE M2PRII   TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           MOVE WS-TODAY-YYYYMMDD
               TO TODO-CREATED-DATE OF WS-MASTER-REC.
           MOVE WS-USER-ID
               TO TODO-CREATED-BY OF WS-MASTER-REC.
           IF TODO-IS-CLOSED OF WS-MASTER-REC
               MOVE WS-TODAY-YYYYMMDD
                   TO TODO-DONE-DATE OF WS-MASTER-REC
           ELSE
               MOVE ZERO TO TODO-DONE-DATE OF WS-MASTER-REC.
           MOVE M2NOT1I  TO TODO-NOTE-LINE-1 OF WS-MASTER-REC.
           MOVE M2NOT2I  TO TODO-NOTE-LINE-2 OF WS-MASTER-REC.
           MOVE M2NOT3I  TO TODO-NOTE-LINE-3 OF WS-MASTER-REC.
           MOVE +1       TO TODO-REC-VERSION OF WS-MASTER-REC.
           PERFORM 9400-WRITE-NEW-MASTER.

      *----------------------------------------------------------------*
      * 2300-COMMIT-EDIT-TASK:                                         *
      *   UPDATES EXISTING RECORD OR DELEGATES IF OWNER WAS CHANGED.   *
      *----------------------------------------------------------------*
       2300-COMMIT-EDIT-TASK.
           MOVE 'Y' TO WS-SAVE-OK-SW.
           IF M2OWNRI NOT = CA-VIEW-OWNER
               PERFORM 2350-DELEGATE-EDITED-TASK
           ELSE
               PERFORM 2310-REWRITE-EDITED-TASK.
           IF SAVE-SUCCEEDED
               PERFORM 3800-RETURN-TO-BROWSE.

      *----------------------------------------------------------------*
      * 2310-REWRITE-EDITED-TASK:                                      *
      *   READS FOR UPDATE UNDER ENQ, VERIFIES VERSION, REWRITES.      *
      *----------------------------------------------------------------*
       2310-REWRITE-EDITED-TASK.
           MOVE CA-VIEW-OWNER TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               PERFORM 2315-PERFORM-VERSIONED-REWRITE
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2315-PERFORM-VERSIONED-REWRITE:                                *
      *   CHECKS REC-VERSION AND EXECUTES CICS REWRITE ON TODOMAST.    *
      *----------------------------------------------------------------*
       2315-PERFORM-VERSIONED-REWRITE.
           MOVE CA-VIEW-OWNER       TO WS-MRID-OWNER.
           MOVE CA-SELECTED-TASK-ID TO WS-MRID-ID.
           MOVE +332                TO WS-MAST-LEN.
           EXEC CICS READ DATASET('TODOMAST')
               INTO(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RIDFLD(WS-MAST-RIDFLD)
               UPDATE
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
               MOVE 'N' TO WS-SAVE-OK-SW
               MOVE LOW-VALUES TO TODOM2O
               MOVE 'RECORD NOT FOUND OR BUSY' TO M2MSGO
               PERFORM 8200-SEND-DETAIL-DATA
           ELSE
               IF TODO-REC-VERSION OF WS-MASTER-REC
                  NOT = CA-SAVED-REC-VERSION
                   MOVE 'N' TO WS-SAVE-OK-SW
                   MOVE LOW-VALUES TO TODOM2O
                   MOVE 'MODIFIED BY ANOTHER USER - CANCEL & REOPEN'
                       TO M2MSGO
                   PERFORM 8200-SEND-DETAIL-DATA
               ELSE
                   PERFORM 2318-APPLY-FIELD-UPDATES.

      *----------------------------------------------------------------*
      * 2318-APPLY-FIELD-UPDATES:                                      *
      *   COPIES EDITED SCREEN VALUES INTO RECORD AND REWRITES.        *
      *----------------------------------------------------------------*
       2318-APPLY-FIELD-UPDATES.
           MOVE M2TITLI TO TODO-TITLE OF WS-MASTER-REC.
           MOVE M2CATI  TO TODO-CATEGORY OF WS-MASTER-REC.
           MOVE M2STATI TO TODO-STATUS OF WS-MASTER-REC.
           MOVE M2PRII  TO TODO-PRIORITY OF WS-MASTER-REC.
           MOVE M2DUEI  TO TODO-DUE-DATE OF WS-MASTER-REC.
           MOVE M2DUEI  TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE M2PRII  TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           IF TODO-IS-CLOSED OF WS-MASTER-REC
               MOVE WS-TODAY-YYYYMMDD
                   TO TODO-DONE-DATE OF WS-MASTER-REC
           ELSE
               MOVE ZERO TO TODO-DONE-DATE OF WS-MASTER-REC.
           MOVE M2NOT1I TO TODO-NOTE-LINE-1 OF WS-MASTER-REC.
           MOVE M2NOT2I TO TODO-NOTE-LINE-2 OF WS-MASTER-REC.
           MOVE M2NOT3I TO TODO-NOTE-LINE-3 OF WS-MASTER-REC.
           ADD +1 TO TODO-REC-VERSION OF WS-MASTER-REC.
           EXEC CICS REWRITE DATASET('TODOMAST')
               FROM(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 2350-DELEGATE-EDITED-TASK:                                     *
      *   ALLOCATES NEW KEY UNDER TARGET OWNER, WRITES, DELETES OLD.   *
      *----------------------------------------------------------------*
       2350-DELEGATE-EDITED-TASK.
           PERFORM 9300-ALLOC-TARGET-ID.
           IF SAVE-SUCCEEDED
               MOVE CA-VIEW-OWNER       TO WS-MRID-OWNER
               MOVE CA-SELECTED-TASK-ID TO WS-MRID-ID
               MOVE +332                TO WS-MAST-LEN
               EXEC CICS READ DATASET('TODOMAST')
                   INTO(WS-MASTER-REC)
                   LENGTH(WS-MAST-LEN)
                   RIDFLD(WS-MAST-RIDFLD)
                   RESP(WS-RESP-CODE)
               END-EXEC
               IF WS-RESP-CODE = DFHRESP(NORMAL)
                   PERFORM 2355-WRITE-NEW-AND-DELETE-OLD
               ELSE
                   MOVE 'N' TO WS-SAVE-OK-SW.

      *----------------------------------------------------------------*
      * 2355-WRITE-NEW-AND-DELETE-OLD:                                 *
      *   WRITES RE-KEYED TASK UNDER NEW OWNER AND DELETES OLD KEY.    *
      *----------------------------------------------------------------*
       2355-WRITE-NEW-AND-DELETE-OLD.
           MOVE M2OWNRI        TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE M2OWNRI        TO TODO-ALT-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-NEW-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC.
           MOVE M2TITLI        TO TODO-TITLE OF WS-MASTER-REC.
           MOVE M2CATI         TO TODO-CATEGORY OF WS-MASTER-REC.
           MOVE M2STATI        TO TODO-STATUS OF WS-MASTER-REC.
           MOVE M2PRII         TO TODO-PRIORITY OF WS-MASTER-REC.
           MOVE M2DUEI         TO TODO-DUE-DATE OF WS-MASTER-REC.
           MOVE M2DUEI         TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE M2PRII         TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           MOVE M2NOT1I        TO TODO-NOTE-LINE-1 OF WS-MASTER-REC.
           MOVE M2NOT2I        TO TODO-NOTE-LINE-2 OF WS-MASTER-REC.
           MOVE M2NOT3I        TO TODO-NOTE-LINE-3 OF WS-MASTER-REC.
           MOVE +1             TO TODO-REC-VERSION OF WS-MASTER-REC.
           PERFORM 9400-WRITE-NEW-MASTER.
           IF SAVE-SUCCEEDED
               MOVE CA-VIEW-OWNER       TO WS-MRID-OWNER
               MOVE CA-SELECTED-TASK-ID TO WS-MRID-ID
               EXEC CICS DELETE DATASET('TODOMAST')
                   RIDFLD(WS-MAST-RIDFLD)
                   RESP(WS-RESP-CODE)
               END-EXEC.

      *----------------------------------------------------------------*
      * 3800-RETURN-TO-BROWSE:                                         *
      *   TRANSFERS CONTROL BACK TO TODOK01 BROWSE SCREEN VIA XCTL.    *
      *----------------------------------------------------------------*
       3800-RETURN-TO-BROWSE.
           MOVE '1' TO CA-PROCESS-STAGE.
           MOVE 'Y' TO WS-XCTL-DONE-SW.
           EXEC CICS XCTL PROGRAM('TODOK01')
               COMMAREA(WS-COMMAREA)
               LENGTH(WS-COMMAREA-LENGTH)
           END-EXEC.

      *----------------------------------------------------------------*
      * 8100-SEND-DETAIL-ERASE:                                        *
      *   SENDS FULL TODOM2 MAP WITH ERASE AND SYMBOLIC CURSOR.        *
      *----------------------------------------------------------------*
       8100-SEND-DETAIL-ERASE.
           EXEC CICS SEND MAP('TODOM2') MAPSET('TODOM00')
               FROM(TODOM2O)
               ERASE
               CURSOR
               FREEKB
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 8200-SEND-DETAIL-DATA:                                         *
      *   SENDS TODOM2 VALIDATION MESSAGE WITH DATAONLY.               *
      *----------------------------------------------------------------*
       8200-SEND-DETAIL-DATA.
           EXEC CICS SEND MAP('TODOM2') MAPSET('TODOM00')
               FROM(TODOM2O)
               DATAONLY
               CURSOR
               FREEKB
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 9300-ALLOC-TARGET-ID:                                          *
      *   ENSURES TARGET OWNER CONTROL RECORD AND INCREMENTS TASK ID.  *
      *----------------------------------------------------------------*
       9300-ALLOC-TARGET-ID.
           MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               PERFORM 9310-READ-OR-CREATE-CTRL
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 9310-READ-OR-CREATE-CTRL:                                      *
      *   READS OR INITIALIZES TARGET USER TODOCTRL AND INCREMENTS ID. *
      *----------------------------------------------------------------*
       9310-READ-OR-CREATE-CTRL.
           MOVE +64 TO WS-CTRL-LEN.
           EXEC CICS READ DATASET('TODOCTRL')
               INTO(WS-CONTROL-REC)
               LENGTH(WS-CTRL-LEN)
               RIDFLD(M2OWNRI)
               UPDATE
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE = DFHRESP(NORMAL)
               ADD 1 TO CTRL-LAST-TASK-ID OF WS-CONTROL-REC
               MOVE CTRL-LAST-TASK-ID OF WS-CONTROL-REC
                   TO WS-NEW-TASK-ID
               EXEC CICS REWRITE DATASET('TODOCTRL')
                   FROM(WS-CONTROL-REC)
                   LENGTH(WS-CTRL-LEN)
                   RESP(WS-RESP-CODE)
               END-EXEC
           ELSE
               IF WS-RESP-CODE = DFHRESP(NOTFND)
                   PERFORM 9320-CREATE-TARGET-CTRL
               ELSE
                   MOVE 'N' TO WS-SAVE-OK-SW.

      *----------------------------------------------------------------*
      * 9320-CREATE-TARGET-CTRL:                                       *
      *   CREATES NEW TODOCTRL RECORD WITH INITIAL TASK ID = 1.        *
      *----------------------------------------------------------------*
       9320-CREATE-TARGET-CTRL.
           MOVE SPACES  TO WS-CONTROL-REC.
           MOVE M2OWNRI TO CTRL-USER-ID OF WS-CONTROL-REC.
           MOVE 1       TO CTRL-LAST-TASK-ID OF WS-CONTROL-REC.
           MOVE 1       TO WS-NEW-TASK-ID.
           MOVE 'Y'     TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC.
           MOVE 3       TO CTRL-DEFAULT-PRI OF WS-CONTROL-REC.
           MOVE M2OWNRI TO CTRL-USER-NAME OF WS-CONTROL-REC.
           MOVE +0      TO CTRL-ACTIVE-COUNT OF WS-CONTROL-REC.
           MOVE WS-TODAY-YYYYMMDD
               TO CTRL-LAST-LOGIN-DATE OF WS-CONTROL-REC.
           EXEC CICS WRITE DATASET('TODOCTRL')
               FROM(WS-CONTROL-REC)
               LENGTH(WS-CTRL-LEN)
               RIDFLD(M2OWNRI)
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 9400-WRITE-NEW-MASTER:                                         *
      *   WRITES NEW RECORD INTO TODOMAST UNDER TARGET OWNER ENQ.      *
      *----------------------------------------------------------------*
       9400-WRITE-NEW-MASTER.
           MOVE TODO-OWNER-ID OF WS-MASTER-REC TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               PERFORM 9410-EXEC-CICS-WRITE-MAST
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 9410-EXEC-CICS-WRITE-MAST:                                     *
      *   ISSUES EXEC CICS WRITE ON TODOMAST AND CHECKS RESPONSE CODE. *
      *----------------------------------------------------------------*
       9410-EXEC-CICS-WRITE-MAST.
           MOVE TODO-OWNER-ID OF WS-MASTER-REC TO WS-MRID-OWNER.
           MOVE TODO-TASK-ID OF WS-MASTER-REC  TO WS-MRID-ID.
           MOVE +332                           TO WS-MAST-LEN.
           EXEC CICS WRITE DATASET('TODOMAST')
               FROM(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RIDFLD(WS-MAST-RIDFLD)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
               MOVE 'N' TO WS-SAVE-OK-SW.

      *----------------------------------------------------------------*
      * 9500-LOCK-RESOURCE:                                            *
      *   INVOKES TODOLOCK FOR SYSTEM-WIDE MVS ENQ SERIALIZATION.      *
      *----------------------------------------------------------------*
       9500-LOCK-RESOURCE.
           MOVE 'ENQ ' TO LLNK-ACTION.
           MOVE +0     TO LLNK-RC.
           CALL 'TODOLOCK' USING WS-LOCK-PARM.
           IF LLNK-OK
               MOVE 'Y' TO WS-LOCK-HELD-SW.

      *----------------------------------------------------------------*
      * 9600-UNLOCK-RESOURCE:                                          *
      *   INVOKES TODOLOCK TO RELEASE SYSTEM-WIDE MVS ENQ.             *
      *----------------------------------------------------------------*
       9600-UNLOCK-RESOURCE.
           IF LOCK-IS-HELD
               MOVE 'DEQ ' TO LLNK-ACTION
               MOVE +0     TO LLNK-RC
               CALL 'TODOLOCK' USING WS-LOCK-PARM
               MOVE 'N' TO WS-LOCK-HELD-SW.