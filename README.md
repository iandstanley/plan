# MVS 3.8j Multi-User To-Do Manager (`TODO`)

A full-featured, multi-user task management system built for **IBM MVS 3.8j (Turnkey 5 / TK5)** running under the Hercules S/370 emulator. Written in native **OS/VS COBOL (`IKFCBL00`)**, **System/370 Assembler (`IFOX00`)**, **BMS**, **TSO CLIST**, and **JCL**.

---

## System Overview & Key Features

* **Dual Multi-User Interfaces (3270 Online + TSO CLI):**
  * **KICKS 3270 Online (`TRANSID=TODO` via `%TODOKICK`):** Pseudo-conversational full-screen 3270 application (`TODOM1` Task Browse/List, `TODOM2` Add/Edit/Delegate Detail, `TODOM3` User Settings) featuring inline row actions (`S`, `C`, `W`, `X`), status filtering (`O`/`W`/`A`), symbolic cursor positioning, and cross-user task delegation.
  * **TSO Line-Mode CLI (`%TODO`):** Fast command-line processor callable directly from any TSO `READY` prompt or `IKJEFT01` batch job (`LIST`, `ADD`, `VIEW`, `START`, `WAIT`, `DONE`, `CANCEL`, `ASSIGN`, `NOTE`, `PRINT`) without needing KICKS started.
* **True Multi-User Concurrency on MVS 3.8j:**
  * Because TK5 runs KICKS inside isolated TSO address spaces, `TODOLOCK` issues system-wide MVS `ENQ` / `DEQ` (`QNAME='TODOFILE'`, `SCOPE=SYSTEM`) around control-counter increments and master VSAM updates, paired with optimistic `TODO-REC-VERSION` checks to prevent lost updates.
* **Priority & Due-Date Scheduling (`AIX1`):**
  * Supports 5 priority levels (`1`=Urgent through `5`=Deferred), validated Gregorian due dates (`YYYYMMDD`), and three 60-character note lines per task, automatically sorted by **Owner + Due Date + Priority** via VSAM Alternate Index `TODO.MASTER.AIX1`.
* **Automated Nightly Batch Cycle (`TODONITE`):**
  * Sweeps Completed (`C`) and Cancelled (`X`) tasks into a `+1` generation of `TODO.ARCHIVE.GDG` and deletes them from `TODO.MASTER.CLUSTER`.
  * Reorganizes `TODO.MASTER.CLUSTER` and rebuilds `TODO.MASTER.AIX1` via `IDCAMS`.
  * Prints Daily Action Sheets on `SYSOUT=A` (`RECFM=FBA,LRECL=133`) with ASA `'1'` page-eject user banners for physical bursting, supporting Subscription Model C (per-user opt-in flag in `TODO.CONTROL.CLUSTER` with optional `TODO.PARMLIB(PRTLIST)` operator override) and `"NO OPEN TASKS TODAY"` confirmation sheets.
* **TK5 Upgrade-Safe Design:**
  * All datasets, VSAM clusters, custom KICKS `2$` tables, and load modules live on user-preserved volume **`PUB000`** under the `TODO.*` HLQ. System touchpoints (`TODO` catalog alias and `SYS2.CMDPROC` CLIST hooks) are isolated in `TODO.JCL(INSTHOOK)` for instant recovery after TK5 updates.

---

## Repository Layout

