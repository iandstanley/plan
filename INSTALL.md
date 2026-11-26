# Installation, Upgrade & Uninstall Guide (`MVS 3.8j TK5`)

This guide covers building, uploading, verifying, maintaining across TK5 updates, and uninstalling the **MVS 3.8j Multi-User To-Do Manager (`TODO`)** from **Windows**, **macOS**, or **Linux**.

---

## 1. Prerequisites

* **Hercules running MVS 3.8j Turnkey 5 (TK5)** with standard user volume **`PUB000`** online and **`KICKS.V1R5M0.*`** installed (included out of the box in TK5).
* A TSO user ID with authority to define Master Catalog aliases and update `SYS2.CMDPROC` (for example, **`HERC01`** or **`HERC02`**).
* A 3270 terminal emulator (`wc3270` on Windows; `x3270` or `c3270` on macOS/Linux) and access to the Hercules console (`http://localhost:8038` or terminal console).

---

## 2. Step 1 — Obtain or Build `TODOINST.jcl`

All datasets, source members, BMS maps, KICKS tables, CLIST hooks, and compile/link steps are packaged into a single combined card-reader JCL job: **`dist/TODOINST.jcl`**.

* **If you downloaded a GitHub Release archive:**
  Extract the release zip/tarball—`dist/TODOINST.jcl` is already pre-built and ready to upload.
* **If you cloned the Git repository (`git clone`):**
  Generate `dist/TODOINST.jcl` locally on your workstation:
  * **Windows (Command Prompt / PowerShell):**
    ```bat
    scripts\build-release.bat
    ```
  * **macOS / Linux:**
    ```sh
    chmod +x scripts/build-release.sh
    ./scripts/build-release.sh
    ```

*(Note: `TODOINST.jcl` uses `//SYSIN DD DATA,DLM=@@` so embedded JCL members containing `//` and `/*` cards load cleanly through `IEBUPDTE` without premature delimiter termination.)*

---

## 3. Step 2 — Upload and Run `TODOINST.jcl` on TK5

Choose **Method A (Hercules Card Reader — Fastest)** or **Method B (3270 `IND$FILE` Transfer)**.

### Method A: Submit Directly via Hercules Card Reader (`00C`) — Recommended

1. Copy `dist/TODOINST.jcl` to a path accessible to your Hercules process (or use its full workstation path).
2. At the **Hercules console** (or via the TK5 web console `http://localhost:8038`), issue:
   * **Windows:**
     ```text
     devinit 00c C:\path\to\mvs-todo\dist\TODOINST.jcl ascii eof
     ```
   * **macOS / Linux:**
     ```text
     devinit 00c /path/to/mvs-todo/dist/TODOINST.jcl ascii eof
     ```
3. JES2 automatically reads `INSTCORE` from device `00C` into the internal reader and executes the entire installation pipeline:
   * Defines Master Catalog alias `TODO` -> `SYS1.UCAT.TSO`
   * Allocates all 10 `TODO.*` PDS libraries, VSAM KSDS clusters (`TODO.MASTER.CLUSTER`, `TODO.CONTROL.CLUSTER`), Alternate Index (`TODO.MASTER.AIX1`), Path (`TODO.MASTER.PATH1`), and `TODO.ARCHIVE.GDG` on **`PUB000`**
   * Loads all source, copybook, BMS, CLIST, `PARMLIB`, JCL, and on-host uninstall documentation members via `IEBUPDTE`
   * Copies `%TODO` and `%TODOKICK` CLISTs into `SYS2.CMDPROC`
   * Assembles `TODOLOCK`, compiles `TODOVAL`, `TODOCMD`, `TODOBAT1`, `TODOBAT2`, generates `TODOM00` BMS maps, compiles `TODOK01`/`TODOK02`, and assembles `KIKPPT2$`/`KIKPCT2$`/`KIKFCT2$`

### Method B: Upload via 3270 Terminal (`IND$FILE`)

1. Log onto TSO as `HERC01` and exit RFE/RPF to the TSO `READY` prompt.
2. Pre-allocate a sequential upload dataset on MVS:
   ```text
   ALLOC DA('HERC01.TODOINST.JCL') NEW CATALOG SPACE(5,2) TRACKS UNIT(3350) VOL(PUB000) RECFM(F B) LRECL(80) BLKSIZE(6160)
   FREE DA('HERC01.TODOINST.JCL')
   ```
