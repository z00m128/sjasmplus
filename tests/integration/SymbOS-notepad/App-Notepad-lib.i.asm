;==============================================================================
;### SYSTEM-LIBRARY-ROUTINES ##################################################
;==============================================================================

SyDesktop_WINOPN
;******************************************************************************
;*** Name           Window_Open_Command
;*** Input          A  = Window data record ram bank (0-15)
;***                DE = Window data record address (#C000-#FFFF)
;*** Output         A  = Window ID (only, if CF=0)
;***                CF = Success status
;***                     0 = OK
;***                     1 = window couldn't be opened, as the maximum number
;***                         of windows (32) has been reached
;*** Destroyed      BC,DE,HL,IX,IY
;*** Description    Opens a new window. Its data record must be placed in the
;***                transfer ram area (between #c000 and #ffff).
;***                For more information about the window data record see the
;***                chapter "desktop manager data records".
;***                For more information about the transfer ram memory types see
;***                the "applications" chapter.
;******************************************************************************
        ld b,a
        db #dd:ld l,e
        db #dd:ld h,d
        ld a,(AppPrzN)      ;register window for the application process
        ld (ix+3),a
        ld a,b
        ld c,MSC_DSK_WINOPN
        call SyDesktop_SendMessage
SyWOpn1 call SyDesktop_WaitMessage
        cp MSR_DSK_WOPNER
        scf
        ret z               ;return with set carry flag, if window couldn't be opened
        cp MSR_DSK_WOPNOK
        jr nz,SyWOpn1       ;different message than "open ok" -> continue waiting
        ld a,(iy+4)         ;get window ID and return with cleared carry flag
        ret

SyDesktop_WINCLS
;******************************************************************************
;*** Name           Window_Close_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Closes the window. The desktop manager will remove it from the
;***                screen.
;******************************************************************************
        ld c,MSC_DSK_WINCLS
        jp SyDesktop_SendMessage

SyDesktop_WINDIN
;******************************************************************************
;*** Name           Window_Redraw_ContentExtended_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -P2 controls, starting from
;***                                  control P3. As an example, if P2 is -3
;***                                  (253) and P3 is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window content. This command is identical with MSC_DSK_WININH
;***                with the exception, that it always works but with less speed.
;***                For more information see MSC_DSK_WININH.
;******************************************************************************
        ld c,MSC_DSK_WINDIN
        jp SyDesktop_SendMessage

SyDesktop_WINTIT
;******************************************************************************
;*** Name           Window_Redraw_Title_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the title bar of a window. Use this command to update
;***                the screen display, if you changed the text of the window
;***                title.
;******************************************************************************
        ld c,MSC_DSK_WINTIT
        jp SyDesktop_SendMessage

SyDesktop_WINSTA
;******************************************************************************
;*** Name           Window_Redraw_Statusbar_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the status bar of a window. Use this command to update
;***                the screen display, if you changed the text of the status bar.
;******************************************************************************
        ld c,MSC_DSK_WINSTA
        jp SyDesktop_SendMessage

SyDesktop_WINMAX
;******************************************************************************
;*** Name           Window_Size_Maximize_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is minimized or restored
;*** Description    Maximizes a window. A maximized window has a special status,
;***                where it can't be moved to another screen position.
;******************************************************************************
        ld c,MSC_DSK_WINMAX
        jp SyDesktop_SendMessage

SyDesktop_WINMID
;******************************************************************************
;*** Name           Window_Size_Restore_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is maximized or minimized
;*** Description    Restores the window or the size of the window, if it was
;***                minimized or maximized before.
;******************************************************************************
        ld c,MSC_DSK_WINMID
        jp SyDesktop_SendMessage

SyDesktop_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                A  = Window ID
;***                DE,HL = additional parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,AppMsgB
        ld (iy+0),c
        ld (iy+1),a
        ld (iy+2),e
        ld (iy+3),d
        ld (iy+4),l
        ld (iy+5),h
        db #dd:ld h,2       ;2 is the number of the desktop manager process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #10
        ret
EndLib

SyDesktop_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,AppMsgB
SyDWMs1 db #dd:ld h,2       ;2 is the number of the desktop manager process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #08             ;wait for a desktop manager message
        db #dd:dec l
        jr nz,SyDWMs1
        ld a,(iy+0)
        ret

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
        ld a,(AppMsgB+1)
        ld hl,(AppMsgB+8)
        ret

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
;***                     [Bit6  ] Flag, if window should be modal
;***                     [Bit7  ] Box type
;***                              0 = default (warning [!] symbol)
;***                              1 = info (own symbol will be used)
;***                DE = Data record of the caller window; the dialogue window
;***                     will be the modal window of it, during its open)
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
;***                          button, not modal). The user should close the other
;***                          infobox first before it can be opened again by the
;***                          application.
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
        ld ix,(SySSOpW)
        ld (ix+51),0
        ld a,(iy+1)
        cp 1
        ret nz
        ld a,(iy+2)
        ld (ix+51),a
        jr SySWrn1
