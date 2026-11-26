IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOCMD.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOCMD                                          *
      * TITLE       : TODO MANAGER TSO LINE-MODE CLI PROCESSOR         *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : TSO FOREGROUND / IKJEFT01 BATCH (IKFCBL00)       *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   EXECUTES TSO COMMAND-LINE TODO OPERATIONS (LIST, ADD, VIEW,  *
      *   START, WAIT, DONE, CANCEL, ASSIGN, NOTE, PRINT) AGAINST      *
      *   SHARED VSAM CLUSTERS WITH SYSTEM-WIDE ENQ/DEQ SERIALIZATION. *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. INITIALIZATION (1000-INITIALIZE): OPENS CMDSYSIN AND VSAM *
      *      CLUSTERS, READS 200-BYTE COMMAND RECORD, CAPTURES SYSTEM  *
      *      DATE IN YYYYMMDD FORMAT.                                  *
      *   2. DISPATCH (2000-EXECUTE-COMMAND): ROUTES TO VERB HANDLER,  *
      *      SERIALIZING UPDATES VIA TODOLOCK AND VALIDATING VIA       *
      *      TODOVAL.                                                  *
      *   3. TERMINATION (3000-TERMINATE): CLOSES ALL DATASETS AND     *
      *      ASSIGNS STANDARD RETURN-CODE (00, 04, 08, OR 16).         *
      *                                                                *
      * USAGE / JCL INTERFACE:                                         *
      *   DDNAME    ORG    RECFM/LRECL  I/O     DESCRIPTION            *
      *   --------  -----  -----------  ------  ---------------------- *
      *   CMDSYSIN  QSAM   FB / 200     INPUT   CLIST COMMAND HANDOFF  *
      *   TODOMAST  VSAM   KSDS / 332   I-O     MASTER TASK CLUSTER    *
      *   TODOPATH  VSAM   PATH / 332   INPUT   AIX1 DUE/PRI BROWSE    *
      *   TODOCTRL  VSAM   KSDS / 64    I-O     USER CONTROL CLUSTER   *
      *   SYSOUT    SYSOUT FBA / 133    OUTPUT  TSO TERMINAL OUTPUT    *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOREC  (IN TODO.COPYLIB) : 332-BYTE MASTER TASK RECORD   *
      *   - TODOCTRL (IN TODO.COPYLIB) : 64-BYTE USER CONTROL RECORD   *
      *   - TODOCREC (IN TODO.COPYLIB) : 200-BYTE CLI COMMAND RECORD   *
      *   - TODOVLNK (IN TODO.COPYLIB) : 120-BYTE VALIDATOR LINKAGE    *
      *   - TODOLLNK (IN TODO.COPYLIB) : 20-BYTE LOCK LINKAGE          *
      *   - TODOLOCK (STATIC CALL)     : MVS SYSTEM-WIDE ENQ/DEQ       *
      *   - TODOVAL  (STATIC CALL)     : SHARED FIELD/DATE VALIDATOR   *
      *                                                                *
      * RETURN CODES:                                                  *
      *   00 - COMMAND COMPLETED SUCCESSFULLY                          *
      *   04 - COMPLETED WITH WARNING (E.G., NO TASKS FOUND)           *
      *   08 - USER SYNTAX OR VALIDATION ERROR                         *
      *   16 - SEVERE VSAM OR SYSTEM LOCK ERROR                        *
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

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CMD-IN-FILE      ASSIGN TO UT-S-CMDSYSIN
                                   FILE STATUS IS WS-CMD-STATUS.
           SELECT TODO-MASTER-FILE ASSIGN TO TODOMAST
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS DYNAMIC
                                   RECORD KEY IS FD-MAST-KEY
                                   FILE STATUS IS WS-MAST-STATUS.
           SELECT TODO-PATH-FILE   ASSIGN TO TODOPATH
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS DYNAMIC
                                   RECORD KEY IS FD-PATH-KEY
                                   ALTERNATE RECORD KEY IS FD-PATH-ALT
                                       WITH DUPLICATES
                                   FILE STATUS IS WS-PATH-STATUS.
           SELECT TODO-CTRL-FILE   ASSIGN TO TODOCTRL
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS DYNAMIC
                                   RECORD KEY IS FD-CTRL-KEY
                                   FILE STATUS IS WS-CTRL-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CMD-IN-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 200 CHARACTERS.
       01  CMD-IN-RECORD               PIC X(200).

       FD  TODO-MASTER-FILE
           RECORD CONTAINS 332 CHARACTERS.
       01  FD-MASTER-RECORD.
           05  FD-MAST-KEY             PIC X(16).
           05  FD-MAST-REST            PIC X(316).

       FD  TODO-PATH-FILE
           RECORD CONTAINS 332 CHARACTERS.
       01  FD-PATH-RECORD.
           05  FD-PATH-KEY             PIC X(16).
           05  FD-PATH-ALT             PIC X(17).
           05  FD-PATH-REST            PIC X(299).

       FD  TODO-CTRL-FILE
           RECORD CONTAINS 64 CHARACTERS.
       01  FD-CTRL-RECORD.
           05  FD-CTRL-KEY             PIC X(08).
           05  FD-CTRL-REST            PIC X(56).

       WORKING-STORAGE SECTION.
       77  WS-CTRL-LOCK-RNAME          PIC X(08) VALUE 'CONTROL '.
       77  WS-CENTURY-19               PIC 9(02) VALUE 19.
       77  WS-CENTURY-20               PIC 9(02) VALUE 20.
       77  WS-Y2K-PIVOT                PIC 9(02) VALUE 79.
       77  WS-DEFAULT-PRI              PIC 9(01) VALUE 3.

       01  WS-FILE-STATUS-AREA.
           05  WS-CMD-STATUS           PIC X(02) VALUE SPACES.
               88  CMD-IO-OK                     VALUE '00'.
               88  CMD-IO-EOF                    VALUE '10'.
           05  WS-MAST-STATUS          PIC X(02) VALUE SPACES.
               88  MAST-IO-OK                    VALUE '00'.
               88  MAST-IO-DUP-ALT               VALUE '02'.
               88  MAST-IO-EOF                   VALUE '10'.
               88  MAST-IO-DUP-KEY               VALUE '22'.
               88  MAST-IO-NOT-FOUND             VALUE '23'.
           05  WS-PATH-STATUS          PIC X(02) VALUE SPACES.
               88  PATH-IO-OK                    VALUE '00' '02'.
               88  PATH-IO-EOF                   VALUE '10'.
               88  PATH-IO-NOT-FOUND             VALUE '23'.
           05  WS-CTRL-STATUS          PIC X(02) VALUE SPACES.
               88  CTRL-IO-OK                    VALUE '00'.
               88  CTRL-IO-NOT-FOUND             VALUE '23'.

       01  WS-CONTROL-FLAGS.
           05  WS-APP-RC               PIC S9(04) COMP SYNC VALUE +0.
           05  WS-FILES-OPEN-SW        PIC X(01) VALUE 'N'.
               88  FILES-ARE-OPEN                VALUE 'Y'.
               88  FILES-ARE-CLOSED              VALUE 'N'.
           05  WS-LIST-EOF-SW          PIC X(01) VALUE 'N'.
               88  END-OF-LIST                   VALUE 'Y'.
               88  MORE-LIST-RECORDS             VALUE 'N'.
           05  WS-ID-VALID-SW          PIC X(01) VALUE 'N'.
               88  TASK-ID-IS-VALID              VALUE 'Y'.
               88  TASK-ID-IS-INVALID            VALUE 'N'.
           05  WS-MATCH-SW             PIC X(01) VALUE 'N'.
               88  RECORD-MATCHES-FILTER         VALUE 'Y'.
               88  RECORD-SKIPPED                VALUE 'N'.
           05  WS-LOCK-HELD-SW         PIC X(01) VALUE 'N'.
               88  LOCK-IS-HELD                  VALUE 'Y'.
               88  LOCK-NOT-HELD                 VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-DISPLAY-CNT          PIC S9(05) COMP-3 VALUE ZERO.
           05  WS-IDX                  PIC S9(04) COMP SYNC VALUE +0.
           05  WS-OUT-IDX              PIC S9(04) COMP SYNC VALUE +0.

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

       01  WS-ID-PARSE-AREA.
           05  WS-RAW-ID-TEXT          PIC X(16) VALUE SPACES.
           05  WS-RAW-ID-ARR REDEFINES WS-RAW-ID-TEXT.
               10  WS-RAW-CH           PIC X(01) OCCURS 16 TIMES.
           05  WS-PARSED-TASK-ID       PIC 9(08) VALUE ZERO.
           05  WS-PARSED-ID-ARR REDEFINES WS-PARSED-TASK-ID.
               10  WS-NUM-CH           PIC X(01) OCCURS 8 TIMES.
           05  WS-TARGET-OWNER         PIC X(08) VALUE SPACES.
           05  WS-NEW-TASK-ID          PIC 9(08) VALUE ZERO.
           05  WS-NEW-STATUS           PIC X(01) VALUE SPACES.

       01  WS-COMMAND-AREA.
           COPY TODOCREC.

       01  WS-MASTER-REC.
           COPY TODOREC.

       01  WS-TEMP-MASTER-REC.
           COPY TODOREC.

       01  WS-CONTROL-REC.
           COPY TODOCTRL.

       01  WS-VAL-PARM.
           COPY TODOVLNK.

       01  WS-LOCK-PARM.
           COPY TODOLLNK.

       01  WS-LIST-HEADER-1.
           05  FILLER                  PIC X(08) VALUE 'ID      '.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE 'ST'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE 'PRI'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE 'DUE     '.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE 'CATEGORY  '.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(42) VALUE
               'TITLE                                     '.

       01  WS-LIST-HEADER-2.
           05  FILLER                  PIC X(08) VALUE '--------'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE '--'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE '---'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '--------'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE '----------'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(42) VALUE
               '------------------------------------------'.

       01  WS-LIST-DETAIL.
           05  LD-TASK-ID              PIC 9(08) VALUE ZERO.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  LD-STATUS               PIC X(01) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  LD-PRIORITY             PIC 9(01) VALUE ZERO.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  LD-DUE-DATE             PIC X(08) VALUE SPACES.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  LD-CATEGORY             PIC X(10) VALUE SPACES.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  LD-TITLE                PIC X(42) VALUE SPACES.

       01  WS-LIST-FOOTER.
           05  FILLER                  PIC X(04) VALUE '*** '.
           05  LF-COUNT                PIC ZZZZ9.
           05  FILLER                  PIC X(27) VALUE
               ' TASK(S) DISPLAYED FOR USER '.
           05  LF-USER                 PIC X(08) VALUE SPACES.
           05  FILLER                  PIC X(04) VALUE ' ***'.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * 0000-MAIN-CONTROL:                                             *
      *   EXECUTIVE DRIVER INITIALIZING FILES, DISPATCHING THE CLI     *
      *   VERB, AND PERFORMING CLEAN TERMINATION.                      *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE.
           IF WS-APP-RC = 0
               PERFORM 2000-EXECUTE-COMMAND.
           PERFORM 3000-TERMINATE.
           GOBACK.

      *----------------------------------------------------------------*
      * 1000-INITIALIZE:                                               *
      *   OPENS DATASETS, READS COMMAND HANDOFF RECORD, AND COMPUTES   *
      *   CURRENT SYSTEM DATE IN YYYYMMDD FORMAT.                      *
      *----------------------------------------------------------------*
       1000-INITIALIZE.
           PERFORM 1100-GET-SYSTEM-DATE.
           OPEN INPUT  CMD-IN-FILE
                       TODO-PATH-FILE
                I-O    TODO-MASTER-FILE
                       TODO-CTRL-FILE.
           IF NOT CMD-IO-OK
              OR NOT MAST-IO-OK
              OR NOT PATH-IO-OK
              OR NOT CTRL-IO-OK
               DISPLAY 'TODOCMD: FILE OPEN ERROR CMD=' WS-CMD-STATUS
                       ' MAST=' WS-MAST-STATUS
                       ' PATH=' WS-PATH-STATUS
                       ' CTRL=' WS-CTRL-STATUS
               MOVE 16 TO WS-APP-RC
           ELSE
               MOVE 'Y' TO WS-FILES-OPEN-SW
               READ CMD-IN-FILE INTO WS-COMMAND-AREA
                   AT END
                       DISPLAY 'TODOCMD: EMPTY CMDSYSIN INPUT'
                       MOVE 16 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 1100-GET-SYSTEM-DATE:                                          *
      *   CONVERTS MVS 6-DIGIT YYMMDD SYSTEM DATE TO 8-DIGIT YYYYMMDD. *
      *----------------------------------------------------------------*
       1100-GET-SYSTEM-DATE.
           ACCEPT WS-SYS-DATE-6 FROM DATE.
           IF WS-SYS-YY < WS-Y2K-PIVOT
               MOVE WS-CENTURY-20 TO WS-TODAY-CC
           ELSE
               MOVE WS-CENTURY-19 TO WS-TODAY-CC.
           MOVE WS-SYS-YY TO WS-TODAY-YY.
           MOVE WS-SYS-MM TO WS-TODAY-MM.
           MOVE WS-SYS-DD TO WS-TODAY-DD.

      *----------------------------------------------------------------*
      * 2000-EXECUTE-COMMAND:                                          *
      *   VALIDATES COMMAND VERB AND ROUTES TO APPROPRIATE HANDLER.    *
      *----------------------------------------------------------------*
       2000-EXECUTE-COMMAND.
           IF CMD-IS-LIST
               PERFORM 2100-CMD-LIST
           ELSE
               IF CMD-IS-ADD
                   PERFORM 2200-CMD-ADD
               ELSE
                   IF CMD-IS-VIEW
                       PERFORM 2300-CMD-VIEW
                   ELSE
                       IF CMD-IS-START
                           MOVE 'I' TO WS-NEW-STATUS
                           PERFORM 2400-CMD-STATUS-CHANGE
                       ELSE
                           IF CMD-IS-WAIT
                               MOVE 'W' TO WS-NEW-STATUS
                               PERFORM 2400-CMD-STATUS-CHANGE
                           ELSE
                               IF CMD-IS-DONE
                                   MOVE 'C' TO WS-NEW-STATUS
                                   PERFORM 2400-CMD-STATUS-CHANGE
                               ELSE
                                   PERFORM 2050-DISPATCH-MORE-VERBS.

      *----------------------------------------------------------------*
      * 2050-DISPATCH-MORE-VERBS:                                      *
      *   HANDLES REMAINING VERBS (CANCEL, ASSIGN, NOTE, PRINT).       *
      *----------------------------------------------------------------*
       2050-DISPATCH-MORE-VERBS.
           IF CMD-IS-CANCEL
               MOVE 'X' TO WS-NEW-STATUS
               PERFORM 2400-CMD-STATUS-CHANGE
           ELSE
               IF CMD-IS-ASSIGN
                   PERFORM 2500-CMD-ASSIGN
               ELSE
                   IF CMD-IS-NOTE
                       PERFORM 2600-CMD-NOTE
                   ELSE
                       IF CMD-IS-PRINT
                           PERFORM 2700-CMD-PRINT
                       ELSE
                           DISPLAY 'TODOCMD: UNKNOWN COMMAND VERB '
                                   CMD-VERB
                           MOVE 8 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 2100-CMD-LIST:                                                 *
      *   BROWSES TASKS VIA AIX1 PATH IN DUE-DATE + PRIORITY ORDER.    *
      *----------------------------------------------------------------*
       2100-CMD-LIST.
           IF CMD-TARGET-USER NOT = SPACES
               MOVE CMD-TARGET-USER TO WS-TARGET-OWNER
           ELSE
               MOVE CMD-USER-ID TO WS-TARGET-OWNER.
           MOVE LOW-VALUES      TO WS-MASTER-REC.
           MOVE WS-TARGET-OWNER TO TODO-ALT-OWNER-ID OF WS-MASTER-REC.
           MOVE ZERO            TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE ZERO            TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           MOVE TODO-ALT-KEY OF WS-MASTER-REC TO FD-PATH-ALT.
           MOVE 'N' TO WS-LIST-EOF-SW.
           MOVE ZERO TO WS-DISPLAY-CNT.
           START TODO-PATH-FILE KEY IS NOT LESS THAN FD-PATH-ALT
               INVALID KEY
                   MOVE 'Y' TO WS-LIST-EOF-SW.
           DISPLAY WS-LIST-HEADER-1.
           DISPLAY WS-LIST-HEADER-2.
           PERFORM 2110-READ-NEXT-PATH UNTIL END-OF-LIST.
           MOVE WS-DISPLAY-CNT  TO LF-COUNT.
           MOVE WS-TARGET-OWNER TO LF-USER.
           DISPLAY WS-LIST-FOOTER.
           IF WS-DISPLAY-CNT = ZERO
               MOVE 4 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 2110-READ-NEXT-PATH:                                           *
      *   READS NEXT RECORD ALONG AIX1 PATH AND APPLIES STATUS FILTER. *
      *----------------------------------------------------------------*
       2110-READ-NEXT-PATH.
           READ TODO-PATH-FILE NEXT RECORD INTO WS-MASTER-REC
               AT END
                   MOVE 'Y' TO WS-LIST-EOF-SW.
           IF NOT END-OF-LIST
               IF TODO-OWNER-ID OF WS-MASTER-REC NOT = WS-TARGET-OWNER
                   MOVE 'Y' TO WS-LIST-EOF-SW
               ELSE
                   PERFORM 2120-FILTER-AND-DISPLAY.

      *----------------------------------------------------------------*
      * 2120-FILTER-AND-DISPLAY:                                       *
      *   FILTERS BY OPEN/WAIT/ALL AND DISPATCHES DETAIL LINE PRINT.   *
      *----------------------------------------------------------------*
       2120-FILTER-AND-DISPLAY.
           MOVE 'N' TO WS-MATCH-SW.
           IF CMD-ARG1 = 'ALL             '
               MOVE 'Y' TO WS-MATCH-SW
           ELSE
               IF CMD-ARG1 = 'WAIT            '
                   IF TODO-STAT-WAITING OF WS-MASTER-REC
                       MOVE 'Y' TO WS-MATCH-SW
                   ELSE
                       NEXT SENTENCE
               ELSE
                   IF TODO-IS-ACTIVE OF WS-MASTER-REC
                       MOVE 'Y' TO WS-MATCH-SW.
           IF RECORD-MATCHES-FILTER
               PERFORM 2130-PRINT-LIST-LINE.

      *----------------------------------------------------------------*
      * 2130-PRINT-LIST-LINE:                                          *
      *   FORMATS AND DISPLAYS ONE 78-COLUMN TASK SUMMARY LINE.        *
      *----------------------------------------------------------------*
       2130-PRINT-LIST-LINE.
           ADD 1 TO WS-DISPLAY-CNT.
           MOVE TODO-TASK-ID OF WS-MASTER-REC  TO LD-TASK-ID.
           MOVE TODO-STATUS OF WS-MASTER-REC   TO LD-STATUS.
           MOVE TODO-PRIORITY OF WS-MASTER-REC TO LD-PRIORITY.
           IF TODO-NO-DUE-DATE OF WS-MASTER-REC
               MOVE '--------' TO LD-DUE-DATE
           ELSE
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO LD-DUE-DATE.
           MOVE TODO-CATEGORY OF WS-MASTER-REC TO LD-CATEGORY.
           MOVE TODO-TITLE OF WS-MASTER-REC    TO LD-TITLE.
           DISPLAY WS-LIST-DETAIL.

      *----------------------------------------------------------------*
      * 2200-CMD-ADD:                                                  *
      *   VALIDATES NEW TASK, ALLOCATES SEQUENCE ID UNDER ENQ, AND     *
      *   WRITES RECORD TO MASTER KSDS.                                *
      *----------------------------------------------------------------*
       2200-CMD-ADD.
           IF CMD-TARGET-USER NOT = SPACES
               MOVE CMD-TARGET-USER TO WS-TARGET-OWNER
           ELSE
               MOVE CMD-USER-ID TO WS-TARGET-OWNER.
           PERFORM 9200-ENSURE-USER-CONTROL.
           IF WS-APP-RC = 0
               PERFORM 2210-VALIDATE-AND-WRITE-TASK.

      *----------------------------------------------------------------*
      * 2210-VALIDATE-AND-WRITE-TASK:                                  *
      *   POPULATES MASTER RECORD, CALLS TODOVAL, ALLOCATES NEXT ID.   *
      *----------------------------------------------------------------*
       2210-VALIDATE-AND-WRITE-TASK.
           MOVE SPACES          TO WS-MASTER-REC.
           MOVE WS-TARGET-OWNER TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-TARGET-OWNER TO TODO-ALT-OWNER-ID OF WS-MASTER-REC.
           MOVE CMD-TEXT        TO TODO-TITLE OF WS-MASTER-REC.
           MOVE CMD-CATEGORY    TO TODO-CATEGORY OF WS-MASTER-REC.
           MOVE 'O'             TO TODO-STATUS OF WS-MASTER-REC.
           IF CMD-PRIORITY = '0' OR CMD-PRIORITY = SPACES
               MOVE CTRL-DEFAULT-PRI OF WS-CONTROL-REC
                   TO TODO-PRIORITY OF WS-MASTER-REC
           ELSE
               IF CMD-PRIORITY IS NUMERIC
                   MOVE CMD-PRIORITY TO TODO-PRIORITY OF WS-MASTER-REC
               ELSE
                   MOVE 9 TO TODO-PRIORITY OF WS-MASTER-REC.
           IF CMD-DUE-DATE IS NUMERIC
               MOVE CMD-DUE-DATE TO TODO-DUE-DATE OF WS-MASTER-REC
           ELSE
               MOVE 99999999 TO TODO-DUE-DATE OF WS-MASTER-REC.
           MOVE TODO-DUE-DATE OF WS-MASTER-REC
               TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE TODO-PRIORITY OF WS-MASTER-REC
               TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           MOVE WS-TODAY-YYYYMMDD
               TO TODO-CREATED-DATE OF WS-MASTER-REC.
           MOVE CMD-USER-ID     TO TODO-CREATED-BY OF WS-MASTER-REC.
           MOVE ZERO            TO TODO-DONE-DATE OF WS-MASTER-REC.
           MOVE CMD-NOTE        TO TODO-NOTE-LINE-1 OF WS-MASTER-REC.
           MOVE +1              TO TODO-REC-VERSION OF WS-MASTER-REC.

           MOVE 'ALL '          TO VLNK-FUNC-CODE.
           MOVE TODO-STATUS OF WS-MASTER-REC   TO VLNK-STATUS.
           MOVE TODO-PRIORITY OF WS-MASTER-REC TO VLNK-PRIORITY.
           MOVE TODO-DUE-DATE OF WS-MASTER-REC TO VLNK-DATE-FIELD.
           MOVE 'Y'             TO VLNK-ZERO-DATE-OK.
           MOVE WS-TARGET-OWNER TO VLNK-OWNER-ID.
           MOVE CMD-TEXT        TO VLNK-TITLE.
           CALL 'TODOVAL' USING WS-VAL-PARM.
           IF VLNK-HAS-ERROR
               DISPLAY 'TODOCMD: ' VLNK-ERR-MSG
               MOVE 8 TO WS-APP-RC
           ELSE
               PERFORM 2220-COMMIT-NEW-TASK.

      *----------------------------------------------------------------*
      * 2220-COMMIT-NEW-TASK:                                          *
      *   ALLOCATES NEXT SEQUENCE ID AND WRITES NEW MASTER RECORD.     *
      *----------------------------------------------------------------*
       2220-COMMIT-NEW-TASK.
           PERFORM 9300-ALLOC-NEXT-TASK-ID.
           IF WS-APP-RC = 0
               MOVE WS-NEW-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC
               PERFORM 9400-WRITE-MASTER-RECORD.

      *----------------------------------------------------------------*
      * 2300-CMD-VIEW:                                                 *
      *   DISPLAYS FULL DETAILS AND NOTES FOR A SINGLE TASK ID.        *
      *----------------------------------------------------------------*
       2300-CMD-VIEW.
           MOVE CMD-ARG1 TO WS-RAW-ID-TEXT.
           PERFORM 9100-PARSE-TASK-ID.
           IF TASK-ID-IS-INVALID
               DISPLAY 'TODOCMD: INVALID NUMERIC TASK ID'
               MOVE 8 TO WS-APP-RC
           ELSE
               MOVE CMD-USER-ID       TO TODO-OWNER-ID OF WS-MASTER-REC
               MOVE WS-PARSED-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC
               MOVE TODO-PRIMARY-KEY OF WS-MASTER-REC TO FD-MAST-KEY
               READ TODO-MASTER-FILE INTO WS-MASTER-REC
                   INVALID KEY
                       DISPLAY 'TODOCMD: TASK NOT FOUND ID='
                               WS-PARSED-TASK-ID
                       MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0 AND TASK-ID-IS-VALID
               PERFORM 2310-DISPLAY-TASK-DETAIL.

      *----------------------------------------------------------------*
      * 2310-DISPLAY-TASK-DETAIL:                                      *
      *   FORMATS ALL MASTER FIELDS AND 3 NOTE LINES FOR TERMINAL.     *
      *----------------------------------------------------------------*
       2310-DISPLAY-TASK-DETAIL.
           DISPLAY 'TASK ID  : ' TODO-TASK-ID OF WS-MASTER-REC
                   '   OWNER: ' TODO-OWNER-ID OF WS-MASTER-REC
                   '   STATUS: ' TODO-STATUS OF WS-MASTER-REC.
           DISPLAY 'PRIORITY : ' TODO-PRIORITY OF WS-MASTER-REC
                   '          DUE  : ' TODO-DUE-DATE OF WS-MASTER-REC
                   '   CAT   : ' TODO-CATEGORY OF WS-MASTER-REC.
           DISPLAY 'CREATED  : ' TODO-CREATED-DATE OF WS-MASTER-REC
                   '   BY   : ' TODO-CREATED-BY OF WS-MASTER-REC
                   '   DONE  : ' TODO-DONE-DATE OF WS-MASTER-REC.
           DISPLAY 'TITLE    : ' TODO-TITLE OF WS-MASTER-REC.
           DISPLAY 'NOTE 1   : ' TODO-NOTE-LINE-1 OF WS-MASTER-REC.
           DISPLAY 'NOTE 2   : ' TODO-NOTE-LINE-2 OF WS-MASTER-REC.
           DISPLAY 'NOTE 3   : ' TODO-NOTE-LINE-3 OF WS-MASTER-REC.

      *----------------------------------------------------------------*
      * 2400-CMD-STATUS-CHANGE:                                        *
      *   UPDATES TASK STATUS (I, W, C, X) UNDER SYSTEM-WIDE ENQ.      *
      *----------------------------------------------------------------*
       2400-CMD-STATUS-CHANGE.
           MOVE CMD-ARG1 TO WS-RAW-ID-TEXT.
           PERFORM 9100-PARSE-TASK-ID.
           IF TASK-ID-IS-INVALID
               DISPLAY 'TODOCMD: INVALID NUMERIC TASK ID'
               MOVE 8 TO WS-APP-RC
           ELSE
               MOVE CMD-USER-ID TO LLNK-RNAME
               PERFORM 9500-LOCK-RESOURCE
               IF WS-APP-RC = 0
                   PERFORM 2410-REWRITE-TASK-STATUS
                   PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2410-REWRITE-TASK-STATUS:                                      *
      *   READS TASK RECORD AND DISPATCHES STATUS REWRITE.             *
      *----------------------------------------------------------------*
       2410-REWRITE-TASK-STATUS.
           MOVE CMD-USER-ID       TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-PARSED-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC.
           MOVE TODO-PRIMARY-KEY OF WS-MASTER-REC TO FD-MAST-KEY.
           READ TODO-MASTER-FILE INTO WS-MASTER-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: TASK NOT FOUND ID='
                           WS-PARSED-TASK-ID
                   MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0
               PERFORM 2420-APPLY-STATUS-REWRITE.

      *----------------------------------------------------------------*
      * 2420-APPLY-STATUS-REWRITE:                                     *
      *   SETS NEW STATUS, UPDATES DONE-DATE, AND REWRITES VSAM REC.   *
      *----------------------------------------------------------------*
       2420-APPLY-STATUS-REWRITE.
           MOVE WS-NEW-STATUS TO TODO-STATUS OF WS-MASTER-REC.
           IF TODO-IS-CLOSED OF WS-MASTER-REC
               MOVE WS-TODAY-YYYYMMDD
                   TO TODO-DONE-DATE OF WS-MASTER-REC
           ELSE
               MOVE ZERO TO TODO-DONE-DATE OF WS-MASTER-REC.
           ADD +1 TO TODO-REC-VERSION OF WS-MASTER-REC.
           REWRITE FD-MASTER-RECORD FROM WS-MASTER-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: REWRITE ERROR STATUS='
                           WS-MAST-STATUS
                   MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               DISPLAY 'TODOCMD: TASK ' WS-PARSED-TASK-ID
                       ' UPDATED TO STATUS ' WS-NEW-STATUS.

      *----------------------------------------------------------------*
      * 2500-CMD-ASSIGN:                                               *
      *   DELEGATES TASK TO TARGET USER BY ALLOCATING NEW KEY AND      *
      *   DELETING SOURCE KEY UNDER SYSTEM-WIDE ENQ.                   *
      *----------------------------------------------------------------*
       2500-CMD-ASSIGN.
           MOVE CMD-ARG1        TO WS-RAW-ID-TEXT.
           MOVE CMD-TARGET-USER TO WS-TARGET-OWNER.
           PERFORM 9100-PARSE-TASK-ID.
           IF TASK-ID-IS-INVALID
               DISPLAY 'TODOCMD: INVALID NUMERIC TASK ID'
               MOVE 8 TO WS-APP-RC
           ELSE
               MOVE 'ALL '             TO VLNK-FUNC-CODE
               MOVE 'O'                TO VLNK-STATUS
               MOVE 3                  TO VLNK-PRIORITY
               MOVE ZERO               TO VLNK-DATE-FIELD
               MOVE 'Y'                TO VLNK-ZERO-DATE-OK
               MOVE WS-TARGET-OWNER    TO VLNK-OWNER-ID
               MOVE 'DELEGATION CHECK' TO VLNK-TITLE
               CALL 'TODOVAL' USING WS-VAL-PARM
               IF VLNK-HAS-ERROR
                   DISPLAY 'TODOCMD: ' VLNK-ERR-MSG
                   MOVE 8 TO WS-APP-RC
               ELSE
                   PERFORM 2510-EXECUTE-DELEGATION.

      *----------------------------------------------------------------*
      * 2510-EXECUTE-DELEGATION:                                       *
      *   ENSURES TARGET CONTROL RECORD AND SERIALIZES DELEGATION.     *
      *----------------------------------------------------------------*
       2510-EXECUTE-DELEGATION.
           PERFORM 9200-ENSURE-USER-CONTROL.
           IF WS-APP-RC = 0
               MOVE CMD-USER-ID TO LLNK-RNAME
               PERFORM 9500-LOCK-RESOURCE
               IF WS-APP-RC = 0
                   PERFORM 2520-MOVE-TASK-TO-NEW-OWNER
                   PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2520-MOVE-TASK-TO-NEW-OWNER:                                   *
      *   READS SOURCE TASK, WRITES UNDER TARGET KEY, DELETES OLD KEY. *
      *----------------------------------------------------------------*
       2520-MOVE-TASK-TO-NEW-OWNER.
           MOVE CMD-USER-ID       TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-PARSED-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC.
           MOVE TODO-PRIMARY-KEY OF WS-MASTER-REC TO FD-MAST-KEY.
           READ TODO-MASTER-FILE INTO WS-MASTER-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: SOURCE TASK NOT FOUND'
                   MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0
               PERFORM 9300-ALLOC-NEXT-TASK-ID.
           IF WS-APP-RC = 0
               MOVE WS-MASTER-REC TO WS-TEMP-MASTER-REC
               MOVE WS-TARGET-OWNER
                   TO TODO-OWNER-ID OF WS-TEMP-MASTER-REC
               MOVE WS-TARGET-OWNER
                   TO TODO-ALT-OWNER-ID OF WS-TEMP-MASTER-REC
               MOVE WS-NEW-TASK-ID
                   TO TODO-TASK-ID OF WS-TEMP-MASTER-REC
               MOVE +1
                   TO TODO-REC-VERSION OF WS-TEMP-MASTER-REC
               WRITE FD-MASTER-RECORD FROM WS-TEMP-MASTER-REC
                   INVALID KEY
                       DISPLAY 'TODOCMD: DELEGATE WRITE ERR='
                               WS-MAST-STATUS
                       MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               DELETE TODO-MASTER-FILE RECORD
                   INVALID KEY
                       DISPLAY 'TODOCMD: DELEGATE DEL ERR='
                               WS-MAST-STATUS
                       MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               DISPLAY 'TODOCMD: TASK ASSIGNED TO '
                       WS-TARGET-OWNER ' AS ID ' WS-NEW-TASK-ID.

      *----------------------------------------------------------------*
      * 2600-CMD-NOTE:                                                 *
      *   UPDATES NOTE LINE 1, 2, OR 3 ON AN EXISTING TASK.            *
      *----------------------------------------------------------------*
       2600-CMD-NOTE.
           MOVE CMD-ARG1 TO WS-RAW-ID-TEXT.
           PERFORM 9100-PARSE-TASK-ID.
           IF TASK-ID-IS-INVALID
               DISPLAY 'TODOCMD: INVALID NUMERIC TASK ID'
               MOVE 8 TO WS-APP-RC
           ELSE
               IF CMD-LINE-NUM NOT = '1'
                  AND CMD-LINE-NUM NOT = '2'
                  AND CMD-LINE-NUM NOT = '3'
                   DISPLAY 'TODOCMD: LINE MUST BE 1, 2, OR 3'
                   MOVE 8 TO WS-APP-RC
               ELSE
                   MOVE CMD-USER-ID TO LLNK-RNAME
                   PERFORM 9500-LOCK-RESOURCE
                   IF WS-APP-RC = 0
                       PERFORM 2610-REWRITE-NOTE-LINE
                       PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2610-REWRITE-NOTE-LINE:                                        *
      *   READS TASK RECORD AND DISPATCHES NOTE LINE REWRITE.          *
      *----------------------------------------------------------------*
       2610-REWRITE-NOTE-LINE.
           MOVE CMD-USER-ID       TO TODO-OWNER-ID OF WS-MASTER-REC.
           MOVE WS-PARSED-TASK-ID TO TODO-TASK-ID OF WS-MASTER-REC.
           MOVE TODO-PRIMARY-KEY OF WS-MASTER-REC TO FD-MAST-KEY.
           READ TODO-MASTER-FILE INTO WS-MASTER-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: TASK NOT FOUND ID='
                           WS-PARSED-TASK-ID
                   MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0
               PERFORM 2620-APPLY-NOTE-REWRITE.

      *----------------------------------------------------------------*
      * 2620-APPLY-NOTE-REWRITE:                                       *
      *   MOVES NEW TEXT TO SELECTED NOTE LINE AND REWRITES RECORD.    *
      *----------------------------------------------------------------*
       2620-APPLY-NOTE-REWRITE.
           IF CMD-LINE-NUM = '1'
               MOVE CMD-NOTE TO TODO-NOTE-LINE-1 OF WS-MASTER-REC
           ELSE
               IF CMD-LINE-NUM = '2'
                   MOVE CMD-NOTE TO TODO-NOTE-LINE-2 OF WS-MASTER-REC
               ELSE
                   MOVE CMD-NOTE TO TODO-NOTE-LINE-3 OF WS-MASTER-REC.
           ADD +1 TO TODO-REC-VERSION OF WS-MASTER-REC.
           REWRITE FD-MASTER-RECORD FROM WS-MASTER-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: NOTE REWRITE ERR='
                           WS-MAST-STATUS
                   MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               DISPLAY 'TODOCMD: NOTE LINE ' CMD-LINE-NUM
                       ' UPDATED FOR TASK ' WS-PARSED-TASK-ID.

      *----------------------------------------------------------------*
      * 2700-CMD-PRINT:                                                *
      *   UPDATES USER CONTROL PREFERENCES (PRINT ON/OFF, NAME, PRI).  *
      *----------------------------------------------------------------*
       2700-CMD-PRINT.
           MOVE CMD-USER-ID TO WS-TARGET-OWNER.
           PERFORM 9200-ENSURE-USER-CONTROL.
           IF WS-APP-RC = 0
               MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME
               PERFORM 9500-LOCK-RESOURCE
               IF WS-APP-RC = 0
                   PERFORM 2705-READ-AND-UPDATE-CTRL
                   PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2705-READ-AND-UPDATE-CTRL:                                     *
      *   READS CONTROL RECORD AND CALLS PREFERENCE UPDATE ROUTINE.    *
      *----------------------------------------------------------------*
       2705-READ-AND-UPDATE-CTRL.
           MOVE CMD-USER-ID TO FD-CTRL-KEY.
           READ TODO-CTRL-FILE INTO WS-CONTROL-REC
               INVALID KEY
                   MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               PERFORM 2710-APPLY-PRINT-PREFS.

      *----------------------------------------------------------------*
      * 2710-APPLY-PRINT-PREFS:                                        *
      *   APPLIES ON/OFF, DISPLAY NAME, AND DEFAULT PRIORITY CHANGES.  *
      *----------------------------------------------------------------*
       2710-APPLY-PRINT-PREFS.
           IF CMD-ARG1 = 'ON              '
               MOVE 'Y' TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
           ELSE
               IF CMD-ARG1 = 'OFF             '
                   MOVE 'N' TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
               ELSE
                   IF CMD-ARG1 NOT = SPACES
                       DISPLAY 'TODOCMD: USE PRINT ON OR PRINT OFF'
                       MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0 AND CMD-TEXT NOT = SPACES
               MOVE CMD-TEXT TO CTRL-USER-NAME OF WS-CONTROL-REC.
           IF WS-APP-RC = 0
              AND CMD-PRIORITY NOT = '0'
              AND CMD-PRIORITY NOT = SPACES
               IF CMD-PRIORITY IS NUMERIC
                  AND CMD-PRIORITY >= '1'
                  AND CMD-PRIORITY <= '5'
                   MOVE CMD-PRIORITY
                       TO CTRL-DEFAULT-PRI OF WS-CONTROL-REC
               ELSE
                   DISPLAY 'TODOCMD: PRI MUST BE 1 THROUGH 5'
                   MOVE 8 TO WS-APP-RC.
           IF WS-APP-RC = 0
               REWRITE FD-CTRL-RECORD FROM WS-CONTROL-REC
                   INVALID KEY
                       DISPLAY 'TODOCMD: CTRL REWRITE ERR='
                               WS-CTRL-STATUS
                       MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               DISPLAY 'TODOCMD: PREFS SAVED PRINT='
                       CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
                       ' PRI=' CTRL-DEFAULT-PRI OF WS-CONTROL-REC.

      *----------------------------------------------------------------*
      * 3000-TERMINATE:                                                *
      *   CLOSES ALL OPEN FILES AND ASSIGNS FINAL RETURN-CODE.         *
      *----------------------------------------------------------------*
       3000-TERMINATE.
           IF FILES-ARE-OPEN
               CLOSE CMD-IN-FILE
                     TODO-MASTER-FILE
                     TODO-PATH-FILE
                     TODO-CTRL-FILE.
           MOVE WS-APP-RC TO RETURN-CODE.

      *----------------------------------------------------------------*
      * 9100-PARSE-TASK-ID:                                            *
      *   RIGHT-JUSTIFIES AND ZERO-PADS UNPADDED NUMERIC TASK IDS.     *
      *----------------------------------------------------------------*
       9100-PARSE-TASK-ID.
           MOVE 'Y'  TO WS-ID-VALID-SW.
           MOVE ZERO TO WS-PARSED-TASK-ID.
           MOVE 8    TO WS-OUT-IDX.
           PERFORM 9110-SCAN-ID-CHAR
               VARYING WS-IDX FROM 16 BY -1
               UNTIL WS-IDX < 1 OR TASK-ID-IS-INVALID.
           IF WS-PARSED-TASK-ID = ZERO
               MOVE 'N' TO WS-ID-VALID-SW.

      *----------------------------------------------------------------*
      * 9110-SCAN-ID-CHAR:                                             *
      *   INSPECTS ONE CHARACTER RIGHT-TO-LEFT FOR DIGIT EXTRACTION.   *
      *----------------------------------------------------------------*
       9110-SCAN-ID-CHAR.
           IF WS-RAW-CH (WS-IDX) = SPACES
               NEXT SENTENCE
           ELSE
               IF WS-RAW-CH (WS-IDX) IS NUMERIC AND WS-OUT-IDX >= 1
                   MOVE WS-RAW-CH (WS-IDX) TO WS-NUM-CH (WS-OUT-IDX)
                   SUBTRACT 1 FROM WS-OUT-IDX
               ELSE
                   MOVE 'N' TO WS-ID-VALID-SW.

      *----------------------------------------------------------------*
      * 9200-ENSURE-USER-CONTROL:                                      *
      *   CREATES A DEFAULT TODOCTRL RECORD IF USER IS NEW TO SYSTEM.  *
      *----------------------------------------------------------------*
       9200-ENSURE-USER-CONTROL.
           MOVE WS-TARGET-OWNER TO FD-CTRL-KEY.
           READ TODO-CTRL-FILE INTO WS-CONTROL-REC
               INVALID KEY
                   PERFORM 9210-CREATE-USER-CONTROL.

      *----------------------------------------------------------------*
      * 9210-CREATE-USER-CONTROL:                                      *
      *   WRITES INITIAL CONTROL RECORD FOR TARGET USER UNDER ENQ.     *
      *----------------------------------------------------------------*
       9210-CREATE-USER-CONTROL.
           MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF WS-APP-RC = 0
               MOVE SPACES           TO WS-CONTROL-REC
               MOVE WS-TARGET-OWNER  TO CTRL-USER-ID OF WS-CONTROL-REC
               MOVE ZERO
                   TO CTRL-LAST-TASK-ID OF WS-CONTROL-REC
               MOVE 'Y'
                   TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
               MOVE WS-DEFAULT-PRI
                   TO CTRL-DEFAULT-PRI OF WS-CONTROL-REC
               MOVE WS-TARGET-OWNER  TO CTRL-USER-NAME OF WS-CONTROL-REC
               MOVE +0
                   TO CTRL-ACTIVE-COUNT OF WS-CONTROL-REC
               MOVE WS-TODAY-YYYYMMDD
                   TO CTRL-LAST-LOGIN-DATE OF WS-CONTROL-REC
               WRITE FD-CTRL-RECORD FROM WS-CONTROL-REC
                   INVALID KEY
                       PERFORM 9220-READ-EXISTING-CTRL.
           IF LOCK-IS-HELD
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 9220-READ-EXISTING-CTRL:                                       *
      *   RECOVERS EXISTING CONTROL RECORD ON CONCURRENT INSERT RACE.  *
      *----------------------------------------------------------------*
       9220-READ-EXISTING-CTRL.
           READ TODO-CTRL-FILE INTO WS-CONTROL-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: CTRL INIT ERROR=' WS-CTRL-STATUS
                   MOVE 16 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 9300-ALLOC-NEXT-TASK-ID:                                       *
      *   INCREMENTS CTRL-LAST-TASK-ID UNDER SYSTEM-WIDE ENQ.          *
      *----------------------------------------------------------------*
       9300-ALLOC-NEXT-TASK-ID.
           MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF WS-APP-RC = 0
               PERFORM 9310-INCREMENT-CTRL-COUNTER
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 9310-INCREMENT-CTRL-COUNTER:                                   *
      *   READS USER CONTROL RECORD, INCREMENTS SEQUENCE ID, REWRITES. *
      *----------------------------------------------------------------*
       9310-INCREMENT-CTRL-COUNTER.
           MOVE WS-TARGET-OWNER TO FD-CTRL-KEY.
           READ TODO-CTRL-FILE INTO WS-CONTROL-REC
               INVALID KEY
                   DISPLAY 'TODOCMD: CTRL MISSING FOR '
                           WS-TARGET-OWNER
                   MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               ADD 1 TO CTRL-LAST-TASK-ID OF WS-CONTROL-REC
               MOVE CTRL-LAST-TASK-ID OF WS-CONTROL-REC
                   TO WS-NEW-TASK-ID
               MOVE WS-TODAY-YYYYMMDD
                   TO CTRL-LAST-LOGIN-DATE OF WS-CONTROL-REC
               REWRITE FD-CTRL-RECORD FROM WS-CONTROL-REC
                   INVALID KEY
                       DISPLAY 'TODOCMD: CTRL REWRITE ERR='
                               WS-CTRL-STATUS
                       MOVE 16 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 9400-WRITE-MASTER-RECORD:                                      *
      *   INSERTS NEW TASK INTO TODO.MASTER.CLUSTER UNDER OWNER ENQ.   *
      *----------------------------------------------------------------*
       9400-WRITE-MASTER-RECORD.
           MOVE WS-TARGET-OWNER TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF WS-APP-RC = 0
               WRITE FD-MASTER-RECORD FROM WS-MASTER-REC
                   INVALID KEY
                       DISPLAY 'TODOCMD: MASTER WRITE ERR='
                               WS-MAST-STATUS
                       MOVE 16 TO WS-APP-RC.
           IF LOCK-IS-HELD
               PERFORM 9600-UNLOCK-RESOURCE.
           IF WS-APP-RC = 0
               DISPLAY 'TODOCMD: ADDED TASK ' WS-NEW-TASK-ID
                       ' FOR ' WS-TARGET-OWNER.

      *----------------------------------------------------------------*
      * 9500-LOCK-RESOURCE:                                            *
      *   INVOKES TODOLOCK FOR SYSTEM-WIDE MVS ENQ SERIALIZATION.      *
      *----------------------------------------------------------------*
       9500-LOCK-RESOURCE.
           MOVE 'ENQ ' TO LLNK-ACTION.
           MOVE +0     TO LLNK-RC.
           CALL 'TODOLOCK' USING WS-LOCK-PARM.
           IF LLNK-OK
               MOVE 'Y' TO WS-LOCK-HELD-SW
           ELSE
               DISPLAY 'TODOCMD: ENQ FAILED RC=' LLNK-RC
               MOVE 16 TO WS-APP-RC.

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
			   