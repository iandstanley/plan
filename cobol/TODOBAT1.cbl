IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOBAT1.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOBAT1                                         *
      * TITLE       : TODO MANAGER NIGHTLY ARCHIVE AND PURGE           *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : NIGHTLY BATCH (IKFCBL00)                         *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   EXTRACTS ALL COMPLETED ('C') AND CANCELLED ('X') TASKS FROM  *
      *   TODO.MASTER.CLUSTER INTO A +1 GENERATION OF TODO.ARCHIVE.GDG *
      *   AND DELETES ARCHIVED RECORDS FROM THE ACTIVE MASTER CLUSTER. *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. INITIALIZATION (1000-INITIALIZE): ACQUIRES SYSTEM-WIDE    *
      *      ENQ VIA TODOLOCK, OPENS MASTER KSDS AND ARCHIVE GDG, AND  *
      *      PERFORMS PRIMING READ ON MASTER CLUSTER.                  *
      *   2. MAIN LOOP (2000-ARCHIVE-CLOSED-TASKS): SKIPS SENTINEL     *
      *      RECORD, WRITES CLOSED ('C'/'X') RECORDS TO ARCHIVE GDG,   *
      *      DELETES THEM FROM MASTER KSDS, AND READS NEXT RECORD.     *
      *   3. TERMINATION (3000-TERMINATE): WRITES AUDIT TOTALS TO      *
      *      SYSOUT, CLOSES DATASETS, RELEASES ENQ, SETS RETURN-CODE.  *
      *                                                                *
      * USAGE / JCL INTERFACE:                                         *
      *   DDNAME    ORG    RECFM/LRECL  I/O     DESCRIPTION            *
      *   --------  -----  -----------  ------  ---------------------- *
      *   TODOMAST  VSAM   KSDS / 332   I-O     MASTER TASK CLUSTER    *
      *   ARCHOUT   QSAM   FB / 332     OUTPUT  ARCHIVE GDG (+1)       *
      *   SYSOUT    SYSOUT FBA / 133    OUTPUT  BATCH AUDIT SUMMARY    *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOREC  (IN TODO.COPYLIB) : 332-BYTE MASTER TASK RECORD   *
      *   - TODOLLNK (IN TODO.COPYLIB) : 20-BYTE LOCK LINKAGE          *
      *   - TODOLOCK (STATIC CALL)     : MVS SYSTEM-WIDE ENQ/DEQ       *
      *                                                                *
      * RETURN CODES:                                                  *
      *   00 - ARCHIVE AND PURGE COMPLETED WITH RECORDS ARCHIVED       *
      *   04 - COMPLETED CLEANLY WITH ZERO RECORDS ELIGIBLE TO ARCHIVE *
      *   16 - SEVERE VSAM, QSAM, OR SYSTEM LOCK ERROR                 *
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
           SELECT TODO-MASTER-FILE ASSIGN TO TODOMAST
                                   ORGANIZATION IS INDEXED
                                   ACCESS MODE IS SEQUENTIAL
                                   RECORD KEY IS FD-MAST-KEY
                                   FILE STATUS IS WS-MAST-STATUS.
           SELECT ARCHIVE-OUT-FILE ASSIGN TO UT-S-ARCHOUT
                                   FILE STATUS IS WS-ARCH-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TODO-MASTER-FILE
           RECORD CONTAINS 332 CHARACTERS.
       01  FD-MASTER-RECORD.
           05  FD-MAST-KEY             PIC X(16).
           05  FD-MAST-REST            PIC X(316).

       FD  ARCHIVE-OUT-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 332 CHARACTERS.
       01  ARCHIVE-OUT-RECORD          PIC X(332).

       WORKING-STORAGE SECTION.
       77  WS-MASTER-LOCK-RNAME        PIC X(08) VALUE 'MASTER  '.
       77  WS-SENTINEL-OWNER           PIC X(08) VALUE '00000000'.

       01  WS-FILE-STATUS-AREA.
           05  WS-MAST-STATUS          PIC X(02) VALUE SPACES.
               88  MAST-IO-OK                    VALUE '00'.
               88  MAST-IO-DUP-ALT               VALUE '02'.
               88  MAST-IO-EOF                   VALUE '10'.
           05  WS-ARCH-STATUS          PIC X(02) VALUE SPACES.
               88  ARCH-IO-OK                    VALUE '00'.

       01  WS-CONTROL-FLAGS.
           05  WS-APP-RC               PIC S9(04) COMP SYNC VALUE +0.
           05  WS-EOF-SW               PIC X(01) VALUE 'N'.
               88  END-OF-MASTER                 VALUE 'Y'.
               88  MORE-MASTER-RECORDS           VALUE 'N'.
           05  WS-FILES-OPEN-SW        PIC X(01) VALUE 'N'.
               88  FILES-ARE-OPEN                VALUE 'Y'.
               88  FILES-ARE-CLOSED              VALUE 'N'.
           05  WS-LOCK-HELD-SW         PIC X(01) VALUE 'N'.
               88  LOCK-IS-HELD                  VALUE 'Y'.
               88  LOCK-NOT-HELD                 VALUE 'N'.

       01  WS-ACCUMULATORS.
           05  WS-READ-CNT             PIC S9(07) COMP-3 VALUE ZERO.
           05  WS-ARCHIVED-CNT         PIC S9(07) COMP-3 VALUE ZERO.
           05  WS-RETAINED-CNT         PIC S9(07) COMP-3 VALUE ZERO.
           05  WS-DISP-READ            PIC Z,ZZZ,ZZ9.
           05  WS-DISP-ARCH            PIC Z,ZZZ,ZZ9.
           05  WS-DISP-RETAIN          PIC Z,ZZZ,ZZ9.

       01  WS-MASTER-REC.
           COPY TODOREC.

       01  WS-LOCK-PARM.
           COPY TODOLLNK.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * 0000-MAIN-CONTROL:                                             *
      *   EXECUTIVE DRIVER CONTROLLING INITIALIZATION, ARCHIVE/PURGE   *
      *   LOOP, AND FINAL AUDIT TERMINATION.                           *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE.
           IF WS-APP-RC = 0
               PERFORM 2000-ARCHIVE-CLOSED-TASKS
                   UNTIL END-OF-MASTER OR WS-APP-RC NOT = 0.
           PERFORM 3000-TERMINATE.
           GOBACK.

      *----------------------------------------------------------------*
      * 1000-INITIALIZE:                                               *
      *   ACQUIRES SYSTEM-WIDE MASTER ENQ, OPENS MASTER & ARCHIVE      *
      *   DATASETS, AND EXECUTES PRIMING READ ON MASTER CLUSTER.       *
      *----------------------------------------------------------------*
       1000-INITIALIZE.
           PERFORM 9500-LOCK-MASTER.
           IF WS-APP-RC = 0
               OPEN I-O    TODO-MASTER-FILE
                    OUTPUT ARCHIVE-OUT-FILE
               IF NOT MAST-IO-OK OR NOT ARCH-IO-OK
                   DISPLAY 'TODOBAT1: OPEN ERROR MAST=' WS-MAST-STATUS
                           ' ARCH=' WS-ARCH-STATUS
                   MOVE 16 TO WS-APP-RC
               ELSE
                   MOVE 'Y' TO WS-FILES-OPEN-SW
                   PERFORM 9100-READ-MASTER.

      *----------------------------------------------------------------*
      * 2000-ARCHIVE-CLOSED-TASKS:                                     *
      *   EVALUATES CURRENT RECORD, ARCHIVES & DELETES IF 'C' OR 'X',  *
      *   AND PERFORMS NEXT SEQUENTIAL READ.                           *
      *----------------------------------------------------------------*
       2000-ARCHIVE-CLOSED-TASKS.
           IF TODO-OWNER-ID OF WS-MASTER-REC = WS-SENTINEL-OWNER
               ADD 1 TO WS-RETAINED-CNT
           ELSE
               IF TODO-IS-CLOSED OF WS-MASTER-REC
                   PERFORM 2100-WRITE-AND-DELETE-TASK
               ELSE
                   ADD 1 TO WS-RETAINED-CNT.
           IF WS-APP-RC = 0
               PERFORM 9100-READ-MASTER.

      *----------------------------------------------------------------*
      * 2100-WRITE-AND-DELETE-TASK:                                    *
      *   WRITES CLOSED RECORD TO ARCHIVE GDG AND DELETES FROM KSDS.   *
      *----------------------------------------------------------------*
       2100-WRITE-AND-DELETE-TASK.
           WRITE ARCHIVE-OUT-RECORD FROM WS-MASTER-REC.
           IF NOT ARCH-IO-OK
               DISPLAY 'TODOBAT1: ARCHIVE WRITE ERR=' WS-ARCH-STATUS
               MOVE 16 TO WS-APP-RC
           ELSE
               DELETE TODO-MASTER-FILE RECORD
                   INVALID KEY
                       DISPLAY 'TODOBAT1: MASTER DELETE ERR='
                               WS-MAST-STATUS
                       MOVE 16 TO WS-APP-RC.
           IF WS-APP-RC = 0
               ADD 1 TO WS-ARCHIVED-CNT.

      *----------------------------------------------------------------*
      * 3000-TERMINATE:                                                *
      *   CLOSES DATASETS, RELEASES ENQ, DISPLAYS AUDIT SUMMARY, AND   *
      *   SETS FINAL RETURN-CODE.                                      *
      *----------------------------------------------------------------*
       3000-TERMINATE.
           IF FILES-ARE-OPEN
               CLOSE TODO-MASTER-FILE
                     ARCHIVE-OUT-FILE.
           IF LOCK-IS-HELD
               PERFORM 9600-UNLOCK-MASTER.
           MOVE WS-READ-CNT     TO WS-DISP-READ.
           MOVE WS-ARCHIVED-CNT TO WS-DISP-ARCH.
           MOVE WS-RETAINED-CNT TO WS-DISP-RETAIN.
           DISPLAY 'TODOBAT1: RECORDS READ     = ' WS-DISP-READ.
           DISPLAY 'TODOBAT1: RECORDS ARCHIVED = ' WS-DISP-ARCH.
           DISPLAY 'TODOBAT1: RECORDS RETAINED = ' WS-DISP-RETAIN.
           IF WS-APP-RC = 0 AND WS-ARCHIVED-CNT = ZERO
               MOVE 4 TO WS-APP-RC.
           MOVE WS-APP-RC TO RETURN-CODE.

      *----------------------------------------------------------------*
      * 9100-READ-MASTER:                                              *
      *   PRIMING / SEQUENTIAL READ FROM TODO.MASTER.CLUSTER.          *
      *----------------------------------------------------------------*
       9100-READ-MASTER.
           READ TODO-MASTER-FILE NEXT RECORD INTO WS-MASTER-REC
               AT END
                   MOVE 'Y' TO WS-EOF-SW.
           IF NOT END-OF-MASTER
               IF NOT MAST-IO-OK AND NOT MAST-IO-DUP-ALT
                   DISPLAY 'TODOBAT1: MASTER READ ERR=' WS-MAST-STATUS
                   MOVE 16 TO WS-APP-RC
               ELSE
                   ADD 1 TO WS-READ-CNT.

      *----------------------------------------------------------------*
      * 9500-LOCK-MASTER:                                              *
      *   ACQUIRES SYSTEM-WIDE ENQ ON MASTER CLUSTER VIA TODOLOCK.     *
      *----------------------------------------------------------------*
       9500-LOCK-MASTER.
           MOVE 'ENQ '               TO LLNK-ACTION.
           MOVE WS-MASTER-LOCK-RNAME TO LLNK-RNAME.
           MOVE +0                   TO LLNK-RC.
           CALL 'TODOLOCK' USING WS-LOCK-PARM.
           IF LLNK-OK
               MOVE 'Y' TO WS-LOCK-HELD-SW
           ELSE
               DISPLAY 'TODOBAT1: ENQ FAILED RC=' LLNK-RC
               MOVE 16 TO WS-APP-RC.

      *----------------------------------------------------------------*
      * 9600-UNLOCK-MASTER:                                            *
      *   RELEASES SYSTEM-WIDE ENQ ON MASTER CLUSTER VIA TODOLOCK.     *
      *----------------------------------------------------------------*
       9600-UNLOCK-MASTER.
           MOVE 'DEQ '               TO LLNK-ACTION.
           MOVE WS-MASTER-LOCK-RNAME TO LLNK-RNAME.
           MOVE +0                   TO LLNK-RC.
           CALL 'TODOLOCK' USING WS-LOCK-PARM.
           MOVE 'N'                  TO WS-LOCK-HELD-SW.