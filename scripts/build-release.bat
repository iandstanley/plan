@echo off
setlocal enabledelayedexpansion
REM ===================================================================
REM SCRIPT: scripts\build-release.bat
REM PURPOSE: BUILDS COMBINED CARD-READER RELEASE JCL (dist\TODOINST.jcl)
REM          FOR MVS 3.8J TK5 INSTALLATION VIA IEBUPDTE.
REM ===================================================================

set "REPO_ROOT=%~dp0.."
cd /d "%REPO_ROOT%"

if not exist "dist" mkdir "dist"
set "OUT=dist\TODOINST.jcl"

echo Building %OUT% ...

REM 1. WRITE INSTCORE (STRIPPING TRAILING // CARD)
> "%OUT%" (
    for /f "usebackq delims=" %%L in ("jcl\INSTCORE.jcl") do (
        if not "%%L"=="//" echo %%L
    )
)

REM 2. APPEND IEBUPDTE STEPS FOR EACH SOURCE PDS
call :APPEND_PDS "TODO.COPYLIB"      "copybook"    "cpy"
call :APPEND_PDS "TODO.COBOL"        "cobol"       "cbl"
call :APPEND_PDS "TODO.ASM"          "asm"         "asm"
call :APPEND_PDS "TODO.KICKS.BMS"    "kicks-bms"   "bms"
call :APPEND_PDS "TODO.KICKS.COBOL"  "kicks-cobol" "cbl"
call :APPEND_PDS "TODO.KICKS.COBOL"  "kicks-cobol" "asm"
call :APPEND_PDS "TODO.CLIST"        "clist"       "clist"
call :APPEND_PDS "TODO.PARMLIB"      "parmlib"     "txt"
call :APPEND_PDS "TODO.JCL"          "jcl"         "jcl"

REM 3. EMBED UNINSTALL INSTRUCTIONS INTO TODO.PARMLIB(UNINSTAL)
>> "%OUT%" (
    echo //*-------------------------------------------------------------------*
    echo //* LOAD UNINSTALL INSTRUCTIONS INTO TODO.PARMLIB^(UNINSTAL^)          *
    echo //*-------------------------------------------------------------------*
    echo //LDUNDOC  EXEC PGM=IEBUPDTE,PARM=MOD,COND=^(4,LT^)
    echo //SYSPRINT DD  SYSOUT=*
    echo //SYSUT1   DD  DSN=TODO.PARMLIB,DISP=SHR
    echo //SYSUT2   DD  DSN=TODO.PARMLIB,DISP=SHR
    echo //SYSIN    DD  DATA,DLM=@@
    echo ./ ADD NAME=UNINSTAL
    echo ========================================================================
    echo TODO MANAGER - ON-HOST UNINSTALL INSTRUCTIONS
    echo ========================================================================
    echo 1. ENSURE ALL USERS HAVE EXITED KICKS ^(PF3^) AND NO TSO SESSION IS
    echo    CURRENTLY RUNNING %%TODO.
    echo 2. SUBMIT MEMBER 'TODO.JCL^(UNINSTAL^)' WITH MSGCLASS=X.
    echo 3. INSPECT HELD OUTPUT IN RFE OPTION 3.8 FOR STEP RETURN CODES
    echo    AND COMPLETE ANY MANUAL CHECKLIST ITEMS LISTED IN STEP CHKLIST.
    echo ========================================================================
    echo ./ ENDUP
    echo @@
)

REM 4. APPEND INSTHOOK STEPS (ALIAS + SYS2.CMDPROC CLISTS)
>> "%OUT%" (
    echo //*-------------------------------------------------------------------*
    echo //* INSTALL SYSTEM HOOKS ^(ALIAS + SYS2.CMDPROC CLISTS^)                *
    echo //*-------------------------------------------------------------------*
    echo //HOOKCLST EXEC PGM=IEBCOPY,COND=^(4,LT^)
    echo //SYSPRINT DD  SYSOUT=*
    echo //SYSUT1   DD  DSN=TODO.CLIST,DISP=SHR
    echo //SYSUT2   DD  DSN=SYS2.CMDPROC,DISP=SHR
    echo //SYSIN    DD  *
    echo   COPY INDD=^(^(SYSUT1,R^)^),OUTDD=SYSUT2
    echo   SELECT MEMBER=^(TODO,TODOKICK^)
    echo /*
)

REM 5. APPEND COMPALL BUILD STEPS (SKIPPING ITS JOB CARD & JCLLIB)
set "SKIP_HDR=1"
>> "%OUT%" (
    for /f "usebackq delims=" %%L in ("jcl\COMPALL.jcl") do (
        set "LINE=%%L"
        if "!LINE:~0,9!"=="//ASMLOCK" set "SKIP_HDR=0"
        if "!SKIP_HDR!"=="0" echo !LINE!
    )
)

echo Done. Output written to %OUT%
exit /b 0

:APPEND_PDS
set "TARGET_DSN=%~1"
set "SRC_DIR=%~2"
set "EXT=%~3"
set "STEP_ID=%~n2%EXT%"
set "STEP_ID=!STEP_ID:-=!"
set "STEP_ID=LD!STEP_ID:~0,6!"

>> "%OUT%" (
    echo //*-------------------------------------------------------------------*
    echo //* LOAD %TARGET_DSN% FROM %SRC_DIR%\*.%EXT%
    echo //*-------------------------------------------------------------------*
    echo //%STEP_ID% EXEC PGM=IEBUPDTE,PARM=NEW,COND=^(4,LT^)
    echo //SYSPRINT DD  SYSOUT=*
    echo //SYSUT2   DD  DSN=%TARGET_DSN%,DISP=SHR
    echo //SYSIN    DD  DATA,DLM=@@
)

for %%F in ("%SRC_DIR%\*.%EXT%") do (
    set "MBR=%%~nF"
    >> "%OUT%" echo ./ ADD NAME=!MBR!
    type "%%F" >> "%OUT%"
    >> "%OUT%" echo.
)

>> "%OUT%" (
    echo ./ ENDUP
    echo @@
)
exit /b 0