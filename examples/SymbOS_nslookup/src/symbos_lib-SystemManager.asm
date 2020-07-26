;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                        - SYSTEM MANAGER FUNCTIONS -                        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / Symbiosis
;Date       28.03.2015

;The system manager is responsible for starting and stopping applications and
;it also provides several dialogue services.
;This library supports you in using the system manager functions.

;The existance of
;- "App_PrcID" (a byte, where the ID of the applications process is stored)
;- "App_MsgBuf" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;is required.


;### SUMMARY ##################################################################

;use_SySystem_PRGRUN     equ 0   ;Starts an application or opens a document
;use_SySystem_PRGEND     equ 0   ;Stops an application and frees its resources
;use_SySystem_PRGSRV     equ 0   ;Manages shared services or finds applications
;use_SySystem_SYSWRN     equ 0   ;Opens an info, warning or confirm box
;use_SySystem_SELOPN     equ 0   ;Opens the file selection dialogue
;use_SySystem_HLPOPN     equ 0   ;Opens the help file for this application (##!!## missing doc)


;### MAIN FUNCTIONS ###########################################################

if use_SySystem_PRGRUN=1
SySystem_PRGRUN
;******************************************************************************
;*** Name           Program_Run_Command
;*** Input          HL = File path and name address
;***                A  = [Bit0-3] File path and name ram bank (0-15)
;***                     [Bit7  ] Flag, if system error message should be
;***                              suppressed
;*** Output         A  = Success status
;***                     0 = OK
;***                     1 = File does not exist
;***                     2 = File is not an executable and its type is not
;***                         associated with an application
;***                     3 = Error while loading (see P8 for error code)
;***                     4 = Memory full
;***                - If success status is 0:
;***                L  = Application ID
;***                H  = Process ID (the applications main process)
;***                - If success status is 3:
;***                L  = File manager error code
;*** Destroyed      F,BC,DE,IX,IY
;*** Description    Loads and starts an application or opens a document with a
;***                known type by loading the associated application first.
;***                If Bit7 of A is not set, the system will open a message box,
;***                if an error occurs during the loading process.
;***                If the operation was successful, you will find the
;***                application ID and the process ID in L and H. If it failed
;***                because of loading problems L contains the file manager
;***                error code.
;******************************************************************************
        ld c,MSC_SYS_PRGRUN
        call SySystem_SendMessage
SySPRn1 call SySystem_WaitMessage
        cp MSR_SYS_PRGRUN
        jr nz,SySPRn1
        ld a,(App_MsgBuf+1)
        ld hl,(App_MsgBuf+8)
        ret
endif

if use_SySystem_PRGEND=1
SySystem_PRGEND
;******************************************************************************
;*** Name           Program_End_Command
;*** Input          L  = Application ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Stops an application and releases all its used system
;***                resources. This command first stops all processes of the
;***                application. After this all open windows will be closed and the
;***                reserved memory will be released.
;***                Please note, that this command can't release memory, stop
;***                processes and timers or close windows, which are not
;***                registered for the application. Such resources first have
;***                to be released by the application itself.
;******************************************************************************
        ld c,MSC_SYS_PRGEND
        jp SySystem_SendMessage
endif

if use_SySystem_PRGSRV=1
SySystem_PRGSRV
;******************************************************************************
;*** Name           Program_SharedService_Command
;*** Input          E  = Command type
;***                     0 = search application or shared service
;***                     1 = search, start and use shared service
;***                     2 = release shared service
;***                - if E is 0 or 1:
;***                HL = Address of the 12byte application ID string
;***                - if E is 0 or 1:
;***                A  = Ram bank (0-15) of the 12byte application ID string
;***                - if E is 2:
;*** Output         A  = Result status
;***                     0 = OK
;***                     5 = application or shared service not found (can only
;***                         occur on command type 0)
;***                     1-4=error while starting shared service; same codes
;***                         like in MSR_SYS_PRGRUN, please read there for a
;***                         detailed description
;***                - If command type was 0 or 1, and result status is 0:
;***                L  = Application ID
;***                H  = Process ID (the applications main process)
;***                - If result status is 3:
;***                L  = File manager error code
;*** Destroyed      F,BC,DE,IX,IY
;*** Description    This function can be used to find, start and release shared
;***                services or to find applications.
;***                For a detailed description please read chapter "System
;***                Manager", "Program_SharedService_Command" in the SymbOS
;***                Developer Documentation.
;******************************************************************************
        ld c,MSC_SYS_PRGSRV
        call SySystem_SendMessage
SySPSr1 call SySystem_WaitMessage
        cp MSR_SYS_PRGSRV
        jr nz,SySPSr1
        ld a,(App_MsgBuf+1)
        ld hl,(App_MsgBuf+8)
        ret
endif

if use_SySystem_SYSWRN=1
SySystem_SYSWRN
;******************************************************************************
;*** Name           Dialogue_Infobox_Command
;*** Input          HL = Content data address (#C000-#FFFF)
;***                A  = Content data ram bank (0-15)
;***                B  = [Bit0-2] Number of buttons (1-3)
;***                              1 = "OK" button
;***                              2 = "Yes", "No" buttons
;***                              3 = "Yes", "No", "Cancel" buttons
;***                     [Bit3-5] Titletext
;***                              0 = default (bit7=[0]"Error!"/[1]"Info")
;***                              1 = "Error!"
;***                              2 = "Info"
;***                              3 = "Warning"
;***                              4 = "Confirmation"
;***                     [Bit6  ] Flag, if window should be modal window
;***                     [Bit7  ] Box type
;***                              0 = default (warning [!] symbol)
;***                              1 = info (own symbol will be used)
;***                DE = 0 or data record of the caller window; the dialogue
;***                     window will be a modal window of it, during its open
;*** Content data   00  1W  Address of text line 1
;***                02  1W  4 * [text line 1 pen] + 2
;***                04  1W  Address of text line 2
;***                06  1W  4 * [text line 2 pen] + 2
;***                08  1W  Address of text line 3
;***                10  1W  4 * [text line 3 pen] + 2
;***                - if E[bit7] is 1:
;***                12  1W  Address of symbol (24x24 pixel SymbOS graphic format)
;*** Output         A  = Result status
;***                     0 -> The infobox is currently used by another
;***                          application. It can only be opened once at the
;***                          same time, if it's not a pure info message (one
;***                          button, not a modal window). The user should
;***                          close the other infobox first before it can be
;***                          opened again by the application.
;***                     2 -> The user clicked "OK".
;***                     3 -> The user clicked "Yes".
;***                     4 -> The user clicked "No".
;***                     5 -> The user clicked "Cancel" or the close button.
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens an info, warning or confirm box and displays three line
;***                of text and up to three click buttons.
;***                If Bit7 of B is set to 1, you can specify an own symbol, which
;***                will be showed left to the text. If this bit is not set, a "!"-
;***                warning symbol will be displayed.
;***                If Bit6 of B is set to 1, the window will be opened as a modal
;***                window, and you will receive a message with its window number
;***                (see MSR_SYS_SYSWRN).
;***                Please note, that the content data must always be placed in the
;***                transfer ram area (#C000-#FFFF). The texts itself and the
;***                optional graphic must always be placed inside a 16K (data ram
;***                area).
;***                As the text line pen, you should choose 1, so 6 would be the
;***                correct value.
;***                For more information about the mentioned memory types (data,
;***                transfer) see the "applications" chapter.
;***                For more information about the SymbOS graphic format see the
;***                "desktop manager data records" chapter.
;******************************************************************************
        ld (SySWrnW),de
        ld e,b
        ld c,MSC_SYS_SYSWRN
        push bc
        call SySystem_SendMessage
        pop af
        and 7+64
        dec a
        ret z
SySWrn1 call SySystem_WaitMessage
        cp MSR_SYS_SYSWRN
        jr nz,SySWrn1
        ld ix,(SySWrnW)
        db #dd:ld a,l
        db #dd:or h
        ld c,0
        jr z,SySWrn2
        ld (ix+51),c
        inc c
SySWrn2 ld a,(App_MsgBuf+1)
        cp 1
        ret nz
        dec c
        jr nz,SySWrn1
        ld a,(App_MsgBuf+2)
        ld (ix+51),a
        jr SySWrn1
SySWrnW dw 0
endif

if use_SySystem_SELOPN=1
SySystem_SELOPN
;******************************************************************************
;*** Name           Dialogue_FileSelector_Command
;*** Input          HL = File mask, path and name address (#C000-#FFFF)
;***                     00  3B  File extension filter (e.g. "*  ")
;***                     03  1B  0
;***                     04 256B path and filename
;***                A  = [Bit0-3] File mask, path and name ram bank (0-15)
;***                     [Bit6  ] Flag, if "open" (0) or "save" (1) dialogue
;***                     [Bit7  ] Flag, if file (0) or directory (1) selection
;***                C  = Attribute filter
;***                     Bit0 = 1 -> don't show read only files
;***                     Bit1 = 1 -> don't show hidden files
;***                     Bit2 = 1 -> don't show system files
;***                     Bit3 = 1 -> don't show volume ID entries
;***                     Bit4 = 1 -> don't show directories
;***                     Bit5 = 1 -> don't show archive files
;***                IX = Maximum number of directory entries
;***                IY = Maximum size of directory data buffer
;***                DE = Data record of the caller window; the file selector
;***                     window will be a modal window of it, during its open)
;*** Output         A  = Success status
;***                     0 -> The user choosed a file and closed the dialogue
;***                          with "OK". The complete file path and name can be
;***                          found in the filepath buffer of the application.
;***                     1 -> The user aborted the file selection. The content
;***                          of the applications filepath buffer is unchanged.
;***                     2 -> The file selection dialogue is currently used by
;***                          another application. It can only be opened once
;***                          at the same time. The user should close the
;***                          dialogue first before it can be opened again by
;***                          the application.
;***                     3 -> Memory full. There was not enough memory
;***                          available for the directory buffer and/or the
;***                          list data structure.
;***                     4 -> No window available. The desktop manager couldn't
;***                          open a new window for the dialogue, as the
;***                          maximum number of windows (32) has already been
;***                          reached.
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens the file selection dialogue. In this dialogue the user
;***                can move through the directory structure, change the drive and
;***                search and select a file or a directory for opening or saving.
;***                If you specify a path, the dialogue will start directly in the
;***                directory. If you append a filename, too, it will be used as
;***                the preselected file.
;***                You can filter the entries of the directory by attributes and
;***                filename extension. We recommend always to set Bit3 of the
;***                attribute filter byte.
;***                The File mask/path/name string (260 bytes) must always be
;***                placed in the transfer ram area (#C000-#FFFF). For more
;***                information about this memory types see the "applications"
;***                chapter.
;***                Please note, that the system will reserve memory to store the
;***                listed directory entries and the data structure of the list.
;***                With IX and IY you can choose, how much memory should be used.
;***                We recommend to set the number of entries between 100 and 200
;***                (Amsdos supports a maximum amount of 64 entries) and to set the
;***                data buffer between 5000 and 10000.
;******************************************************************************
        ld (SySSOpW+2),de
        push iy
        ld iy,App_MsgBuf
        ld (App_MsgBuf+6),a
        ld (iy+7),c
        ld (App_MsgBuf+8),hl
        db #dd:ld a,l
        ld (App_MsgBuf+10),a
        db #dd:ld a,h
        ld (App_MsgBuf+11),a
        pop de
        ld (App_MsgBuf+12),de
        ld c,MSC_SYS_SELOPN
        call SySystem_SendMessage
SySSOp1 call SySystem_WaitMessage
        cp MSR_SYS_SELOPN
        jr nz,SySSOp1
SySSOpW ld ix,0
        ld (ix+51),0
        ld a,(App_MsgBuf+1)
        cp -1
        ret nz
        ld a,(App_MsgBuf+2)
        ld (ix+51),a
        jr SySSOp1
endif

if use_SySystem_HLPOPN=1
SySystem_HLPFLG db 0    ;flag, if HLP-path is valid
SySystem_HLPPTH db "%help.exe "
SySystem_HLPPTH1 ds 128
SySHInX db ".HLP",0

SySystem_HLPINI
        ld hl,(App_BegCode)
        ld de,App_BegCode
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld de,SySystem_HLPPTH1
        ld bc,0
        db #dd:ld l,128
SySHIn1 ld a,(hl)
        or a
        jr z,SySHIn3
        cp " "
        jr z,SySHIn3
        cp "."
        jr nz,SySHIn2
        ld c,e
        ld b,d
SySHIn2 ld (de),a
        inc hl
        inc de
        db #dd:dec l
        ret z
        jr SySHIn1
SySHIn3 ld a,c
        or b
        ret z
        ld e,c
        ld d,b
        ld hl,SySHInX
        ld bc,5
        ldir
        ld a,1
        ld (SySystem_HLPFLG),a
        ret

SySystem_HLPOPN
        ld a,(SySystem_HLPFLG)
        or a
        ret z
        ld hl,SySystem_HLPPTH
        ld a,(App_BnkNum)
        jp SySystem_PRGRUN
endif


;### SUB ROUTINES #############################################################

SySystem_SendMessage
;******************************************************************************
;*** Input          C       = Command
;***                HL,A,DE = additional Parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the system manager
;******************************************************************************
        ld iy,App_MsgBuf
        ld (iy+0),c
        ld (App_MsgBuf+1),hl
        ld (App_MsgBuf+3),a
        ld (App_MsgBuf+4),de
        db #dd:ld h,PRC_ID_SYSTEM
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #10
        ret

SySystem_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,App_MsgBuf
SySWMs1 db #dd:ld h,PRC_ID_SYSTEM
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #08             ;wait for a system manager message
        db #dd:dec l
        jr nz,SySWMs1
        ld a,(App_MsgBuf+0)
        ret