```text
mvs-todo/
├── README.md                  # Project overview, build, install & usage guide
├── INSTALL.md                 # Detailed installation, upload & uninstall manual
├── application-spec0.txt      # Master hybrid architecture specification
├── application-spec-tso.txt   # TSO-only edition specification
├── application-spec-kicks.txt # KICKS 3270 edition specification
├── application-spec-tos.txt   # System/360 TOS/360 tape-port specification
├── coding-standards.md        # MVS 3.8j COBOL-68 & JCL development standards
├── copybook/                  # -> TODO.COPYLIB
│   ├── TODOREC.cpy            #    332-byte Master Task VSAM KSDS layout
│   ├── TODOCTRL.cpy           #    64-byte User Control VSAM KSDS layout
│   ├── TODOCREC.cpy           #    200-byte TSO CLI command handoff record
│   ├── TODOCOMM.cpy           #    64-byte KICKS DFHCOMMAREA contract
│   ├── TODOVLNK.cpy           #    120-byte TODOVAL linkage contract
│   └── TODOLLNK.cpy           #    20-byte TODOLOCK linkage contract
├── asm/                       # -> TODO.ASM
│   └── TODOLOCK.asm           #    MVS system-wide ENQ/DEQ subprogram
├── cobol/                     # -> TODO.COBOL
│   ├── TODOVAL.cbl            #    Shared field, priority, date & owner validator
│   ├── TODOCMD.cbl            #    TSO line-mode CLI processor
│   ├── TODOBAT1.cbl           #    Nightly archive & purge program
│   └── TODOBAT2.cbl           #    Daily Action Sheet print generator
├── kicks-bms/                 # -> TODO.KICKS.BMS
│   └── TODOM00.bms            #    3270 BMS mapset (TODOM1, TODOM2, TODOM3)
├── kicks-cobol/               # -> TODO.KICKS.COBOL
│   ├── TODOK01.cbl            #    KICKS browse & settings controller
│   ├── TODOK02.cbl            #    KICKS task add, edit & delegate controller
│   ├── KIKPPT2$.asm           #    Custom KICKS Processing Program Table (suffix 2$)
│   ├── KIKPCT2$.asm           #    Custom KICKS Program Control Table (suffix 2$)
│   └── KIKFCT2$.asm           #    Custom KICKS File Control Table (suffix 2$)
├── clist/                     # -> TODO.CLIST
│   ├── TODO.clist             #    TSO CLI wrapper CLIST
│   └── TODOKICK.clist         #    Upgrade-safe KICKS launcher CLIST
├── parmlib/                   # -> TODO.PARMLIB
│   └── PRTLIST.txt            #    Optional user override list for Action Sheets
├── jcl/                       # -> TODO.JCL
│   ├── INSTCORE.jcl           #    One-time PDS & VSAM/GDG allocation on PUB000
│   ├── INSTHOOK.jcl           #    Idempotent post-TK5-upgrade alias & CLIST hook
│   ├── COMPALL.jcl            #    Master assembly, BMS mapgen & COBOL compile job
│   ├── TODONITE.jcl           #    Nightly archive, VSAM reorg & Action Sheet job
│   ├── UNINSTAL.jcl           #    Complete teardown JCL (with held checklist)
│   ├── INSTDOC.txt            #    On-host post-upload installation guide
│   └── UNINDOC.txt            #    On-host uninstall guide
├── scripts/                   # Workstation release builders
│   ├── build-release.bat      #    Windows script to generate dist\TODOINST.jcl
│   └── build-release.sh       #    macOS/Linux script to generate dist/TODOINST.jcl
└── dist/
    └── TODOINST.jcl           # Combined card-reader / IND$FILE install JCL
```

---

## Building the Combined Install JCL (`dist/TODOINST.jcl`)

The entire application—allocations, VSAM/GDG definitions, `IEBUPDTE` source loads (`//SYSIN DD DATA,DLM=@@`), on-host guides (`INSTDOC`/`UNINDOC`), `SYS2.CMDPROC` CLIST hooks, and all assembly/BMS/COBOL compile steps—packages into a single 80-column JCL stream: **`dist/TODOINST.jcl`**.

* **If you downloaded a pre-built Release:** `dist/TODOINST.jcl` is already included and ready to upload.
* **If you cloned the repository (`git clone`) or edited source files:** Run the builder script for your workstation OS from the repository root:
  * **Windows (Command Prompt / PowerShell):**
    ```bat
    scripts\build-release.bat
    ```
  * **macOS / Linux:**
    ```sh
    chmod +x scripts/build-release.sh
    ./scripts/build-release.sh
    ```

---

## Installation on MVS 3.8j (TK5)

See **`INSTALL.md`** for full step-by-step details. In brief:

1. **Upload & Execute `dist/TODOINST.jcl`:**
   * **Option A — Hercules Card Reader (`00C`, Recommended):**
     At the Hercules console (or web console `http://localhost:8038`), submit the job directly into the internal reader:
     ```text
     devinit 00c /path/to/mvs-todo/dist/TODOINST.jcl ascii eof
     ```
   * **Option B — 3270 `IND$FILE` Transfer (`wc3270` / `x3270` / `c3270`):**
     Allocate `'HERC01.TODOINST.JCL'` (`RECFM=FB, LRECL=80, BLKSIZE=6160` on `PUB000`), upload `dist/TODOINST.jcl` in **ASCII** mode with **CRLF** translation, and run:
     ```text
     SUBMIT 'HERC01.TODOINST.JCL'
     ```
