%TITLE  "LED Device Controller by Stas (Mail: stas@linuxbr.com.br; URL: http://sysd.hypermart.net)"

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;* You will need Turbo Assembler 5.0 to compile this program.  *
;* To compile, just type "MAKE -fMakefile".                    *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

        IDEAL
        P286
	MODEL	tiny

	CODESEG

VER     EQU     "4.2"

; Aliases to common ASCII sequences
CRLF    EQU     0Dh, 0Ah
TAB     EQU     9h
Item    EQU     0FEh, ' '
L_Arrow EQU     11h
R_Arrow EQU     10h

BIOSSeg EQU     40h
LPTOffs EQU     8h
MaxLPTn EQU     4
DfltLPT EQU     1


EXTRN	Bin2ASC:PROC

        ORG     100h

;**********************************************************
;                   W A R N I N G  !!!
;**********************************************************
;       If you are going to edit this code, be very
; carefull!!! As I designed this program to be
; fastest and smallest possible (thus why I used
; MODEL TINY ;), many of high-level stuff where
; stripped out. If you look well to this code, you'll
; see that it puts all necessary data in registers and
; stack!!! And that sub-routines doesn't restores all
; registers they changed... I know, it looks ugly and
; unsafe, but... Damn, this isn't any fuckin' Kernel to
; be hugest code of the world!!!
;       So, here are some registers, that are used as
; "static" variables:
;       BX => LPT _logical_ port number (like 1 for LPT1)
;       DX => LPT _physical_ port number (like 0x378 for LPT1)
;       DS = ES = CS => All used to access printing data...
; All other registers can keep "temporary" values, but be
; carefull anyway...
;**********************************************************
Start:
        mov     al, 3h                  ; CLear Screen
        int     10h
        mov     ah, 1h                  ; Sets invisible cursor
        int     10h

        mov     dx, offset InfoMSG      ; Print info message
        mov     ah, 9h
        int     21h

        push    es                      ; Check if any LPT is present
        mov     ax, BIOSSeg
        mov     es, ax
        mov     di, LPTOffs
        mov     cl, MaxLPTn + 1
        xor     al, al
        repz    scasw
        pop     es

        jcxz    Error                   ; If not, we can't continue running

        mov     dx, offset HelpMSG      ; Print usage message
        mov     ah, 9h
        int     21h

        mov     bl, DfltLPT             ; Scan from LPT1 by default
        call    LPTDetect

GetKey:
        call    WaitVert                ; Flicker sucks!!!
        in      al, dx                  ; Get current state of Parallel Port
                                        ; (for LPT status report)
        call    PrintStatus             ; Print selected LPT's status

        mov     ah, 1h                  ; Check if any key was pressed
        int     16h
        jz      GetKey
        xor     ah, ah                  ; Get pressed key and flush
        int     16h                     ; keyboard buffer

; Program Controls
        cmp     ax, 11Bh                ; Is it ESC?
        je      short Bye               ; If so, exit
        cmp     ax, 3920h               ; Is it Space?
        jne     short @@05              ; No, it's NOT...
        inc     bl                      ; Try to switch LPT
        call    LPTDetect
        jmp     short GetKey            ; Reset loop

; LED Controls (uses only high word of keyboard state)
@@05:
        in      al, dx                  ; Get current state of Parallel Port

        cmp     ah, 0Ah                 ; Set all LEDs to ON
        jne     short @@10
        mov     al, 0FFh
        jmp     short SetLPT

@@10:
        cmp     ah, 0Bh                 ; Set all LEDs to OFF
        jne     short @@20
        xor     al, al
        jmp     short SetLPT

@@20:
        cmp     ah, 2Dh                 ; XOR all LEDs
        jne     short @@30
        xor     al, 0FFh                ; XOR 'Em All!!!
        jmp     short SetLPT

@@30:
        cmp     ah, 4Bh                 ; ROL LEDs
        jne     short @@40
        rol     al, 1h
        jmp     short SetLPT

@@40:
        cmp     ah, 4Dh                 ; ROR LEDs
        jne     short @@50
        ror     al, 1h
        jmp     short SetLPT

@@50:
        cmp     ah, 2h                  ; Is this key something from 1 to 8?
        jb      GetKey
        cmp     ah, 9h
        ja      GetKey

        sub     ah, 2                   ; Use soon as shift counter
        mov     cl, 1                   ; CL = 00000001b (one bit for shift :)
        xchg    ah, cl                  ; Yeah, that's right now!
        shl     ah, cl                  ; AH is now a bitmask for LED

        xor     al, ah                  ; Apply bitmask

SetLPT:
        out     dx, al                  ; Set new state of Parallel Port
        jmp     short GetKey            ; Loop

Bye:
        ret                             ; RETurn to system

Error:
        mov     dx, offset NoLPT        ; Print error message
        mov     ah, 9h
        int     21h
        ret


