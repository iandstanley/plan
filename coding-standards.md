
# DEPARTMENTAL APPLICATION DEVELOPMENT & JCL STANDARDS MANUAL

## Enterprise Batch & KICKS Online COBOL-68 Engineering Governance

### Document Control & Classification

| Attribute | Specification |
| :---- | :---- |
| Document ID | STD-MVS38J-COBOL-001 |
| Revision | 3.2 — Indexed Reference & Title Page Edition |
| Effective Date | November 2026 |
| Author | Ian Stanley (HERC01) |
| Target Operating System | IBM MVS 3.8j (Turnkey 5 / TK5 Distribution under Hercules S/370) |
| Approved Compilers & Tools | IBM OS/VS COBOL (IKFCBL00), KICKS Translator (KIKCB2CL / KIKPPCOB), BMS (KIKMAPS), IDCAMS |
| Audience | Application Developers, Systems Analysts, Mainframe Systems Programmers, and Production Support |
| Compliance Level | Mandatory for All Batch and KICKS Online Promotion to PROD.* Libraries |

### Revision History

| Revision | Date | Author | Summary of Changes |
| :---- | :---- | :---- | :---- |
| 1.0 | November 2026 | Ian Stanley | Initial release establishing MVS 3.8j TK5 batch COBOL-68 and JCL engineering standards. |
| 2.0 | November 2026 | Ian Stanley | Integrated KICKS OLTP pseudo-conversational architecture, BMS mapset rules, and EMPINQ01 reference template. |
| 3.0 | November 2026 | Ian Stanley | Added Section 10 complete KICKS build/deployment suite (EMPREC, EMPMAPS, IDCAMS, KIKMAPS, KIKCB2CL, PPT/PCT/FCT). |
| 3.1 | November 2026 | Ian Stanley | Added comprehensive Table of Contents and Alphabetical Technical & Keyword Index. |
| 3.2 | November 2026 | Ian Stanley | Added formal Title Page, Document Control Block, and Revision History. |

## Table of Contents

1. Purpose, Scope, and Architectural Governance
	
	1.1 Environment Baseline: TK5 vs. Reference SYSGEN Builds

2. Compiler Selection & Language Standard Compliance

	2.1 Approved Production Compilers & Pre-Translators

	2.2 Mandatory COBOL-68 Syntax Boundaries

3. Dataset Naming, Library Architecture, and JCL Standards

	3.1 Departmental Dataset Naming Conventions

	3.2 Standardized DCB & DASD Allocation Geometry

	3.3 Mandatory JOB Card and JES2 Control Standards

	3.4 Cataloged Procedures & Override Rules (COBUCL / COBUCLG)

	3.5 Idempotent Dataset Cleanup & Condition Code (COND) Control

4. Data Division & Copybook Architecture Standards

	4.1 Copybook Modularity (COPY Statements)

	4.2 Level Number Hierarchy & BLOCK CONTAINS 0 RECORDS

	4.3 Numeric Data Representation (USAGE) & Initialization

	4.4 Condition Names (88-Levels): Comprehensive Standards & Patterns

5. Procedure Division Structure & Control Flow Standards

	5.1 Top-Down Paragraph Numbering Architecture

	5.2 Control Flow Rules & Exit Discipline

6. Batch File I/O, Sort/Merge, and VSAM Engineering Standards

	6.1 The Priming Read Pattern

	6.2 Internal SORT (SD) Standards

	6.3 VSAM KSDS Processing Standards (Batch & Online Shared Files)

7. Modular Subprogram Linkage (CALL vs. EXEC CICS LINK/XCTL)

8. KICKS Online COBOL & BMS Screen Engineering Standards

	8.1 Pseudo-Conversational Transaction Architecture (Mandatory)

	8.2 DFHCOMMAREA State Management & Copybook Standards

	8.3 Basic Mapping Support (BMS) Screen Design Standards

	8.4 KICKS Resource Definition (PPT, PCT, FCT) & Pre-Translation Workflow

9. Complete Reference Templates (Batch & KICKS Online)

	9.1 Compliant Batch Reference Template (PAYAUD01)

	9.2 Compliant KICKS Pseudo-Conversational Online Template (EMPINQ01)

10. KICKS Build, Deployment & Resource Configuration Suite

	10.1 Shared Record Copybook (EMPREC)

	10.2 BMS Mapset Source (EMPMAPS)

	10.3 VSAM KSDS Cluster Creation & Seed Load JCL (IDCAMS)

	10.4 BMS Mapset Assembly & COBOL Compile JCL

	10.5 KICKS Resource Table Entries (KIKPPT, KIKPCT, KIKFCT) & Startup Allocation

11. Production Readiness Checklist & Abend Triage Protocol

	11.1 Pre-Promotion Sign-Off Checklist

	11.2 Rapid Abend Resolution Guide (Batch & KICKS)

12. Appendix: COBOL Commenting and Program Prologue Standards

13. Alphabetical Technical & Keyword Index

## 1. Purpose, Scope, and Architectural Governance

This manual establishes mandatory design, coding, Job Control Language (JCL), online transaction processing (OLTP), testing, deployment, and operational standards for all batch and interactive COBOL applications developed on the department's MVS 3.8j (TK5) mainframe environment.

### Why Standardized Governance Matters:

Mainframe batch and online environments operate under strict resource ceilings—most notably a 24-bit virtual addressing limit (16 MB per address space) and shared Direct Access Storage Device (DASD) volumes. Unlike modern runtime environments that mask memory leaks or uninitialized variables behind garbage collectors and dynamic heap allocation, MVS 3.8j executes compiled System/370 machine instructions directly against fixed storage offsets. Without uniform coding and JCL conventions, minor oversights—such as an uninitialized packed-decimal accumulator, a missing BLOCK CONTAINS clause, an improperly coded COND parameter, or a conversational online task holding locks across terminal think-time—escalate into production abends (S0C7, S013, S80A, ASRA), silent data corruption, or cascaded batch schedule failures.

Enforcing a single departmental baseline ensures that any engineer can pick up an unfamiliar batch or KICKS online module, read its structure immediately, diagnose a dump using predictable compiler listings, and promote code into production without operational surprises.

### 1.1 Environment Baseline: TK5 vs. Reference SYSGEN Builds

All departmental build procedures assume the MVS-Turnkey 5 (TK5) software stack. Engineers accustomed to clean-room System Generation (SYSGEN) builds—such as Jay Moseley's baseline MVS 3.8j distribution—must observe the following environmental differences before migrating or submitting jobs:

| Architectural Component | Departmental TK5 Standard | Reference SYSGEN (e.g., Jay Moseley) | Operational Impact on Development |
| :---- | :---- | :---- | :---- |
| Primary COBOL Compiler | IBM ANS COBOL V2 (IKFCBL00) pre-installed in SYS2.LINKLIB | Assembler XF (IFOX00) only out of the box; IKFCBL00 installed optionally from MVT/SYSCPK | Production JCL may invoke COBUC* procedures directly without custom STEPLIB compiler overrides |
| Online CICS-Compatible Monitor | KICKS (pre-installed or deployed under KICKS.V1R5M0.* / HERC01.KICKS.*) | No OLTP monitor installed out of the box | Online applications use Command-Level EXEC CICS translated via KIKCB2CL and mapped via KIKMAPS |
| Cataloged Procedures | Standardized in SYS2.PROCLIB (COBUC, COBUCL, COBUCG, COBUCLG) and KICKS proclibs | Manually authored or loaded from optional compiler distribution tape | Standardized step names (COB, LKED, GO, KIKPP, ASM) are guaranteed across all departmental JCL |
| Security & Access Control | RAKF active (HERC01/HERC02 profiles; dataset-level RACF-style protection) | Basic MVS dataset password protection only unless RAKF is installed | Production and test datasets must follow High-Level Qualifier (HLQ) naming rules to avoid S913 security abends |
| Interactive Workbench | RFE (Review Front End) and RPF pre-installed under TSO | Line-mode TSO EDIT command unless RPF/RFE is manually installed | Developers use RFE Option 3.4 for PDS management and Option 3.8 for held spool inspection |
| JES2 Spool Routing | Held output class X enabled for online TSO review; class A routes to printer | Varies by local JES2PARM initialization deck | All test jobs must specify MSGCLASS=X to conserve virtual printer output |

## 2. Compiler Selection & Language Standard Compliance

### 2.1 Approved Production Compilers & Pre-Translators

All production COBOL modules shall be compiled using IBM OS/VS COBOL (IKFCBL00), conforming to the ANSI X3.23-1968 standard (COBOL-68) with supported IBM OS/VS extensions, link-edited against SYS1.COBLIB (and KICKS.V1R5M0.SKIKLOAD for online KICKS modules).

#### Why We Standardize on Native IKFCBL00 and KIKCB2CL:

While educational distributions offer in-memory student compilers (such as WATBOL) and modern workstations allow cross-compiling COBOL-85/2002 source via GnuCOBOL and GCCMVS, neither approach is acceptable for departmental production modules. WATBOL lacks true object-deck generation and cannot link-edit static subprograms into permanent load libraries. Cross-compiled C-to-370 code introduces non-standard runtime dependencies that complicate SYSUDUMP diagnostics and break KICKS Command-Level API translation. Native IKFCBL00 paired with the KICKS COBOL pre-translator (KIKPPCOB) produces deterministic, compact System/370 machine code supported directly by MVS 3.8j runtime libraries (ILBO* routines) and standard IBM linkage conventions.

### 2.2 Mandatory COBOL-68 Syntax Boundaries

Because IKFCBL00 predates the ANSI COBOL-85 standard, engineers with modern Enterprise COBOL backgrounds must strictly avoid post-1974 language constructs in both batch and KICKS online programs:

1. No Explicit Scope Terminators: END-IF, END-PERFORM, END-READ, END-WRITE, and END-EVALUATE are syntax errors. Conditional blocks are terminated exclusively by ELSE or a period (.).

2. No EVALUATE Verb: Multi-way branching must be coded using nested IF ... ELSE IF structures or, for dense integer dispatch tables, GO TO ... DEPENDING ON.

3. No Inline PERFORM: PERFORM UNTIL ... END-PERFORM is prohibited. Every loop body must reside in a separate, named out-of-line paragraph.

4. No SET condition-name TO TRUE: In COBOL-68, 88-level condition names are strictly read-only boolean tests used in IF and UNTIL clauses. State changes must be performed via an explicit MOVE to the parent elementary field (e.g., MOVE 'Y' TO WS-EOF-SW).

5. Fixed Column Margin Discipline:

   * Columns 1–6 (Sequence Area): Six-digit ascending sequence numbers (000100, 000200). Non-numeric characters in columns 1–6 generate compiler warnings.

   * Column 7 (Indicator Area): Blank for standard code; * for comment lines; / for comment lines triggering a page eject on the source listing; - for non-numeric literal continuation.

   * Columns 8–11 (Area A): DIVISION headers, SECTION headers, paragraph names, FD/SD level indicators, and 01/77 level numbers.

   * Columns 12–72 (Area B): All executable statements, 02–49 level numbers, 88 condition names, SELECT/FD clauses, and EXEC CICS ... END-EXEC blocks.

   * Columns 73–80 (Identification Area): Ignored by IKFCBL00; reserved for member/change tags or RFE sequence metadata.


#### Why Strict Margin and Period Discipline Is Enforced:

In COBOL-68, a single misplaced period inside a nested IF prematurely closes every enclosing conditional block, causing subsequent statements to execute unconditionally without generating a compile-time error. Conversely, omitting a period before a new paragraph header causes the compiler to treat the paragraph name as part of the preceding statement, cascading into dozens of false syntax diagnostics. Enforcing visual indentation aligned with Area B boundaries makes block scope immediately visible during code reviews.

## 3. Dataset Naming, Library Architecture, and JCL Standards

### 3.1 Departmental Dataset Naming Conventions

Every dataset created or referenced by departmental batch or KICKS jobs must adhere to a structured multi-qualifier naming convention:

HLQ.APPLICATION.TYPE[.QUALIFIER]

* Development / Personal Batch Libraries: HERC01.PAYROLL.COBOL, HERC01.PAYROLL.COPYLIB, HERC01.PAYROLL.JCL, HERC01.PAYROLL.LOADLIB

* Development / Personal KICKS Libraries: HERC01.KICKS.COBOL, HERC01.KICKS.BMS, HERC01.KICKS.COPYLIB, HERC01.KICKS.LOADLIB

