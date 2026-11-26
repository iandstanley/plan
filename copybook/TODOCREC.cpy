*================================================================*
      * COPYBOOK: TODOCREC - TSO CLI COMMAND RECORD LAYOUT (200 BYTES) *
      * SUBSYSTEM: TODO MANAGER (MVS 3.8J TK5 / IKFCBL00)              *
      *================================================================*
           05  CMD-USER-ID             PIC X(08).
           05  CMD-VERB                PIC X(08).
               88  CMD-IS-LIST             VALUE 'LIST    ' '        '.
               88  CMD-IS-ADD              VALUE 'ADD     '.
               88  CMD-IS-VIEW             VALUE 'VIEW    '.
               88  CMD-IS-START            VALUE 'START   '.
               88  CMD-IS-WAIT             VALUE 'WAIT    '.
               88  CMD-IS-DONE             VALUE 'DONE    '.
               88  CMD-IS-CANCEL           VALUE 'CANCEL  '.
               88  CMD-IS-ASSIGN           VALUE 'ASSIGN  '.
               88  CMD-IS-NOTE             VALUE 'NOTE    '.
               88  CMD-IS-PRINT            VALUE 'PRINT   '.
               88  VALID-CMD-VERB          VALUE 'LIST    ' '        '
                                                 'ADD     ' 'VIEW    '
                                                 'START   ' 'WAIT    '
                                                 'DONE    ' 'CANCEL  '
                                                 'ASSIGN  ' 'NOTE    '
                                                 'PRINT   '.
           05  CMD-ARG1                PIC X(16).
           05  CMD-ARG2                PIC X(16).
           05  CMD-DUE-DATE            PIC X(08).
           05  CMD-PRIORITY            PIC X(01).
           05  CMD-LINE-NUM            PIC X(01).
           05  CMD-CATEGORY            PIC X(10).
           05  CMD-TARGET-USER         PIC X(08).
           05  CMD-TEXT                PIC X(60).
           05  CMD-NOTE                PIC X(60).
           05  CMD-FILLER              PIC X(04).