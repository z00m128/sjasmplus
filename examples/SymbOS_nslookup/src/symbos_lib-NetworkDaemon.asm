;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                        - NETWORK DAEMON FUNCTIONS -                        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / SymbiosiS
;Date       11.07.2015

;This library supports you in using all network daemon functions.

;The existance of
;- "App_PrcID" (a byte, where the ID of the applications process is stored)
;- "App_MsgBuf" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;- "App_BnkNum" (a byte, where the number of the applications' ram bank (0-15)
;  is stored)
;is required.


;### SUMMARY ##################################################################

;;   SyNet_NETINI                ;...
;use_SyNet_NETEVT        equ 0   ;check for network events
;use_SyNet_CFGGET        equ 0   ;Config get data
;use_SyNet_CFGSET        equ 0   ;Config set data
;use_SyNet_CFGSCK        equ 0   ;Config socket status
;use_SyNet_TCPOPN        equ 0   ;TCP open connection
;use_SyNet_TCPCLO        equ 0   ;TCP close connecton
;use_SyNet_TCPSTA        equ 0   ;TCP status of connection
;use_SyNet_TCPRCV        equ 0   ;TCP receive from connection
;use_SyNet_TCPSND        equ 0   ;TCP send to connection
;use_SyNet_TCPSKP        equ 0   ;TCP skip received data
;use_SyNet_TCPFLS        equ 0   ;TCP flush send buffer
;use_SyNet_TCPDIS        equ 0   ;TCP disconnect connection
;use_SyNet_TCPRLN        equ 0   ;TCP receive textline from connection
;use_SyNet_UDPOPN        equ 0   ;UDP open
;use_SyNet_UDPCLO        equ 0   ;UDP close
;use_SyNet_UDPSTA        equ 0   ;UDP status
;use_SyNet_UDPRCV        equ 0   ;UDP receive
;use_SyNet_UDPSND        equ 0   ;UDP send
;use_SyNet_UDPSKP        equ 0   ;UDP skip received data
;use_SyNet_DNSRSV        equ 0   ;DNS resolve
;use_SyNet_DNSVFY        equ 0   ;DNS verify


;### GLOBAL VARIABLES #########################################################

SyNet_PrcID db 0    ;network daemon process ID


;### GENERAL FUNCTIONS ########################################################

SyNet_NETINI
;******************************************************************************
;*** Name           Network_Init
;*** Input          -
;*** Output         CF   = Error state (0 = ok, 1 = Network daemon not running)
;***                - if CF is 0:
;***                (SyNet_PrcID) = Network daemon process ID
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld e,0
        ld hl,snwdmnt
        ld a,(App_BnkNum)
        call SySystem_PRGSRV
        or a
        scf
        ret nz
        ld a,h
        ld (SyNet_PrcID),a
        or a
        ret
snwdmnt db "Network Daem"

if use_SyNet_NETEVT=1
SyNet_NETEVT
;******************************************************************************
;*** Name           Network_Event
;*** Input          -
;*** Output         CF   = Flag, if network event occured (1=no)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status (1=TCP opening, 2=TCP established, 3=TCP
;***                       close waiting, 4=TCP close,
;***                       16=UDP sending,
;***                       128=data received)
;***                IX,IY= Remote IP
;***                DE   = Remote port
;***                BC   = Received bytes
;*** Destroyed      F,HL
;*** Description    ...
;******************************************************************************
        ld a,(App_PrcID)
        db #dd:ld l,a
        ld a,(SyNet_PrcID)
        db #dd:ld h,a
        ld iy,App_MsgBuf
        rst #18                 ;check for message
        db #dd:dec l
        scf
        ret nz                  ;no message available
        ld a,(App_MsgBuf)
        cp MSR_NET_TCPEVT
        jp z,snwmsgo_afbcdehlixiy
        cp MSR_NET_UDPEVT
        jp z,snwmsgo_afbcdehlixiy
        scf                     ;senseless message
        ret
endif


;### CONFIG FUNCTIONS #########################################################

if use_SyNet_CFGSET=1
SyNet_CFGGET
;******************************************************************************
;*** ID             001 (CFGGET)
;*** Name           Config_GetData
;*** Input          A    = Type
;***                HL   = Config data buffer
;*** Output         CF   = status (CF=1 invalid type)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_BnkNum)
        call snwmsgi_afdehl
        db FNC_NET_CFGGET
        jp snwmsgo_afhl
