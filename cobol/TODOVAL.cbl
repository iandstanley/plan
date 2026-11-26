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