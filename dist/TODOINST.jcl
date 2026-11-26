//INSTCORE JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(2,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//*===================================================================*
//* JOB: INSTCORE - ALLOCATE TODO PDS LIBRARIES & VSAM CLUSTERS       *
//* NOTE: ALL DATASETS RESIDE ON USER-PRESERVED VOLUME PUB000.        *
//*===================================================================*
//* STEP 1: DEFINE MASTER CATALOG ALIAS FOR HLQ 'TODO'                *
//*-------------------------------------------------------------------*
//DEFALIAS EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO ALIAS
  SET MAXCC = 0
  DEFINE ALIAS (NAME(TODO) RELATE(SYS1.UCAT.TSO))
/*
//*-------------------------------------------------------------------*
//* STEP 2: ALLOCATE DEPARTMENTAL SOURCE, JCL, CLIST, & LOAD PDS'S    *
//*-------------------------------------------------------------------*
//ALLOCPDS EXEC PGM=IEFBR14,COND=(4,LT)
//COPYLIB  DD  DSN=TODO.COPYLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//COBOL    DD  DSN=TODO.COBOL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//ASM      DD  DSN=TODO.ASM,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//KCOBOL   DD  DSN=TODO.KICKS.COBOL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//KBMS     DD  DSN=TODO.KICKS.BMS,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//CLIST    DD  DSN=TODO.CLIST,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//PARMLIB  DD  DSN=TODO.PARMLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//JCL      DD  DSN=TODO.JCL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//LOADLIB  DD  DSN=TODO.LOADLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(CYL,(5,2,30)),
//             DCB=(DSORG=PO,RECFM=U,LRECL=0,BLKSIZE=19069)
//KLOADLIB DD  DSN=TODO.KICKS.LOADLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(CYL,(5,2,30)),
//             DCB=(DSORG=PO,RECFM=U,LRECL=0,BLKSIZE=19069)
//*-------------------------------------------------------------------*
//* STEP 3: DEFINE VSAM KSDS CLUSTERS, AIX, PATH, AND ARCHIVE GDG     *
//*-------------------------------------------------------------------*
//DEFVSAM  EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO.MASTER.CLUSTER CLUSTER PURGE
  DELETE TODO.CONTROL.CLUSTER CLUSTER PURGE
  SET MAXCC = 0
  DEFINE CLUSTER ( -
           NAME(TODO.MASTER.CLUSTER) -
           INDEXED -
           TRACKS(15 5) -
           VOLUMES(PUB000) -
           RECORDSIZE(332 332) -
           KEYS(16 0) -
           CISZ(4096) -
           FREESPACE(20 10) -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.MASTER.DATA) ) -
         INDEX ( -
           NAME(TODO.MASTER.INDEX) )
  DEFINE CLUSTER ( -
           NAME(TODO.CONTROL.CLUSTER) -
           INDEXED -
           TRACKS(2 1) -
           VOLUMES(PUB000) -
           RECORDSIZE(64 64) -
           KEYS(8 0) -
           CISZ(2048) -
           FREESPACE(20 10) -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.CONTROL.DATA) ) -
         INDEX ( -
           NAME(TODO.CONTROL.INDEX) )
  DEFINE ALTERNATEINDEX ( -
           NAME(TODO.MASTER.AIX1) -
           RELATE(TODO.MASTER.CLUSTER) -
           TRACKS(5 2) -
           VOLUMES(PUB000) -
           KEYS(17 16) -
           RECORDSIZE(60 200) -
           NONUNIQUEKEY -
           UPGRADE -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.MASTER.AIX1.DATA) ) -
         INDEX ( -
           NAME(TODO.MASTER.AIX1.INDEX) )
  DEFINE PATH ( -
           NAME(TODO.MASTER.PATH1) -
           PATHENTRY(TODO.MASTER.AIX1) -
           UPDATE )
  DEFINE GDG ( -
           NAME(TODO.ARCHIVE.GDG) -
           LIMIT(30) -
           NOEMPTY -
           SCRATCH )
/*
//*-------------------------------------------------------------------*
//* STEP 4: LOAD ZERO-KEY SENTINEL RECORDS & BUILD ALTERNATE INDEX    *
//*         (REQUIRED BY MVS 3.8J VSAM BEFORE OPEN FOR I-O)           *
//*-------------------------------------------------------------------*
//SEEDVSAM EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//MASTSEED DD  *
000000000000000000000000000000000SEED RECORD - DO NOT DELETE                                        SYSTEM    X90000000000000000SYSTEM  00000000                                                                                                                                                                                              000000000000000
/*
//CTRLSEED DD  *
0000000000000000N3SENTINEL CONTROL RECORD   00000000000000000000
/*
//SYSIN    DD  *
  REPRO INFILE(MASTSEED) OUTDATASET(TODO.MASTER.CLUSTER)
  REPRO INFILE(CTRLSEED) OUTDATASET(TODO.CONTROL.CLUSTER)
  BLDINDEX INDATASET(TODO.MASTER.CLUSTER) -
           OUTDATASET(TODO.MASTER.AIX1)
/*
//*-------------------------------------------------------------------*
//* LOAD TODO.COPYLIB FROM copybook\*.cpy
//*-------------------------------------------------------------------*
//LDcopybo EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.COPYLIB,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=TODOCOMM
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
./ ADD NAME=TODOCREC
*================================================================*
      * COPYBOOK: TODOCREC - TSO CLI COMMAND RECORD LAYOUT (200 BYTES) *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  CMD-USER-ID             PIC X(08).
           05  CMD-VERB                PIC X(08).
               88  CMD-IS-LIST             VALUE 'LIST    ' '        '.
               88  CMD-IS-ADD              VALUE 'ADD     '.
               88  CMD-IS-VIEW             VALUE 'VIEW    '.
               88  CMD-IS-START            VALUE 'START   '.
               88  CMD-IS-WAIT             VALUE 'WAIT    '.
               88  CMD-IS-DONE             VALUE 'DONE    '.
               88  CMD-IS-CANCEL           VALUE 'CANCEL  '.
               88  CMD-IS-ASSIGN           VALUE 'ASSIGN  '.
               88  CMD-IS-NOTE             VALUE 'NOTE    '.
               88  CMD-IS-PRINT            VALUE 'PRINT   '.
               88  VALID-CMD-VERB          VALUE 'LIST    ' '        '
                                                 'ADD     ' 'VIEW    '
                                                 'START   ' 'WAIT    '
                                                 'DONE    ' 'CANCEL  '
                                                 'ASSIGN  ' 'NOTE    '
                                                 'PRINT   '.
           05  CMD-ARG1                PIC X(16).
           05  CMD-ARG2                PIC X(16).
           05  CMD-DUE-DATE            PIC X(08).
           05  CMD-PRIORITY            PIC X(01).
           05  CMD-LINE-NUM            PIC X(01).
           05  CMD-CATEGORY            PIC X(10).
           05  CMD-TARGET-USER         PIC X(08).
           05  CMD-TEXT                PIC X(60).
           05  CMD-NOTE                PIC X(60).
           05  CMD-FILLER              PIC X(04).
./ ADD NAME=TODOCTRL
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
./ ADD NAME=TODOLLNK
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
		   
./ ADD NAME=TODOREC
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
./ ADD NAME=TODOVLNK
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
			   
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.COBOL FROM cobol\*.cbl
//*-------------------------------------------------------------------*
//LDcobolc EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.COBOL,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=TODOBAT1
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
./ ADD NAME=TODOBAT2
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
./ ADD NAME=TODOCMD
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
			   
./ ADD NAME=TODOVAL
IDENTIFICATION DIVISION.
       PROGRAM-ID.    TODOVAL.
       AUTHOR.        IAN STANLEY.
       DATE-WRITTEN.  NOVEMBER 2026.
      *================================================================*
      * PROGRAM ID  : TODOVAL                                          *
      * TITLE       : TODO MANAGER SHARED FIELD & DATE VALIDATOR       *
      * SUBSYSTEM   : TODO MANAGER (MVS 3.8J TK5)                      *
      * ENVIRONMENT : BATCH / TSO / KICKS SUBPROGRAM (IKFCBL00)        *
      * AUTHOR      : IAN STANLEY                                      *
      * CREATED     : 2026-11-26                                       *
      *================================================================*
      * PURPOSE:                                                       *
      *   PROVIDES CENTRALIZED BUSINESS RULE VALIDATION FOR TODO TASK  *
      *   FIELDS (TITLE, STATUS, PRIORITY, YYYYMMDD CALENDAR DATES,    *
      *   AND OWNER TSO USER ID) ACROSS TSO CLI, KICKS, AND BATCH.     *
      *                                                                *
      * METHOD OF OPERATION:                                           *
      *   1. INITIALIZATION (1000-INIT-VALIDATION): CLEARS OUTPUT      *
      *      FLAGS AND SETS DEFAULT VALID STATE.                       *
      *   2. DISPATCH (2000-DISPATCH-CHECKS): ROUTES BY VLNK-FUNC-CODE *
      *      ('ALL ', 'DATE', OR 'TASK') TO SPECIFIC FIELD CHECKS.     *
      *   3. TERMINATION (3000-FINISH-VALIDATION): SETS RETURN-CODE    *
      *      AND RETURNS VIA EXIT PROGRAM / GOBACK.                    *
      *                                                                *
      * USAGE / JCL INTERFACE:                                         *
      *   CALLED STATICALLY OR DYNAMICALLY VIA LINKAGE COPYBOOK        *
      *   TODOVLNK (NO DIRECT FILE I/O PERFORMED BY THIS MODULE).      *
      *                                                                *
      * COPYBOOKS & EXTERNAL CALLS:                                    *
      *   - TODOVLNK (IN TODO.COPYLIB) : 120-BYTE LINKAGE CONTRACT     *
      *                                                                *
      * RETURN CODES:                                                  *
      *   00 - ALL REQUESTED FIELDS PASSED VALIDATION                  *
      *   08 - ONE OR MORE FIELDS FAILED VALIDATION (SEE VLNK-ERR-*)   *
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
       77  WS-MIN-PRIORITY             PIC 9(01) VALUE 1.
       77  WS-MAX-PRIORITY             PIC 9(01) VALUE 5.
       77  WS-MIN-YEAR                 PIC 9(04) VALUE 1979.
       77  WS-MAX-YEAR                 PIC 9(04) VALUE 2099.

       01  WS-DATE-WORK-AREA.
           05  WS-WORK-DATE            PIC 9(08) VALUE ZERO.
           05  WS-DATE-PARTS REDEFINES WS-WORK-DATE.
               10  WS-YEAR             PIC 9(04).
               10  WS-MONTH            PIC 9(02).
                   88  VALID-MONTH           VALUE 01 THRU 12.
                   88  MONTH-31-DAYS         VALUE 01 03 05 07 08 10 12.
                   88  MONTH-30-DAYS         VALUE 04 06 09 11.
                   88  MONTH-FEBRUARY        VALUE 02.
               10  WS-DAY              PIC 9(02).
           05  WS-MAX-DAYS             PIC S9(03) COMP-3 VALUE ZERO.
           05  WS-LEAP-QUOTIENT        PIC S9(05) COMP-3 VALUE ZERO.
           05  WS-LEAP-REM-4           PIC S9(03) COMP-3 VALUE ZERO.
           05  WS-LEAP-REM-100         PIC S9(03) COMP-3 VALUE ZERO.
           05  WS-LEAP-REM-400         PIC S9(03) COMP-3 VALUE ZERO.

       01  WS-OWNER-WORK-AREA.
           05  WS-OWNER-CHECK          PIC X(08) VALUE SPACES.
           05  WS-OWNER-BYTES REDEFINES WS-OWNER-CHECK.
               10  WS-FIRST-CHAR       PIC X(01).
                   88  VALID-FIRST-CHAR      VALUE 'A' THRU 'I'
                                                   'J' THRU 'R'
                                                   'S' THRU 'Z'
                                                   '@' '#' '$'.
               10  WS-MID-CHARS        PIC X(06).
               10  WS-EIGHTH-CHAR      PIC X(01).

       LINKAGE SECTION.
       01  LS-VALIDATION-PARM.
           COPY TODOVLNK.

       PROCEDURE DIVISION USING LS-VALIDATION-PARM.
      *----------------------------------------------------------------*
      * 0000-MAIN-CONTROL:                                             *
      *   EXECUTIVE DRIVER VALIDATING LINKAGE INPUTS AND RETURNING     *
      *   STATUS TO CALLING TSO, BATCH, OR KICKS MODULE.               *
      *----------------------------------------------------------------*
       0000-MAIN-CONTROL.
           PERFORM 1000-INIT-VALIDATION.
           PERFORM 2000-DISPATCH-CHECKS.
           PERFORM 3000-FINISH-VALIDATION.
           EXIT PROGRAM.
           GOBACK.

      *----------------------------------------------------------------*
      * 1000-INIT-VALIDATION:                                          *
      *   RESETS OUTPUT STATUS AND ERROR CODES TO CLEAN DEFAULTS.      *
      *----------------------------------------------------------------*
       1000-INIT-VALIDATION.
           MOVE 'Y'    TO VLNK-VALID-SW.
           MOVE '0000' TO VLNK-ERR-CODE.
           MOVE SPACES TO VLNK-ERR-MSG.

      *----------------------------------------------------------------*
      * 2000-DISPATCH-CHECKS:                                          *
      *   EXECUTES APPROPRIATE VALIDATION ROUTINES BASED ON FUNCTION.  *
      *----------------------------------------------------------------*
       2000-DISPATCH-CHECKS.
           IF VLNK-CHECK-DATE
               PERFORM 2400-CHECK-DATE
           ELSE
               IF VLNK-CHECK-TASK
                   PERFORM 2100-CHECK-TITLE
                   IF VLNK-IS-VALID
                       PERFORM 2200-CHECK-STATUS
                   END-IF
                   IF VLNK-IS-VALID
                       PERFORM 2300-CHECK-PRIORITY
                   END-IF
                   IF VLNK-IS-
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.KICKS.BMS FROM kicks-bms\*.bms
//*-------------------------------------------------------------------*
//LDkicksb EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.KICKS.BMS,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=TODOM00
TODOM00  DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,TIOAPFX=YES,       X
               CTRL=(FREEKB,FRSET),STORAGE=AUTO
*=====================================================================*
* MAP 1: TODOM1 - TASK LIST / BROWSE SCREEN (24X80 MODEL 2)           *
*=====================================================================*
TODOM1   DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
         DFHMDF POS=(1,2),LENGTH=4,ATTRB=(ASKIP,NORM),INITIAL='TODO'
         DFHMDF POS=(1,24),LENGTH=31,ATTRB=(ASKIP,BRT),                X
               INITIAL='MVS 3.8J TASK MANAGER - BROWSE'
         DFHMDF POS=(1,65),LENGTH=5,ATTRB=(ASKIP,NORM),INITIAL='USER:'
M1USER   DFHMDF POS=(1,71),LENGTH=8,ATTRB=(ASKIP,BRT)
*
         DFHMDF POS=(2,2),LENGTH=11,ATTRB=(ASKIP,NORM),                X
               INITIAL='VIEW OWNER:'
M1OWNR   DFHMDF POS=(2,14),LENGTH=8,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(2,23),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(2,26),LENGTH=23,ATTRB=(ASKIP,NORM),               X
               INITIAL='FILTER (O=ACT W=WT A=ALL):'
M1FILT   DFHMDF POS=(2,50),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(2,52),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(2,55),LENGTH=24,ATTRB=(ASKIP,NORM),               X
               INITIAL='ACT: S=EDT C=DN W=WT X=CN'
*
         DFHMDF POS=(4,2),LENGTH=76,ATTRB=(ASKIP,BRT),                 X
               INITIAL='ACT TASK-ID  ST PRI DUE-DATE CATEGORY   TITLE  X
                                              '
         DFHMDF POS=(5,2),LENGTH=76,ATTRB=(ASKIP,NORM),                X
               INITIAL='--- -------- -- --- -------- ---------- ------ X
               ------------------------------'
*
* ROW 1 (LINE 6)
M1ACT01  DFHMDF POS=(6,3),LENGTH=1,ATTRB=(UNPROT,BRT,IC)
         DFHMDF POS=(6,5),LENGTH=1,ATTRB=ASKIP
M1ID01   DFHMDF POS=(6,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST01   DFHMDF POS=(6,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR01   DFHMDF POS=(6,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU01   DFHMDF POS=(6,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT01   DFHMDF POS=(6,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI01   DFHMDF POS=(6,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 2 (LINE 7)
M1ACT02  DFHMDF POS=(7,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(7,5),LENGTH=1,ATTRB=ASKIP
M1ID02   DFHMDF POS=(7,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST02   DFHMDF POS=(7,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR02   DFHMDF POS=(7,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU02   DFHMDF POS=(7,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT02   DFHMDF POS=(7,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI02   DFHMDF POS=(7,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 3 (LINE 8)
M1ACT03  DFHMDF POS=(8,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(8,5),LENGTH=1,ATTRB=ASKIP
M1ID03   DFHMDF POS=(8,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST03   DFHMDF POS=(8,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR03   DFHMDF POS=(8,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU03   DFHMDF POS=(8,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT03   DFHMDF POS=(8,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI03   DFHMDF POS=(8,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 4 (LINE 9)
M1ACT04  DFHMDF POS=(9,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(9,5),LENGTH=1,ATTRB=ASKIP
M1ID04   DFHMDF POS=(9,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST04   DFHMDF POS=(9,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR04   DFHMDF POS=(9,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU04   DFHMDF POS=(9,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT04   DFHMDF POS=(9,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI04   DFHMDF POS=(9,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 5 (LINE 10)
M1ACT05  DFHMDF POS=(10,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(10,5),LENGTH=1,ATTRB=ASKIP
M1ID05   DFHMDF POS=(10,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST05   DFHMDF POS=(10,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR05   DFHMDF POS=(10,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU05   DFHMDF POS=(10,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT05   DFHMDF POS=(10,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI05   DFHMDF POS=(10,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 6 (LINE 11)
M1ACT06  DFHMDF POS=(11,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(11,5),LENGTH=1,ATTRB=ASKIP
M1ID06   DFHMDF POS=(11,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST06   DFHMDF POS=(11,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR06   DFHMDF POS=(11,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU06   DFHMDF POS=(11,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT06   DFHMDF POS=(11,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI06   DFHMDF POS=(11,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 7 (LINE 12)
M1ACT07  DFHMDF POS=(12,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(12,5),LENGTH=1,ATTRB=ASKIP
M1ID07   DFHMDF POS=(12,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST07   DFHMDF POS=(12,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR07   DFHMDF POS=(12,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU07   DFHMDF POS=(12,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT07   DFHMDF POS=(12,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI07   DFHMDF POS=(12,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 8 (LINE 13)
M1ACT08  DFHMDF POS=(13,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(13,5),LENGTH=1,ATTRB=ASKIP
M1ID08   DFHMDF POS=(13,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST08   DFHMDF POS=(13,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR08   DFHMDF POS=(13,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU08   DFHMDF POS=(13,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT08   DFHMDF POS=(13,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI08   DFHMDF POS=(13,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 9 (LINE 14)
M1ACT09  DFHMDF POS=(14,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(14,5),LENGTH=1,ATTRB=ASKIP
M1ID09   DFHMDF POS=(14,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST09   DFHMDF POS=(14,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR09   DFHMDF POS=(14,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU09   DFHMDF POS=(14,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT09   DFHMDF POS=(14,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI09   DFHMDF POS=(14,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
* ROW 10 (LINE 15)
M1ACT10  DFHMDF POS=(15,3),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(15,5),LENGTH=1,ATTRB=ASKIP
M1ID10   DFHMDF POS=(15,6),LENGTH=8,ATTRB=(ASKIP,NORM)
M1ST10   DFHMDF POS=(15,15),LENGTH=1,ATTRB=(ASKIP,BRT)
M1PR10   DFHMDF POS=(15,19),LENGTH=1,ATTRB=(ASKIP,NORM)
M1DU10   DFHMDF POS=(15,22),LENGTH=8,ATTRB=(ASKIP,NORM)
M1CT10   DFHMDF POS=(15,31),LENGTH=10,ATTRB=(ASKIP,NORM)
M1TI10   DFHMDF POS=(15,42),LENGTH=36,ATTRB=(ASKIP,NORM)
*
M1MSG    DFHMDF POS=(22,2),LENGTH=78,ATTRB=(ASKIP,BRT)
         DFHMDF POS=(24,2),LENGTH=74,ATTRB=(ASKIP,NORM),               X
               INITIAL='ENTER=Process  PF3=Exit  PF4=Add  PF5=Refresh  X
               PF8=NextPg  PF9=Settings'
*
*=====================================================================*
* MAP 2: TODOM2 - ADD / EDIT / DELEGATE TASK DETAIL SCREEN            *
*=====================================================================*
TODOM2   DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
         DFHMDF POS=(1,2),LENGTH=4,ATTRB=(ASKIP,NORM),INITIAL='TODO'
         DFHMDF POS=(1,23),LENGTH=33,ATTRB=(ASKIP,BRT),                X
               INITIAL='MVS 3.8J TASK MANAGER - TASK EDIT'
M2MODE   DFHMDF POS=(2,32),LENGTH=16,ATTRB=(ASKIP,BRT)
*
         DFHMDF POS=(4,4),LENGTH=12,ATTRB=(ASKIP,NORM),                X
               INITIAL='TASK ID    :'
M2ID     DFHMDF POS=(4,17),LENGTH=8,ATTRB=(ASKIP,BRT)
         DFHMDF POS=(4,35),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='OWNER ID   :'
M2OWNR   DFHMDF POS=(4,48),LENGTH=8,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(4,57),LENGTH=1,ATTRB=ASKIP
*
         DFHMDF POS=(6,4),LENGTH=12,ATTRB=(ASKIP,NORM),                X
               INITIAL='TITLE      :'
M2TITL   DFHMDF POS=(6,17),LENGTH=60,ATTRB=(UNPROT,BRT,IC)
         DFHMDF POS=(6,78),LENGTH=1,ATTRB=ASKIP
*
         DFHMDF POS=(8,4),LENGTH=12,ATTRB=(ASKIP,NORM),                X
               INITIAL='CATEGORY   :'
M2CAT    DFHMDF POS=(8,17),LENGTH=10,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(8,28),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(8,35),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='STATUS     :'
M2STAT   DFHMDF POS=(8,48),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(8,50),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(8,52),LENGTH=23,ATTRB=(ASKIP,NORM),               X
               INITIAL='(O/I/W=ACT, C/X=CLOSED)'
*
         DFHMDF POS=(10,4),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='PRIORITY   :'
M2PRI    DFHMDF POS=(10,17),LENGTH=1,ATTRB=(UNPROT,BRT,NUM)
         DFHMDF POS=(10,19),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(10,21),LENGTH=9,ATTRB=(ASKIP,NORM),               X
               INITIAL='(1-5)    '
         DFHMDF POS=(10,35),LENGTH=12,ATTRB=(ASKIP,NORM),              X
               INITIAL='DUE DATE   :'
M2DUE    DFHMDF POS=(10,48),LENGTH=8,ATTRB=(UNPROT,BRT,NUM)
         DFHMDF POS=(10,57),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(10,59),LENGTH=15,ATTRB=(ASKIP,NORM),              X
               INITIAL='(YYYYMMDD / 0) '
*
         DFHMDF POS=(12,4),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='CREATED BY :'
M2CBY    DFHMDF POS=(12,17),LENGTH=8,ATTRB=(ASKIP,NORM)
         DFHMDF POS=(12,35),LENGTH=12,ATTRB=(ASKIP,NORM),              X
               INITIAL='CREATED ON :'
M2CDT    DFHMDF POS=(12,48),LENGTH=8,ATTRB=(ASKIP,NORM)
*
         DFHMDF POS=(14,4),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='NOTE LINE 1:'
M2NOT1   DFHMDF POS=(14,17),LENGTH=60,ATTRB=(UNPROT,NORM)
         DFHMDF POS=(14,78),LENGTH=1,ATTRB=ASKIP
*
         DFHMDF POS=(15,4),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='NOTE LINE 2:'
M2NOT2   DFHMDF POS=(15,17),LENGTH=60,ATTRB=(UNPROT,NORM)
         DFHMDF POS=(15,78),LENGTH=1,ATTRB=ASKIP
*
         DFHMDF POS=(16,4),LENGTH=12,ATTRB=(ASKIP,NORM),               X
               INITIAL='NOTE LINE 3:'
M2NOT3   DFHMDF POS=(16,17),LENGTH=60,ATTRB=(UNPROT,NORM)
         DFHMDF POS=(16,78),LENGTH=1,ATTRB=ASKIP
*
M2MSG    DFHMDF POS=(22,2),LENGTH=78,ATTRB=(ASKIP,BRT)
         DFHMDF POS=(24,2),LENGTH=54,ATTRB=(ASKIP,NORM),               X
               INITIAL='ENTER=Save Task   PF3=Return to List   PF12=CaX
               ncel'
*
*=====================================================================*
* MAP 3: TODOM3 - USER PREFERENCES & PRINT SUBSCRIPTION SCREEN        *
*=====================================================================*
TODOM3   DFHMDI SIZE=(24,80),LINE=1,COLUMN=1
         DFHMDF POS=(1,2),LENGTH=4,ATTRB=(ASKIP,NORM),INITIAL='TODO'
         DFHMDF POS=(1,21),LENGTH=37,ATTRB=(ASKIP,BRT),                X
               INITIAL='MVS 3.8J TASK MANAGER - USER SETTINGS'
*
         DFHMDF POS=(5,6),LENGTH=22,ATTRB=(ASKIP,NORM),                X
               INITIAL='TSO USER ID          :'
M3USER   DFHMDF POS=(5,29),LENGTH=8,ATTRB=(ASKIP,BRT)
*
         DFHMDF POS=(7,6),LENGTH=22,ATTRB=(ASKIP,NORM),                X
               INITIAL='BANNER DISPLAY NAME  :'
M3NAME   DFHMDF POS=(7,29),LENGTH=24,ATTRB=(UNPROT,BRT,IC)
         DFHMDF POS=(7,54),LENGTH=1,ATTRB=ASKIP
*
         DFHMDF POS=(9,6),LENGTH=22,ATTRB=(ASKIP,NORM),                X
               INITIAL='DAILY ACTION SHEET   :'
M3PRNT   DFHMDF POS=(9,29),LENGTH=1,ATTRB=(UNPROT,BRT)
         DFHMDF POS=(9,31),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(9,33),LENGTH=24,ATTRB=(ASKIP,NORM),               X
               INITIAL='(Y=Print Nightly, N=Off)'
*
         DFHMDF POS=(11,6),LENGTH=22,ATTRB=(ASKIP,NORM),               X
               INITIAL='DEFAULT PRIORITY     :'
M3PRI    DFHMDF POS=(11,29),LENGTH=1,ATTRB=(UNPROT,BRT,NUM)
         DFHMDF POS=(11,31),LENGTH=1,ATTRB=ASKIP
         DFHMDF POS=(11,33),LENGTH=15,ATTRB=(ASKIP,NORM),              X
               INITIAL='(1=Urgent..5)  '
*
         DFHMDF POS=(13,6),LENGTH=22,ATTRB=(ASKIP,NORM),               X
               INITIAL='LAST ASSIGNED TASK ID:'
M3LAST   DFHMDF POS=(13,29),LENGTH=8,ATTRB=(ASKIP,NORM)
*
M3MSG    DFHMDF POS=(22,2),LENGTH=78,ATTRB=(ASKIP,BRT)
         DFHMDF POS=(24,2),LENGTH=54,ATTRB=(ASKIP,NORM),               X
               INITIAL='ENTER=Save Settings   PF3=Return to List   PF1X
               2=Cancel'
         DFHMSD TYPE=FINAL
         END
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.KICKS.COBOL FROM kicks-cobol\*.cbl
//*-------------------------------------------------------------------*
//LDkicksc EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.KICKS.COBOL,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=TODOK01
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
./ ADD NAME=TODOK02
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
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.KICKS.COBOL FROM kicks-cobol\*.asm
//*-------------------------------------------------------------------*
//LDkicksc EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.KICKS.COBOL,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=KIKFCT2$
KIKFCT TYPE=INITIAL,SUFFIX=2$
         KIKFCT TYPE=ENTRY,DATASET=TODOMAST,ACCMETH=VSAM,               X
               SERVREQ=(ADD,BROWSE,DELETE,READ,UPDATE),STRNO=2
         KIKFCT TYPE=ENTRY,DATASET=TODOPATH,ACCMETH=VSAM,               X
               SERVREQ=(BROWSE,READ),STRNO=2
         KIKFCT TYPE=ENTRY,DATASET=TODOCTRL,ACCMETH=VSAM,               X
               SERVREQ=(ADD,BROWSE,READ,UPDATE),STRNO=2
         KIKFCT TYPE=FINAL
         END
./ ADD NAME=KIKPCT2$
KIKPCT TYPE=INITIAL,SUFFIX=2$
         KIKPCT TYPE=ENTRY,TRANSID=TODO,PROGRAM=TODOK01
         KIKPCT TYPE=FINAL
         END
./ ADD NAME=KIKPPT2$
KIKPPT TYPE=INITIAL,SUFFIX=2$
         KIKPPT TYPE=ENTRY,PROGRAM=TODOK01,PGMLANG=CMDLVL
         KIKPPT TYPE=ENTRY,PROGRAM=TODOK02,PGMLANG=CMDLVL
         KIKPPT TYPE=ENTRY,MAPSET=TODOM00,USAGE=MAP
         KIKPPT TYPE=FINAL
         END
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.CLIST FROM clist\*.clist
//*-------------------------------------------------------------------*
//LDclistc EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.CLIST,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=TODO
PROC 1 SUBCMD ARG1() ARG2() TITLE() DUE(00000000) PRI(0) +
       CAT() TO() USER() NOTE() LINE(1) NAME()
/*===================================================================*/
/* CLIST:     TODO - TSO LINE-MODE CLI DRIVER FOR TODO MANAGER       */
/* SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5)                            */
/* USAGE:                                                            */
/*   %TODO LIST [ALL|OPEN|WAIT] [USER(uid)]                          */
/*   %TODO ADD TITLE('text') [DUE(yyyymmdd)] [PRI(1-5)] [CAT(c)]     */
/*             [TO(uid)] [NOTE('text')]                              */
/*   %TODO VIEW ARG1(id)                                             */
/*   %TODO START|WAIT|DONE|CANCEL ARG1(id)                           */
/*   %TODO ASSIGN ARG1(id) TO(uid)                                   */
/*   %TODO NOTE ARG1(id) NOTE('text') [LINE(1|2|3)]                  */
/*   %TODO PRINT ARG1(ON|OFF) [NAME('display name')] [PRI(1-5)]      */
/*===================================================================*/
CONTROL NOLIST NOCONLIST NOSYMLIST NOFLUSH