endif

if use_SyNet_CFGGET=1
SyNet_CFGSET
;******************************************************************************
;*** ID             002 (CFGSET)
;*** Name           Config_SetData
;*** Input          A    = Type
;***                HL   = New config data
;*** Output         CF   = status (CF=1 invalid type)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_BnkNum)
        call snwmsgi_afdehl
        db FNC_NET_CFGSET
        jp snwmsgo_afhl
endif

if use_SyNet_CFGSCK=1
SyNet_CFGSCK
;******************************************************************************
;*** ID             003 (CFGSCK)
;*** Name           Config_SocketStatus
;*** Input          A    = first socket
;***                C    = number of sockets
;***                HL   = data buffer
;*** Output         CF   = status (CF=1 invalid range)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_BnkNum)
        call snwmsgi_afbcdehl
        db FNC_NET_CFGSCK
        jp snwmsgo_afhl
endif


;### TCP FUNCTIONS ############################################################

if use_SyNet_TCPOPN=1
;******************************************************************************
;*** ID             016 (TCPOPN)
;*** Name           TCP_Open
;*** Input          A    = Type (0=active/client, 1=passive/server)
;***                HL   = Local port (-1=dynamic client port)
;***                - if A is 0:
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens a TCP connection as a client (active) or as a server
;***                (passive). If it's an active connection you have to specify
;***                the remote IP address and port number as well.
;***                The local port number always has to be set. For client
;***                network applications you should set HL to -1 (65535) to get
;***                a dynamic port number. This will automaticaly generated by
;***                the network daemon in the range of 49152-65535 (official
;***                range for dynamic ports).
;***                This function will fail, if there is no free socket left.
;***                It returns the connection handle if it was successful.
;******************************************************************************
SyNet_TCPOPN
        call snwmsgi_afbcdehlixiy
        db FNC_NET_TCPOPN
        jp snwmsgo_afhl
endif

if use_SyNet_TCPCLO=1
;******************************************************************************
;*** ID             017 (TCPCLO)
;*** Name           TCP_Close
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Closes a TCP connection and releases the used socket. It
;***                will not send a disconnect signal to the remote host (see
;***                TCPDIS). Use this, after the remote host already
;***                closed the connection.
;******************************************************************************
SyNet_TCPCLO
        call snwmsgi_af
        db FNC_NET_TCPCLO
        jp snwmsgo_afhl
endif

if use_SyNet_TCPSTA=1
;******************************************************************************
;*** ID             018 (TCPSTA)
;*** Name           TCP_Status
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status (1=TCP opening, 2=TCP established, 3=TCP
;***                       close waiting, 4=TCP close; +128=data received)
;***                - if L is >1:
;***                IX,IY= Remote IP
;***                DE   = Remote port
;***                - if L is >=128:
;***                BC   = Received bytes (which are available in the RX
;***                       buffer)
;*** Destroyed      F,H
;*** Description    Returns the actual status of the TCP connection. Usually
;***                this is exactly the same as received in the last event
;***                message (see TCPEVT). The number of received bytes in BC
;***                may have been increased during the last event, if it was
;***                already larger than 0.
;******************************************************************************
SyNet_TCPSTA
        call snwmsgi_af
        db FNC_NET_TCPSTA
        jp snwmsgo_afbcdehlixiy
endif

if use_SyNet_TCPRCV=1
;******************************************************************************
;*** ID             019 (TCPRCV)
;*** Name           TCP_Receive
;*** Input          A    = Handle
;***                E    = Destination bank
;***                HL   = Destination address
;***                BC   = Length (has to be >0)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                BC   = Number of transfered bytes (which have been copied
;***                       to the destination)
;***                HL   = Number of remaining bytes (which are still left in
;***                       the RX buffer)
;***                ZF   = 1 -> no remaining bytes (RX buffer is empty)
;*** Destroyed      F,DE,HL,IX,IY
;*** Description    Copies data, which has been received from the remote host,
;***                to a specified destination in memory. The length of the
;***                requested data is not limited, but this function will only
;***                receive the available one.
;***                Please note, that a new TCPEVT event only occurs on new
;***                incoming bytes, if this function returned HL=0 (no
;***                remaining bytes). It may happen, that during the last
;***                TCPEVT/TCPSTA status the number of remaining bytes has been
;***                increased, so you always have to check HL, even if you
;***                requested all incoming bytes known from the last status.
;******************************************************************************
SyNet_TCPRCV
        call snwmsgi_afbcdehl
        db FNC_NET_TCPRCV
        jp snwmsgo_afbchl