* Production Libraries: PROD.PAYROLL.LOADLIB, PROD.KICKS.LOADLIB, PROD.PAYROLL.PROCLIB, PROD.PAYROLL.PARMLIB

* Production Data Files: PROD.PAYROLL.MASTER.CUST, PROD.PAYROLL.TRANS.DAILY, PROD.PAYROLL.VSAM.CLUSTER

#### Why Standardized Dataset Naming Is Mandatory:

MVS 3.8j catalogs datasets in a hierarchical VSAM/CVOL catalog structure where the High-Level Qualifier (HLQ) governs catalog routing and RAKF security permissions. Consistent third-level type qualifiers (.COBOL, .BMS, .COPYLIB, .LOADLIB) enable automated backup jobs (IEBCOPY / IEHMOVE), prevent developers from accidentally overwriting production load modules with test compiles, and allow operations staff to identify dataset contents immediately in RFE Option 3.4 listings.

### 3.2 Standardized DCB & DASD Allocation Geometry

All new datasets must explicitly declare Data Control Block (DCB) attributes optimized for emulated IBM 3350 DASD volumes (19,069 bytes per track, 30 tracks per cylinder):

| Dataset Category | DSORG | RECFM | LRECL | BLKSIZE | Space Allocation Standard |
| :---- | :---- | :---- | :---- | :---- | :---- |
| COBOL Source / BMS / Copybooks / JCL | PO (PDS) | FB | 80 | 3120 or 6160 | SPACE=(TRK,(15,5,20)) |
| Executable Load Libraries (Batch & KICKS) | PO (PDS) | U | 0 | 19069 | SPACE=(CYL,(5,2,30)) |
| Sequential Master / Trans Data | PS | FB | Record Len | Multiple 9440 | SPACE=(CYL,(10,5),RLSE) |
| Print Reports (SYSPRINT / Disk) | PS | FBA | 133 | 3990 or 6118 | SPACE=(TRK,(10,5),RLSE) |

#### Why Optimal Blocking and RLSE Are Required:

Every physical block read or written on MVS triggers a Start I/O (SIO) channel program, incurring CPU supervisor overhead and emulated disk latency. Choosing BLKSIZE=6160 for 80-byte source members packs 77 source cards into a single physical block (3 blocks per 3350 track), cutting I/O operations by nearly 99% compared to unblocked (BLKSIZE=80) datasets. Including RLSE (Release) on sequential output datasets returns unused allocated tracks to the VTOC upon normal CLOSE, preventing artificial disk exhaustion across shared DASD volumes.

### 3.3 Mandatory JOB Card and JES2 Control Standards