2. **Verify Job Completion:**
   * Open **RFE Option 3.8** (Outlist) and check held job **`INSTCORE`**. Confirm all steps return **`RC = 0000`** (or **`RC = 0004`** compiler warnings only).
   * On-host installation reference documentation is also stored inside **`TODO.JCL(INSTDOC)`**.
3. **Post-TK5-Upgrade Re-Hook (Whenever TK5 System Packs Are Replaced):**
   ```text
   SUBMIT 'TODO.JCL(INSTHOOK)'
   ```

---

## Quick Usage Guide

### 1. TSO Line-Mode CLI (`%TODO`)
Run from any TSO `READY` prompt or RFE/RPF Option 6:
```text
%TODO ADD TITLE('TEST NIGHTLY ARCHIVE JCL') DUE(20261201) PRI(1) CAT(MVS)
%TODO LIST
%TODO LIST ALL
%TODO LIST WAIT USER(HERC02)
%TODO VIEW ARG1(1)
%TODO START ARG1(1)
%TODO WAIT ARG1(1)
%TODO DONE ARG1(1)
%TODO CANCEL ARG1(1)
%TODO ASSIGN ARG1(2) TO(HERC02)
%TODO NOTE ARG1(2) NOTE('FOLLOW UP ON FRIDAY') LINE(2)
%TODO PRINT ARG1(ON) NAME('IAN STANLEY') PRI(2)
```

### 2. KICKS Online 3270 Interface (`%TODOKICK`)
1. From TSO `READY`, enter:
   ```text
   %TODOKICK
   ```
2. Press `CLEAR` on the KICKS banner, type **`TODO`**, and press `ENTER`.
3. Use inline row actions (`S`=Edit/Delegate, `C`=Complete, `W`=Wait, `X`=Cancel), `PF4` (Add Task), `PF5` (Refresh), `PF9` (User Settings), and `PF3` (Exit).

### 3. Nightly Batch Suite (`TODONITE`)
Submit `TODO.JCL(TODONITE)` at the end of the day to archive closed tasks to `TODO.ARCHIVE.GDG(+1)`, reorganize `TODO.MASTER.CLUSTER` + `AIX1`, and print Daily Action Sheets to `SYSOUT=A` (`00E`):
```text
SUBMIT 'TODO.JCL(TODONITE)'
```

---

## Uninstalling the Application

Complete teardown JCL and instructions are stored both in this repository (`jcl/UNINSTAL.jcl`, `jcl/UNINDOC.txt`) and directly on the mainframe in **`TODO.JCL(UNINSTAL)`** and **`TODO.JCL(UNINDOC)`**:

1. Ensure all users have exited KICKS (`PF3`) and no TSO session is currently running `%TODO`.
2. Submit the uninstall job (runs with `MSGCLASS=X` held output):
   ```text
   SUBMIT 'TODO.JCL(UNINSTAL)'
   ```
3. Inspect job **`UNINSTAL`** in **RFE Option 3.8** to verify `RC = 0000` across steps `CHKUSE`, `DELVSAM`, `DELPDS`, `DELALIAS`, and review the post-uninstall verification checklist printed in step `CHKLIST`.

---

## Reporting Bugs & Issues

Found a bug, JCL condition code error, or compiler diagnostic? Please open a **GitHub Issue** on this repository with as much detail as you can include:

* **Environment details:** TK5 update level, Hercules version, and host OS (Windows / macOS / Linux).
* **Interface & command/screen:** Whether the issue occurred in `%TODO` (TSO CLI), `%TODOKICK` (KICKS 3270 map `TODOM1`/`TODOM2`/`TODOM3`), or batch (`INSTCORE`, `COMPALL`, `TODONITE`, `UNINSTAL`).
* **Steps to reproduce:** Exact command, input values, or JCL submitted.
* **Mainframe diagnostics:** Exact JES2 step `RC` / `ABEND` code, `IKFCBL00` / `IFOX00` / `IDCAMS` error message, VSAM file status code, or KICKS `RESP` code from your held `SYSOUT`.