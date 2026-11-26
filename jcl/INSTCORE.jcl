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