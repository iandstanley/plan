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