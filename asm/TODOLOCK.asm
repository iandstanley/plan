TODOLOCK CSECT
*=====================================================================*
* MODULE:      TODOLOCK - MVS SYSTEM-WIDE ENQ/DEQ SERIALIZATION       *
* SUBSYSTEM:   TODO MANAGER (MVS 3.8J TK5)                            *
* ENVIRONMENT: CALLABLE FROM BATCH/TSO COBOL AND KICKS COBOL          *
* LINKAGE:     R1 -> 4-BYTE POINTER TO 20-BYTE TODOLLNK AREA:         *
*                +00 (4) ACTION ('ENQ ' OR 'DEQ ')                    *
*                +04 (8) RNAME  (8-BYTE RESOURCE MINOR NAME)          *
*                +12 (2) RC     (HALFWORD RETURN CODE: 0, 8, 16)      *
*                +14 (6) FILLER                                       *
*=====================================================================*
         STM   R14,R12,12(R13)         SAVE CALLER REGISTERS
         LR    R12,R15                 ESTABLISH BASE REGISTER
         USING TODOLOCK,R12
         LA    R2,SAVEAREA             CHAIN SAVE AREAS
         ST    R13,4(,R2)
         ST    R2,8(,R13)
         LR    R13,R2
*
         L     R3,0(,R1)               R3 -> TODOLLNK PARAMETER BLOCK
         MVC   WORKRNAME(8),4(R3)      COPY 8-BYTE RNAME FROM PARM
*
         CLC   0(4,R3),=CL4'ENQ '      REQUEST EXCLUSIVE ENQ?
         BE    DOENQ
         CLC   0(4,R3),=CL4'DEQ '      REQUEST DEQ RELEASE?
         BE    DODEQ
         MVC   12(2,R3),=H'8'          INVALID ACTION CODE -> RC=8
         B     RETURN
*
DOENQ    DS    0H
         MVC   ENQLIST(ENQLEN),ENQMODEL
         ENQ   (QNAME,WORKRNAME,E,8,SYSTEM),MF=(E,ENQLIST)
         LTR   R15,R15                 TEST ENQ RETURN CODE
         BZ    SETOK
         CH    R15,=H'8'               ALREADY HELD BY THIS TASK?
         BE    SETOK
         MVC   12(2,R3),=H'16'         SEVERE ENQ FAILURE -> RC=16
         B     RETURN
*
DODEQ    DS    0H
         MVC   DEQLIST(DEQLEN),DEQMODEL
         DEQ   (QNAME,WORKRNAME,8,SYSTEM),RET=HAVE,MF=(E,DEQLIST)
         LTR   R15,R15                 TEST DEQ RETURN CODE
         BZ    SETOK
         CH    R15,=H'8'               NOT HELD (BENIGN) -> RC=0
         BE    SETOK
         MVC   12(2,R3),=H'16'         SEVERE DEQ FAILURE -> RC=16
         B     RETURN
*
SETOK    DS    0H
         MVC   12(2,R3),=H'0'          NORMAL COMPLETION -> RC=0
*
RETURN   DS    0H
         L     R13,4(,R13)             RESTORE CALLER SAVE AREA
         LM    R14,R12,12(R13)         RESTORE REGISTERS
         SR    R15,R15                 CLEAR R15
         BR    R14                     RETURN TO CALLER
*
*---------------------------------------------------------------------*
* CONSTANTS, LIST-FORM MACROS, AND SAVE AREA                          *
*---------------------------------------------------------------------*
QNAME    DC    CL8'TODOFILE'
ENQMODEL ENQ   (QNAME,QNAME,E,8,SYSTEM),MF=L
ENQLEN   EQU   *-ENQMODEL
DEQMODEL DEQ   (QNAME,QNAME,8,SYSTEM),RET=HAVE,MF=L
DEQLEN   EQU   *-DEQMODEL
*
SAVEAREA DC    18F'0'
WORKRNAME DC   CL8' '
ENQLIST  DS    CL(ENQLEN)
DEQLIST  DS    CL(DEQLEN)
*
R1       EQU   1
R2       EQU   2
R3       EQU   3
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
         END   TODOLOCK