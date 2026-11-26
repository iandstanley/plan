#!/usr/bin/env sh
# =====================================================================
# SCRIPT: scripts/build-release.sh
# PURPOSE: BUILDS COMBINED CARD-READER RELEASE JCL (dist/TODOINST.jcl)
#          FOR MVS 3.8J TK5 INSTALLATION VIA IEBUPDTE.
# =====================================================================
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p dist
OUT="dist/TODOINST.jcl"

echo "Building $OUT ..."

# 1. WRITE INSTCORE (STRIPPING TRAILING // CARD)
grep -v '^//$' jcl/INSTCORE.jcl > "$OUT"

append_pds() {
    TARGET_DSN="$1"
    SRC_DIR="$2"
    EXT="$3"
    STEP_TAG="$(printf '%s%s' "$SRC_DIR" "$EXT" | tr -d '-' | tr '[:lower:]' '[:upper:]' | cut -c1-6)"

    # CHECK IF ANY MATCHING FILES EXIST
    set -- "$SRC_DIR"/*."$EXT"
    if [ ! -e "$1" ]; then
        return 0
    fi

    cat <<EOF >> "$OUT"
//*-------------------------------------------------------------------*
//* LOAD $TARGET_DSN FROM $SRC_DIR/*.$EXT
//*-------------------------------------------------------------------*
//LD${STEP_TAG} EXEC PGM=IEBUPDTE,PARM=NEW,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT2   DD  DSN=$TARGET_DSN,DISP=SHR
//SYSIN    DD  DATA,DLM=@@
EOF

    for FILE in "$SRC_DIR"/*."$EXT"; do
        MBR="$(basename "$FILE" ".$EXT" | tr '[:lower:]' '[:upper:]')"
        printf './ ADD NAME=%s\n' "$MBR" >> "$OUT"
        tr -d '\r' < "$FILE" >> "$OUT"
        # ENSURE TRAILING NEWLINE BEFORE NEXT ./ ADD
        tail -c1 "$FILE" \vert{} read -r _ \vert{}\vert{} printf '\n' >> "$OUT"
    done

    cat <<'EOF' >> "$OUT"
./ ENDUP
@@
EOF
}

# 2. APPEND IEBUPDTE STEPS FOR ALL SOURCE LIBRARIES
append_pds "TODO.COPYLIB"     "copybook"    "cpy"
append_pds "TODO.COBOL"       "cobol"       "cbl"
append_pds "TODO.ASM"         "asm"         "asm"
append_pds "TODO.KICKS.BMS"   "kicks-bms"   "bms"
append_pds "TODO.KICKS.COBOL" "kicks-cobol" "cbl"
append_pds "TODO.KICKS.COBOL" "kicks-cobol" "asm"
append_pds "TODO.CLIST"       "clist"       "clist"
append_pds "TODO.PARMLIB"     "parmlib"     "txt"
append_pds "TODO.JCL"         "jcl"         "jcl"

# 3. EMBED ON-HOST UNINSTALL INSTRUCTIONS INTO TODO.PARMLIB(UNINSTAL)
cat <<'EOF' >> "$OUT"
//*-------------------------------------------------------------------*
//* LOAD UNINSTALL INSTRUCTIONS INTO TODO.PARMLIB(UNINSTAL)           *
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
//* INSTALL SYSTEM HOOKS (SYS2.CMDPROC CLISTS)                        *
//*-------------------------------------------------------------------*
//HOOKCLST EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  DSN=TODO.CLIST,DISP=SHR
//SYSUT2   DD  DSN=SYS2.CMDPROC,DISP=SHR
//SYSIN    DD  *
  COPY INDD=((SYSUT1,R)),OUTDD=SYSUT2
  SELECT MEMBER=(TODO,TODOKICK)
/*
EOF

# 4. APPEND COMPALL BUILD STEPS (FROM //ASMLOCK ONWARD)
sed -n '/^\/\/ASMLOCK/,$p' jcl/COMPALL.jcl >> "$OUT"

echo "Done. Output written to $OUT"