SySWrnW dw 0

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
        ld (SySSOpW),de
        push iy
        ld iy,AppMsgB
        ld (iy+6),a
        ld (iy+7),c
        ld (iy+8),l
        ld (iy+9),h
        db #dd:ld a,l
        ld (iy+10),a
        db #dd:ld a,h
        ld (iy+11),a
        pop de
        ld (iy+12),e
        ld (iy+13),d
        ld c,MSC_SYS_SELOPN
        call SySystem_SendMessage
SySSOp1 call SySystem_WaitMessage
        cp MSR_SYS_SELOPN
        jr nz,SySSOp1
        ld ix,(SySSOpW)
        ld (ix+51),0
        ld a,(iy+1)
        cp -1
        ret nz
        ld a,(iy+2)
        ld (ix+51),a
        jr SySSOp1
SySSOpW dw 0

SySystem_SendMessage
;******************************************************************************
;*** Input          C       = Command
;***                HL,A,DE = additional Parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the system manager
;******************************************************************************
        ld iy,AppMsgB
        ld (iy+0),c
        ld (iy+1),l
        ld (iy+2),h
        ld (iy+3),a
        ld (iy+4),e
        ld (iy+5),d
        db #dd:ld h,3       ;3 is the number of the system manager process
        ld a,(AppPrzN)
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
        ld iy,AppMsgB
SySWMs1 db #dd:ld h,3       ;3 is the number of the system manager process
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #08             ;wait for a system manager message
        db #dd:dec l
        jr nz,SySWMs1
        ld a,(iy+0)
        ret

SySystem_CallFunction
;******************************************************************************
;*** Name           System_CallFunction
;*** Input          ((SP+0)) = System manager command
;***                ((SP+1)) = Function ID
;***                AF,BC,DE,HL,IX,IY = Input for the function
;*** Output         AF,BC,DE,HL,IX,IY = Output from the function
;*** Destroyed      -
;*** Description    Calls a function via the system manager. This function is
;***                needed to have access to the file manager.
;******************************************************************************
        ld (AppMsgB+04),bc      ;copy registers into the message buffer
        ld (AppMsgB+06),de
        ld (AppMsgB+08),hl
        ld (AppMsgB+10),ix
        ld (AppMsgB+12),iy
        push af
        pop hl
        ld (AppMsgB+02),hl
        pop hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld (AppMsgB+00),de      ;module und funktion number
        ld a,e
        ld (SyCallN),a
        ld iy,AppMsgB
        ld a,(AppPrzN)
        db #dd:ld l,a
        ld a,3
        db #dd:ld h,a
        rst #10                 ;send message
SyCall1 rst #30
        ld iy,AppMsgB
        ld a,(AppPrzN)
        db #dd:ld l,a
        ld a,3
        db #dd:ld h,a
        rst #18                 ;wait for answer
        db #dd:dec l
        jr nz,SyCall1
        ld a,(AppMsgB)
        sub 128
        ld e,a
        ld a,(SyCallN)
        cp e
        jr nz,SyCall1
        ld hl,(AppMsgB+02)      ;get registers out of the message buffer
        push hl
        pop af
        ld bc,(AppMsgB+04)
        ld de,(AppMsgB+06)
        ld hl,(AppMsgB+08)
        ld ix,(AppMsgB+10)
        ld iy,(AppMsgB+12)
        ret
SyCallN db 0
