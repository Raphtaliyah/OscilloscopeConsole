; Disables global interrupts but it's restorable
.macro disableIntRestorable
    push IEN0
    clr EA
.endm

; Restores EA bit from the stack
; note: overwrites 'a' register
EAmask == 0x80
.macro restoreInt
    ; Get the byte from the stack and mask everything but EA
    pop acc
    anl a, #EAmask

    ; Clear the global int enable bit
    clr EA

    ; OR the masked byte with IEN0
    orl IEN0, a
.endm