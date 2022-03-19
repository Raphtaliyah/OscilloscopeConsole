; Calls the address in dptr
; note: cannot be used for functions expecting data in 'a' or dptr
.macro callDptr, ?returnAddress
    push a
    
    ; Push return address
    mov a, #<returnAddress
    push a
    mov a, #>returnAddress
    push a

    ; Jump to dptr
    clr a
    jmp @a + dptr

    returnAddress:
    pop a
.endm