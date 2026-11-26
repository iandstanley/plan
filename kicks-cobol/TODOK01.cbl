IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOK01.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOK01                                          *
      * TITLE       : TODO MANAGER KICKS BROWSE & SETTINGS CONTROLLER  *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : KICKS OLTP PSEUDO-CONVERSATIONAL (IKFCBL00)      *
      * TRANSID     : TODO   MAPSET: TODOM00   MAPS: TODOM1, TODOM3    *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   DRIVES THE KICKS 3270 TASK LIST/BROWSE SCREEN (TODOM1) AND   *
      *   USER PREFERENCES SCREEN (TODOM3), SUPPORTING INLINE STATUS   *
      *   ACTIONS (S/C/W/X), FILTERING, PAGING, AND XCTL TO TODOK02.   *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. ENTRY DISPATCH (0000-MAIN-CONTROL): INSPECTS EIBCALEN;    *
      *      ON FIRST ENTRY (0) INITIALIZES USER CONTROL & DISPLAYS    *
      *      TODOM1; ON RE-ENTRY (>0) RESTORES COMMAREA AND ROUTES BY  *
      *      CA-PROCESS-STAGE.                                         *
      *   2. BROWSE & INLINE ACTIONS (2100-HANDLE-BROWSE): PROCESSES   *
      *      PF KEYS AND ROW ACTION CODES UNDER TODOLOCK ENQ/DEQ.      *
      *   3. SETTINGS (2300-HANDLE-SETTINGS): UPDATES TODOCTRL PREFS.  *
      *   4. EXIT (3000-PSEUDO-RETURN / 3900-EXIT-SESSION): RETURNS    *
      *      PSEUDO-CONVERSATIONALLY WITH TRANSID('TODO').             *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOREC  (IN TODO.COPYLIB) : 332-BYTE MASTER TASK RECORD   *
      *   - TODOCTRL (IN TODO.COPYLIB) : 64-BYTE USER CONTROL RECORD   *
      *   - TODOCOMM (IN TODO.COPYLIB) : 64-BYTE DFHCOMMAREA CONTRACT  *
      *   - TODOLLNK (IN TODO.COPYLIB) : 20-BYTE LOCK LINKAGE          *
      *   - TODOM00  (IN TODO.COPYLIB) : BMS SYMBOLIC MAPSET           *
      *   - DFHAID / DFHBMSCA          : KICKS ATTENTION & ATTRIBUTES  *
      *   - TODOLOCK (STATIC CALL)     : MVS SYSTEM-WIDE ENQ/DEQ       *
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
       77  WS-MAX-BROWSE-ROWS          PIC S9(04) COMP SYNC VALUE +10.

       01  WS-COMMAREA.
           COPY TODOCOMM.

       01  WS-COMMAREA-LENGTH          PIC S9(04) COMP SYNC VALUE +64.

       01  WS-KICKS-WORK-AREA.
           05  WS-RESP-CODE            PIC S9(08) COMP SYNC VALUE ZERO.
           05  WS-MAST-LEN             PIC S9(04) COMP SYNC VALUE +332.
           05  WS-CTRL-LEN             PIC S9(04) COMP SYNC VALUE +64.
           05  WS-USER-ID              PIC X(08) VALUE SPACES.
           05  WS-MSG-TEXT             PIC X(78) VALUE SPACES.

       01  WS-CONTROL-FLAGS.
           05  WS-BROWSE-EOF-SW        PIC X(01) VALUE 'N'.
               88  END-OF-BROWSE                 VALUE 'Y'.
               88  MORE-BROWSE-RECORDS           VALUE 'N'.
           05  WS-LOCK-HELD-SW         PIC X(01) VALUE 'N'.
               88  LOCK-IS-HELD                  VALUE 'Y'.
               88  LOCK-NOT-HELD                 VALUE 'N'.
           05  WS-XCTL-DONE-SW         PIC X(01) VALUE 'N'.
               88  XCTL-WAS-ISSUED               VALUE 'Y'.
               88  NO-XCTL-ISSUED                VALUE 'N'.
           05  WS-EXIT-DONE-SW         PIC X(01) VALUE 'N'.
               88  SESSION-ENDED                 VALUE 'Y'.
               88  SESSION-ACTIVE                VALUE 'N'.

       01  WS-BROWSE-WORK.
           05  WS-ROW-IDX              PIC S9(04) COMP SYNC VALUE +0.
           05  WS-CUR-ACTION           PIC X(01) VALUE SPACES.
           05  WS-CUR-TASK-ID          PIC 9(08) VALUE ZERO.
           05  WS-ALT-RIDFLD.
               10  WS-RID-OWNER        PIC X(08) VALUE SPACES.
               10  WS-RID-DUE          PIC 9(08) VALUE ZERO.
               10  WS-RID-PRI          PIC 9(01) VALUE ZERO.
           05  WS-MAST-RIDFLD.
               10  WS-MRID-OWNER       PIC X(08) VALUE SPACES.
               10  WS-MRID-ID          PIC 9(08) VALUE ZERO.

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
      *   PSEUDO-CONVERSATIONAL ENTRY DISPATCHER FOR TODOK01.          *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-GET-USER-AND-DATE.
           IF EIBCALEN = 0
               PERFORM 1100-FIRST-TIME-INIT
           ELSE
               PERFORM 1200-RESTORE-COMMAREA
               PERFORM 2000-DISPATCH-STAGE.
           IF NOT SESSION-ENDED AND NOT XCTL-WAS-ISSUED
               PERFORM 3000-PSEUDO-RETURN.
           EXEC CICS RETURN END-EXEC.

      *----------------------------------------------------------------*
      * 1000-GET-USER-AND-DATE:                                        *
      *   RETRIEVES TSO USERID FROM KICKS EIB AND FORMATS YYYYMMDD.    *
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
      * 1100-FIRST-TIME-INIT:                                          *
      *   INITIALIZES COMMAREA, ENSURES USER CONTROL RECORD EXISTS,    *
      *   AND LOADS INITIAL TASK BROWSE PAGE.                          *
      *----------------------------------------------------------------*
       1100-FIRST-TIME-INIT.
           MOVE SPACES     TO WS-COMMAREA.
           MOVE '1'        TO CA-PROCESS-STAGE.
           MOVE 'O'        TO CA-FILTER-MODE.
           MOVE WS-USER-ID TO CA-VIEW-OWNER.
           MOVE +0         TO CA-SAVED-REC-VERSION.
           PERFORM 9200-ENSURE-USER-CONTROL.
           MOVE 'READY - ENTER ACTION CODE OR PF KEY' TO WS-MSG-TEXT.
           PERFORM 8100-BUILD-AND-SEND-BROWSE.

      *----------------------------------------------------------------*
      * 1200-RESTORE-COMMAREA:                                         *
      *   VALIDATES EIBCALEN AND COPIES DFHCOMMAREA TO WORKING-STORAGE.*
      *----------------------------------------------------------------*
       1200-RESTORE-COMMAREA.
           IF EIBCALEN = WS-COMMAREA-LENGTH
               MOVE DFHCOMMAREA TO WS-COMMAREA
           ELSE
               PERFORM 1100-FIRST-TIME-INIT.

      *----------------------------------------------------------------*
      * 2000-DISPATCH-STAGE:                                           *
      *   ROUTES RE-ENTRY PROCESSING BY CURRENT SCREEN STAGE.          *
      *----------------------------------------------------------------*
       2000-DISPATCH-STAGE.
           IF CA-STAGE-BROWSE
               PERFORM 2100-HANDLE-BROWSE
           ELSE
               IF CA-STAGE-SETTINGS
                   PERFORM 2300-HANDLE-SETTINGS
               ELSE
                   MOVE '1' TO CA-PROCESS-STAGE
                   MOVE 'RETURNED FROM TASK EDIT' TO WS-MSG-TEXT
                   PERFORM 8100-BUILD-AND-SEND-BROWSE.

      *----------------------------------------------------------------*
      * 2100-HANDLE-BROWSE:                                            *
      *   HANDLES PF KEYS AND INLINE ROW ACTIONS ON TODOM1.            *
      *----------------------------------------------------------------*
       2100-HANDLE-BROWSE.
           IF EIBAID = DFHPF3
               PERFORM 3900-EXIT-SESSION
           ELSE
               IF EIBAID = DFHCLEAR OR EIBAID = DFHPF5
                   MOVE 'REFRESHED TASK LIST' TO WS-MSG-TEXT
                   PERFORM 8100-BUILD-AND-SEND-BROWSE
               ELSE
                   IF EIBAID = DFHPF4
                       PERFORM 2150-XCTL-TO-ADD
                   ELSE
                       IF EIBAID = DFHPF9
                           PERFORM 8300-LOAD-AND-SEND-SETTINGS
                       ELSE
                           PERFORM 2110-RECEIVE-AND-PROCESS-M1.

      *----------------------------------------------------------------*
      * 2110-RECEIVE-AND-PROCESS-M1:                                   *
      *   RECEIVES TODOM1 INPUTS, UPDATES OWNER/FILTER, AND APPLIES    *
      *   ANY ROW ACTION CODE (S, C, W, X).                            *
      *----------------------------------------------------------------*
       2110-RECEIVE-AND-PROCESS-M1.
           MOVE LOW-VALUES TO TODOM1I.
           EXEC CICS RECEIVE MAP('TODOM1') MAPSET('TODOM00')
               INTO(TODOM1I)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF M1OWNRI NOT = SPACES AND M1OWNRI NOT = LOW-VALUES
               MOVE M1OWNRI TO CA-VIEW-OWNER.
           IF M1FILTI = 'O' OR M1FILTI = 'W' OR M1FILTI = 'A'
               MOVE M1FILTI TO CA-FILTER-MODE.
           PERFORM 2120-SCAN-BROWSE-ACTIONS.
           IF NOT XCTL-WAS-ISSUED
               PERFORM 8100-BUILD-AND-SEND-BROWSE.

      *----------------------------------------------------------------*
      * 2120-SCAN-BROWSE-ACTIONS:                                      *
      *   CHECKS ROWS 1-10 FOR INLINE ACTION CODES (S, C, W, X).       *
      *----------------------------------------------------------------*
       2120-SCAN-BROWSE-ACTIONS.
           MOVE SPACES TO WS-CUR-ACTION.
           MOVE ZERO   TO WS-CUR-TASK-ID.
           IF M1ACT01I NOT = SPACES AND M1ACT01I NOT = LOW-VALUES
               MOVE M1ACT01I TO WS-CUR-ACTION
               MOVE M1ID01I  TO WS-CUR-TASK-ID
           ELSE
               IF M1ACT02I NOT = SPACES AND M1ACT02I NOT = LOW-VALUES
                   MOVE M1ACT02I TO WS-CUR-ACTION
                   MOVE M1ID02I  TO WS-CUR-TASK-ID
               ELSE
                   IF M1ACT03I NOT = SPACES AND M1ACT03I NOT = LOW-VALUES
                       MOVE M1ACT03I TO WS-CUR-ACTION
                       MOVE M1ID03I  TO WS-CUR-TASK-ID
                   ELSE
                       PERFORM 2125-SCAN-ROWS-4-TO-10.
           IF WS-CUR-ACTION NOT = SPACES AND WS-CUR-TASK-ID > ZERO
               PERFORM 2130-EXECUTE-ROW-ACTION
           ELSE
               MOVE 'DISPLAY UPDATED' TO WS-MSG-TEXT.

      *----------------------------------------------------------------*
      * 2125-SCAN-ROWS-4-TO-10:                                        *
      *   CONTINUES INLINE ACTION CODE SCAN ACROSS REMAINING ROWS.     *
      *----------------------------------------------------------------*
       2125-SCAN-ROWS-4-TO-10.
           IF M1ACT04I NOT = SPACES AND M1ACT04I NOT = LOW-VALUES
               MOVE M1ACT04I TO WS-CUR-ACTION
               MOVE M1ID04I  TO WS-CUR-TASK-ID
           ELSE
               IF M1ACT05I NOT = SPACES AND M1ACT05I NOT = LOW-VALUES
                   MOVE M1ACT05I TO WS-CUR-ACTION
                   MOVE M1ID05I  TO WS-CUR-TASK-ID
               ELSE
                   IF M1ACT06I NOT = SPACES AND M1ACT06I NOT = LOW-VALUES
                       MOVE M1ACT06I TO WS-CUR-ACTION
                       MOVE M1ID06I  TO WS-CUR-TASK-ID
                   ELSE
                       IF M1ACT07I NOT = SPACES
                          AND M1ACT07I NOT = LOW-VALUES
                           MOVE M1ACT07I TO WS-CUR-ACTION
                           MOVE M1ID07I  TO WS-CUR-TASK-ID
                       ELSE
                           PERFORM 2128-SCAN-ROWS-8-TO-10.

      *----------------------------------------------------------------*
      * 2128-SCAN-ROWS-8-TO-10:                                        *
      *   CHECKS ROWS 8-10 FOR INLINE ACTION CODES.                    *
      *----------------------------------------------------------------*
       2128-SCAN-ROWS-8-TO-10.
           IF M1ACT08I NOT = SPACES AND M1ACT08I NOT = LOW-VALUES
               MOVE M1ACT08I TO WS-CUR-ACTION
               MOVE M1ID08I  TO WS-CUR-TASK-ID
           ELSE
               IF M1ACT09I NOT = SPACES AND M1ACT09I NOT = LOW-VALUES
                   MOVE M1ACT09I TO WS-CUR-ACTION
                   MOVE M1ID09I  TO WS-CUR-TASK-ID
               ELSE
                   IF M1ACT10I NOT = SPACES
                      AND M1ACT10I NOT = LOW-VALUES
                       MOVE M1ACT10I TO WS-CUR-ACTION
                       MOVE M1ID10I  TO WS-CUR-TASK-ID.

      *----------------------------------------------------------------*
      * 2130-EXECUTE-ROW-ACTION:                                       *
      *   ROUTES S=EDIT TO TODOK02, OR UPDATES STATUS FOR C, W, X.     *
      *----------------------------------------------------------------*
       2130-EXECUTE-ROW-ACTION.
           IF WS-CUR-ACTION = 'S'
               MOVE '2'            TO CA-PROCESS-STAGE
               MOVE 'E'            TO CA-DETAIL-MODE
               MOVE WS-CUR-TASK-ID TO CA-SELECTED-TASK-ID
               MOVE 'Y'            TO WS-XCTL-DONE-SW
               EXEC CICS XCTL PROGRAM('TODOK02')
                   COMMAREA(WS-COMMAREA)
                   LENGTH(WS-COMMAREA-LENGTH)
               END-EXEC
           ELSE
               IF WS-CUR-ACTION = 'C'
                  OR WS-CUR-ACTION = 'W'
                  OR WS-CUR-ACTION = 'X'
                   PERFORM 2140-QUICK-STATUS-UPDATE
               ELSE
                   MOVE 'INVALID ACTION CODE (USE S, C, W, OR X)'
                       TO WS-MSG-TEXT.

      *----------------------------------------------------------------*
      * 2140-QUICK-STATUS-UPDATE:                                      *
      *   UPDATES TASK STATUS INLINE UNDER TODOLOCK ENQ/DEQ.           *
      *----------------------------------------------------------------*
       2140-QUICK-STATUS-UPDATE.
           MOVE CA-VIEW-OWNER TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               PERFORM 2145-REWRITE-MASTER-STATUS
               PERFORM 9600-UNLOCK-RESOURCE.

      *----------------------------------------------------------------*
      * 2145-REWRITE-MASTER-STATUS:                                    *
      *   READS TASK FOR UPDATE, SETS STATUS & DONE-DATE, REWRITES.    *
      *----------------------------------------------------------------*
       2145-REWRITE-MASTER-STATUS.
           MOVE CA-VIEW-OWNER  TO WS-MRID-OWNER.
           MOVE WS-CUR-TASK-ID TO WS-MRID-ID.
           MOVE +332           TO WS-MAST-LEN.
           EXEC CICS READ DATASET('TODOMAST')
               INTO(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RIDFLD(WS-MAST-RIDFLD)
               UPDATE
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE = DFHRESP(NORMAL)
               MOVE WS-CUR-ACTION TO TODO-STATUS OF WS-MASTER-REC
               IF TODO-IS-CLOSED OF WS-MASTER-REC
                   MOVE WS-TODAY-YYYYMMDD
                       TO TODO-DONE-DATE OF WS-MASTER-REC
               ELSE
                   MOVE ZERO TO TODO-DONE-DATE OF WS-MASTER-REC
               END-IF
               ADD +1 TO TODO-REC-VERSION OF WS-MASTER-REC
               EXEC CICS REWRITE DATASET('TODOMAST')
                   FROM(WS-MASTER-REC)
                   LENGTH(WS-MAST-LEN)
                   RESP(WS-RESP-CODE)
               END-EXEC
               MOVE 'TASK STATUS UPDATED' TO WS-MSG-TEXT
           ELSE
               MOVE 'UNABLE TO UPDATE TASK RECORD' TO WS-MSG-TEXT.

      *----------------------------------------------------------------*
      * 2150-XCTL-TO-ADD:                                              *
      *   TRANSFERS TO TODOK02 IN ADD MODE TO CREATE A NEW TASK.       *
      *----------------------------------------------------------------*
       2150-XCTL-TO-ADD.
           MOVE '2' TO CA-PROCESS-STAGE.
           MOVE 'A' TO CA-DETAIL-MODE.
           MOVE ZERO TO CA-SELECTED-TASK-ID.
           MOVE 'Y' TO WS-XCTL-DONE-SW.
           EXEC CICS XCTL PROGRAM('TODOK02')
               COMMAREA(WS-COMMAREA)
               LENGTH(WS-COMMAREA-LENGTH)
           END-EXEC.

      *----------------------------------------------------------------*
      * 2300-HANDLE-SETTINGS:                                          *
      *   PROCESSES TODOM3 PREFERENCES SCREEN (PRINT SW, NAME, PRI).   *
      *----------------------------------------------------------------*
       2300-HANDLE-SETTINGS.
           IF EIBAID = DFHPF3 OR EIBAID = DFHPF12
               MOVE '1' TO CA-PROCESS-STAGE
               MOVE 'SETTINGS CANCELLED' TO WS-MSG-TEXT
               PERFORM 8100-BUILD-AND-SEND-BROWSE
           ELSE
               PERFORM 2310-SAVE-USER-SETTINGS.

      *----------------------------------------------------------------*
      * 2310-SAVE-USER-SETTINGS:                                       *
      *   RECEIVES TODOM3 INPUTS, VALIDATES, AND REWRITES TODOCTRL.    *
      *----------------------------------------------------------------*
       2310-SAVE-USER-SETTINGS.
           MOVE LOW-VALUES TO TODOM3I.
           EXEC CICS RECEIVE MAP('TODOM3') MAPSET('TODOM00')
               INTO(TODOM3I)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF M3PRNTI NOT = 'Y' AND M3PRNTI NOT = 'N'
               MOVE LOW-VALUES TO TODOM3O
               MOVE 'DAILY PRINT MUST BE Y OR N' TO M3MSGO
               MOVE -1 TO M3PRNTL
               PERFORM 8350-SEND-SETTINGS-DATA
           ELSE
               IF M3PRII < '1' OR M3PRII > '5'
                   MOVE LOW-VALUES TO TODOM3O
                   MOVE 'PRIORITY MUST BE 1 THROUGH 5' TO M3MSGO
                   MOVE -1 TO M3PRIL
                   PERFORM 8350-SEND-SETTINGS-DATA
               ELSE
                   PERFORM 2320-REWRITE-CONTROL-REC.

      *----------------------------------------------------------------*
      * 2320-REWRITE-CONTROL-REC:                                      *
      *   UPDATES TODO.CONTROL.CLUSTER UNDER ENQ AND RETURNS TO LIST.  *
      *----------------------------------------------------------------*
       2320-REWRITE-CONTROL-REC.
           MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               PERFORM 2325-APPLY-CTRL-REWRITE
               PERFORM 9600-UNLOCK-RESOURCE.
           MOVE '1' TO CA-PROCESS-STAGE.
           MOVE 'USER SETTINGS SAVED' TO WS-MSG-TEXT.
           PERFORM 8100-BUILD-AND-SEND-BROWSE.

      *----------------------------------------------------------------*
      * 2325-APPLY-CTRL-REWRITE:                                       *
      *   READS TODOCTRL FOR UPDATE AND WRITES PREFERENCE CHANGES.     *
      *----------------------------------------------------------------*
       2325-APPLY-CTRL-REWRITE.
           MOVE +64 TO WS-CTRL-LEN.
           EXEC CICS READ DATASET('TODOCTRL')
               INTO(WS-CONTROL-REC)
               LENGTH(WS-CTRL-LEN)
               RIDFLD(WS-USER-ID)
               UPDATE
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE = DFHRESP(NORMAL)
               MOVE M3NAMEI TO CTRL-USER-NAME OF WS-CONTROL-REC
               MOVE M3PRNTI TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
               MOVE M3PRII  TO CTRL-DEFAULT-PRI OF WS-CONTROL-REC
               EXEC CICS REWRITE DATASET('TODOCTRL')
                   FROM(WS-CONTROL-REC)
                   LENGTH(WS-CTRL-LEN)
                   RESP(WS-RESP-CODE)
               END-EXEC.

      *----------------------------------------------------------------*
      * 3000-PSEUDO-RETURN:                                            *
      *   RETURNS CONTROL TO KICKS WITH TRANSID('TODO') AND COMMAREA.  *
      *----------------------------------------------------------------*
       3000-PSEUDO-RETURN.
           EXEC CICS RETURN
               TRANSID('TODO')
               COMMAREA(WS-COMMAREA)
               LENGTH(WS-COMMAREA-LENGTH)
           END-EXEC.

      *----------------------------------------------------------------*
      * 3900-EXIT-SESSION:                                             *
      *   CLEANLY TERMINATES KICKS TODO SESSION ON PF3.                *
      *----------------------------------------------------------------*
       3900-EXIT-SESSION.
           MOVE 'Y' TO WS-EXIT-DONE-SW.
           EXEC CICS SEND TEXT
               FROM('TODO MANAGER SESSION ENDED.')
               LENGTH(27)
               ERASE
               FREEKB
           END-EXEC.

      *----------------------------------------------------------------*
      * 8100-BUILD-AND-SEND-BROWSE:                                    *
      *   BROWSES AIX1 PATH FOR CA-VIEW-OWNER AND SENDS TODOM1 MAP.    *
      *----------------------------------------------------------------*
       8100-BUILD-AND-SEND-BROWSE.
           MOVE LOW-VALUES     TO TODOM1O.
           MOVE WS-USER-ID     TO M1USERO.
           MOVE CA-VIEW-OWNER  TO M1OWNRO.
           MOVE CA-FILTER-MODE TO M1FILTO.
           MOVE WS-MSG-TEXT    TO M1MSGO.

           MOVE CA-VIEW-OWNER TO WS-RID-OWNER.
           MOVE ZERO          TO WS-RID-DUE.
           MOVE ZERO          TO WS-RID-PRI.
           MOVE 'N'           TO WS-BROWSE-EOF-SW.
           MOVE +0            TO WS-ROW-IDX.

           EXEC CICS STARTBR DATASET('TODOPATH')
               RIDFLD(WS-ALT-RIDFLD)
               GTEQ
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
               MOVE 'Y' TO WS-BROWSE-EOF-SW.

           PERFORM 8110-FETCH-NEXT-BROWSE-ROW
               UNTIL END-OF-BROWSE OR WS-ROW-IDX >= WS-MAX-BROWSE-ROWS.

           IF WS-RESP-CODE = DFHRESP(NORMAL)
               EXEC CICS ENDBR DATASET('TODOPATH')
                   RESP(WS-RESP-CODE)
               END-EXEC.

           MOVE -1 TO M1ACT01L.
           EXEC CICS SEND MAP('TODOM1') MAPSET('TODOM00')
               FROM(TODOM1O)
               ERASE
               CURSOR
               FREEKB
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 8110-FETCH-NEXT-BROWSE-ROW:                                    *
      *   READS NEXT AIX1 RECORD AND POPULATES NEXT SCREEN ROW SLOT.   *
      *----------------------------------------------------------------*
       8110-FETCH-NEXT-BROWSE-ROW.
           MOVE +332 TO WS-MAST-LEN.
           EXEC CICS READNEXT DATASET('TODOPATH')
               INTO(WS-MASTER-REC)
               LENGTH(WS-MAST-LEN)
               RIDFLD(WS-ALT-RIDFLD)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE NOT = DFHRESP(NORMAL)
              AND WS-RESP-CODE NOT = DFHRESP(DUPKEY)
               MOVE 'Y' TO WS-BROWSE-EOF-SW
           ELSE
               IF TODO-OWNER-ID OF WS-MASTER-REC NOT = CA-VIEW-OWNER
                   MOVE 'Y' TO WS-BROWSE-EOF-SW
               ELSE
                   PERFORM 8120-CHECK-FILTER-AND-POPULATE.

      *----------------------------------------------------------------*
      * 8120-CHECK-FILTER-AND-POPULATE:                                *
      *   APPLIES FILTER (O/W/A) AND MOVES FIELDS TO ROW 1..10.        *
      *----------------------------------------------------------------*
       8120-CHECK-FILTER-AND-POPULATE.
           IF CA-FILTER-ALL
              OR (CA-FILTER-WAIT AND TODO-STAT-WAITING OF WS-MASTER-REC)
              OR (CA-FILTER-ACTIVE AND TODO-IS-ACTIVE OF WS-MASTER-REC)
               ADD +1 TO WS-ROW-IDX
               PERFORM 8130-MOVE-ROW-FIELDS.

      *----------------------------------------------------------------*
      * 8130-MOVE-ROW-FIELDS:                                          *
      *   POPULATES BMS OUTPUT FIELDS FOR CURRENT WS-ROW-IDX (1-10).   *
      *----------------------------------------------------------------*
       8130-MOVE-ROW-FIELDS.
           IF WS-ROW-IDX = +1
               MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID01O
               MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST01O
               MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR01O
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU01O
               MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT01O
               MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI01O
           ELSE
               IF WS-ROW-IDX = +2
                   MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID02O
                   MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST02O
                   MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR02O
                   MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU02O
                   MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT02O
                   MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI02O
               ELSE
                   IF WS-ROW-IDX = +3
                       MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID03O
                       MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST03O
                       MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR03O
                       MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU03O
                       MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT03O
                       MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI03O
                   ELSE
                       PERFORM 8135-MOVE-ROWS-4-TO-10.

      *----------------------------------------------------------------*
      * 8135-MOVE-ROWS-4-TO-10:                                        *
      *   POPULATES BMS OUTPUT FIELDS FOR ROWS 4 THROUGH 10.           *
      *----------------------------------------------------------------*
       8135-MOVE-ROWS-4-TO-10.
           IF WS-ROW-IDX = +4
               MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID04O
               MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST04O
               MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR04O
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU04O
               MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT04O
               MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI04O
           ELSE
               IF WS-ROW-IDX = +5
                   MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID05O
                   MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST05O
                   MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR05O
                   MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU05O
                   MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT05O
                   MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI05O
               ELSE
                   IF WS-ROW-IDX = +6
                       MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID06O
                       MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST06O
                       MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR06O
                       MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU06O
                       MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT06O
                       MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI06O
                   ELSE
                       PERFORM 8138-MOVE-ROWS-7-TO-10.

      *----------------------------------------------------------------*
      * 8138-MOVE-ROWS-7-TO-10:                                        *
      *   POPULATES BMS OUTPUT FIELDS FOR ROWS 7 THROUGH 10.           *
      *----------------------------------------------------------------*
       8138-MOVE-ROWS-7-TO-10.
           IF WS-ROW-IDX = +7
               MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID07O
               MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST07O
               MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR07O
               MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU07O
               MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT07O
               MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI07O
           ELSE
               IF WS-ROW-IDX = +8
                   MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID08O
                   MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST08O
                   MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR08O
                   MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU08O
                   MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT08O
                   MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI08O
               ELSE
                   IF WS-ROW-IDX = +9
                       MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID09O
                       MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST09O
                       MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR09O
                       MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU09O
                       MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT09O
                       MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI09O
                   ELSE
                       MOVE TODO-TASK-ID OF WS-MASTER-REC  TO M1ID10O
                       MOVE TODO-STATUS OF WS-MASTER-REC   TO M1ST10O
                       MOVE TODO-PRIORITY OF WS-MASTER-REC TO M1PR10O
                       MOVE TODO-DUE-DATE OF WS-MASTER-REC TO M1DU10O
                       MOVE TODO-CATEGORY OF WS-MASTER-REC TO M1CT10O
                       MOVE TODO-TITLE OF WS-MASTER-REC    TO M1TI10O.

      *----------------------------------------------------------------*
      * 8300-LOAD-AND-SEND-SETTINGS:                                   *
      *   READS CURRENT USER TODOCTRL RECORD AND DISPLAYS TODOM3 MAP.  *
      *----------------------------------------------------------------*
       8300-LOAD-AND-SEND-SETTINGS.
           MOVE '3' TO CA-PROCESS-STAGE.
           MOVE +64 TO WS-CTRL-LEN.
           EXEC CICS READ DATASET('TODOCTRL')
               INTO(WS-CONTROL-REC)
               LENGTH(WS-CTRL-LEN)
               RIDFLD(WS-USER-ID)
               RESP(WS-RESP-CODE)
           END-EXEC.
           MOVE LOW-VALUES TO TODOM3O.
           MOVE WS-USER-ID TO M3USERO.
           MOVE CTRL-USER-NAME OF WS-CONTROL-REC      TO M3NAMEO.
           MOVE CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC TO M3PRNTO.
           MOVE CTRL-DEFAULT-PRI OF WS-CONTROL-REC    TO M3PRIO.
           MOVE CTRL-LAST-TASK-ID OF WS-CONTROL-REC   TO M3LASTO.
           MOVE 'UPDATE PREFERENCES AND PRESS ENTER'  TO M3MSGO.
           MOVE -1 TO M3NAMEL.
           EXEC CICS SEND MAP('TODOM3') MAPSET('TODOM00')
               FROM(TODOM3O)
               ERASE
               CURSOR
               FREEKB
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 8350-SEND-SETTINGS-DATA:                                       *
      *   SENDS VALIDATION ERROR FEEDBACK ON TODOM3 (DATAONLY).        *
      *----------------------------------------------------------------*
       8350-SEND-SETTINGS-DATA.
           EXEC CICS SEND MAP('TODOM3') MAPSET('TODOM00')
               FROM(TODOM3O)
               DATAONLY
               CURSOR
               FREEKB
               RESP(WS-RESP-CODE)
           END-EXEC.

      *----------------------------------------------------------------*
      * 9200-ENSURE-USER-CONTROL:                                      *
      *   AUTO-CREATES DEFAULT TODOCTRL RECORD FOR FIRST-TIME USERS.   *
      *----------------------------------------------------------------*
       9200-ENSURE-USER-CONTROL.
           MOVE +64 TO WS-CTRL-LEN.
           EXEC CICS READ DATASET('TODOCTRL')
               INTO(WS-CONTROL-REC)
               LENGTH(WS-CTRL-LEN)
               RIDFLD(WS-USER-ID)
               RESP(WS-RESP-CODE)
           END-EXEC.
           IF WS-RESP-CODE = DFHRESP(NOTFND)
               PERFORM 9210-WRITE-DEFAULT-CTRL.

      *----------------------------------------------------------------*
      * 9210-WRITE-DEFAULT-CTRL:                                       *
      *   WRITES INITIAL CONTROL RECORD FOR FIRST-TIME USER UNDER ENQ. *
      *----------------------------------------------------------------*
       9210-WRITE-DEFAULT-CTRL.
           MOVE WS-CTRL-LOCK-RNAME TO LLNK-RNAME.
           PERFORM 9500-LOCK-RESOURCE.
           IF LOCK-IS-HELD
               MOVE SPACES     TO WS-CONTROL-REC
               MOVE WS-USER-ID TO CTRL-USER-ID OF WS-CONTROL-REC
               MOVE ZERO
                   TO CTRL-LAST-TASK-ID OF WS-CONTROL-REC
               MOVE 'Y'
                   TO CTRL-DAILY-PRINT-SW OF WS-CONTROL-REC
               MOVE 3
                   TO CTRL-DEFAULT-PRI OF WS-CONTROL-REC
               MOVE WS-USER-ID TO CTRL-USER-NAME OF WS-CONTROL-REC
               MOVE +0
                   TO CTRL-ACTIVE-COUNT OF WS-CONTROL-REC
               MOVE WS-TODAY-YYYYMMDD
                   TO CTRL-LAST-LOGIN-DATE OF WS-CONTROL-REC
               EXEC CICS WRITE DATASET('TODOCTRL')
                   FROM(WS-CONTROL-REC)
                   LENGTH(WS-CTRL-LEN)
                   RIDFLD(WS-USER-ID)
                   RESP(WS-RESP-CODE)
               END-EXEC
               PERFORM 9600-UNLOCK-RESOURCE.

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