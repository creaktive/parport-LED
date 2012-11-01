        IDEAL
        MODEL small

        DATASEG
        CODESEG

GLOBAL	Bin2ASC:PROC

;**********************************************************
; Bin2ASC: Converts binary number to ASCII string
;**********************************************************
; # Input:
;       AX = 16-bit value
;       BX = result's base (2 <= BX <= 16)
;       CX = minimum size of string (fills with '0' if smaller)
;       DI = ASCII string offset
; # Output:
;       NONE
; # Registers:
;       NONE
;**********************************************************
PROC    Bin2ASC
        push    ax
        push    cx
        push    dx
        push    di
        push    si

        xor     si, si
        jcxz    @@40

@@10:
        xor     dx, dx
        div     bx

        cmp     dl, 10
        jb      @@20
        add     dl, 'A' - 10
        jmp     short @@30

@@20:
        or      dl, '0'

@@30:
        push    dx
        inc     si
        loop    @@10

@@40:
        inc     cx
        or      ax, ax
        jnz     @@10
        mov     cx, si
        jcxz    @@60
        cld

@@50:
        pop     ax
        stosb
        loop    @@50

@@60:
;        mov     BYTE PTR [di], 0h
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     ax

        ret
ENDP    Bin2ASC

END