endif

if use_SyNet_TCPSND=1
;******************************************************************************
;*** ID             020 (TCPSND)
;*** Name           TCP_Send
;*** Input          A    = Handle
;***                E    = Source bank
;***                HL   = Source address
;***                BC   = Length
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                BC   = Number of transfered bytes
;***                HL   = Number of remaining bytes (which couldn't be
;***                       transfered, as the TX buffer is full at the moment)
;***                ZF   = 1 -> no remaining bytes
;*** Destroyed      F,DE,IX,IY
;*** Description    Sends data to the remote host. The length of the data is
;***                not limited, but this function may send only a part of it.
;***                In case that not all data have been send, the application
;***                should idle for a short time and send the remaining part
;***                at another attempt.
;******************************************************************************
SyNet_TCPSND
        call snwmsgi_afbcdehl
        db FNC_NET_TCPSND
        jp snwmsgo_afbchl
endif

if use_SyNet_TCPSKP=1
;******************************************************************************
;*** ID             021 (TCPSKP)
;*** Name           TCP_Skip
;*** Input          A    = Handle
;***                BC   = Length
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Skips data, which has been received from the remote host.
;***                This can be used if the application is sure, that the
;***                following bytes are not needed and the data transfer can be
;***                skipped to save resources. The amount of bytes must be
;***                equal or smaller than the total amount of received data.
;******************************************************************************
SyNet_TCPSKP
        call snwmsgi_afbcdehl
        db FNC_NET_TCPSKP
        jp snwmsgo_afhl
endif

if use_SyNet_TCPFLS=1
;******************************************************************************
;*** ID             022 (TCPFLS)
;*** Name           TCP_Flush
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Flushes the send buffer. This maybe used to send data
;***                immediately, as some network hardware or software
;***                implementations may store it first in the send buffer for a
;***                while until it is full or a special amount of time has
;***                passed.
;******************************************************************************
SyNet_TCPFLS
        call snwmsgi_af
        db FNC_NET_TCPFLS
        jp snwmsgo_afhl
endif

if use_SyNet_TCPDIS=1
;******************************************************************************
;*** ID             023 (TCPDIS)
;*** Name           TCP_Disconnect
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a disconnect signal to the remote host, closes the
;***                TCP connection and releases the used socket. Use this, if
;***                you want to close the connection by yourself.
;******************************************************************************
SyNet_TCPDIS
        call snwmsgi_af
        db FNC_NET_TCPDIS
        jp snwmsgo_afhl
endif

if use_SyNet_TCPRLN=1
;******************************************************************************
;*** ID             024 (TCPRLN)
;*** Name           TCP_ReceiveLine
;*** Input          A    = Handle
;***                E    = Destination bank
;***                HL   = Destination address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                D    = Line length (-1=no complete line received, ZF=1)
;***                ZF   = 1 -> no complete line received
;*** Destroyed      AF,E,HL,IX,IY
;*** Description    ...
;******************************************************************************
SyNet_TCPRLN_Buffer ds 256      ;buffer
SyNet_TCPRLN_Length db 0        ;length (always <255)
SyNet_TCPRLN
        ld (snwrln3+1),a
        ld a,e
        add a:add a:add a:add a
        ld (snwrlnb+1),a
        ld (snwrlna+1),hl
        call snwrln0
        ld a,d
        inc a
        jr z,snwrln8
snwrln9 ld a,d
        inc a
        or a
snwrlnc ld a,(snwrln3+1)
        ret
snwrln8 ld a,(SyNet_TCPRLN_Length)
        ld c,a
        ld b,0
        cpl                     ;A=255-buflen
        ld hl,SyNet_TCPRLN_Buffer
        add hl,bc
        ld c,a