3. Transfer `dist/TODOINST.jcl` in **ASCII** mode with **CRLF** translation:
   * **`wc3270` (Windows):** Menu -> *File* -> *File Transfer* -> *Send to host*, Local File: `dist\TODOINST.jcl`, Host File: `'HERC01.TODOINST.JCL'`, Mode: `ASCII`, Record Format: `Fixed`, `LRECL=80`.
   * **`x3270` / `c3270` (macOS / Linux):** At the `Transfer()` prompt or file-transfer dialog, send `dist/TODOINST.jcl` to `'HERC01.TODOINST.JCL'` with `Mode=ascii`, `HostFile=tso`, `Recfm=fixed`, `Lrecl=80`.
4. Submit the uploaded job from TSO `READY`:
   ```text
   SUBMIT 'HERC01.TODOINST.JCL'
   ```
5. Once complete, delete the temporary upload file:
   ```text
   DELETE 'HERC01.TODOINST.JCL'
   ```

---

## 4. Step 3 — Verify the Installation

1. **Check JES2 Job Output (`MSGCLASS=X`):**
   * Open **RFE Option 3.8** (Outlist) and inspect job **`INSTCORE`**.
   * Confirm all steps completed with **`RC = 0000`** (or **`RC = 0004`** warnings only—no `RC >= 0008` or abends).
2. **Test the TSO Line-Mode CLI (`%TODO`):**
   At the TSO `READY` prompt:
   ```text
   %TODO ADD TITLE('VERIFY TK5 INSTALLATION') PRI(1) CAT(MVS)
   %TODO LIST
   %TODO DONE ARG1(1)
   ```
3. **Test the KICKS Online 3270 Interface (`%TODOKICK`):**
   At the TSO `READY` prompt:
   ```text
   %TODOKICK
   ```
   Press `CLEAR` on the KICKS splash banner, type **`TODO`**, and press `ENTER` to open the `TODOM1` Browse screen. Press `PF3` to exit KICKS cleanly.
4. **Test the Nightly Batch Cycle (`TODONITE`):**
   Submit `TODO.JCL(TODONITE)` from RFE Option 3.4 or TSO:
   ```text
   SUBMIT 'TODO.JCL(TODONITE)'
   ```
   Verify that task `00000001` is archived to `TODO.ARCHIVE.GDG.G0001V00` and a Daily Action Sheet prints on `SYSOUT=A` (virtual printer `00E`).

---

## 5. Preserving the Application Across TK5 Upgrades

All `TODO.*` datasets and VSAM clusters reside on **`PUB000`**, which TK5 preserves across system upgrades. If a TK5 distribution update replaces `MVSRES`, the Master Catalog, or `SYS2.CMDPROC`:

1. Submit the idempotent re-hook job directly from `PUB000`:
   ```text
   SUBMIT 'TODO.JCL(INSTHOOK)'
   ```
2. This re-creates the `TODO` Master Catalog alias and refreshes `TODO` and `TODOKICK` in `SYS2.CMDPROC` without touching your task data.

---

## 6. Uninstalling the Application

Uninstall JCL and plain-text instructions are stored directly on the mainframe inside **`TODO.JCL(UNINSTAL)`** and **`TODO.PARMLIB(UNINSTAL)`** (as well as `jcl/UNINSTAL.jcl` in this repository).

1. **Quiesce Active Users:**
   Ensure no TSO session is currently running KICKS (`%TODOKICK`) or `%TODO`. (`UNINSTAL` allocates `TODO.MASTER.CLUSTER` with `DISP=OLD` and will wait/fail safely if the file is in use.)
2. **Submit the Uninstall Job:**
   ```text
   SUBMIT 'TODO.JCL(UNINSTAL)'
   ```
3. **Inspect Held Job Output (`MSGCLASS=X`):**
   * Open **RFE Option 3.8** and select job **`UNINSTAL`**.
   * Verify `RC = 0000` across steps `CHKUSE`, `DELVSAM`, `DELPDS`, `DELALIAS`, and `CHKLIST`.
   * Read the **Uninstall Verification & Manual Checklist** printed at the bottom of the job output (`STEP CHKLIST`) to confirm `SYS2.CMDPROC` cleanup and remove any optional site-specific RAKF rules or batch scheduler entries.