SET &UID     = &SYSSTR(&SYSUID        ,1,8)
SET &VERB    = &SYSSTR(&SUBCMD        ,1,8)
SET &P1      = &SYSSTR(&ARG1                ,1,16)
SET &P2      = &SYSSTR(&ARG2                ,1,16)
SET &DDUE    = &SYSSTR(&DUE        ,1,8)
SET &DPRI    = &SYSSTR(&PRI ,1,1)
SET &DLINE   = &SYSSTR(&LINE ,1,1)
SET &DCAT    = &SYSSTR(&CAT          ,1,10)
SET &DTO     = &SYSSTR(&TO        ,1,8)

IF &STR(&USER) NE &STR() THEN +
  SET &DTO = &SYSSTR(&USER        ,1,8)

SET &DTITLE  = &SYSSTR(&TITLE                                                            ,1,60)
IF &STR(&NAME) NE &STR() THEN +
  SET &DTITLE = &SYSSTR(&NAME                                                            ,1,60)

SET &DNOTE   = &SYSSTR(&NOTE                                                            ,1,60)

SET &CMDREC  = &STR(&UID&VERB&P1&P2&DDUE&DPRI&DLINE&DCAT&DTO&DTITLE&DNOTE    )
SET &TEMPDSN = &STR('&SYSUID..TODO.CMDTEMP')

