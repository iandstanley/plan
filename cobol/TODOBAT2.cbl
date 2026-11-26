IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOBAT2.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOBAT2                                         *
      * TITLE       : TODO MANAGER DAILY ACTION SHEET PRINT GENERATOR  *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : NIGHTLY BATCH (IKFCBL00)                         *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   GENERATES DAILY ACTION SHEETS ON SYSOUT (RECFM=FBA,LRECL=133)*
      *   FOR SUBSCRIBED USERS USING SUBSCRIPTION MODEL C:             *
      *   - IF PRTLIST CONTAINS EXPLICIT USERIDS, PRINTS ONLY THOSE.   *
      *   - OTHERWISE SCANS TODO.CONTROL.CLUSTER FOR PRINT-SW = 'Y'.   *
      *   SEPARATES USERS WITH ASA '1' FORM-FEEDS AND USER BANNERS,    *
      *   AND PRINTS 'NO OPEN TASKS TODAY' WHEN A USER QUEUE IS EMPTY. *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. INITIALIZATION (1000-INITIALIZE): OPENS CONTROL, PATH,    *
      *      PRTLIST, AND RPTOUT; INSPECTS PRTLIST FOR OVERRIDE USERS. *
      *   2. MAIN PROCESSING (2000-GENERATE-SHEETS): ITERATES OVER     *
      *      OVERRIDE LIST OR CONTROL CLUSTER AND PRINTS EACH USER'S   *
      *      BANNER AND ACTIVE TASKS IN DUE-DATE / PRIORITY ORDER.     *
      *   3. TERMINATION (3000-TERMINATE): CLOSES FILES AND SETS RC.   *
      *                                                                *
      * USAGE / JCL INTERFACE:                                         *
      *   DDNAME    ORG    RECFM/LRECL  I/O     DESCRIPTION            *
      *   --------  -----  -----------  ------  ---------------------- *
      *   TODOCTRL  VSAM   KSDS / 64    INPUT   USER CONTROL CLUSTER   *
      *   TODOPATH  VSAM   PATH / 332   INPUT   AIX1 DUE/PRI BROWSE    *
      *   PRTLIST   QSAM   FB / 80      INPUT   OPTIONAL USER OVERRIDE *
      *   RPTOUT    SYSOUT FBA / 133    OUTPUT  DAILY ACTION SHEETS    *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOREC  (IN TODO.COPYLIB) : 332-BYTE MASTER TASK RECORD   *
      *   - TODOCTRL (IN TODO.COPYLIB) : 64-BYTE USER CONTROL RECORD   *
      *                                                                *
      * RETURN CODES:                                                  *
      *   00 - ACTION SHEETS GENERATED SUCCESSFULLY                    *
      *   04 - ZERO USERS SUBSCRIBED / NO SHEETS PRINTED               *
      *   16 - SEVERE FILE OPEN OR I/O ERROR                           *
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
           SELECT TODO-CTRL-FILE   ASSIGN TO TODOCTRL
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS DYNAMIC
                                   RECORD KEY IS FD-CTRL-KEY
                                   FILE STATUS IS WS-CTRL-STATUS.
           SELECT TODO-PATH-FILE   ASSIGN TO TODOPATH
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS DYNAMIC
                                   RECORD KEY IS FD-PATH-KEY
                                   ALTERNATE RECORD KEY IS FD-PATH-ALT
                                       WITH DUPLICATES
                                   FILE STATUS IS WS-PATH-STATUS.
           SELECT PRTLIST-IN-FILE  ASSIGN TO UT-S-PRTLIST
                                   FILE STATUS IS WS-LIST-STATUS.
           SELECT ACTION-RPT-FILE  ASSIGN TO UR-S-RPTOUT.

       DATA DIVISION.
       FILE SECTION.
       FD  TODO-CTRL-FILE
           RECORD CONTAINS 64 CHARACTERS.
       01  FD-CTRL-RECORD.
           05  FD-CTRL-KEY             PIC X(08).
           05  FD-CTRL-REST            PIC X(56).

       FD  TODO-PATH-FILE
           RECORD CONTAINS 332 CHARACTERS.
       01  FD-PATH-RECORD.
           05  FD-PATH-KEY             PIC X(16).
           05  FD-PATH-ALT             PIC X(17).
           05  FD-PATH-REST            PIC X(299).

       FD  PRTLIST-IN-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS.
       01  PRTLIST-IN-RECORD.
           05  PL-CARD-COL1            PIC X(01).
               88  PL-IS-COMMENT             VALUE '*'.
           05  PL-CARD-REST            PIC X(79).

       FD  ACTION-RPT-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE OMITTED
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 133 CHARACTERS.
       01  ACTION-RPT-RECORD           PIC X(133).

       WORKING-STORAGE SECTION.
       77  WS-SENTINEL-USER            PIC X(08) VALUE '00000000'.
       77  WS-CENTURY-19               PIC 9(02) VALUE 19.
       77  WS-CENTURY-20               PIC 9(02) VALUE 20.
       77  WS-Y2K-PIVOT                PIC 9(02) VALUE 79.
       77  WS-MAX-OVERRIDE-USERS       PIC S9(04) COMP SYNC VALUE +100.

       01  WS-FILE-STATUS-AREA.
           05  WS-CTRL-STATUS          PIC X(02) VALUE SPACES.
               88  CTRL-IO-OK                    VALUE '00'.
               88  CTRL-IO-EOF                   VALUE '10'.
               88  CTRL-IO-NOT-FOUND             VALUE '23'.
           05  WS-PATH-STATUS          PIC X(02) VALUE SPACES.
               88  PATH-IO-OK                    VALUE '00' '02'.
               88  PATH-IO-EOF                   VALUE '10'.
           05  WS-LIST-STATUS          PIC X(02) VALUE SPACES.
               88  LIST-IO-OK                    VALUE '00'.
               88  LIST-IO-EOF                   VALUE '10'.

       01  WS-CONTROL-FLAGS.
           05  WS-APP-RC               PIC S9(04) COMP SYNC VALUE +0.
           05  WS-FILES-OPEN-SW        PIC X(01) VALUE 'N'.
               88  FILES-ARE-OPEN                VALUE 'Y'.
               88  FILES-ARE-CLOSED              VALUE 'N'.
           05  WS-LIST-EOF-SW          PIC X(01) VALUE 'N'.
               88  END-OF-PRTLIST                VALUE 'Y'.
               88  MORE-PRTLIST-CARDS            VALUE 'N'.
           05  WS-CTRL-EOF-SW          PIC X(01) VALUE 'N'.
               88  END-OF-CONTROL                VALUE 'Y'.
               88  MORE-CONTROL-RECORDS          VALUE 'N'.
           05  WS-TASK-EOF-SW          PIC X(01) VALUE 'N'.
               88  END-OF-USER-TASKS             VALUE 'Y'.
               88  MORE-USER-TASKS               VALUE 'N'.
           05  WS-OVERRIDE-MODE-SW     PIC X(01) VALUE 'N'.
               88  USING-OVERRIDE-LIST           VALUE 'Y'.
               88  USING-CONTROL-FLAGS           VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-OVERRIDE-CNT         PIC S9(04) COMP SYNC VALUE +0.
           05  WS-IDX                  PIC S9(04) COMP SYNC VALUE +0.
           05  WS-LINE-CNT             PIC S9(03) COMP SYNC VALUE +99.
           05  WS-MAX-LINES            PIC S9(03) COMP SYNC VALUE +54.
           05  WS-USER-PAGE-NO         PIC S9(05) COMP-3 VALUE ZERO.
           05  WS-USER-TASK-CNT        PIC S9(05) COMP-3 VALUE ZERO.
           05  WS-TOTAL-USERS-PRT      PIC S9(05) COMP-3 VALUE ZERO.

       01  WS-OVERRIDE-TABLE.
           05  WS-OVR-USER-ID          PIC X(08) OCCURS 100 TIMES.

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

       01  WS-ACTIVE-USER-INFO.
           05  WS-CUR-USER-ID          PIC X(08) VALUE SPACES.
           05  WS-CUR-USER-NAME        PIC X(24) VALUE SPACES.

       01  WS-MASTER-REC.
           COPY TODOREC.

       01  WS-CONTROL-REC.
           COPY TODOCTRL.

       01  WS-BANNER-LINE-1.
           05  FILLER                  PIC X(01) VALUE '1'.
           05  FILLER                  PIC X(132) VALUE ALL '='.

       01  WS-BANNER-LINE-2.
           05  FILLER                  PIC X(01) VALUE ' '.
           05  FILLER                  PIC X(26) VALUE
               'DAILY ACTION SHEET - USER:'.
           05  FILLER                  PIC X(01) VALUE SPACES.
           05  BL2-USER-ID             PIC X(08) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE ' ( '.
           05  BL2-USER-NAME           PIC X(24) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE ' ) '.
           05  FILLER                  PIC X(38) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'DATE: '.
           05  BL2-RUN-DATE            PIC 9(08) VALUE ZERO.
           05  FILLER                  PIC X(03) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'PAGE: '.
           05  BL2-PAGE-NO             PIC ZZZZ9.

       01  WS-BANNER-LINE-3.
           05  FILLER                  PIC X(01) VALUE ' '.
           05  FILLER                  PIC X(132) VALUE ALL '='.

       01  WS-COL-HEADER-1.
           05  FILLER                  PIC X(01) VALUE '0'.
           05  FILLER                  PIC X(04) VALUE 'DONE'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE 'TASK ID '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'STATUS'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE 'PRI'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE 'DUE DATE'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE 'CATEGORY  '.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(60) VALUE
               'TASK DESCRIPTION                                            '.
           05  FILLER                  PIC X(21) VALUE SPACES.

       01  WS-COL-HEADER-2.
           05  FILLER                  PIC X(01) VALUE ' '.
           05  FILLER                  PIC X(04) VALUE '----'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '--------'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE '------'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE '---'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(08) VALUE '--------'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(10) VALUE '----------'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  FILLER                  PIC X(60) VALUE ALL '-'.
           05  FILLER                  PIC X(21) VALUE SPACES.

       01  WS-TASK-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE ' '.
           05  FILLER                  PIC X(04) VALUE '[  ]'.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  TD-TASK-ID              PIC 9(08) VALUE ZERO.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  TD-STATUS-TEXT          PIC X(06) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  TD-PRIORITY             PIC 9(01) VALUE ZERO.
           05  FILLER                  PIC X(04) VALUE SPACES.
           05  TD-DUE-DATE             PIC X(08) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  TD-CATEGORY             PIC X(10) VALUE SPACES.
           05  FILLER                  PIC X(02) VALUE SPACES.
           05  TD-TITLE                PIC X(60) VALUE SPACES.
           05  FILLER                  PIC X(21) VALUE SPACES.

       01  WS-NOTE-DETAIL-LINE.
           05  FILLER                  PIC X(01) VALUE ' '.
           05  FILLER                  PIC X(51) VALUE SPACES.
           05  FILLER                  PIC X(06) VALUE 'NOTE: '.
           05  ND-NOTE-TEXT            PIC X(60) VALUE SPACES.
           05  FILLER                  PIC X(15) VALUE SPACES.

       01  WS-EMPTY-QUEUE-LINE.
           05  FILLER                  PIC X(01) VALUE '-'.
           05  FILLER                  PIC X(20) VALUE SPACES.
           05  FILLER                  PIC X(30) VALUE
               '*** NO OPEN TASKS TODAY ***   '.
           05  FILLER                  PIC X(82) VALUE SPACES.

       01  WS-USER-FOOTER-LINE.
           05  FILLER                  PIC X(01) VALUE '0'.
           05  FILLER                  PIC X(25) VALUE
               'TOTAL ACTIVE TASKS FOR   '.
           05  UF-USER-ID              PIC X(08) VALUE SPACES.
           05  FILLER                  PIC X(03) VALUE ' : '.
           05  UF-TASK-CNT             PIC ZZZZ9.
           05  FILLER                  PIC X(91) VALUE SPACES.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * 0000-MAIN-CONTROL:                                             *
      *   EXECUTIVE DRIVER INITIALIZING FILES, LOADING OVERRIDE LIST,  *
      *   GENERATING PER-USER ACTION SHEETS, AND TERMINATING CLEANLY.  *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE.
           IF WS-APP-RC = 0
               PERFORM 2000-GENERATE-SHEETS.
           PERFORM 3000-TERMINATE.
           GOBACK.

      *----------------------------------------------------------------*
      * 1000-INITIALIZE:                                               *
      *   COMPUTES RUN DATE, OPENS ALL DATASETS, AND READS PRTLIST     *
      *   OVERRIDE CARDS IF PRESENT.                                   *
      *----------------------------------------------------------------*
       1000-INITIALIZE.
           PERFORM 1100-GET-SYSTEM-DATE.
           OPEN INPUT  TODO-CTRL-FILE
                       TODO-PATH-FILE
                       PRTLIST-IN-FILE
                OUTPUT ACTION-RPT-FILE.
           IF NOT CTRL-IO-OK OR NOT PATH-IO-OK OR NOT LIST-IO-OK
               DISPLAY 'TODOBAT2: OPEN ERROR CTRL=' WS-CTRL-STATUS
                       ' PATH=' WS-PATH-STATUS
                       ' LIST=' WS-LIST-STATUS
               MOVE 16 TO WS-APP-RC
           ELSE
               MOVE 'Y' TO WS-FILES-OPEN-SW
               PERFORM 1200-LOAD-OVERRIDE-LIST.

      *----------------------------------------------------------------*
      * 1100-GET-SYSTEM-DATE:                                          *
      *   CONVERTS 6-DIGIT SYSTEM DATE TO 8-DIGIT YYYYMMDD FORMAT.     *
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
      * 1200-LOAD-OVERRIDE-LIST:                                       *
      *   READS PRTLIST FOR EXPLICIT USERIDS (SUBSCRIPTION MODEL C).   *
      *----------------------------------------------------------------*
       1200-LOAD-OVERRIDE-LIST.
           MOVE 'N' TO WS-LIST-EOF-SW.
           MOVE +0  TO WS-OVERRIDE-CNT.
           PERFORM 9100-READ-PRTLIST.
           PERFORM 1210-STORE-OVERRIDE-CARD
               UNTIL END-OF-PRTLIST
                  OR WS-OVERRIDE-CNT >= WS-MAX-OVERRIDE-USERS.
           IF WS-OVERRIDE-CNT > +0
               MOVE 'Y' TO WS-OVERRIDE-MODE-SW
           ELSE
               MOVE 'N' TO WS-OVERRIDE-MODE-SW.

      *----------------------------------------------------------------*
      * 1210-STORE-OVERRIDE-CARD:                                      *
      *   IGNORES '*' COMMENTS & BLANKS; STORES VALID USERID IN TABLE. *
      *----------------------------------------------------------------*
       1210-STORE-OVERRIDE-CARD.
           IF NOT PL-IS-COMMENT AND PRTLIST-IN-RECORD NOT = SPACES
               ADD +1 TO WS-OVERRIDE-CNT
               MOVE PRTLIST-IN-RECORD
                   TO WS-OVR-USER-ID (WS-OVERRIDE-CNT).
           PERFORM 9100-READ-PRTLIST.

      *----------------------------------------------------------------*
      * 2000-GENERATE-SHEETS:                                          *
      *   ROUTES TO EXPLICIT OVERRIDE TABLE OR CONTROL CLUSTER SCAN.   *
      *----------------------------------------------------------------*
       2000-GENERATE-SHEETS.
           IF USING-OVERRIDE-LIST
               PERFORM 2100-PROCESS-OVERRIDE-USERS
                   VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-OVERRIDE-CNT
           ELSE
               PERFORM 2200-PROCESS-SUBSCRIBED-USERS.

      *----------------------------------------------------------------*
      * 2100-PROCESS-OVERRIDE-USERS:                                   *
      *   LOOKS UP CONTROL INFO FOR EXPLICIT USER AND PRINTS SHEET.    *
      *----------------------------------------------------------------*
       2100-PROCESS-OVERRIDE-USERS.
           MOVE WS-OVR-USER-ID (WS-IDX) TO WS-CUR-USER-ID.
           MOVE WS-CUR-USER-ID          TO FD-CTRL-KEY.
           READ TODO-CTRL-FILE INTO WS-CONTROL-REC
               INVALID KEY
                   MOVE WS-CUR-USER-ID TO WS-CUR-USER-NAME.
           IF CTRL-IO-OK
               MOVE CTRL-USER-NAME OF WS-CONTROL-REC
                   TO WS-CUR-USER-NAME.
           PERFORM 2300-PRINT-USER-ACTION-SHEET.

      *----------------------------------------------------------------*
      * 2200-PROCESS-SUBSCRIBED-USERS:                                 *
      *   SCANS TODO.CONTROL.CLUSTER FOR USERS WITH PRINT-SW = 'Y'.    *
      *----------------------------------------------------------------*
       2200-PROCESS-SUBSCRIBED-USERS.
           MOVE 'N' TO WS-CTRL-EOF-SW.
           PERFORM 9200-READ-NEXT-CONTROL.
           PERFORM 2210-EVALUATE-CONTROL-USER
               UNTIL END-OF-CONTROL OR WS-APP-RC NOT = 0.

      *----------------------------------------------------------------*
      * 2210-EVALUATE-CONTROL-USER:                                    *
      *   PRINTS SHEET IF USER IS NOT SENTINEL AND PRINT-SW = 'Y'.     *
      *----------------------------------------------------------------*
       2210-EVALUATE-CONTROL-USER.
           IF CTRL-USER-ID OF WS-CONTROL-REC NOT = WS-SENTINEL-USER
              AND CTRL-PRINT-YES OF WS-CONTROL-REC
               MOVE CTRL-USER-ID OF WS-CONTROL-REC   TO WS-CUR-USER-ID
               MOVE CTRL-USER-NAME OF WS-CONTROL-REC TO WS-CUR-USER-NAME
               PERFORM 2300-PRINT-USER-ACTION-SHEET.
           PERFORM 9200-READ-NEXT-CONTROL.

      *----------------------------------------------------------------*
      * 2300-PRINT-USER-ACTION-SHEET:                                  *
      *   POSITIONS ON AIX1 PATH FOR CURRENT USER, PRINTS BANNER AND   *
      *   ACTIVE TASKS OR 'NO OPEN TASKS TODAY' MESSAGE.               *
      *----------------------------------------------------------------*
       2300-PRINT-USER-ACTION-SHEET.
           ADD 1 TO WS-TOTAL-USERS-PRT.
           MOVE ZERO TO WS-USER-PAGE-NO.
           MOVE ZERO TO WS-USER-TASK-CNT.
           PERFORM 8100-PRINT-USER-BANNER.

           MOVE LOW-VALUES     TO WS-MASTER-REC.
           MOVE WS-CUR-USER-ID TO TODO-ALT-OWNER-ID OF WS-MASTER-REC.
           MOVE ZERO           TO TODO-ALT-DUE-DATE OF WS-MASTER-REC.
           MOVE ZERO           TO TODO-ALT-PRIORITY OF WS-MASTER-REC.
           MOVE TODO-ALT-KEY OF WS-MASTER-REC TO FD-PATH-ALT.
           MOVE 'N' TO WS-TASK-EOF-SW.
           START TODO-PATH-FILE KEY IS NOT LESS THAN FD-PATH-ALT
               INVALID KEY
                   MOVE 'Y' TO WS-TASK-EOF-SW.
           PERFORM 2310-READ-AND-PRINT-TASK
               UNTIL END-OF-USER-TASKS.

           IF WS-USER-TASK-CNT = ZERO
               WRITE ACTION-RPT-RECORD FROM WS-EMPTY-QUEUE-LINE
           ELSE
               MOVE WS-CUR-USER-ID   TO UF-USER-ID
               MOVE WS-USER-TASK-CNT TO UF-TASK-CNT
               WRITE ACTION-RPT-RECORD FROM WS-USER-FOOTER-LINE.

      *----------------------------------------------------------------*
      * 2310-READ-AND-PRINT-TASK:                                      *
      *   READS NEXT AIX1 RECORD FOR USER AND PRINTS IF ACTIVE.        *
      *----------------------------------------------------------------*
       2310-READ-AND-PRINT-TASK.
           READ TODO-PATH-FILE NEXT RECORD INTO WS-MASTER-REC
               AT END
                   MOVE 'Y' TO WS-TASK-EOF-SW.
           IF NOT END-OF-USER-TASKS
               IF TODO-OWNER-ID OF WS-MASTER-REC NOT = WS-CUR-USER-ID
                   MOVE 'Y' TO WS-TASK-EOF-SW
               ELSE
                   IF TODO-IS-ACTIVE OF WS-MASTER-REC
                       PERFORM 2320-FORMAT-TASK-LINES.

      *----------------------------------------------------------------*
      * 2320-FORMAT-TASK-LINES:                                        *
      *   PRINTS TASK SUMMARY LINE AND ANY POPULATED NOTE LINES.       *
      *----------------------------------------------------------------*
       2320-FORMAT-TASK-LINES.
           IF WS-LINE-CNT > WS-MAX-LINES
               PERFORM 8100-PRINT-USER-BANNER.
           ADD 1 TO WS-USER-TASK-CNT.
           MOVE TODO-TASK-ID OF WS-MASTER-REC  TO TD-TASK-ID.
           IF TODO-STAT-OPEN OF WS-MASTER-REC
               MOVE 'OPEN  ' TO TD-STATUS-TEXT
           ELSE
               IF TODO-STAT-INPROG OF WS-MASTER-REC
                   MOVE 'INPROG' TO TD-STATUS-TEXT
               ELSE
                   MOVE 'WAIT  ' TO TD-STATUS-TEXT.
           MOVE TODO-PRIORITY OF WS-MASTER-REC TO TD-PRIORITY.
           IF TODO-NO-DUE-DATE OF WS-MASTER-REC
               MOVE 'NONE    ' TO TD-DUE-DATE
           ELSE
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO TD-DUE-DATE.
           MOVE TODO-CATEGORY OF WS-MASTER-REC TO TD-CATEGORY.
           MOVE TODO-TITLE OF WS-MASTER-REC    TO TD-TITLE.
           WRITE ACTION-RPT-RECORD FROM WS-TASK-DETAIL-LINE.
           ADD 1 TO WS-LINE-CNT.

           IF TODO-NOTE-LINE-1 OF WS-MASTER-REC NOT = SPACES
               MOVE TODO-NOTE-LINE-1 OF WS-MASTER-REC TO ND-NOTE-TEXT
               WRITE ACTION-RPT-RECORD FROM WS-NOTE-DETAIL-LINE
               ADD 1 TO WS-LINE-CNT.
           IF TODO-NOTE-LINE-2 OF WS-MASTER-REC NOT = SPACES
               MOVE TODO-NOTE-LINE-2 OF WS-MASTER-REC TO ND-NOTE-TEXT
               WRITE ACTION-RPT-RECORD FROM WS-NOTE-DETAIL-LINE
               ADD 1 TO WS-LINE-CNT.
           IF TODO-NOTE-LINE-3 OF WS-MASTER-REC NOT = SPACES
               MOVE TODO-NOTE-LINE-3 OF WS-MASTER-REC TO ND-NOTE-TEXT
               WRITE ACTION-RPT-RECORD FROM WS-NOTE-DETAIL-LINE
               ADD 1 TO WS-LINE-CNT.

      *----------------------------------------------------------------*
      * 3000-TERMINATE:                                                *
      *   CLOSES DATASETS AND ASSIGNS RETURN-CODE (00, 04, OR 16).     *
      *----------------------------------------------------------------*
       3000-TERMINATE.
           IF FILES-ARE-OPEN
               CLOSE TODO-CTRL-FILE
                     TODO-PATH-FILE
                     PRTLIST-IN-FILE
                     ACTION-RPT-FILE.
           IF WS-APP-RC = 0 AND WS-TOTAL-USERS-PRT = ZERO
               MOVE 4 TO WS-APP-RC.
           MOVE WS-APP-RC TO RETURN-CODE.

      *----------------------------------------------------------------*
      * 8100-PRINT-USER-BANNER:                                        *
      *   ISSUES ASA '1' PAGE EJECT AND PRINTS USER BURSTING BANNER.   *
      *----------------------------------------------------------------*
       8100-PRINT-USER-BANNER.
           ADD 1 TO WS-USER-PAGE-NO.
           MOVE WS-CUR-USER-ID   TO BL2-USER-ID.
           MOVE WS-CUR-USER-NAME TO BL2-USER-NAME.
           MOVE WS-TODAY-YYYYMMDD TO BL2-RUN-DATE.
           MOVE WS-USER-PAGE-NO  TO BL2-PAGE-NO.
           WRITE ACTION-RPT-RECORD FROM WS-BANNER-LINE-1.
           WRITE ACTION-RPT-RECORD FROM WS-BANNER-LINE-2.
           WRITE ACTION-RPT-RECORD FROM WS-BANNER-LINE-3.
           WRITE ACTION-RPT-RECORD FROM WS-COL-HEADER-1.
           WRITE ACTION-RPT-RECORD FROM WS-COL-HEADER-2.
           MOVE 6 TO WS-LINE-CNT.

      *----------------------------------------------------------------*
      * 9100-READ-PRTLIST:                                             *
      *   READS NEXT 80-BYTE CARD FROM PRTLIST OVERRIDE DATASET.       *
      *----------------------------------------------------------------*
       9100-READ-PRTLIST.
           READ PRTLIST-IN-FILE
               AT END
                   MOVE 'Y' TO WS-LIST-EOF-SW.

      *----------------------------------------------------------------*
      * 9200-READ-NEXT-CONTROL:                                        *
      *   READS NEXT USER CONTROL RECORD SEQUENTIALLY FROM KSDS.       *
      *----------------------------------------------------------------*
       9200-READ-NEXT-CONTROL.
           READ TODO-CTRL-FILE NEXT RECORD INTO WS-CONTROL-REC
               AT END
                   MOVE 'Y' TO WS-CTRL-EOF-SW.