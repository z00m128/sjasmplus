    DEVICE ZXSPECTRUMNEXT
    ; do various config commands without any NEX file being opened => errors
    SAVENEX     CORE    15,15,255
    SAVENEX     CFG     5,"hf",1,1
    SAVENEX     BAR     1,'L','D','d'
    SAVENEX     SCREEN  L2 0, 0, 0, 0
    SAVENEX     SCREEN  LR 0, 0, 0, 0
    SAVENEX     SCREEN  SCR
    SAVENEX     SCREEN  SHC
    SAVENEX     SCREEN  SHR 5
    SAVENEX     BANK    5, 0
    SAVENEX     SCREEN  SCR
    SAVENEX     AUTO

    ; create empty NEX file with empty default LR screen
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  LR
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE   "nonExistentFile.bin"   ; error, file not found
    ; some palette defined
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  LR 5*2, 0, 200, 0
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE

    ; create empty NEX file with empty default L2 screen
    SAVENEX     OPEN    "savenexCoverageL2.nex" ; this will be 48+kiB source for later
    SAVENEX     SCREEN  L2
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE

    ; create empty NEX file with empty default SCR screen
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SCR
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE   "savenexCoverageL2.nex" ; exercise append of binary file

    ; create empty NEX file with empty default SHC screen
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SHC
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE

    ; create empty NEX file with empty default SHR screen
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SHR 5
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE
    ; no hiRes colour defined, default = 0
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SHR
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE
    ; hiRes colour defined wrongly => warning
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SHR 8
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE
    ; hiRes colour defined wrongly => warning
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  SHR -1
    SAVENEX     SCREEN  SCR     ; error "screen was already stored"
    SAVENEX     CLOSE

;; adding coverage tests after NEX file format V1.3 changes:
    SAVENEX     CFG3    0, 0
    SAVENEX     PALETTE   DEFAULT
    SAVENEX     COPPER  0, 0
    ; palette after some bank is stored
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     BANK    5
    SAVENEX     PALETTE   DEFAULT
    SAVENEX     CLOSE
    ; valid L2 640x256 case from memory
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     SCREEN  L2_640
    SAVENEX     CLOSE

;; test the new error message when NEX file has banks 48+, but doesn't set 2MB required
    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     BANK 100
    SAVENEX     CLOSE   ; error about 2MB required

    SAVENEX     OPEN    "savenexCoverage.nex"
    SAVENEX     CFG 0, 0, 0, 1  ; 2mb required set
    SAVENEX     BANK 100
    SAVENEX     CLOSE