/* CLEAN UP ANY STALE TEMP DATASET AND ALLOCATE FRESH 200-BYTE FILE */
FREE FI(CMDSYSIN TODOMAST TODOPATH TODOCTRL)
DELETE &TEMPDSN

ALLOC FI(CMDSYSIN) DA(&TEMPDSN) NEW CATALOG +
      SPACE(1,1) TRACKS UNIT(SYSDA) +
      RECFM(F B) LRECL(200) BLKSIZE(200)

OPENFILE CMDSYSIN OUTPUT
SET &CMDSYSIN = &STR(&CMDREC)
PUTFILE CMDSYSIN
CLOSFILE CMDSYSIN

/* ALLOCATE VSAM CLUSTERS SHR & ROUTE SYSOUT TO TSO TERMINAL */
ALLOC FI(TODOMAST) DA('TODO.MASTER.CLUSTER') SHR
ALLOC FI(TODOPATH) DA('TODO.MASTER.PATH1')   SHR
ALLOC FI(TODOCTRL) DA('TODO.CONTROL.CLUSTER') SHR
ALLOC FI(SYSOUT)   DA(*)

CALL 'TODO.LOADLIB(TODOCMD)'
SET &SAVERC = &LASTCC

/* IMMEDIATELY RELEASE ALL DATASET LOCKS & DELETE TEMP WORK FILE */
FREE FI(CMDSYSIN TODOMAST TODOPATH TODOCTRL)
DELETE &TEMPDSN