snwrln3 ld a,0
        ld de,(App_BnkNum)
        call snwmsgi_afbcdehl   ;receive data
        db FNC_NET_TCPRCV
        call snwmsgo_afbchl
        ret c
        ld hl,SyNet_TCPRLN_Length
        ld a,(hl)
        add c
        ld (hl),a               ;update buffer length
        call snwrln0
        jr snwrln9

snwrln0 ld a,(SyNet_TCPRLN_Length)
        cp 255
        ccf
        sbc 0
        ld d,-1
        ret z
        ld e,a                  ;e,bc=search length (max 254)
        ld c,a
        ld b,0
        ld hl,SyNet_TCPRLN_Buffer
        ld a,13
        cpir
        jr z,snwrln5
        ld a,e
        cp 254
        ret c                   ;** not found and <254 chars -> no complete line received
        inc d
snwrln4 call snwrln7            ;** not found and =254 chars -> send line anyway
        ld d,254
        ret
snwrln5 ld a,c                  ;** found -> HL=behind 13-char, BC=remaining length
        or b
        ld d,-1
        ret z                   ;found at the last position -> no complete line received
        ld d,1
        ld a,10
        cp (hl)
        jr nz,snwrln6
        inc d
snwrln6 ld bc,SyNet_TCPRLN_Buffer+1
        or a
        sbc hl,bc
        ld e,l
        push de
        call snwrln7
        pop de
        ld d,e
        ret

;e=line length, d=bytes to skip -> copy line to destination and remove it from the buffer
snwrln7 push de
        ld d,0
        ld hl,SyNet_TCPRLN_Buffer
        push hl
        add hl,de
        ld (hl),0
        pop hl
        ld c,e
        inc c
        ld b,0
        ld a,(App_BnkNum)
snwrlnb add 0
snwrlna ld de,0
        rst #20:dw jmp_bnkcop
        pop de
        ld hl,SyNet_TCPRLN_Length
        ld a,(hl)
        sub e
        sub d
        ld (hl),a
        ret z
        ld c,a
        ld b,0
        ld a,e
        add d
        ld e,a
        ld d,0
        ld hl,SyNet_TCPRLN_Buffer
        add hl,de
        ld de,SyNet_TCPRLN_Buffer
        ldir
        ret
endif

;### UDP FUNCTIONS ############################################################

if use_SyNet_UDPOPN=1
;******************************************************************************
;*** ID             032 (UDPOPN)
;*** Name           UDP_Open
;*** Input          A    = Type
;***                HL   = Local port
;***                E    = Source/destination bank for receive/send
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens an UDP session. Already with this functions you have
;***                to specify the ram bank number of the source and
;***                destination memory areas for upcoming data transfer.
;***                This function will fail, if there is no free socket left.
;***                It returns the session handle if it was successful.
;******************************************************************************
SyNet_UDPOPN
        call snwmsgi_afdehl
        db FNC_NET_UDPOPN
        jp snwmsgo_afhl
endif

if use_SyNet_UDPCLO=1
;******************************************************************************
;*** ID             033 (UDPCLO)
;*** Name           UDP_Close
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Closes an UDP session and releases the used socket.
;******************************************************************************
SyNet_UDPCLO
        call snwmsgi_af
        db FNC_NET_UDPCLO
        jp snwmsgo_afhl
endif

if use_SyNet_UDPSTA=1
;******************************************************************************
;*** ID             034 (UDPSTA)
;*** Name           UDP_Status
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status
;***                - if L is ???:
;***                BC   = Received bytes
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Returns the actual status of the UDP session. This is
;***                always exactly the same as received in the last event
;***                message (see UDPEVT).
;******************************************************************************
SyNet_UDPSTA
        call snwmsgi_af
        db FNC_NET_UDPSTA
        jp snwmsgo_afbcdehlixiy
endif

if use_SyNet_UDPRCV=1
;******************************************************************************
;*** ID             035 (UDPRCV)
;*** Name           UDP_Receive
;*** Input          A    = Handle
;***                HL   = Destination address
;***                       (bank has been specified by the UDPOPN function)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Copies the package data, which has been received from a
;***                remote host, to a specified destination in memory. Please
;***                note, that this function will always transfer the whole
;***                data at once, so there should be enough place at the
;***                destination address. The destination ram bank number has
;***                already been specified with the UDPOPN function.
;******************************************************************************
SyNet_UDPRCV
        call snwmsgi_afhl
        db FNC_NET_UDPRCV
        jp snwmsgo_afhl
