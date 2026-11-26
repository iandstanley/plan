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