Every JCL job stream must begin with a complete, multi-parameter JOB card and a /*JOBPARM statement:

```JCL
//HERC01B  JOB (PAYR01),'IAN STANLEY', 
//             CLASS=A, 
//             MSGCLASS=X, 
//             MSGLEVEL=(1,1), 
//             REGION=4096K, 
//             TIME=(2,0), 
//             NOTIFY=HERC01
/*JOBPARM LINES=50 
```

#### Why Every JOB Parameter Is Specified:

* Job Name (UserID + 1 Char): Prefixing job names with your TSO User ID (HERC01B) allows JES2 NOTIFY and OUTPUT commands to isolate your jobs from other users in the spool queue.

* MSGCLASS=X: Routes JES2 job logs, JCL expansions, and allocation messages to held spool class X for online inspection via RFE Option 3.8, rather than flooding the emulated physical line printer (CLASS=A).

* MSGLEVEL=(1,1): Forces JES2 to print full expanded cataloged procedures (XX statements) and all step allocation/termination condition codes (IEF142I), providing an indispensable audit trail when debugging procedure overrides.

* REGION=4096K: Grants 4 MB of private virtual storage. IKFCBL00, the Linkage Editor (IEWL), KICKS pre-translators, and OS Sort/Merge routinely abend with S80A (insufficient storage) when executed under default 512K–1024K step regions.

* TIME=(2,0) and JOBPARM LINES=50: Protects the MVS environment against runaway PERFORM UNTIL loops that would otherwise consume 100% host CPU (S322 timeout) or fill the JES2 spool volume (S722 line limit).

### 3.4 Cataloged Procedures & Override Rules (COBUCL / COBUCLG)

* Development Compile-Link-Go (Batch): Use EXEC COBUCLG for unit testing.

* Production Promotion (Batch): Use EXEC COBUCL targeting PROD.<APP>.LOADLIB—never execute production jobs directly via COBUCLG.

* Standardized Compiler PARM.COB:

```JCL
//BUILD    EXEC COBUCLG,   
//         PARM.COB='LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,SIZE=2048K,BUF=1024K',   
//         PARM.LKED='LIST,XREF,LET,MAP' 
```


#### Why These Compiler Options Are Non-Negotiable:

DMAP (Data Map), CLIST (Condensed Listing), and SXREF (Sorted Cross-Reference) together form the diagnostic foundation for MVS 3.8j. When a production batch job or KICKS transaction abends with a S0C7, S0C4, or ASRA, the MVS SYSUDUMP reports only a hexadecimal Program Status Word (PSW) instruction address. Without CLIST (to map that hex offset back to a COBOL source line) and DMAP (to locate the exact Base Locator and displacement of the offending data field), debugging a dump becomes guesswork. Furthermore, FLAGW surfaces warning-level (W) diagnostics—such as field truncation or slack-byte insertion—that frequently mask subtle data corruption.

### 3.5 Idempotent Dataset Cleanup & Condition Code (COND) Control

Batch jobs must be restartable without manual catalog intervention. Before allocating any new permanent sequential dataset, include an IEFBR14 cleanup step:

```JCL
//CLEANUP  EXEC PGM=IEFBR14 
//OUTDEL   DD DSN=HERC01.PAYROLL.REPORT, 
//            DISP=(MOD,DELETE,DELETE), 
//            UNIT=SYSDA,SPACE=(TRK,(1,0)) 
```

##### Why DISP=(MOD,DELETE,DELETE) Is Used:

If a job abends mid-run and is resubmitted, a standard DISP=(NEW,CATLG,DELETE) on a dataset created in an earlier completed step fails immediately with a JCL ERROR - DUPLICATE NAME ON DIRECT ACCESS VOLUME. Using DISP=(MOD,DELETE,DELETE) in an initial IEFBR14 step safely deletes and uncatalogs the dataset if it exists, or allocates and immediately deletes a dummy 1-track dataset if it does not—guaranteeing clean reruns every time.

Control step progression using inverse COND= logic:

```JCL 
//RUNSTEP  EXEC PGM=PAYR010,COND=(4,LT) 
```


* COND=(4,LT): bypasses RUNSTEP if 4 is less than any prior return code (i.e., skips execution if any prior step returned RC >= 8), allowing execution to proceed cleanly on RC = 0 or RC = 4 (compiler warnings).

## 4. Data Division & Copybook Architecture Standards

### 4.1 Copybook Modularity (COPY Statements)

All file record layouts, shared working-storage parameter blocks, KICKS DFHCOMMAREA structures, BMS symbolic maps, standard error message structures, and subprogram linkage areas must be stored as standalone members in a dedicated .COPYLIB PDS and included via COPY statements in Area B:

```COBOL
	FD  EMP-MASTER-FILE            
		RECORDING MODE IS F            
		LABEL RECORDS ARE STANDARD            
		BLOCK CONTAINS 0 RECORDS            
		RECORD CONTAINS 150 CHARACTERS.        
	01  EMP-MASTER-REC.           
		COPY EMPREC. 
```

#### Why Copybooks Are Mandatory Across All Multi-Program Systems:

Hardcoding record layouts or COMMAREA structures inside individual COBOL source members creates silent structural drift: when a field length changes or a new status byte is added to a master file or online transaction payload, one program is updated while a downstream reporting program continues reading the old offset, producing corrupted totals or S0C7/ASRA abends. 

Centralizing layouts in .COPYLIB guarantees a single source of truth across every batch reader, writer, subprogram, and KICKS transaction, simplifies impact analysis via SXREF and PDS member searches, and enforces uniform field naming across the entire development team.

### 4.2 Level Number Hierarchy & BLOCK CONTAINS 0 RECORDS

1. Level Number Increments: Use 01 for record/group roots, then increment subordinate group and elementary levels by 05 (05, 10, 15, 20). Never use 77-level independent items (group related flags and counters under logical 01 structures instead) and strictly prohibit 66-level RENAMES clauses.

2. File Description (FD) Blocking: Every sequential FD in batch programs must specify BLOCK CONTAINS 0 RECORDS. (Note: KICKS online programs never declare FD or FILE SECTION entries; all file I/O in KICKS uses EXEC CICS File Control APIs).

#### Why We Increment by 05 and Code BLOCK CONTAINS 0 RECORDS:

Incrementing level numbers by 05 allows future programmers to insert intermediate group levels (such as 07 or 12) during maintenance without renumbering an entire record structure. Coding BLOCK CONTAINS 0 RECORDS in batch FDs decouples the compiled load module from physical DASD blocking: QSAM dynamically interrogates the JCL DD card or dataset VTOC label at OPEN time, allowing operations staff to re-block files for faster I/O without recompiling COBOL source code.


### 4.3 Numeric Data Representation (USAGE) & Initialization

* COMP-3 (Packed Decimal): Mandatory for all business amounts, counters, accumulators, and financial quantities. Always declare an odd number of digits (PIC S9(7)V99 COMP-3 = 5 bytes) so the sign nybble aligns cleanly on a byte boundary without wasting a half-byte.

* COMP (Binary) with SYNC: Mandatory for table subscripts, OCCURS indices, KICKS LENGTH parameters, and CALL length fields (PIC S9(4) COMP SYNC).

* DISPLAY (Zoned Decimal): Restricted exclusively to external human-readable input fields, report edit masks (PIC $, 9.99), BMS screen map fields, and character keys.

* Explicit Initialization: Every WORKING-STORAGE counter, accumulator, switch, and status field must carry an explicit VALUE clause (VALUE ZERO or VALUE SPACES).

#### Why COMP-3 and Explicit Initialization Prevent S0C7 and ASRA Abends:

System/370 hardware executes decimal arithmetic natively on packed-decimal operands (AP, SP, MP, DP). Performing arithmetic on DISPLAY fields forces IKFCBL00 to emit extra PACK and UNPK conversion instructions on every verb, bloating code size and CPU consumption. Furthermore, MVS 3.8j does not zero-initialize WORKING-STORAGE fields lacking a VALUE clause—residual memory bytes remain in storage. Attempting arithmetic on an uninitialized COMP-3 field triggers an immediate hardware S0C7 (Data Exception) abend in batch or an ASRA (Program Check) abend in KICKS. Never initialize a group structure containing COMP-3 fields via MOVE SPACES TO group-name, as EBCDIC spaces (X'40') are invalid packed-decimal digits.

### 4.4 Condition Names (88-Levels): Comprehensive Standards & Patterns

Every status code, transaction type, file status check, record flag, KICKS EIBAID attention key check, and multi-value validation rule must be defined using descriptive 88-level condition names immediately beneath its parent elementary item.

#### Why Descriptive 88-Level Condition Names Are Superior to Literal Comparisons:

Literal checks scattered throughout the PROCEDURE DIVISION (such as IF EMP-STATUS = 'A' OR EMP-STATUS = 'P' OR EMP-STATUS = 'L') obscure business intent, create duplication across paragraphs, and force engineers to hunt through hundreds of lines of procedural code whenever a new business code is introduced. Encapsulating domain values inside 88-level condition names transforms opaque character comparisons into self-documenting business English (IF EMP-ELIGIBLE-FOR-BENEFITS), centralizes valid value lists inside the Data Division or copybook, and eliminates typo-induced logic bugs.

#### Standard 88-Level Usage Patterns in IKFCBL00

##### Pattern 1: Single-State Binary Switches & EOF Flags

Pair positive and negative condition names on every control switch so procedural tests read naturally without double negatives (IF NOT NOT-EOF):

```COBOL

01  WS-CONTROL-SWITCHES. 
	05  WS-MASTER-EOF-SW        PIC X(01) VALUE 'N'. 
		88  END-OF-MASTER                 VALUE 'Y'. 
		88  MORE-MASTER-RECORDS           VALUE 'N'. 
	05  WS-VALID-RECORD-SW      PIC X(01) VALUE 'Y'. 
		88  RECORD-IS-VALID               VALUE 'Y'.
		88  RECORD-HAS-ERRORS             VALUE 'N'. 
```

##### Pattern 2: Multi-Value Sets and Contiguous Ranges (THRU)

Group discrete business codes and contiguous numeric/alphanumeric ranges into semantic classifications:

```COBOL
01  EMP-RECORD-FIELDS. 
	05  EMP-PAY-STATUS          PIC X(01). 
		88  EMP-ACTIVE-SALARIED           VALUE 'S'. 
		88  EMP-ACTIVE-HOURLY             VALUE 'H'. 
		88  EMP-ON-PAID-LEAVE             VALUE 'L'.
		88  EMP-TERMINATED                VALUE 'T'. 
		88  EMP-RETIRED                   VALUE 'R'.
		88  EMP-CURRENTLY-ACTIVE          VALUE 'S' 'H' 'L'.
		88  EMP-INACTIVE                  VALUE 'T' 'R'.
		88  VALID-PAY-STATUS              VALUE 'S' 'H' 'L' 'T' 'R'. 
	05  EMP-DEPT-CODE           PIC 9(03).
		88  DEPT-ENGINEERING              VALUE 100 THRU 199.
		88  DEPT-MANUFACTURING            VALUE 200 THRU 299.
		88  DEPT-ADMINISTRATION           VALUE 300 THRU 350.
		88  DEPT-VALID-RANGE              VALUE 100 THRU 350. 
```

##### Pattern 3: Standardized File Status & KICKS Response/AID Evaluation

Define 88-level conditions on every FILE STATUS (PIC XX) field and KICKS RESP / EIBAID field so error and key handling never hardcode raw codes in the PROCEDURE DIVISION:

```COBOL
01  WS-FILE-STATUS-AREA. 
	05  WS-CUST-VSAM-STATUS     PIC X(02) VALUE SPACES. 
		88  VSAM-SUCCESS                  VALUE '00'. 
		88  VSAM-DUP-ALT-KEY              VALUE '02'.
		88  VSAM-EOF                      VALUE '10'. 
		88  VSAM-DUP-PRIMARY-KEY          VALUE '22'. 
		88  VSAM-RECORD-NOT-FOUND         VALUE '23'. 
		88  VSAM-EMPTY-OR-MISSING         VALUE '35'. 
		88  VSAM-RECOVERABLE-ERR        VALUE '02' '22' '23'.  
01  WS-KICKS-AID-WORK. 
	05  WS-PRESSED-KEY          PIC X(01) VALUE SPACES.
		88  KEY-ENTER                     VALUE ''''. 
		88  KEY-PF3-EXIT                  VALUE '3'.
		88  KEY-PF5-REFRESH               VALUE '5'. 
		88  KEY-PF12-CANCEL               VALUE '@'. 
		88  KEY-CLEAR                     VALUE '_'. 
```

## 5. Procedure Division Structure & Control Flow Standards

### 5.1 Top-Down Paragraph Numbering Architecture

Every COBOL program (batch and online) must organize its PROCEDURE DIVISION into a top-down hierarchy using four-digit numeric prefixes paired with verb-noun descriptive names:

* 0000-MAIN-CONTROL: Executive driver paragraph (contains only PERFORM statements and GOBACK / EXEC CICS RETURN).

* 1000–1999 (Initialization): File opens (batch), EIBCALEN inspection and initial map send (KICKS), parameter validation, and priming reads.

* 2000–2999 (Core Business Processing): Main transaction loop (batch) or user key/input dispatch (KICKS), validation, calculations, and master updates.

* 3000–3999 (Termination & Clean Exit): Summary totals, audit trailer output, file closes, and RETURN-CODE assignment (batch) or EXEC CICS RETURN TRANSID(...) COMMAREA(...) (KICKS).

* 8000–8999 (Report & Screen Formatting Utilities): Page break checks, header printing, or BMS symbolic map population.

* 9000–9999 (Centralized I/O & Abend Handling): Single-purpose READ/WRITE or EXEC CICS READ/REWRITE/SEND/RECEIVE paragraphs and fatal error routines.

#### Why Hierarchical Numbering Is Enforced:

In large COBOL-68 programs lacking nested block scoping, locating a target paragraph called via PERFORM can require scanning thousands of lines. Sequential four-digit numbering acts as a built-in table of contents: any developer reading PERFORM 8120-SEND-ERROR-MAP knows immediately that the paragraph resides near the bottom of the program in the formatting section, dramatically accelerating maintenance and code walkthroughs.

### 5.2 Control Flow Rules & Exit Discipline

1. Prohibit ALTER and Arbitrary GO TO: The ALTER verb is strictly banned. GO TO is permitted only when branching forward to an -EXIT paragraph within a PERFORM ... THRU ...-EXIT range to handle an early validation exit.

2. Terminate Batch Main Programs with GOBACK: Never use STOP RUN in modular batch applications. GOBACK cleanly returns control to MVS (passing RETURN-CODE to JES2) when invoked as a main program, and returns to the calling module when invoked via CALL. (In KICKS online programs, always terminate via EXEC CICS RETURN ... END-EXEC—never STOP RUN or GOBACK from a top-level KICKS transaction).

3. Set RETURN-CODE Explicitly (Batch): Every batch program must set the RETURN-CODE special register before GOBACK (0 = clean, 4 = non-fatal data warnings logged, 8 = business rule failure, 16 = fatal I/O or system abort).

#### Why GOBACK and Explicit RETURN-CODE Are Critical:

If a batch program uses STOP RUN and is later converted into a called subprogram, STOP RUN abruptly terminates the entire MVS task—preventing the caller from closing files or writing audit totals. Similarly, failing to set RETURN-CODE leaves whatever residual value happened to sit in Register 15, potentially fooling downstream JCL COND= checks into running updates against failed prerequisite steps. In KICKS, executing STOP RUN terminates the entire TSO/KICKS session abruptly rather than returning control to the transaction monitor.

## 6. Batch File I/O, Sort/Merge, and VSAM Engineering Standards

### 6.1 The Priming Read Pattern

All sequential batch file processing must use the Priming Read architecture, isolating READ statements inside dedicated 9000-series paragraphs:

```COBOL
	1000-INITIALIZE.
		OPEN INPUT  TRANS-IN-FILE 
		OUTPUT AUDIT-REPORT-FILE. 
		IF NOT TRANS-IO-OK 
			DISPLAY 'FATAL: OPEN FAILED ON TRANSIN = ' WS-TRANS-STATUS 
			MOVE 16 TO RETURN-CODE 
			GOBACK
		END-IF. 
		PERFORM 9100-READ-TRANS.
	2000-PROCESS-LOOP.
		PERFORM 2100-PROCESS-ONE-RECORD.
		PERFORM 9100-READ-TRANS. 
	9100-READ-TRANS. 
		READ TRANS-IN-FILE 
			AT END
			SET END-OF-TRANS TO TRUE 
			END-READ. 
		IF NOT END-OF-TRANS 
			IF NOT TRANS-IO-OK 
				DISPLAY 'FATAL: READ ERROR ON TRANSIN = ' WS-TRANS-STATUS
				MOVE 16 TO RETURN-CODE
				GOBACK 
			END-IF 
			ADD 1 TO WS-TRANS-READ-CNT 
		END-IF. 
```

#### Why the Priming Read Pattern Is Mandatory:

A classic COBOL defect occurs when a developer places READ at the top of a PERFORM UNTIL EOF loop: when AT END triggers on the final read, execution falls straight through into the processing logic below it, processing the last record twice or referencing an invalid FD buffer. The Priming Read pattern handles empty input files gracefully (0 iterations of 2000-PROCESS-LOOP), guarantees every valid record is processed exactly once, and centralizes FILE STATUS verification and record counting in one location.

### 6.2 Internal SORT (SD) Standards

When sorting is required within a batch COBOL program, use SORT ... INPUT PROCEDURE ... OUTPUT PROCEDURE rather than invoking an external sort step when pre-filtering or post-aggregation reduces I/O volume:

* Always check SORT-RETURN immediately after the SORT verb (IF SORT-RETURN NOT = 0).

* Every JCL GO step invoking an internal COBOL SORT must supply //GO.SYSOUT DD SYSOUT=* and at least three SORTWK01–SORTWK03 DD allocations.

#### Why SYSOUT and SORTWK DDs Are Required in TK5:

The OS/360 Sort/Merge utility integrated into MVS 3.8j TK5 requires SYSOUT for diagnostic messages and SORTWKnn DASD work files whenever sort volume exceeds in-memory buffers. Omitting SYSOUT causes Sort/Merge to issue a console Write-To-Programmer warning and terminate with RC=16.

### 6.3 VSAM KSDS Processing Standards (Batch & Online Shared Files)

1. Cluster Definition: Define all VSAM Key-Sequenced Data Sets (KSDS) via IDCAMS DEFINE CLUSTER in a dedicated setup job before program execution.
2. Initial Seed Record Requirement: On MVS 3.8j VSAM, an empty KSDS cluster cannot be opened directly for I-O (FILE STATUS '35' or '90', or KICKS NOTOPEN/ILLOGIC). Load a low-values (LOW-VALUES) or zero-key sentinel control record via IDCAMS REPRO immediately after cluster creation.
3. Status Checking: Evaluate FILE STATUS (batch) or RESP codes (KICKS) after every I/O operation using 88-level condition names.

## 7. Modular Subprogram Linkage (CALL vs. EXEC CICS LINK/XCTL)

1. Batch Static vs. Dynamic Linking: Use static CALL 'SUBPROG' USING ... for tightly coupled utility routines bound at link-edit time via LKED.SYSLIB. Use dynamic CALL WS-MODULE-NAME USING ... (compiled with DYNAM) for shared business services that must be upgraded independently without relinking callers.
2. KICKS Program Control: In online KICKS transactions, use EXEC CICS LINK PROGRAM('SUBPROG') COMMAREA(...) LENGTH(...) END-EXEC for subroutine calls that return to the caller, and EXEC CICS XCTL PROGRAM('NEXTPROG') COMMAREA(...) LENGTH(...) END-EXEC to transfer control to the next screen program at the same logical level without stacking return addresses.
3. Group-Level Parameter Passing: Pass arguments using a single 01-level LINKAGE SECTION copybook structure rather than long lists of elementary fields.
4. Batch Subprogram Termination: Terminate every batch subprogram with EXIT PROGRAM. followed by GOBACK..

#### Why Group-Level Linkage Copybooks Are Enforced:

Passing 15 separate elementary arguments in a CALL ... USING list invites parameter order mismatches and alignment bugs that produce subtle memory corruption or S0C4 protection exceptions. Passing a single shared 01-level copybook guarantees identical byte offsets, picture clauses, and USAGE types between caller and callee.

## 8. KICKS Online COBOL & BMS Screen Engineering Standards

KICKS provides a CICS Command-Level compatible online transaction processing (OLTP) monitor on MVS 3.8j TK5, running under TSO (or VTAM) and executing 3270 terminal transactions against VSAM datasets. All departmental online applications must adhere to the following KICKS architectural standards.

### 8.1 Pseudo-Conversational Transaction Architecture (Mandatory)

Every interactive KICKS screen program must be designed as pseudo-conversational—never conversational.

#### Why Pseudo-Conversational Design Is Non-Negotiable:

In a conversational program, the transaction issues EXEC CICS SEND MAP followed immediately by EXEC CICS RECEIVE MAP inside a single task execution. While the human operator thinks, types, or steps away from the 3270 terminal, the task remains active in virtual memory, tying up a KICKS task control block, holding working-storage memory within the 24-bit address space, and potentially holding VSAM exclusive control intervals (locks) that block other users or batch jobs. In a pseudo-conversational design, the program sends the 3270 map and immediately terminates (EXEC CICS RETURN TRANSID('XXXX') COMMAREA(WS-COMMAREA) LENGTH(WS-COMM-LEN) END-EXEC), releasing all memory and file locks. When the user presses ENTER or a PF key, KICKS initiates a fresh task instance and passes the saved state back via DFHCOMMAREA.

#### Standard 0000-MAIN-CONTROL Pseudo-Conversational Dispatch Pattern

Every KICKS screen program must inspect EIBCALEN (the length of DFHCOMMAREA passed into the task) upon entry:

* EIBCALEN = 0 (First Entry): The transaction was invoked freshly from a cleared screen (e.g., typing EINQ) or transferred from a menu without state. Initialize WS-COMMAREA, send an empty formatted map (MAPONLY), and return with TRANSID pointing back to itself.

* EIBCALEN > 0 (Subsequent Re-Entry): The user interacted with the screen and pressed an AID key (ENTER, PF3, PF5, PF12). Copy DFHCOMMAREA into WS-COMMAREA, evaluate EIBAID using standard DFHAID copybook definitions, receive the map (RECEIVE MAP), process business logic, send updated screen feedback (DATAONLY or full map), and return with updated WS-COMMAREA.

### 8.2 DFHCOMMAREA State Management & Copybook Standards

1. Dedicated Copybook: Define every transaction's COMMAREA layout in a dedicated .COPYLIB member (e.g., CUSTCOMM) and copy it into both WORKING-STORAGE SECTION (01 WS-COMMAREA) and LINKAGE SECTION (01 DFHCOMMAREA).
2. State Machine Flag (CA-PROCESS-STAGE): Include a 1-byte stage indicator with 88-level condition names inside WS-COMMAREA (CA-STAGE-FIRST-ENTRY, CA-STAGE-AWAIT-KEY, CA-STAGE-CONFIRM-DEL) so the program tracks multi-step user workflows deterministically across pseudo-conversational turns.
3. Strict Length Matching: Always compute WS-COMM-LEN (PIC S9(4) COMP SYNC) using a binary field matching the exact byte length of WS-COMMAREA, and verify IF EIBCALEN NOT = WS-COMM-LEN on re-entry to trap LENGERR anomalies before moving DFHCOMMAREA.

#### Why WS-COMMAREA Must Be Copied to Working Storage:

DFHCOMMAREA resides in storage owned by KICKS outside the program's local WORKING-STORAGE. Copying DFHCOMMAREA into 01 WS-COMMAREA at the start of 1100-RESTORE-COMMAREA ensures that local modifications remain safe across EXEC CICS calls and can be cleanly passed back on EXEC CICS RETURN.

### 8.3 Basic Mapping Support (BMS) Screen Design Standards

All 3270 terminal layouts must be defined using standard BMS macros (DFHMSD, DFHMDI, DFHMDF) in HERC01.KICKS.BMS and assembled via the KICKS map generation procedure (KIKMAPS) to produce both a Physical Map (load module in SKIKLOAD / user loadlib) and a Symbolic Map (COBOL copybook in .COPYLIB).

#### Departmental 3270 Screen Layout Conventions (24×80 Model 2 Standard)

| Screen Row(s) | Functional Zone | Standard Content & BMS Attributes |
| :---- | :---- | :---- |
| Row 1 | System Header Banner | Transaction ID (Cols 2–5), Application/Screen Title (centered, BRT,PROT), System Date & Time (Cols 65–79, PROT) |
| Row 2 | Sub-Header / Mode Indicator | Current Action Mode (INQUIRY, ADD, UPDATE) (ASKIP,NORM) |
| Rows 4–20 | Data Entry & Display Body | Field labels (ASKIP,NORM) followed by input fields (UNPROT,IC on first input field; NUM for numeric fields; DARK for passwords) |
| Row 22 | Operator Message Line | 78-byte message area (MSGFLD, ASKIP,BRT) for validation errors, confirmations, and status notices |
| Rows 23–24 | Function Key Legend | Standardized PF key guide (ENTER=Process PF3=Exit PF5=Refresh PF12=Cancel, ASKIP,NORM) |

#### Mandatory BMS Coding Rules

1. Always Include Stopper Bytes: Every unprotected input field (ATTRB=(UNPROT,...)) must be immediately followed by a 1-byte dummy stopper field (DFHMDF POS=(r,c),LENGTH=1,ATTRB=ASKIP) so user typing cannot spill across the screen into adjacent labels or wrap onto the next row.
2. Always Set FSET (FRSET on Map / FSET on Field) Carefully: Use CTRL=(FREEKB,FRSET) on DFHMDI so Modified Data Tags (MDTs) are reset before sending a fresh screen, preventing stale input fields from retransmitting unintentionally unless explicitly flagged with DFHBMFSE (FSET) during validation error re-displays.
3. Cursor Positioning (IC / Symbolic -1 Length): Move -1 to the symbolic length field (FIELDL) and include the CURSOR option on EXEC CICS SEND MAP whenever highlighting a validation error so the 3270 cursor jumps directly to the offending input field.

#### Why Stopper Bytes and Symbolic Cursor Positioning Are Mandatory:

On a 3270 data stream, an unprotected field continues until the next attribute byte in the screen buffer. Omitting a stopper byte allows an operator typing an extra character to overwrite the following field's attribute byte or corrupt screen formatting. Positioning the cursor programmatically via MOVE -1 TO fieldL eliminates operator hunting during data entry errors, significantly reducing keystrokes and entry errors.

### 8.4 KICKS Resource Definition (PPT, PCT, FCT) & Pre-Translation Workflow

Unlike batch programs executed directly via EXEC PGM=, every KICKS transaction requires three table entries in the KICKS System Initialization / Resource Definition tables (KIKPPT, KIKPCT, KIKFCT) and a two-stage build pipeline (KIKCB2CL):

1. PPT (Processing Program Table): Registers both the compiled COBOL program load module (PROGRAM=EMPINQ01) and every BMS physical mapset (MAPSET=EMPMAPS) so KICKS can locate and load them into storage.
2. PCT (Program Control Table): Maps the 4-character terminal Transaction ID (TRANSID=EINQ) to its initial COBOL program (PROGRAM=EMPINQ01).
3. FCT (File Control Table): Links the logical COBOL DATASET('EMPFILE') name in EXEC CICS READ/WRITE commands to the physical MVS VSAM KSDS cluster DD statement allocated in the KICKS startup CLIST/JCL.
 

#### KICKS Pre-Translation & Compilation Standards (KIKCB2CL)

* Never compile a KICKS COBOL program directly with COBUCL; it must first pass through the KICKS COBOL Pre-Translator (KIKPPCOB), which injects DFHEIBLK and DFHCOMMAREA into the LINKAGE SECTION and translates EXEC CICS ... END-EXEC blocks into standard COBOL-68 CALL 'KIKCOB' statements before invoking IKFCBL00.

* Always check RESP(WS-RESP-CODE) on every EXEC CICS command (READ, WRITE, REWRITE, DELETE, RECEIVE MAP, SEND MAP) rather than relying on legacy EXEC CICS HANDLE CONDITION GO TO branches, which violate structured control flow standards.

#### Why RESP() Is Mandatory Over HANDLE CONDITION:

EXEC CICS HANDLE CONDITION behaves like a hidden, non-local GO TO that jumps out of the middle of a PERFORM paragraph whenever an exception occurs—leaving COBOL-68 PERFORM return stacks corrupted and causing unpredictable control flow when the program continues. Coding RESP(WS-RESP-CODE) keeps error handling strictly inline immediately after each EXEC CICS call, preserving single-entry/single-exit paragraph integrity.

## 9. Complete Reference Templates (Batch & KICKS Online)

### 9.1 Compliant Batch Reference Template (PAYAUD01)

The following template demonstrates full compliance with departmental JCL, 88-level condition naming, COMP-3 arithmetic, priming reads, and ANSI carriage-control reporting standards:

```JCL
//HERC01P  JOB (PAYR01),'IAN STANLEY', 
//             CLASS=A, 
//             MSGCLASS=X, 
//             MSGLEVEL=(1,1), 
//             REGION=4096K, 
//             TIME=(1,30), 
//             NOTIFY=HERC01 
/*JOBPARM LINES=50 
//*-------------------------------------------------------------------* 
//* STEP 1: IDEMPOTENT CLEANUP OF PRIOR OUTPUT REPORT DATASET         * 
//*-------------------------------------------------------------------* 
//CLEANUP  EXEC PGM=IEFBR14 
//RPTDEL   DD DSN=HERC01.PAYROLL.AUDITRPT,
//            DISP=(MOD,DELETE,DELETE), 
//            UNIT=SYSDA,SPACE=(TRK,(1,0)) 
//*-------------------------------------------------------------------* 
//* STEP 2: COMPILE, LINK-EDIT, AND EXECUTE PAYROLL AUDIT MODULE      * 
//*-------------------------------------------------------------------* 
//BUILD    EXEC COBUCLG, 
//         PARM.COB='LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,SIZE=2048K,BUF=1024K', 
//         PARM.LKED='LIST,XREF,LET,MAP' 
//COB.SYSIN DD * 
	   IDENTIFICATION DIVISION. 
       PROGRAM-ID.    PAYAUD01. 
       AUTHOR.        IAN STANLEY. 
       DATE-WRITTEN.  NOVEMBER 2026. 
      *================================================================* 
      * MODULE:  PAYAUD01 - DEPARTMENTAL PAYROLL AUDIT REPORT          * 
      * PURPOSE: VALIDATES EMPLOYEE STATUS AND DEPARTMENT RANGES USING * 
      *          88-LEVEL CONDITION NAMES AND PRODUCES AUDIT SUMMARY.  * 
      *================================================================*  
       ENVIRONMENT DIVISION. 
       CONFIGURATION SECTION. 
       SOURCE-COMPUTER. IBM-370. 
       OBJECT-COMPUTER. IBM-370.  
       INPUT-OUTPUT SECTION. 
       FILE-CONTROL. 
           SELECT EMP-IN-FILE      ASSIGN TO UT-S-EMPIN
                      FILE STATUS IS WS-EMP-STATUS. 
           SELECT AUDIT-RPT-FILE   ASSIGN TO UR-S-RPTOUT.  
       DATA DIVISION. 
       FILE SECTION. 
       FD  EMP-IN-FILE 
           RECORDING MODE IS F 
           LABEL RECORDS ARE STANDARD 
           BLOCK CONTAINS 0 RECORDS 
           RECORD CONTAINS 80 CHARACTERS. 
       01  EMP-IN-RECORD. 
           05  EI-EMP-ID               PIC X(06). 
           05  EI-EMP-NAME             PIC X(25). 
           05  EI-PAY-STATUS           PIC X(01).
			  88  EMP-SALARIED                  VALUE 'S'.
			  88  EMP-HOURLY                    VALUE 'H'.
			  88  EMP-PAID-LEAVE                VALUE 'L'.
			  88  EMP-TERMINATED                VALUE 'T'.
			  88  EMP-ACTIVE                    VALUE 'S' 'H' 'L'.
			  88  VALID-PAY-STATUS              VALUE 'S' 'H' 'L' 'T'. 
           05  EI-DEPT-CODE            PIC 9(03).
			  88  DEPT-ENGINEERING              VALUE 100 THRU 199.
			  88  DEPT-OPERATIONS               VALUE 200 THRU 299.
			  88  DEPT-FINANCE                  VALUE 300 THRU 350.
			  88  VALID-DEPT-CODE               VALUE 100 THRU 350. 
           05  EI-GROSS-PAY            PIC 9(07)V99. 
           05  FILLER                  PIC X(36).  
       FD  AUDIT-RPT-FILE 
           RECORDING MODE IS F 
           LABEL RECORDS ARE OMITTED 
           BLOCK CONTAINS 0 RECORDS 
           RECORD CONTAINS 133 CHARACTERS. 
       01  AUDIT-RPT-RECORD            PIC X(133).  
       WORKING-STORAGE SECTION. 
       01  WS-FILE-STATUS-FLAGS. 
           05  WS-EMP-STATUS           PIC X(02) VALUE SPACES.
			  88  EMP-IO-OK            			VALUE '00'.
			  88  EMP-IO-EOF           			VALUE '10'.  
       01  WS-CONTROL-SWITCHES. 
           05  WS-EOF-SW               PIC X(01) VALUE 'N'.
			  88  END-OF-EMP-FILE      			VALUE 'Y'.
			  88  MORE-EMP-RECORDS        	    VALUE 'N'. 
           05  WS-REC-VALID-SW         PIC X(01) VALUE 'Y'.
			  88  RECORD-IS-VALID           	VALUE 'Y'.
			  88  RECORD-IS-INVALID         	VALUE 'N'.  
       01  WS-ACCUMULATORS. 
           05  WS-READ-COUNT           PIC S9(07) COMP-3 VALUE ZERO. 
           05  WS-ACTIVE-COUNT         PIC S9(07) COMP-3 VALUE ZERO. 
           05  WS-ERROR-COUNT          PIC S9(07) COMP-3 VALUE ZERO. 
           05  WS-ACTIVE-PAY-TOTAL     PIC S9(11)V99 COMP-3 VALUE ZERO.  
       01  WS-PAGE-CONTROLS. 
           05  WS-LINE-CNT             PIC S9(03) COMP SYNC VALUE +99. 
           05  WS-MAX-LINES            PIC S9(03) COMP SYNC VALUE +55. 
           05  WS-PAGE-NUM             PIC S9(05) COMP-3 VALUE ZERO.  
       01  WS-HEADER-LINE. 
           05  FILLER                  PIC X(01) VALUE '1'. 
           05  FILLER                  PIC X(08) VALUE 'PAYAUD01'. 
           05  FILLER                  PIC X(30) VALUE SPACES. 
           05  FILLER                  PIC X(36) VALUE
				'DEPARTMENTAL PAYROLL ELIGIBILITY RPT'. 
           05  FILLER                  PIC X(45) VALUE SPACES. 
           05  FILLER                  PIC X(06) VALUE 'PAGE: '. 
           05  HL-PAGE-NO              PIC ZZZZ9. 
           05  FILLER                  PIC X(02) VALUE SPACES.  
       01  WS-DETAIL-LINE. 
           05  FILLER                  PIC X(01) VALUE ' '. 
           05  DL-EMP-ID               PIC X(06). 
           05  FILLER                  PIC X(03) VALUE SPACES. 
           05  DL-EMP-NAME             PIC X(25). 
           05  FILLER                  PIC X(03) VALUE SPACES. 
           05  DL-STATUS-DESC          PIC X(14). 
           05  FILLER                  PIC X(03) VALUE SPACES. 
           05  DL-DEPT-CODE            PIC 9(03). 
           05  FILLER                  PIC X(04) VALUE SPACES. 
           05  DL-GROSS-PAY            PIC $,$9.99. 
           05  FILLER                  PIC X(57) VALUE SPACES.  
       01  WS-TOTAL-LINE. 
           05  FILLER                  PIC X(01) VALUE '0'. 
           05  FILLER                  PIC X(22) VALUE
				'ACTIVE EMPLOYEES PAID:'. 
           05  TL-ACTIVE-CNT           PIC Z,ZZZ,ZZ9. 
           05  FILLER                  PIC X(08) VALUE SPACES. 
           05  FILLER                  PIC X(19) VALUE
				'TOTAL ACTIVE GROSS:'. 
           05  TL-PAY-TOTAL            PIC $$$$,$9.99. 
           05  FILLER                  PIC X(55) VALUE SPACES.  
       PROCEDURE DIVISION. 
       0000-MAIN-CONTROL. 
           PERFORM 1000-INITIALIZE. 
           PERFORM 2000-PROCESS-EMPLOYEES
				UNTIL END-OF-EMP-FILE. 
           PERFORM 3000-TERMINATE. 
           GOBACK.  
       1000-INITIALIZE. 
           OPEN INPUT  EMP-IN-FILE
				OUTPUT AUDIT-RPT-FILE. 
           IF NOT EMP-IO-OK
			  DISPLAY 'PAYAUD01: OPEN FAILED ON EMPIN = ' WS-EMP-STATUS
			  MOVE 16 TO RETURN-CODE
			  GOBACK 
           END-IF. 
           PERFORM 9100-READ-EMPLOYEE.  
       2000-PROCESS-EMPLOYEES. 
           PERFORM 2100-VALIDATE-RECORD. 
           IF RECORD-IS-VALID
			  IF EMP-ACTIVE
				  ADD 1 TO WS-ACTIVE-COUNT
				  ADD EI-GROSS-PAY TO WS-ACTIVE-PAY-TOTAL
				  PERFORM 2200-FORMAT-AND-PRINT
			  END-IF 
           ELSE
				ADD 1 TO WS-ERROR-COUNT 
           END-IF. 
           PERFORM 9100-READ-EMPLOYEE.  
       2100-VALIDATE-RECORD. 
           MOVE 'Y' TO WS-REC-VALID-SW. 
           IF NOT VALID-PAY-STATUS
			  DISPLAY 'PAYAUD01: BAD PAY STATUS FOR ID ' EI-EMP-ID
			  MOVE 'N' TO WS-REC-VALID-SW 
           END-IF. 
           IF NOT VALID-DEPT-CODE
				DISPLAY 'PAYAUD01: BAD DEPT CODE FOR ID ' EI-EMP-ID
				MOVE 'N' TO WS-REC-VALID-SW 
           END-IF. 
           IF EI-GROSS-PAY IS NOT NUMERIC
			  DISPLAY 'PAYAUD01: NON-NUMERIC PAY FOR ID ' EI-EMP-ID
			  MOVE 'N' TO WS-REC-VALID-SW 
           END-IF.  
       2200-FORMAT-AND-PRINT. 
           IF WS-LINE-CNT GREATER THAN WS-MAX-LINES
				PERFORM 8100-PRINT-HEADER 
           END-IF. 
           MOVE EI-EMP-ID   TO DL-EMP-ID. 
           MOVE EI-EMP-NAME TO DL-EMP-NAME. 
           MOVE EI-DEPT-CODE TO DL-DEPT-CODE. 
           MOVE EI-GROSS-PAY TO DL-GROSS-PAY. 
           IF EMP-SALARIED
				MOVE 'ACTIVE-SALARY ' TO DL-STATUS-DESC 
           ELSE
			  IF EMP-HOURLY
				  MOVE 'ACTIVE-HOURLY ' TO DL-STATUS-DESC
			  ELSE
				  MOVE 'PAID-LEAVE    ' TO DL-STATUS-DESC
			  END-IF 
           END-IF. 
           WRITE AUDIT-RPT-RECORD FROM WS-DETAIL-LINE. 
           ADD 1 TO WS-LINE-CNT.  
       3000-TERMINATE. 
           IF WS-LINE-CNT GREATER THAN WS-MAX-LINES
				PERFORM 8100-PRINT-HEADER 
           END-IF. 
           MOVE WS-ACTIVE-COUNT     TO TL-ACTIVE-CNT. 
           MOVE WS-ACTIVE-PAY-TOTAL TO TL-PAY-TOTAL. 
           WRITE AUDIT-RPT-RECORD FROM WS-TOTAL-LINE. 
           CLOSE EMP-IN-FILE
				 AUDIT-RPT-FILE. 
           IF WS-ERROR-COUNT GREATER THAN ZERO
				MOVE 4 TO RETURN-CODE 
           ELSE
				MOVE 0 TO RETURN-CODE 
           END-IF.  
       8100-PRINT-HEADER. 
           ADD 1 TO WS-PAGE-NUM. 
           MOVE WS-PAGE-NUM TO HL-PAGE-NO. 
           WRITE AUDIT-RPT-RECORD FROM WS-HEADER-LINE. 
           MOVE 3 TO WS-LINE-CNT.  
       9100-READ-EMPLOYEE. 
           READ EMP-IN-FILE
				AT END
				SET END-OF-EMP-FILE TO TRUE 
           END-READ. 
           IF NOT END-OF-EMP-FILE
				IF NOT EMP-IO-OK
				  DISPLAY 'PAYAUD01: READ ERROR = ' WS-EMP-STATUS
				  MOVE 16 TO RETURN-CODE
				  GOBACK
				END-IF
				ADD 1 TO WS-READ-COUNT 
           END-IF. 
/* 
//GO.SYSOUT  DD SYSOUT=* 
//GO.EMPIN   DD * 
E00101ALICE MORGAN             S12000450000 
E00102DAVID REES               H21000285050 
E00103SARAH JENKINS            T15000000000 
E00104GARETH THOMAS            X99900150000 
/* 
//GO.RPTOUT  DD DSN=HERC01.PAYROLL.AUDITRPT, 
//              DISP=(NEW,CATLG,DELETE), 
//              UNIT=SYSDA, 
//              SPACE=(TRK,(5,2),RLSE), 
//              DCB=(RECFM=FBA,LRECL=133,BLKSIZE=3990) 
// 
```

### 9.2 Compliant KICKS Pseudo-Conversational Online Template (EMPINQ01)

The following COBOL-68 KICKS program demonstrates compliant pseudo-conversational structure, DFHCOMMAREA state management, DFHAID key evaluation, symbolic BMS cursor positioning, and RESP() VSAM inquiry handling:

```COBOL

	   IDENTIFICATION DIVISION.        
	   PROGRAM-ID.    EMPINQ01.        
	   AUTHOR.        IAN STANLEY.        
	   DATE-WRITTEN.  NOVEMBER 2026.       
	  *==================================================================*       
	  * MODULE:  EMPINQ01 - KICKS PSEUDO-CONVERSATIONAL EMPLOYEE INQUIRY *       
	  * TRANSID: EINQ   MAPSET: EMPMAPS   MAP: EMPINQM                   *       
	  * PURPOSE: INQUIRES EMPLOYEE VSAM KSDS RECORD BY ID WITH FULL      *       
	  *          COMMAREA STATE MANAGEMENT AND INLINE RESP HANDLING.     *       
	  *==================================================================*         
	   ENVIRONMENT DIVISION.        
	   CONFIGURATION SECTION.        
	   SOURCE-COMPUTER. IBM-370.        
	   OBJECT-COMPUTER. IBM-370.        
	   DATA DIVISION.        
	   WORKING-STORAGE SECTION.        
	   01  WS-COMMAREA.            
			05  CA-PROCESS-STAGE        PIC X(01) VALUE '1'.                
				88  CA-STAGE-FIRST-ENTRY          VALUE '1'.               
				88  CA-STAGE-AWAIT-KEY            VALUE '2'.            
			05  CA-LAST-EMP-ID          PIC X(06) VALUE SPACES.         
	   01  WS-COMMAREA-LENGTH          PIC S9(04) COMP SYNC VALUE +7.         
	   01  WS-KICKS-RESPONSE-FIELDS.            
			05  WS-RESP-CODE            PIC S9(08) COMP SYNC VALUE ZERO.            
			05  WS-VSAM-REC-LEN         PIC S9(04) COMP SYNC VALUE +80.         
	   01  WS-CONTROL-FLAGS.            
			05  WS-INPUT-VALID-SW       PIC X(01) VALUE 'Y'.                
				88  INPUT-IS-VALID                VALUE 'Y'.               
				88  INPUT-HAS-ERRORS              VALUE 'N'.         
	   01  EMP-VSAM-RECORD.            
	   COPY EMPREC.         
	   COPY EMPMAPS.        
	   COPY DFHAID.        
	   COPY DFHBMSCA.         
	   LINKAGE SECTION.        
	   01  DFHCOMMAREA                 PIC X(07).         
	   PROCEDURE DIVISION.        
	   0000-MAIN-CONTROL.            
			IF EIBCALEN = 0                
				PERFORM 1000-FIRST-TIME-INIT            
			ELSE                
				PERFORM 1100-RESTORE-COMMAREA                
				PERFORM 2000-PROCESS-USER-ACTION            
			END-IF.            
			PERFORM 3000-PSEUDO-RETURN.         
		1000-FIRST-TIME-INIT.            
			MOVE LOW-VALUES TO EMPINQMO.            
			MOVE '1'        TO CA-PROCESS-STAGE.            
			MOVE SPACES     TO CA-LAST-EMP-ID.            
			MOVE 'ENTER EMPLOYEE ID AND PRESS ENTER (PF3=EXIT)'  
				TO MSGOUT.            
			MOVE -1         TO EMPIDL.            
			PERFORM 8100-SEND-FULL-MAP.        
		1100-RESTORE-COMMAREA.            
			IF EIBCALEN = WS-COMMAREA-LENGTH                
				MOVE DFHCOMMAREA TO WS-COMMAREA            
			ELSE                
				MOVE '1'    TO CA-PROCESS-STAGE                
				MOVE SPACES TO CA-LAST-EMP-ID            
			END-IF.         
		2000-PROCESS-USER-ACTION.            
			IF EIBAID = DFHPF3                
				PERFORM 3900-EXIT-APPLICATION            
			ELSE                
				IF EIBAID = DFHCLEAR                    
					PERFORM 1000-FIRST-TIME-INIT                
				ELSE                    
					IF EIBAID = DFHENTER                        
						PERFORM 2100-PROCESS-INQUIRY                    
					ELSE                        
						MOVE LOW-VALUES TO EMPINQMO                        
						MOVE 'INVALID KEY PRESSED - USE ENTER OR PF3'     
							TO MSGOUT                        
						MOVE -1 TO EMPIDL                        
						PERFORM 8200-SEND-DATA-ONLY                   
					END-IF                
				END-IF            
			END-IF.         
		2100-PROCESS-INQUIRY.            
			PERFORM 9100-RECEIVE-MAP.            
			MOVE 'Y' TO WS-INPUT-VALID-SW.            
			IF EMPIDL = 0 OR EMPIDI = SPACES OR EMPIDI = LOW-VALUES                
				MOVE 'N' TO WS-INPUT-VALID-SW                
				MOVE LOW-VALUES TO EMPINQMO                
				MOVE 'EMPLOYEE ID IS REQUIRED' TO MSGOUT                
				MOVE -1 TO EMPIDL                
				PERFORM 8200-SEND-DATA-ONLY            
			END-IF.            
			IF INPUT-IS-VALID  
				PERFORM 9200-READ-EMP-VSAM            
			END-IF.         
		3000-PSEUDO-RETURN.            
			MOVE '2' TO CA-PROCESS-STAGE.            
			EXEC CICS RETURN  
				TRANSID('EINQ')                
				COMMAREA(WS-COMMAREA)                
				LENGTH(WS-COMMAREA-LENGTH)            
			END-EXEC.         
		3900-EXIT-APPLICATION.            
			EXEC CICS SEND TEXT                
				FROM('EMPINQ01 SESSION ENDED.')                
				LENGTH(23)                
				ERASE                
				FREEKB            
			END-EXEC.            
			EXEC CICS RETURN 
			END-EXEC.         
		8100-SEND-FULL-MAP.            
			EXEC CICS SEND                
				MAP('EMPINQM')                
				MAPSET('EMPMAPS')                
				FROM(EMPINQMO)                
				ERASE                
				CURSOR                
				FREEKB                
				RESP(WS-RESP-CODE)            
			END-EXEC.         
		8200-SEND-DATA-ONLY.            
			EXEC CICS SEND                
				MAP('EMPINQM')                
				MAPSET('EMPMAPS')                
				FROM(EMPINQMO)                
				DATAONLY                
				CURSOR                
				FREEKB                
				RESP(WS-RESP-CODE)            
			END-EXEC.         
		9100-RECEIVE-MAP.            
			MOVE LOW-VALUES TO EMPINQMI.            
			EXEC CICS RECEIVE                
				MAP('EMPINQM')                
				MAPSET('EMPMAPS')                
				INTO(EMPINQMI)                
				RESP(WS-RESP-CODE)            
			END-EXEC.         
		9200-READ-EMP-VSAM.            
			MOVE EMPIDI TO EI-EMP-ID.            
			MOVE 80     TO WS-VSAM-REC-LEN.            
			EXEC CICS READ                
				DATASET('EMPFILE')                
				INTO(EMP-VSAM-RECORD)                
				LENGTH(WS-VSAM-REC-LEN)                
				RIDFLD(EI-EMP-ID)                
				RESP(WS-RESP-CODE)            
			END-EXEC.            
			MOVE LOW-VALUES TO EMPINQMO.            
			IF WS-RESP-CODE = DFHRESP(NORMAL)                
				MOVE EI-EMP-ID      TO EMPIDO                
				MOVE EI-EMP-NAME    TO EMPNAMO                
				MOVE EI-PAY-STATUS  TO STATO                
				MOVE EI-DEPT-CODE   TO DEPTO                
				MOVE EI-GROSS-PAY   TO PAYO                
				MOVE EI-EMP-ID      TO CA-LAST-EMP-ID                
				MOVE 'RECORD RETRIEVED SUCCESSFULLY' TO MSGOUT            
			ELSE                
				IF WS-RESP-CODE = DFHRESP(NOTFND)                    
					MOVE EMPIDI TO EMPIDO                    
					MOVE 'EMPLOYEE RECORD NOT FOUND' TO MSGOUT                
				ELSE                    
					MOVE 'VSAM I/O ERROR ON EMPFILE' TO MSGOUT                
				END-IF            
			END-IF.            
			MOVE -1 TO EMPIDL.            
			PERFORM 8200-SEND-DATA-ONLY. 
```			

## 10. KICKS Build, Deployment & Resource Configuration Suite

To deploy EMPINQ01 (Section 9.2) into the TK5 KICKS environment, execute the following standardized build and table registration artifacts in sequence.

### 10.1 Shared Record Copybook (EMPREC)

Store this member in HERC01.KICKS.COPYLIB(EMPREC) so both batch utilities and KICKS online programs share the exact 80-byte VSAM record layout:

```COBOL

  *================================================================*  
  * COPYBOOK: EMPREC - EMPLOYEE MASTER VSAM KSDS RECORD (80 BYTES) *  
  *================================================================*  
	   05  EI-EMP-ID               PIC X(06).  
	   05  EI-EMP-NAME             PIC X(25).  
	   05  EI-PAY-STATUS           PIC X(01).  
		   88  EMP-SALARIED                  VALUE 'S'.  
		   88  EMP-HOURLY                    VALUE 'H'.  
		   88  EMP-PAID-LEAVE                VALUE 'L'.  
		   88  EMP-TERMINATED                VALUE 'T'.  
		   88  EMP-ACTIVE                    VALUE 'S' 'H' 'L'.  
		   88  VALID-PAY-STATUS              VALUE 'S' 'H' 'L' 'T'.  
	   05  EI-DEPT-CODE            PIC 9(03).  
		   88  DEPT-ENGINEERING              VALUE 100 THRU 199.  
		   88  DEPT-OPERATIONS               VALUE 200 THRU 299.  
		   88  DEPT-FINANCE                  VALUE 300 THRU 350.  
		   88  VALID-DEPT-CODE               VALUE 100 THRU 350.  
	   05  EI-GROSS-PAY            PIC 9(07)V99.  
	   05  FILLER                  PIC X(36).
```

### 10.2 BMS Mapset Source (EMPMAPS)

Store this member in HERC01.KICKS.BMS(EMPMAPS). It implements the departmental 24×80 Model 2 screen layout, including CTRL=(FREEKB,FRSET), IC initial cursor positioning, and mandatory 1-byte ASKIP stopper fields immediately following every UNPROT input field:

```Code snippet
EMPMAPS  DFHMSD TYPE=&SYSPARM,MODE=INOUT,LANG=COBOL,TIOAPFX=YES,       X
				CTRL=(FREEKB,FRSET),STORAGE=AUTO
EMPINQM  DFHMDI SIZE=(24,80),LINE=1,COLUMN=1 
*---------------------------------------------------------------------*
* ROW 1: SYSTEM HEADER BANNER                                         *
*---------------------------------------------------------------------*
		DFHMDF POS=(1,2),LENGTH=4,ATTRB=(ASKIP,NORM),INITIAL='EINQ' 
		DFHMDF POS=(1,22),LENGTH=35,ATTRB=(ASKIP,BRT),                X
			INITIAL='DEPARTMENTAL EMPLOYEE INQUIRY SYSTEM'
*---------------------------------------------------------------------* 
* ROW 2: SUB-HEADER / MODE INDICATOR                                  *
*---------------------------------------------------------------------*
		DFHMDF POS=(2,32),LENGTH=14,ATTRB=(ASKIP,NORM),               X
			INITIAL='MODE: INQUIRY' 
*---------------------------------------------------------------------*
* ROW 5: KEY INPUT FIELD (WITH STOPPER BYTE AT COL 28)               *
*---------------------------------------------------------------------*
		DFHMDF POS=(5,5),LENGTH=14,ATTRB=(ASKIP,NORM),                X
			INITIAL='EMPLOYEE ID  :' 
EMPID   DFHMDF POS=(5,21),LENGTH=6,ATTRB=(UNPROT,BRT,IC) 
		DFHMDF POS=(5,28),LENGTH=1,ATTRB=ASKIP
*---------------------------------------------------------------------*
* ROWS 8-14: PROTECTED DISPLAY FIELDS                                 *
*---------------------------------------------------------------------*
		DFHMDF POS=(8,5),LENGTH=14,ATTRB=(ASKIP,NORM),                X
			INITIAL='EMPLOYEE NAME:' 
EMPNAM  DFHMDF POS=(8,21),LENGTH=25,ATTRB=(ASKIP,BRT) 
		DFHMDF POS=(10,5),LENGTH=14,ATTRB=(ASKIP,NORM),               X
			INITIAL='PAY STATUS   :' 
STAT    DFHMDF POS=(10,21),LENGTH=1,ATTRB=(ASKIP,BRT)
		DFHMDF POS=(10,24),LENGTH=24,ATTRB=(ASKIP,NORM),              X
			INITIAL='(S=SAL H=HRLY L=LV T=TRM)' 
		DFHMDF POS=(12,5),LENGTH=14,ATTRB=(ASKIP,NORM),               X
			INITIAL='DEPARTMENT   :' 
DEPT    DFHMDF POS=(12,21),LENGTH=3,ATTRB=(ASKIP,BRT) 
		DFHMDF POS=(14,5),LENGTH=14,ATTRB=(ASKIP,NORM),               X
			INITIAL='GROSS PAY    :' 
			PAY      DFHMDF POS=(14,21),LENGTH=14,ATTRB=(ASKIP,BRT),               X
			PICOUT='$,$9.99' 
*---------------------------------------------------------------------*
* ROW 22: OPERATOR MESSAGE LINE                                       *
*---------------------------------------------------------------------*
MSG     DFHMDF POS=(22,2),LENGTH=78,ATTRB=(ASKIP,BRT)
*---------------------------------------------------------------------*
* ROW 24: FUNCTION KEY LEGEND                                         *
*---------------------------------------------------------------------*
		DFHMDF POS=(24,2),LENGTH=46,ATTRB=(ASKIP,NORM),               X
			INITIAL='ENTER=Inquire   CLEAR=Reset   PF3=Exit Session'
		DFHMSD TYPE=FINAL
		END 
```

### 10.3 VSAM KSDS Cluster Creation & Seed Load JCL (IDCAMS)

Before starting KICKS, allocate and populate HERC01.KICKS.EMPFILE (80-byte fixed records, 6-byte primary key at offset 0). The initial zero-key seed record guarantees MVS 3.8j VSAM never encounters an empty cluster on open:

```JCL
//HERC01V  JOB (KICKS1),'IAN STANLEY', 
//             CLASS=A, 
//             MSGCLASS=X, 
//             MSGLEVEL=(1,1), 
//             REGION=4096K, 
//             NOTIFY=HERC01 
//*-------------------------------------------------------------------* 
//* DEFINE AND SEED VSAM KSDS CLUSTER FOR EMPFILE                     *
//*-------------------------------------------------------------------* 
//DEFVSAM  EXEC PGM=IDCAMS 
//SYSPRINT DD SYSOUT=* 
//SYSIN    DD *   
  DELETE HERC01.KICKS.EMPFILE CLUSTER PURGE   
  SET MAXCC = 0   
  DEFINE CLUSTER (                               	   -
				NAME(HERC01.KICKS.EMPFILE)             -            
				VOLUMES(PUB001)                        -            
				TRACKS(5 2)                            -            
				RECORDSIZE(80 80)                      -            
				KEYS(6 0)                              -            
				INDEXED                                -            
				SHAREOPTIONS(2 3)                      -          
				)                                      -          
				DATA (                                	   -            
					NAME(HERC01.KICKS.EMPFILE.DATA)        -          
					)                                        -          
					INDEX (                                  -            
						NAME(HERC01.KICKS.EMPFILE.INDEX)       -          
						)   
						REPRO INFILE(SEEDDATA) OUTDATASET(HERC01.KICKS.EMPFILE) 
/* 
//SEEDDATA DD * 
000000SEED RECORD - DO NOT DELETE T00000000000 
E00101ALICE MORGAN             S12000450000 
E00102DAVID REES               H21000285050 
E00103SARAH JENKINS            T15000000000 
E00104GARETH THOMAS            L31000320000 
/* 
// 
```

### 10.4 BMS Mapset Assembly & COBOL Compile JCL

#### Step A: Assemble Physical & Symbolic Map (KIKMAPS)

Generates the COBOL symbolic copybook in HERC01.KICKS.COPYLIB(EMPMAPS) (SYSPARM=DSECT) and link-edits the physical mapset into HERC01.KICKS.LOADLIB(EMPMAPS) (SYSPARM=MAP):

```JCL

//HERC01M  JOB (KICKS1),'IAN STANLEY', 
//             CLASS=A, 
//             MSGCLASS=X, 
//             MSGLEVEL=(1,1), 
//             REGION=4096K
//             NOTIFY=HERC01 
//         JCLLIB ORDER=(KICKS.V1R5M0.PROCLIB) 
//*-------------------------------------------------------------------* 
//* GENERATE SYMBOLIC COPYBOOK AND PHYSICAL BMS MAPSET (EMPMAPS)      *
//*-------------------------------------------------------------------*
//MAPGEN   EXEC KIKMAPS, 
//         MAPNAME=EMPMAPS,
//         MAPSRC='HERC01.KICKS.BMS', 
//         COPYLIB='HERC01.KICKS.COPYLIB', 
//         LOADLIB='HERC01.KICKS.LOADLIB' 
// 
```

#### Step B: Pre-Translate, Compile, and Link EMPINQ01 (KIKCB2CL)

Runs the KICKS COBOL pre-translator (KIKPPCOB), compiles with IKFCBL00 using departmental diagnostic flags (DMAP, CLIST, SXREF), and link-edits EMPINQ01 into HERC01.KICKS.LOADLIB:

```JCL
//HERC01K  JOB (KICKS1),'IAN STANLEY',
//             CLASS=A, 
//             MSGCLASS=X, 
//             MSGLEVEL=(1,1), 
//             REGION=4096K, 
//             NOTIFY=HERC01 
//         JCLLIB ORDER=(KICKS.V1R5M0.PROCLIB) 
//*-------------------------------------------------------------------* 
//* PRE-TRANSLATE, COMPILE, AND LINK KICKS COBOL MODULE EMPINQ01      * 
//*-------------------------------------------------------------------* 
//COMPCOB  EXEC KIKCB2CL, 
//         PARM.COB='LOAD,NODECK,LIST,DMAP,CLIST,SXREF,FLAGW,SIZE=2048K,BUF=1024K', 
//         PARM.LKED='LIST,XREF,LET,MAP' 
//TRN.SYSIN  DD DSN=HERC01.KICKS.COBOL(EMPINQ01),DISP=SHR 
//COB.SYSLIB DD DSN=HERC01.KICKS.COPYLIB,DISP=SHR 
//           DD DSN=KICKS.V1R5M0.COBCOPY,DISP=SHR 
//LKED.SYSLMOD DD DSN=HERC01.KICKS.LOADLIB(EMPINQ01),DISP=SHR 
// 
```

### 10.5 KICKS Resource Table Entries (KIKPPT, KIKPCT, KIKFCT) & Startup Allocation

Register the program, mapset, transaction ID, and VSAM dataset in the KICKS resource tables (KICKS.V1R5M0.INSTLIB or HERC01.KICKS.TABLES) and reassemble:

```
*---------------------------------------------------------------------*
* 1. PROCESSING PROGRAM TABLE (KIKPPT)                                * 
*---------------------------------------------------------------------* 
	KIKPPT TYPE=ENTRY,PROGRAM=EMPINQ01,PGMLANG=COBOL
	KIKPPT TYPE=ENTRY,MAPSET=EMPMAPS,USAGE=MAP
*---------------------------------------------------------------------*
* 2. PROGRAM CONTROL TABLE (KIKPCT)                                   *
*---------------------------------------------------------------------*
	KIKPCT TYPE=ENTRY,TRANSID=EINQ,PROGRAM=EMPINQ01
*---------------------------------------------------------------------*
* 3. FILE CONTROL TABLE (KIKFCT)                                      *
*---------------------------------------------------------------------*
	KIKFCT TYPE=ENTRY,DATASET=EMPFILE,ACCMETH=VSAM,               X
		SERVREQ=(READ,BROWSE),STRNO=2 
```

Ensure the KICKS startup CLIST concatenates HERC01.KICKS.LOADLIB into SKIKLOAD and allocates EMPFILE:

```
	ALLOC FI(EMPFILE) DA('HERC01.KICKS.EMPFILE') SHR 
```

## 11. Production Readiness Checklist & Abend Triage Protocol

### 11.1 Pre-Promotion Sign-Off Checklist

Before promoting any batch or KICKS online load module, BMS mapset, or JCL procedure to PROD.* libraries, the developer and peer reviewer must verify:

* Compiler & Translator Cleanliness: Zero E (Error) or D (Disaster) messages from KIKPPCOB (if online) and IKFCBL00; all W (Warning) messages reviewed and documented.

* Storage Hygiene: All WORKING-STORAGE counters, accumulators, and switches carry explicit VALUE clauses; all financial math uses COMP-3; binary length fields use PIC S9(4) COMP SYNC.

* Dataset Decoupling: Every batch sequential FD includes BLOCK CONTAINS 0 RECORDS; all batch DD statements specify RLSE and optimal 3350 BLKSIZE values.

* Restartability (Batch): Output datasets are preceded by IEFBR14 DISP=(MOD,DELETE,DELETE) cleanup steps, and COND= parameters enforce safe step skipping on RC >= 8.

* Online Architecture (KICKS): Transactions are strictly pseudo-conversational (EXEC CICS RETURN TRANSID(...) COMMAREA(...)), use RESP() instead of HANDLE CONDITION, include stopper bytes on all BMS input fields, and have verified PPT, PCT, and FCT entries.

* Self-Documenting Logic: All status checks, ranges, and EOF flags use 88-level condition names rather than hardcoded literals.



### 11.2 Rapid Abend Resolution Guide (Batch & KICKS)

| Completion / Abend Code | Subsystem | Primary Cause | Immediate Diagnostic Action |
| :---- | :---- | :---- | :---- |
| S0C7 | Batch MVS | Invalid packed/zoned decimal data in arithmetic or numeric IF | Subtract entry point from PSW Next Instruction Address, locate verb in CLIST, and check DMAP offset for uninitialized COMP-3 or bad input |
| ASRA | KICKS OLTP | Hardware program check inside online transaction (most commonly S0C7 or S0C4) | Locate the failing instruction offset in EIB / KICKS trace against the IKFCBL00 CLIST listing and inspect WORKING-STORAGE / COMMAREA initialization |
| AEIx / AEYx | KICKS OLTP | Unhandled EXEC CICS exceptional condition (e.g., AEI0 = PGMIDERR, AEI9 = MAPFAIL, AEIN = DUPREC) | Verify PPT/PCT/FCT table entries, add RESP(WS-RESP-CODE) to the failing command, and check for empty map input (MAPFAIL on CLEAR/unmodified screen) |
| S0C4 | Batch / KICKS | Out-of-bounds table subscript, mismatched CALL/COMMAREA length, or FD reference after AT END | Verify all subscript bounds (1 to OCCURS max) and confirm 01-level LINKAGE / COMMAREA copybooks match between caller and callee |
| S013-xx | Batch MVS | DCB attribute conflict or missing PDS member (-18: member missing; -20: BLKSIZE not multiple of LRECL) | Inspect JES2 IEC141I message in RFE Option 3.8 and align JCL DCB with COBOL FD |
| S80A / S878 | Batch MVS | Virtual storage exhausted in 24-bit private region | Increase REGION=4096K on the JOB card and set SIZE=2048K,BUF=1024K in PARM.COB |
| SB37 / SD37 | Batch MVS | Output dataset out of primary/secondary extents on DASD | Increase primary/secondary SPACE=(CYL,(10,5),RLSE) or compress target PDS with IEBCOPY |


# Appendix: COBOL Commenting and Program Prologue Standards

## A.1 Purpose and Scope

This appendix defines the mandatory documentation, commenting, and header formatting standards for all COBOL source modules and copybooks developed or maintained under the Application Development Standards Manual.

In enterprise COBOL environments, source code must be self-sustaining for rapid production support, auditability, and long-term maintenance. Comments shall document business intent, operational interfaces, and architectural design—never the literal mechanics of self-evident COBOL syntax.

These standards apply to all batch and online COBOL modules, including legacy fixed-format compilers (e.g., OS/VS COBOL IKFCBL00) as well as modern COBOL-85/2002/2014 compilers (e.g., IBM Enterprise COBOL, GnuCOBOL).

## A.2 Syntax and Formatting Rules 

### Column 7 Indicator Discipline:

* All standard comment lines must place an asterisk (*) strictly in Column 7.

* Page-eject directives (/ in Column 7) may be used sparingly immediately prior to DIVISION headers or major PROCEDURE DIVISION sections to improve readability on printed or spooled compiler listings.

* The obsolete REMARKS paragraph in the IDENTIFICATION DIVISION is prohibited; use standard Column 7 comment blocks instead to guarantee cross-compiler portability.

* Column 72 Boundary Enforcement:

* All comment text must terminate at or before Column 72. Columns 73–80 are reserved for sequence numbers or change tags and are ignored by fixed-format compilers; text extending past Column 72 will be silently truncated on compiler listings.

* Open-Ended Borders (No Right-Hand Boxes):

  * Use horizontal divider lines (*=============================================== or *----------------------------------------------------------------------) extending from Column 7 to Column 72.

  * Do not place closing asterisks in Column 72 to form closed ASCII boxes. Right-hand borders create unnecessary maintenance overhead and alignment defects during routine edits.

* Indentation and Visual Breathing Room:

  * Align inline comment text cleanly with the Area B indentation level of the code block it describes (typically Column 12 or deeper), rather than jamming text against Column 8.

  * Use blank comment lines (* in Column 7 followed by spaces) before paragraph headers and complex conditional blocks (EVALUATE or nested IF statements) to separate logical units.

## A.3 The Program Prologue (Identification Header)

Every production COBOL program must begin with a standardized Program Prologue placed immediately after the PROGRAM-ID statement. This block serves as the primary operational reference for production support analysts and maintenance programmers.

Mandatory Prologue Sections

| Section | Required Content |
| :---- | :---- |
| 1. Identification & Ownership | Exact PROGRAM-ID, plain-English functional title, parent subsystem/application name, execution environment (BATCH, CICS/KICKS, TSO), target compiler, original author, and creation date. |
| 2. Purpose | A concise narrative explaining what business problem the module solves, summarizing primary inputs, core business transformations, and outputs. |
| 3. Method of Operation | A high-level architectural walkthrough of how the program completes its task (e.g., sequential master-transaction file matching, control-break reporting, table lookup strategy), mapped to major PROCEDURE DIVISION driver paragraphs. |
| 4. Usage / JCL Interface | A complete tabular matrix of every external dataset (DDNAME), file organization (QSAM, VSAM KSDS/ESDS/RRDS, SYSOUT), record format and length (RECFM/LRECL), I/O direction (INPUT, OUTPUT, I-O), and functional description. |
| 5. Dependencies | Explicit list of all included COPY members (with source library names), static or dynamic CALL subprograms, and SYSIN control-card layouts. |
| 6. Return Codes & Abends | Complete specification of all RETURN-CODE values (00, 04, 08, 12, 16), user abend codes, and batch restart/checkpoint procedures. |
| 7. Modification History | A chronological audit ledger tracking all post-baseline changes by Version, Date, Change/Ticket ID, Author Initials, and a concise summary of the functional impact. |

## A.4 In-Code Documentation Standards

### A.4.1 DATA DIVISION Documentation

* Flag & State Semantics: Document the business meaning and lifecycle of control switches, status variables, and accumulators—especially where 88-level condition names alone do not convey initialization or reset rules.

* Numeric Scaling & Storage: Clarify implied decimal assumptions, COMP-3 (packed-decimal) or COMP (binary) usage rationales, and REDEFINES memory overlays.

* LINKAGE SECTION Contracts: For called subprograms, clearly label every parameter as [IN], [OUT], or [IN/OUT], documenting expected byte lengths, null/space defaults, and validation expectations.

### A.4.2 PROCEDURE DIVISION Documentation

* Section & Paragraph Headers: Precede every major section and functional paragraph with a horizontal separator (*-------------------------------------------------------------) and a 1–3 line summary stating entry conditions, core processing responsibility, and exit state.

* Business Rules & Domain Logic: Comment the why behind non-obvious rules, regulatory formulas, hardcoded thresholds ("magic numbers"), and edge-case bypasses.

* Technical Constraints & Prerequisites: Explicitly document performance-critical or fragile assumptions—such as sort-order prerequisites before SEARCH ALL (binary search) or sequential file-matching routines.


### A.5 Prohibited Practices (Anti-Patterns)

* Restating COBOL Syntax: Never write comments that merely translate COBOL verbs into prose.  
  
  Non-Compliant comment:

``` 	
	* ADD 1 TO WS-REC-COUNT
```

`
	Compliant comment:	    

``` 	
	* INCREMENT BILLABLE TRANSACTION COUNTER FOR END-OF-DAY GL BALANCING
```

* Retaining Commented-Out Dead Code: Large blocks of inactive code prefixed with * in Column 7 obscure program flow, pollute cross-reference searches, and cause maintenance confusion. Obsolete logic must be deleted once verified; historical versions belong in Source Code Management (SCM), not in active source members.

* Inline Pseudocode Narratives: Do not mirror every IF/ELSE or PERFORM statement in comments. If a paragraph requires line-by-line English translation to be understood, refactor the paragraph into smaller, well-named sub-paragraphs.

* Unmaintained Modification Logs: Any production change committed without a corresponding entry in the Program Prologue's Modification History table and matching inline change markers (--- CHG-XXXX ---) shall fail peer code review.

## A.6 Standard Skeleton Template

Developers should copy the following compliant skeleton when creating new batch COBOL modules:

```
IDENTIFICATION DIVISION.  
PROGRAM-ID. PROGNAME.  
*=================================================================  
* PROGRAM ID : PROGNAME  
* TITLE : FUNCTIONAL PROGRAM TITLE  
* SUBSYSTEM : APPLICATION / SUBSYSTEM NAME  
* ENVIRONMENT : BATCH / KICKS / TSO (OS/VS COBOL IKFCBL00)  
* AUTHOR : DEVELOPER NAME  
* CREATED : YYYY-MM-DD  
*=================================================================  
* PURPOSE:  
* CONCISE DESCRIPTION OF THE BUSINESS PURPOSE, INPUTS, AND  
* OUTPUTS PRODUCED BY THIS MODULE.  
*  
* METHOD OF OPERATION:  
* 1. INITIALIZATION (1000-INIT): DESCRIBE SETUP AND FILE OPENS.  
* 2. MAIN PROCESSING (2000-MAIN): DESCRIBE CORE ALGORITHM.  
* 3. TERMINATION (3000-WRAPUP): DESCRIBE TOTALS AND FILE CLOSES.  
*  
* USAGE / JCL INTERFACE:  
* DDNAME ORG RECFM/LRECL I/O DESCRIPTION  
* --------- -------- ----------- ------ --------------------  
* INFILE QSAM FB / 80 INPUT PRIMARY INPUT FILE  
* OUTFILE QSAM FB / 133 OUTPUT PRIMARY OUTPUT FILE  
* SYSOUT SYSOUT FBA / 133 OUTPUT RUN AUDIT LOG  
*  
* COPYBOOKS & EXTERNAL CALLS:  
* - COPYMBR (IN APP.COPYLIB) : RECORD LAYOUT DESCRIPTION  
* - SUBPROG (DYNAMIC/STATIC) : CALLED SUBPROGRAM PURPOSE  
*  
* RETURN CODES:  
* 00 - NORMAL COMPLETION  
* 04 - COMPLETED WITH WARNINGS  
* 08 - NO RECORDS PROCESSED / EMPTY INPUT  
* 16 - SEVERE I/O OR VALIDATION ERROR (SEE SYSOUT)  
*=================================================================  
* MODIFICATION HISTORY:  
* VER DATE CHANGE-ID AUTHOR DESCRIPTION  
* ---- ---------- --------- ------ ---------------------------  
* 1.0 YYYY-MM-DD INIT-001 XX INITIAL PRODUCTION BASELINE  
*=================================================================

ENVIRONMENT DIVISION.

DATA DIVISION.  
WORKING-STORAGE SECTION.

PROCEDURE DIVISION.  
*-----------------------------------------------------------------  
* 0000-MAINLINE:  
* TOP-LEVEL DRIVER CONTROLLING INITIALIZATION, MAIN PROCESSING  
* LOOP, AND FINAL TERMINATION.  
*-----------------------------------------------------------------  
	   0000-MAINLINE.  
			PERFORM 1000-INITIALIZE.  
			PERFORM 2000-PROCESS-DATA UNTIL WS-EOF.  
			PERFORM 3000-TERMINATE.  
			STOP RUN.
```

## Alphabetical Technical & Keyword Index

24-bit Addressing Ceiling: 1, 3.3, 8.1, 11.2

3350 DASD Geometry & Blocking: 3.2, 11.1

66-level (RENAMES) Prohibition: 4.2

77-level Prohibition: 2.2, 4.2

88-level Condition Names: 2.2, 4.4, 6.3, 8.2, 9.1, 10.1, 11.1

Abend Resolution & Triage: 11.2

AEI0 / AEI9 / AEIN (KICKS Abends): 11.2

ALTER Statement Prohibition: 5.2

Area A & Area B Column Margins: 2.2, 4.1

ASRA (KICKS Program Check Abend): 1, 3.4, 4.1, 4.3, 11.2

BLKSIZE Optimization: 3.2, 4.2, 11.1, 11.2

BLOCK CONTAINS 0 RECORDS: 1, 4.2, 9.1, 11.1

BMS (Basic Mapping Support): 8.3, 9.2, 10.2, 10.4

CALL (Static & Dynamic Subprograms): 4.3, 5.2, 7

Cataloged Procedures (COBUC, COBUCL, COBUCG, COBUCLG): 1.1, 3.4, 9.1

CLIST (Compiler Condensed Listing): 3.4, 4.3, 9.1, 10.4, 11.2

COBOL-68 Standard (ANSI X3.23-1968): 2.1, 2.2, 4.4, 5.1, 8.4

COMP (Binary) & SYNC: 4.3, 8.2, 9.1, 9.2, 11.1

COMP-3 (Packed Decimal): 4.3, 9.1, 11.1, 11.2

COND= Parameter (Inverse Logic): 1, 3.5, 5.2, 11.1

Condition Names (88-Levels): 2.2, 4.4, 6.3, 8.2, 9.1, 10.1, 11.1

Conversational vs. Pseudo-Conversational Design: 1, 8.1, 9.2, 11.1

COPY Statements & Copybook Architecture: 4.1, 7, 8.2, 9.2, 10.1

Cursor Positioning (Symbolic -1 Length & IC): 8.3, 9.2, 10.2

Dataset Naming Conventions (HLQ & Qualifiers): 1.1, 3.1

DCB (Data Control Block) Attributes: 3.2, 9.1, 11.2

DFHAID Copybook: 8.1, 9.2

DFHCOMMAREA State Management: 4.1, 8.1, 8.2, 8.4, 9.2, 11.1

DFHMSD / DFHMDI / DFHMDF Macros: 8.3, 10.2

DISP=(MOD,DELETE,DELETE) Restartability: 3.5, 9.1, 11.1

DISPLAY (Zoned Decimal) Usage: 4.3

DMAP (Compiler Data Map): 3.4, 9.1, 10.4, 11.2

EIBAID (Attention Identifier): 4.4, 8.1, 9.2

EIBCALEN (COMMAREA Length Check): 5.1, 8.1, 8.2, 9.2

EMPINQ01 (KICKS Reference Program): 9.2, 10, 10.4, 10.5

EMPMAPS (BMS Reference Mapset): 9.2, 10.2, 10.4, 10.5

EMPREC (Shared VSAM Copybook): 4.1, 9.2, 10.1

EVALUATE Prohibition: 2.2

EXEC CICS LINK & XCTL: 7

EXEC CICS RECEIVE MAP & SEND MAP: 8.1, 8.3, 8.4, 9.2

EXEC CICS RETURN: 5.1, 5.2, 8.1, 8.2, 9.2, 11.1

FCT (KIKFCT File Control Table): 8.4, 10.5, 11.1, 11.2

FILE STATUS Checking: 4.4, 6.1, 6.3, 9.1

FLAGW Compiler Option: 3.4, 9.1, 10.4

FRSET / FSET (Modified Data Tags): 8.3, 10.2

GOBACK vs. STOP RUN: 5.1, 5.2, 7, 9.1

GO TO Restrictions: 2.2, 5.2, 8.4

HANDLE CONDITION Prohibition: 8.4, 11.1

IDCAMS (DEFINE CLUSTER & REPRO): 6.3, 10.3

IEBCOPY: 3.1, 11.2

IEFBR14 Cleanup Step: 3.5, 9.1, 11.1

IKFCBL00 (IBM OS/VS COBOL Compiler): 1.1, 2.1, 2.2, 3.3, 4.3, 8.4, 10.4, 11.1, 11.2

Initialization of WORKING-STORAGE: 1, 4.3, 11.1, 11.2

Jay Moseley SYSGEN Comparison: 1.1

JES2 Spool & MSGCLASS=X: 1.1, 3.3, 9.1, 10.3

JOB Card Parameters: 3.3, 9.1

/*JOBPARM Control Statement: 3.3, 9.1

KICKS OLTP Architecture: 1.1, 2.1, 8, 9.2, 10

KIKCB2CL (KICKS COBOL Compile Proc): 1.1, 2.1, 8.4, 10.4

KIKMAPS (BMS Map Generation Proc): 1.1, 8.3, 10.4

KIKPPCOB (KICKS Pre-Translator): 2.1, 8.4, 10.4, 11.1

Level Number Hierarchy (01–49, 88): 4.2, 4.4

LINKAGE SECTION: 4.1, 7, 8.2, 8.4, 9.2, 11.2

MSGLEVEL=(1,1): 3.3, 9.1, 10.3

NOTIFY= Parameter: 3.3, 9.1, 10.3

Paragraph Numbering Hierarchy (0000–9999): 5.1, 6.1, 9.1, 9.2

PARM.COB & PARM.LKED Overrides: 3.4, 9.1, 10.4, 11.2

PAYAUD01 (Batch Reference Program): 9.1

PCT (KIKPCT Program Control Table): 8.4, 10.5, 11.1, 11.2

Period Discipline (COBOL-68): 2.2

PERFORM Rules (Out-of-Line): 2.2, 5.1, 5.2, 8.4

PPT (KIKPPT Processing Program Table): 8.4, 10.5, 11.1, 11.2

Priming Read Pattern: 5.1, 6.1, 9.1

Pseudo-Conversational Architecture: 1, 8.1, 9.2, 11.1

RAKF Security: 1.1, 3.1

REGION=4096K: 3.3, 9.1, 10.3, 11.2

RESP() Inline Error Handling: 4.4, 6.3, 8.4, 9.2, 11.1, 11.2

RETURN-CODE Special Register: 5.1, 5.2, 6.1, 9.1

RFE (Review Front End): 1.1, 2.2, 3.1, 3.3, 11.2

RLSE Space Parameter: 3.2, 9.1, 11.1, 11.2

S013 (Open Macro Abend): 1, 11.2

S0C4 (Protection Exception Abend): 3.4, 4.1, 7, 11.2

S0C7 (Data Exception Abend): 1, 3.4, 4.1, 4.3, 11.2

S322 (CPU Timeout Abend): 3.3

S722 (Spool Line Limit Abend): 3.3

S80A / S878 (Virtual Storage Abend): 1, 3.3, 11.2

S913 (RAKF Security Abend): 1.1

SB37 / SD37 (DASD Space Abends): 11.2

Scope Terminators (END-IF Prohibition): 2.2

Seed Record Requirement (VSAM KSDS): 6.3, 10.3

SORT (SD) & SORTWK Datasets: 6.2

Stopper Bytes (BMS 3270 Fields): 8.3, 10.2, 11.1

SXREF (Sorted Cross-Reference): 3.4, 4.1, 9.1, 10.4

TK5 (MVS-Turnkey 5) Baseline: 1, 1.1, 6.2, 8, 10

VSAM KSDS Standards: 3.1, 4.4, 6.3, 8.1, 8.4, 9.2, 10.1, 10.3

WATBOL Comparison: 2.1

WORKING-STORAGE SECTION Hygiene: 4.1, 4.3, 8.2, 9.1, 9.2, 11.1, 11.2