EXIT CODE(&SAVERC)
./ ADD NAME=TODOKICK
PROC 0
/*===================================================================*/
/* CLIST:     TODOKICK - UPGRADE-SAFE KICKS LAUNCHER FOR TODO APP    */
/* SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5)                            */
/*===================================================================*/
CONTROL NOLIST NOCONLIST NOSYMLIST NOFLUSH

FREE FI(TODOMAST TODOPATH TODOCTRL)
ALLOC FI(TODOMAST) DA('TODO.MASTER.CLUSTER') SHR
ALLOC FI(TODOPATH) DA('TODO.MASTER.PATH1')   SHR
ALLOC FI(TODOCTRL) DA('TODO.CONTROL.CLUSTER') SHR

/* INVOKE KICKS WITH TODO.KICKS.LOADLIB CONCATENATED AND 2$ TABLES   */
EXEC 'KICKS.V1R5M0.CLIST(KICKS)' +
     'PPT(2$) PCT(2$) FCT(2$) USRLOAD(''TODO.KICKS.LOADLIB'')'

FREE FI(TODOMAST TODOPATH TODOCTRL)
EXIT CODE(0)
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.PARMLIB FROM parmlib\*.txt
//*-------------------------------------------------------------------*
//LDparmli EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.PARMLIB,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=PRTLIST
*======================================================================*
* MEMBER: TODO.PARMLIB(PRTLIST) - DAILY ACTION SHEET USER OVERRIDE LIST  *
*                                                                      *
* SUBSCRIPTION MODEL C RULES:                                          *
*   1. LINES STARTING WITH '*' IN COLUMN 1 OR BLANK LINES ARE IGNORED. *
*   2. IF THIS MEMBER CONTAINS NO ACTIVE USERID LINES, TODOBAT2 SCANS  *
*      TODO.CONTROL.CLUSTER AND PRINTS FOR ALL USERS WITH PRINT='Y'.   *
*   3. IF ONE OR MORE USERIDS ARE LISTED BELOW (COLS 1-8), TODOBAT2    *
*      PRINTS ACTION SHEETS EXCLUSIVELY FOR THOSE LISTED USERS.        *
*======================================================================*
*HERC01
*HERC02
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD TODO.JCL FROM jcl\*.jcl
//*-------------------------------------------------------------------*
//LDjcljcl EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=TODO.JCL,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=COMPALL
//COMPALL  JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(5,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//         JCLLIB ORDER=(KICKS.V1R5M0.PROCLIB)
//*===================================================================*
//* JOB: COMPALL - MASTER BUILD FOR TODO MANAGER (MVS 3.8J TK5)       *
//* BUILDS: TODOLOCK, TODOVAL, TODOCMD, TODOBAT1, TODOBAT2, TODOM00,  *
//*         TODOK01, TODOK02, AND KICKS 2$ RESOURCE TABLES.           *
//*===================================================================*
//* STEP 1: ASSEMBLE TODOLOCK (SYSTEM-WIDE ENQ/DEQ) INTO BOTH LOADLIBS*
//*-------------------------------------------------------------------*
//ASMLOCK  EXEC ASMFCL,
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='NCAL,LIST,MAP'
//ASM.SYSLIB DD DSN=SYS1.MACLIB,DISP=SHR
//           DD DSN=SYS1.AMODGEN,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.ASM(TODOLOCK),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOLOCK),DISP=SHR
//*
//CPYLOCK  EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.LOADLIB,DISP=SHR
//SYSUT2   DD  DSN=TODO.KICKS.LOADLIB,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODOLOCK)
/*
//*-------------------------------------------------------------------*
//* STEP 2: COMPILE TODOVAL SUBPROGRAM (NCAL) INTO BOTH LOADLIBS      *
//*-------------------------------------------------------------------*
//CMPVAL   EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='NCAL,LIST,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOVAL),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOVAL),DISP=SHR
//*
//CPYVAL   EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.LOADLIB,DISP=SHR
//SYSUT2   DD  DSN=TODO.KICKS.LOADLIB,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODOVAL)
/*
//*-------------------------------------------------------------------*
//* STEP 3: COMPILE & LINK TODOCMD (TSO LINE-MODE CLI PROCESSOR)      *
//*-------------------------------------------------------------------*
//CMPCMD   EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOCMD),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOCMD),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 4: COMPILE & LINK TODOBAT1 (NIGHTLY ARCHIVE & PURGE)         *
//*-------------------------------------------------------------------*
//CMPBAT1  EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOBAT1),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOBAT1),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 5: COMPILE & LINK TODOBAT2 (DAILY ACTION SHEET PRINTER)      *
//*-------------------------------------------------------------------*
//CMPBAT2  EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOBAT2),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOBAT2),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 6: ASSEMBLE BMS SYMBOLIC & PHYSICAL MAPSET (TODOM00)         *
//*-------------------------------------------------------------------*
//MAPGEN   EXEC KIKMAPS,COND=(4,LT),
//         MAPNAME=TODOM00,
//         MAPSRC='TODO.KICKS.BMS',
//         COPYLIB='TODO.COPYLIB',
//         LOADLIB='TODO.KICKS.LOADLIB'
//*-------------------------------------------------------------------*
//* STEP 7: TRANSLATE, COMPILE & LINK KICKS BROWSE MODULE (TODOK01)   *
//*-------------------------------------------------------------------*
//CMPK01   EXEC KIKCB2CL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//TRN.SYSIN  DD DSN=TODO.KICKS.COBOL(TODOK01),DISP=SHR
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//           DD DSN=KICKS.V1R5M0.COBCOPY,DISP=SHR
//LKED.SYSLIB DD DSN=KICKS.V1R5M0.SKIKLOAD,DISP=SHR
//            DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.KICKS.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(TODOK01),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 8: TRANSLATE, COMPILE & LINK KICKS DETAIL MODULE (TODOK02)   *
//*-------------------------------------------------------------------*
//CMPK02   EXEC KIKCB2CL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//TRN.SYSIN  DD DSN=TODO.KICKS.COBOL(TODOK02),DISP=SHR
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//           DD DSN=KICKS.V1R5M0.COBCOPY,DISP=SHR
//LKED.SYSLIB DD DSN=KICKS.V1R5M0.SKIKLOAD,DISP=SHR
//            DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.KICKS.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(TODOK02),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 9: ASSEMBLE & LINK CUSTOM KICKS TABLES (KIKPPT2$/PCT2$/FCT2$)*
//*-------------------------------------------------------------------*
//ASMPPT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKPPT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKPPT2$),DISP=SHR
//*
//ASMPCT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKPCT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKPCT2$),DISP=SHR
//*
//ASMFCT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKFCT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKFCT2$),DISP=SHR
//
./ ADD NAME=INSTCORE
//INSTCORE JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(2,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//*===================================================================*
//* JOB: INSTCORE - ALLOCATE TODO PDS LIBRARIES & VSAM CLUSTERS       *
//* NOTE: ALL DATASETS RESIDE ON USER-PRESERVED VOLUME PUB000.        *
//*===================================================================*
//* STEP 1: DEFINE MASTER CATALOG ALIAS FOR HLQ 'TODO'                *
//*-------------------------------------------------------------------*
//DEFALIAS EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO ALIAS
  SET MAXCC = 0
  DEFINE ALIAS (NAME(TODO) RELATE(SYS1.UCAT.TSO))
/*
//*-------------------------------------------------------------------*
//* STEP 2: ALLOCATE DEPARTMENTAL SOURCE, JCL, CLIST, & LOAD PDS'S    *
//*-------------------------------------------------------------------*
//ALLOCPDS EXEC PGM=IEFBR14,COND=(4,LT)
//COPYLIB  DD  DSN=TODO.COPYLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//COBOL    DD  DSN=TODO.COBOL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//ASM      DD  DSN=TODO.ASM,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//KCOBOL   DD  DSN=TODO.KICKS.COBOL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(30,10,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//KBMS     DD  DSN=TODO.KICKS.BMS,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//CLIST    DD  DSN=TODO.CLIST,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//PARMLIB  DD  DSN=TODO.PARMLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//JCL      DD  DSN=TODO.JCL,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5,20)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=6160)
//LOADLIB  DD  DSN=TODO.LOADLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(CYL,(5,2,30)),
//             DCB=(DSORG=PO,RECFM=U,LRECL=0,BLKSIZE=19069)
//KLOADLIB DD  DSN=TODO.KICKS.LOADLIB,DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(CYL,(5,2,30)),
//             DCB=(DSORG=PO,RECFM=U,LRECL=0,BLKSIZE=19069)
//*-------------------------------------------------------------------*
//* STEP 3: DEFINE VSAM KSDS CLUSTERS, AIX, PATH, AND ARCHIVE GDG     *
//*-------------------------------------------------------------------*
//DEFVSAM  EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO.MASTER.CLUSTER CLUSTER PURGE
  DELETE TODO.CONTROL.CLUSTER CLUSTER PURGE
  SET MAXCC = 0

  DEFINE CLUSTER ( -
           NAME(TODO.MASTER.CLUSTER) -
           INDEXED -
           TRACKS(15 5) -
           VOLUMES(PUB000) -
           RECORDSIZE(332 332) -
           KEYS(16 0) -
           CISZ(4096) -
           FREESPACE(20 10) -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.MASTER.DATA) ) -
         INDEX ( -
           NAME(TODO.MASTER.INDEX) )

  DEFINE CLUSTER ( -
           NAME(TODO.CONTROL.CLUSTER) -
           INDEXED -
           TRACKS(2 1) -
           VOLUMES(PUB000) -
           RECORDSIZE(64 64) -
           KEYS(8 0) -
           CISZ(2048) -
           FREESPACE(20 10) -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.CONTROL.DATA) ) -
         INDEX ( -
           NAME(TODO.CONTROL.INDEX) )

  DEFINE ALTERNATEINDEX ( -
           NAME(TODO.MASTER.AIX1) -
           RELATE(TODO.MASTER.CLUSTER) -
           TRACKS(5 2) -
           VOLUMES(PUB000) -
           KEYS(17 16) -
           RECORDSIZE(60 200) -
           NONUNIQUEKEY -
           UPGRADE -
           SHAREOPTIONS(3 3) ) -
         DATA ( -
           NAME(TODO.MASTER.AIX1.DATA) ) -
         INDEX ( -
           NAME(TODO.MASTER.AIX1.INDEX) )

  DEFINE PATH ( -
           NAME(TODO.MASTER.PATH1) -
           PATHENTRY(TODO.MASTER.AIX1) -
           UPDATE )

  DEFINE GDG ( -
           NAME(TODO.ARCHIVE.GDG) -
           LIMIT(30) -
           NOEMPTY -
           SCRATCH )
/*
//*-------------------------------------------------------------------*
//* STEP 4: LOAD ZERO-KEY SENTINEL RECORDS & BUILD ALTERNATE INDEX    *
//*         (REQUIRED BY MVS 3.8J VSAM BEFORE OPEN FOR I-O)           *
//*-------------------------------------------------------------------*
//SEEDVSAM EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//MASTSEED DD  *
000000000000000000000000000000000SEED RECORD - DO NOT DELETE                                        SYSTEM    X90000000000000000SYSTEM  00000000                                                                                                                                                                                              000000000000000
/*
//CTRLSEED DD  *
0000000000000000N3SENTINEL CONTROL RECORD   00000000000000000000
/*
//SYSIN    DD  *
  REPRO INFILE(MASTSEED) OUTDATASET(TODO.MASTER.CLUSTER)
  REPRO INFILE(CTRLSEED) OUTDATASET(TODO.CONTROL.CLUSTER)
  BLDINDEX INDATASET(TODO.MASTER.CLUSTER) -
           OUTDATASET(TODO.MASTER.AIX1)
/*
//
./ ADD NAME=INSTHOOK
//INSTHOOK JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(1,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//*===================================================================*
//* JOB: INSTHOOK - IDEMPOTENT TK5 POST-UPGRADE SYSTEM HOOKS          *
//* PURPOSE: RE-ESTABLISHES THE 'TODO' MASTER CATALOG ALIAS AND       *
//*          COPIES TODO/TODOKICK CLISTS INTO SYS2.CMDPROC.           *
//*          SAFE TO RUN REPEATEDLY AFTER ANY TK5 SYSTEM UPGRADE.     *
//*===================================================================*
//* STEP 1: RE-LINK 'TODO' ALIAS TO USER CATALOG ON PUB000            *
//*-------------------------------------------------------------------*
//REALIAS  EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO ALIAS
  SET MAXCC = 0
  DEFINE ALIAS (NAME(TODO) RELATE(SYS1.UCAT.TSO))
/*
//*-------------------------------------------------------------------*
//* STEP 2: REFRESH TSO CLIST HOOKS IN SYS2.CMDPROC FROM TODO.CLIST   *
//*-------------------------------------------------------------------*
//HOOKCLST EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.CLIST,DISP=SHR
//SYSUT2   DD  DSN=SYS2.CMDPROC,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODO,TODOKICK)
/*
//
./ ADD NAME=TODONITE
//TODONITE JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(5,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//*===================================================================*
//* JOB: TODONITE - NIGHTLY TODO ARCHIVE, VSAM REORG & ACTION SHEETS  *
//*===================================================================*
//* STEP 1: IDEMPOTENT CLEANUP OF STAGING DATASET FOR RESTARTABILITY  *
//*-------------------------------------------------------------------*
//CLEANUP  EXEC PGM=IEFBR14
//TMPDEL   DD  DSN=TODO.REORG.TEMP,
//             DISP=(MOD,DELETE,DELETE),
//             UNIT=3350,VOL=SER=PUB000,SPACE=(TRK,(1,0))
//*-------------------------------------------------------------------*
//* STEP 2: ARCHIVE COMPLETED/CANCELLED TASKS TO GDG(+1) & PURGE      *
//*-------------------------------------------------------------------*
//ARCHIVE  EXEC PGM=TODOBAT1,COND=(4,LT)
//STEPLIB  DD  DSN=TODO.LOADLIB,DISP=SHR
//TODOMAST DD  DSN=TODO.MASTER.CLUSTER,DISP=SHR
//ARCHOUT  DD  DSN=TODO.ARCHIVE.GDG(+1),
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(5,2),RLSE),
//             DCB=(RECFM=FB,LRECL=332,BLKSIZE=6308)
//SYSOUT   DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*-------------------------------------------------------------------*
//* STEP 3: REORGANIZE MASTER KSDS & REBUILD ALTERNATE INDEX (AIX1)   *
//*-------------------------------------------------------------------*
//REORG    EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//REORGTMP DD  DSN=TODO.REORG.TEMP,
//             DISP=(NEW,CATLG,DELETE),
//             UNIT=3350,VOL=SER=PUB000,
//             SPACE=(TRK,(15,5),RLSE),
//             DCB=(RECFM=FB,LRECL=332,BLKSIZE=6308)
//SYSIN    DD  *
  REPRO INDATASET(TODO.MASTER.CLUSTER) OUTFILE(REORGTMP)
  IF LASTCC = 0 THEN DO
    DELETE TODO.MASTER.CLUSTER CLUSTER PURGE
    DEFINE CLUSTER ( -
             NAME(TODO.MASTER.CLUSTER) -
             INDEXED -
             TRACKS(15 5) -
             VOLUMES(PUB000) -
             RECORDSIZE(332 332) -
             KEYS(16 0) -
             CISZ(4096) -
             FREESPACE(20 10) -
             SHAREOPTIONS(3 3) ) -
           DATA ( -
             NAME(TODO.MASTER.DATA) ) -
           INDEX ( -
             NAME(TODO.MASTER.INDEX) )
    DEFINE ALTERNATEINDEX ( -
             NAME(TODO.MASTER.AIX1) -
             RELATE(TODO.MASTER.CLUSTER) -
             TRACKS(5 2) -
             VOLUMES(PUB000) -
             KEYS(17 16) -
             RECORDSIZE(60 200) -
             NONUNIQUEKEY -
             UPGRADE -
             SHAREOPTIONS(3 3) ) -
           DATA ( -
             NAME(TODO.MASTER.AIX1.DATA) ) -
           INDEX ( -
             NAME(TODO.MASTER.AIX1.INDEX) )
    DEFINE PATH ( -
             NAME(TODO.MASTER.PATH1) -
             PATHENTRY(TODO.MASTER.AIX1) -
             UPDATE )
    REPRO INFILE(REORGTMP) OUTDATASET(TODO.MASTER.CLUSTER)
    BLDINDEX INDATASET(TODO.MASTER.CLUSTER) -
             OUTDATASET(TODO.MASTER.AIX1)
  END
/*
//*-------------------------------------------------------------------*
//* STEP 4: REMOVE TEMPORARY REORG STAGING DATASET                    *
//*-------------------------------------------------------------------*
//DELTEMP  EXEC PGM=IEFBR14,COND=(4,LT)
//TMPDEL   DD  DSN=TODO.REORG.TEMP,
//             DISP=(MOD,DELETE,DELETE),
//             UNIT=3350,VOL=SER=PUB000,SPACE=(TRK,(1,0))
//*-------------------------------------------------------------------*
//* STEP 5: PRINT DAILY ACTION SHEETS (SUBSCRIPTION MODEL C)          *
//*-------------------------------------------------------------------*
//PRTSHEET EXEC PGM=TODOBAT2,COND=(4,LT)
//STEPLIB  DD  DSN=TODO.LOADLIB,DISP=SHR
//TODOCTRL DD  DSN=TODO.CONTROL.CLUSTER,DISP=SHR
//TODOPATH DD  DSN=TODO.MASTER.PATH1,DISP=SHR
//PRTLIST  DD  DSN=TODO.PARMLIB(PRTLIST),DISP=SHR
//RPTOUT   DD  SYSOUT=A,
//             DCB=(RECFM=FBA,LRECL=133,BLKSIZE=3990)
//SYSOUT   DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//
./ ADD NAME=UNINSTAL
//UNINSTAL JOB (TODO01),'IAN STANLEY',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             REGION=4096K,
//             TIME=(2,0),
//             NOTIFY=&SYSUID
/*JOBPARM LINES=50
//*===================================================================*
//* JOB: UNINSTAL - COMPLETE TEARDOWN OF MVS 3.8J TODO MANAGER        *
//* NOTE: SUBMIT WITH MSGCLASS=X AND INSPECT HELD SYSOUT CHECKLIST.   *
//*===================================================================*
//* STEP 1: VERIFY NO TSO OR KICKS SESSION HOLDS TODO.MASTER.CLUSTER  *
//*-------------------------------------------------------------------*
//CHKUSE   EXEC PGM=IEFBR14
//MASTLOCK DD  DSN=TODO.MASTER.CLUSTER,DISP=OLD
//*-------------------------------------------------------------------*
//* STEP 2: DELETE VSAM PATH, AIX, CLUSTERS, GDG, & SYS2.CMDPROC HOOKS*
//*-------------------------------------------------------------------*
//DELVSAM  EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO.MASTER.PATH1 PATH PURGE
  DELETE TODO.MASTER.AIX1 ALTERNATEINDEX PURGE
  DELETE TODO.MASTER.CLUSTER CLUSTER PURGE
  DELETE TODO.CONTROL.CLUSTER CLUSTER PURGE
  DELETE TODO.ARCHIVE.GDG GENERATION PURGE FORCE
  DELETE TODO.ARCHIVE.GDG GDG PURGE
  DELETE SYS2.CMDPROC(TODO) NONVSAM
  DELETE SYS2.CMDPROC(TODOKICK) NONVSAM
  SET MAXCC = 0
/*
//*-------------------------------------------------------------------*
//* STEP 3: DELETE ALL TODO.* PDS LIBRARIES ON PUB000                 *
//*-------------------------------------------------------------------*
//DELPDS   EXEC PGM=IEFBR14,COND=(4,LT)
//COPYLIB  DD  DSN=TODO.COPYLIB,DISP=(OLD,DELETE,DELETE)
//COBOL    DD  DSN=TODO.COBOL,DISP=(OLD,DELETE,DELETE)
//ASM      DD  DSN=TODO.ASM,DISP=(OLD,DELETE,DELETE)
//KCOBOL   DD  DSN=TODO.KICKS.COBOL,DISP=(OLD,DELETE,DELETE)
//KBMS     DD  DSN=TODO.KICKS.BMS,DISP=(OLD,DELETE,DELETE)
//CLIST    DD  DSN=TODO.CLIST,DISP=(OLD,DELETE,DELETE)
//PARMLIB  DD  DSN=TODO.PARMLIB,DISP=(OLD,DELETE,DELETE)
//JCL      DD  DSN=TODO.JCL,DISP=(OLD,DELETE,DELETE)
//LOADLIB  DD  DSN=TODO.LOADLIB,DISP=(OLD,DELETE,DELETE)
//KLOADLIB DD  DSN=TODO.KICKS.LOADLIB,DISP=(OLD,DELETE,DELETE)
//*-------------------------------------------------------------------*
//* STEP 4: REMOVE 'TODO' ALIAS FROM MASTER CATALOG                   *
//*-------------------------------------------------------------------*
//DELALIAS EXEC PGM=IDCAMS,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  DELETE TODO ALIAS
  SET MAXCC = 0
/*
//*-------------------------------------------------------------------*
//* STEP 5: WRITE HELD POST-UNINSTALL VERIFICATION CHECKLIST          *
//*-------------------------------------------------------------------*
//CHKLIST  EXEC PGM=IEBGENER,COND=(4,LT)
//SYSPRINT DD  DUMMY
//SYSIN    DD  DUMMY
//SYSUT2   DD  SYSOUT=*
//SYSUT1   DD  *
========================================================================
TODO MANAGER (MVS 3.8J TK5) - UNINSTALL VERIFICATION & MANUAL CHECKLIST
========================================================================
AUTOMATIC TEARDOWN COMPLETED BY THIS JOB:
  [X] VERIFIED NO ACTIVE KICKS/TSO SESSIONS HELD TODO.MASTER.CLUSTER
  [X] DELETED VSAM PATH1, AIX1, MASTER.CLUSTER, AND CONTROL.CLUSTER
  [X] DELETED ALL GENERATIONS AND BASE OF TODO.ARCHIVE.GDG
  [X] REMOVED TODO AND TODOKICK CLIST HOOKS FROM SYS2.CMDPROC
  [X] DELETED ALL TEN TODO.* PDS LIBRARIES FROM VOLUME PUB000
  [X] REMOVED 'TODO' ALIAS FROM THE MVS MASTER CATALOG

MANUAL POST-UNINSTALL VERIFICATION STEPS (INSPECT IN RFE / TSO):
  1. CONFIRM RETURN CODES:
     CHECK JES2 STEP COMPLETION CODES ABOVE (CHKUSE, DELVSAM, DELPDS,
     DELALIAS). ALL STEPS MUST SHOW RC=0000 (OR RC=0008 IF A DATASET
     WAS ALREADY REMOVED PRIOR TO RERUNNING UNINSTAL).

  2. VERIFY NO ORPHAN DATASETS REMAIN ON PUB000:
     IN RFE OPTION 3.4, ENTER DSNAME LEVEL 'TODO' AND CONFIRM NO
     CATALOGED DATASETS REMAIN. CHECK VTOC ON PUB000 IF NEEDED.

  3. VERIFY SYS2.CMDPROC CLEANUP:
     IN RFE OPTION 3.4, BROWSE 'SYS2.CMDPROC' AND CONFIRM MEMBERS
     'TODO' AND 'TODOKICK' ARE NO LONGER PRESENT.

  4. REMOVE OPTIONAL SITE-SPECIFIC CUSTOMIZATIONS (IF CONFIGURED):
     - IF YOU ADDED RAKF SECURITY PROFILES FOR 'TODO.**', REMOVE THEM
       FROM YOUR RAKF USER/DATASET PROFILE TABLE AND REFRESH RAKF.
     - IF YOU SCHEDULED 'TODO.JCL(TODONITE)' IN AN EXTERNAL BATCH
       SCHEDULER OR HERCULES CRON/SCRIPT, REMOVE THAT SCHEDULE ENTRY.
========================================================================
/*
//
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* LOAD UNINSTALL INSTRUCTIONS INTO TODO.PARMLIB(UNINSTAL)          *
//*-------------------------------------------------------------------*
//LDUNDOC  EXEC PGM=IEBUPDTE,PARM=MOD,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.PARMLIB,DISP=SHR
//SYSUT2   DD  DSN=TODO.PARMLIB,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
./ ADD NAME=UNINSTAL
========================================================================
TODO MANAGER - ON-HOST UNINSTALL INSTRUCTIONS
========================================================================
1. ENSURE ALL USERS HAVE EXITED KICKS (PF3) AND NO TSO SESSION IS
   CURRENTLY RUNNING %TODO.
2. SUBMIT MEMBER 'TODO.JCL(UNINSTAL)' WITH MSGCLASS=X.
3. INSPECT HELD OUTPUT IN RFE OPTION 3.8 FOR STEP RETURN CODES
   AND COMPLETE ANY MANUAL CHECKLIST ITEMS LISTED IN STEP CHKLIST.
========================================================================
./ ENDUP
@@
//*-------------------------------------------------------------------*
//* INSTALL SYSTEM HOOKS (ALIAS + SYS2.CMDPROC CLISTS)                *
//*-------------------------------------------------------------------*
//HOOKCLST EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.CLIST,DISP=SHR
//SYSUT2   DD  DSN=SYS2.CMDPROC,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODO,TODOKICK)
/*
//ASMLOCK  EXEC ASMFCL,
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='NCAL,LIST,MAP'
//ASM.SYSLIB DD DSN=SYS1.MACLIB,DISP=SHR
//           DD DSN=SYS1.AMODGEN,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.ASM(TODOLOCK),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOLOCK),DISP=SHR
//*
//CPYLOCK  EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.LOADLIB,DISP=SHR
//SYSUT2   DD  DSN=TODO.KICKS.LOADLIB,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODOLOCK)
/*
//*-------------------------------------------------------------------*
//* STEP 2: COMPILE TODOVAL SUBPROGRAM (NCAL) INTO BOTH LOADLIBS      *
//*-------------------------------------------------------------------*
//CMPVAL   EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='NCAL,LIST,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOVAL),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOVAL),DISP=SHR
//*
//CPYVAL   EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.LOADLIB,DISP=SHR
//SYSUT2   DD  DSN=TODO.KICKS.LOADLIB,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODOVAL)
/*
//*-------------------------------------------------------------------*
//* STEP 3: COMPILE & LINK TODOCMD (TSO LINE-MODE CLI PROCESSOR)      *
//*-------------------------------------------------------------------*
//CMPCMD   EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOCMD),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOCMD),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 4: COMPILE & LINK TODOBAT1 (NIGHTLY ARCHIVE & PURGE)         *
//*-------------------------------------------------------------------*
//CMPBAT1  EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOBAT1),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOBAT1),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 5: COMPILE & LINK TODOBAT2 (DAILY ACTION SHEET PRINTER)      *
//*-------------------------------------------------------------------*
//CMPBAT2  EXEC COBUCL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//COB.SYSIN  DD DSN=TODO.COBOL(TODOBAT2),DISP=SHR
//LKED.SYSLIB DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.LOADLIB(TODOBAT2),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 6: ASSEMBLE BMS SYMBOLIC & PHYSICAL MAPSET (TODOM00)         *
//*-------------------------------------------------------------------*
//MAPGEN   EXEC KIKMAPS,COND=(4,LT),
//         MAPNAME=TODOM00,
//         MAPSRC='TODO.KICKS.BMS',
//         COPYLIB='TODO.COPYLIB',
//         LOADLIB='TODO.KICKS.LOADLIB'
//*-------------------------------------------------------------------*
//* STEP 7: TRANSLATE, COMPILE & LINK KICKS BROWSE MODULE (TODOK01)   *
//*-------------------------------------------------------------------*
//CMPK01   EXEC KIKCB2CL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//TRN.SYSIN  DD DSN=TODO.KICKS.COBOL(TODOK01),DISP=SHR
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//           DD DSN=KICKS.V1R5M0.COBCOPY,DISP=SHR
//LKED.SYSLIB DD DSN=KICKS.V1R5M0.SKIKLOAD,DISP=SHR
//            DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.KICKS.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(TODOK01),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 8: TRANSLATE, COMPILE & LINK KICKS DETAIL MODULE (TODOK02)   *
//*-------------------------------------------------------------------*
//CMPK02   EXEC KIKCB2CL,COND=(4,LT),
//         PARM.COB=('LIB,LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,',
//             'APOST,SIZE=2048K,BUF=1024K'),
//         PARM.LKED='LIST,XREF,LET,MAP'
//TRN.SYSIN  DD DSN=TODO.KICKS.COBOL(TODOK02),DISP=SHR
//COB.SYSLIB DD DSN=TODO.COPYLIB,DISP=SHR
//           DD DSN=KICKS.V1R5M0.COBCOPY,DISP=SHR
//LKED.SYSLIB DD DSN=KICKS.V1R5M0.SKIKLOAD,DISP=SHR
//            DD DSN=SYS1.COBLIB,DISP=SHR
//            DD DSN=TODO.KICKS.LOADLIB,DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(TODOK02),DISP=SHR
//*-------------------------------------------------------------------*
//* STEP 9: ASSEMBLE & LINK CUSTOM KICKS TABLES (KIKPPT2$/PCT2$/FCT2$)*
//*-------------------------------------------------------------------*
//ASMPPT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKPPT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKPPT2$),DISP=SHR
//*
//ASMPCT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKPCT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKPCT2$),DISP=SHR
//*
//ASMFCT   EXEC ASMFCL,COND=(4,LT),
//         PARM.ASM='OBJ,NODECK',
//         PARM.LKED='LIST,MAP'
//ASM.SYSLIB DD DSN=KICKS.V1R5M0.MACLIB,DISP=SHR
//           DD DSN=SYS1.MACLIB,DISP=SHR
//ASM.SYSIN  DD DSN=TODO.KICKS.COBOL(KIKFCT2$),DISP=SHR
//LKED.SYSLMOD DD DSN=TODO.KICKS.LOADLIB(KIKFCT2$),DISP=SHR
//