endif

if use_SyNet_UDPSND=1
;******************************************************************************
;*** ID             036 (UDPSND)
;*** Name           UDP_Send
;*** Input          A    = Handle
;***                HL   = Source address
;***                       (bank has been specified by the UDPOPN function)
;***                BC   = Length
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a data package to a remote host. It may happen, that
;***                the send buffer is currently full, and this function will
;***                the return the appropriate error code. In this case the
;***                application should idle for a short time and try to send
;***                the package again at another attempt.
;******************************************************************************
SyNet_UDPSND
        call snwmsgi_afbcdehlixiy
        db FNC_NET_UDPSND
        jp snwmsgo_afhl
endif

if use_SyNet_UDPSKP=1
;******************************************************************************
;*** ID             037 (UDPSKP)
;*** Name           UDP_Skip
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Skips a received data package. This can be used if the
;***                application is sure, that the data is not needed or has
;***                sent from the wrong remote host, so the data transfer can
;***                be skipped to save resources.
;******************************************************************************
SyNet_UDPSKP
        call snwmsgi_af
        db FNC_NET_UDPSKP
        jp snwmsgo_afhl
endif


;### DNS FUNCTIONS ############################################################

if use_SyNet_DNSRSV=1
;******************************************************************************
;*** ID             112 (DNSRSV)
;*** Name           DNS_Resolve
;*** Input          HL = string address (0-terminated)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                IX,IY= IP
;*** Destroyed      AF,BC,DE,HL
;*** Description    ...
;******************************************************************************
SyNet_DNSRSV
        ld de,(App_BnkNum)
        call snwmsgi_afdehl
        db FNC_NET_DNSRSV
        jp snwmsgo_afbcdehlixiy
endif

if use_SyNet_DNSVFY=1
;******************************************************************************
;*** ID             113 (DNSVFY)
;*** Name           DNS_Verify
;*** Input          HL = string address (0-terminated)
;*** Output         L    = type of address (0=no valid address, 1=IP address,
;***                                        2=domain address)
;***                - if L is 1:
;***                IX,IY= IP
;*** Destroyed      F,BC,DE,HL
;*** Description    ...
;******************************************************************************
SyNet_DNSVFY
        ld de,(App_BnkNum)
        call snwmsgi_afdehl
        db FNC_NET_DNSVFY
        jp snwmsgo_afbcdehlixiy
endif


;### SUB ROUTINES #############################################################

snwmsgi_afbcdehlixiy
        ld (App_MsgBuf+10),ix   ;store registers to message buffer
        ld (App_MsgBuf+12),iy
snwmsgi_afbcdehl
        ld (App_MsgBuf+04),bc
snwmsgi_afdehl
        ld (App_MsgBuf+06),de
snwmsgi_afhl
        ld (App_MsgBuf+08),hl
snwmsgi_af
        push af:pop hl
        ld (App_MsgBuf+02),hl
        pop hl
        ld a,(hl)               ;set command
        inc hl
        push hl
        ld (App_MsgBuf+0),a
        ld (snwmsg2+1),a
        ld iy,App_MsgBuf
        ld a,(App_PrcID)
        db #dd:ld l,a
        ld a,(SyNet_PrcID)
        db #dd:ld h,a
        ld (snwmsg1+2),ix
        rst #10                 ;send message
snwmsg1 ld ix,0                 ;wait for response
        rst #08
        db #dd:dec l
        jr nz,snwmsg1
        ld a,(App_MsgBuf)
        sub 128
snwmsg2 cp 0
        ret z
        ld a,(App_PrcID)        ;wrong response code -> re-send and wait for correct one
        db #dd:ld h,a
        ld a,(SyNet_PrcID)
        db #dd:ld l,a
        rst #10
        rst #30
        jr snwmsg1
snwmsgo_afbcdehlixiy
        ld ix,(App_MsgBuf+10)   ;get registers from the message buffer
        ld iy,(App_MsgBuf+12)
        ld de,(App_MsgBuf+06)
snwmsgo_afbchl
        ld bc,(App_MsgBuf+04)
snwmsgo_afhl
        ld hl,(App_MsgBuf+02)
        push hl
        pop af
        ld hl,(App_MsgBuf+08)
        ret