;**********************************************************
; LPTDetect: Scans for first available Parallel Port
;**********************************************************
; # Input:
;       BL = Lowest Parallel Port number (LPTx)
; # Output:
;       BL = First available Parallel Port number (LPTx)
;       DX = Port address for respective Parallel Port
; # Registers:
;       AX, CX
; # WARNING:
;       This functions needs that at least one LPT is
;       present. If not, it enters in infinite loop!!!
;**********************************************************
PROC    LPTDetect
        push    es

        mov     ax, BIOSSeg             ; Set up segment
        mov     es, ax

        dec     bl                      ; Set up offset
        mov     cx, bx                  ; Save LPT number in CX
        mov     al, 2
        mul     bl
        xchg    ax, bx
        add     bl, LPTOffs

@@10:
        inc     cx                      ; Increase LPT number

        cmp     cl, MaxLPTn             ; We have 4 Parallel Ports AT MAX!!!
        jbe     short @@20
        mov     bl, LPTOffs             ; On overkill regress to LPT1
        xor     cx, cx
        jmp     short @@10

@@20:
        mov     dx, [es:bx]             ; Read LPT port address
        or      dx, dx                  ; Is this LPT present?
        jne     short @@30              ; Yeah, so leave

        add     bl, 2                   ; Increase LPT address offset
        jmp     short @@10              ; Continue searching

@@30:
        mov     bx, cx                  ; Put found value in BX

        pop     es
        ret
ENDP    LPTDetect


;**********************************************************
; PrintStatus: Formats and outputs LPT status
;**********************************************************
; # Input:
;       AL = Current port value
; # Output:
;       NONE
; # Registers:
;       CX, DI
;**********************************************************
PROC    PrintStatus
        push    ax
        push    dx
        push    bx

        xor     ah, ah

        mov     bx, 2                   ; Show binary state
        mov     cx, 8
        mov     di, offset StatusB
        call    Bin2ASC

        mov     bx, 8                   ; Show octal state
        mov     cx, 3
        mov     di, offset StatusO
        call    Bin2ASC

        mov     bx, 10                  ; Show decimal state
        mov     cx, 3
        mov     di, offset StatusD
        call    Bin2ASC

        mov     bx, 16                  ; Show hex state
        mov     cx, 2
        mov     di, offset StatusH
        call    Bin2ASC


        pop     bx                      ; LPTx: Parallel Port number
        push    bx
        mov     ax, bx
        mov     bx, 10
        xor     cx, cx
        mov     di, offset LPTNum
        call    Bin2ASC

        mov     ax, dx                  ; LPT Port number
        mov     bx, 16
        mov     cx, 4
        mov     di, offset LPTPort
        call    Bin2ASC


        mov     ah, 3h                  ; Save cursor position
        int     10h
        push    dx

        mov     dx, offset Status       ; Show current port status
        mov     ah, 9h
        int     21h

        pop     dx                      ; Restore cursor position
        mov     ah, 2h
        int     10h

        pop     bx
        pop     dx
        pop     ax
        ret
ENDP    PrintStatus


;**********************************************************
; WaitVert: Waits for vertical screen refresh
;**********************************************************
; # Input:
;       NONE
; # Output:
;       NONE
; # Registers:
;       AX
;**********************************************************
PROC    WaitVert
        push    dx

        mov     dx, 3DAh                ; Color status port

@@10:
        in      al, dx
        test    al, 8h
        jnz     @@10                    ; Wait for vertical off

@@20:
        in      al, dx
        test    al, 8h
        jnz     @@20                    ; Wait for vertical on

        pop     dx
        ret
ENDP    WaitVert


InfoMSG DB      "LED Device Controller v", VER, " (", ??Date, ")", CRLF
        DB      "Coded by Stas (Mail: stas@linuxbr.com.br; URL: http://sysd.hypermart.net);", CRLF
        DB      "(C)opyLeft by SysD Destructive Labs, 1997-2000", CRLF, CRLF
        DB      '$'

NoLPT   DB      "ERROR: No Parallel Port was found on your computer!!!", 7, CRLF
        DB      '$'

HelpMSG DB      "Usage (keys):", CRLF
        DB      TAB, Item, "1-8.....Toggle respective LED state (a.k.a. datapin logic level)", CRLF
        DB      TAB, Item, "9.......Turn all LEDs ON", CRLF
        DB      TAB, Item, "0.......Turn all LEDs OFF", CRLF
        DB      TAB, Item, "X.......Toggle all LEDs", CRLF
        DB      TAB, Item, L_Arrow, '......."ROtate Left" LEDs', CRLF
        DB      TAB, Item, R_Arrow, '......."ROtate Right" LEDs', CRLF
        DB      TAB, Item, "Space...Switch to next Parallel Port (if present)", CRLF
        DB      TAB, Item, "ESC.....Exit", CRLF, CRLF
        DB      '$'

Status  DB      "LPT"
LPTNum  DB      '0'
        DB      " (Port 0x"
LPTPort DB      4 DUP ('0')
        DB      ") Status: "
StatusB DB      8 DUP ('0'), "b "
StatusO DB      3 DUP ('0'), "o "
StatusD DB      3 DUP ('0'), "d "
StatusH DB      2 DUP ('0'), "h"
        DB      CRLF
        DB      '$'

END Start
