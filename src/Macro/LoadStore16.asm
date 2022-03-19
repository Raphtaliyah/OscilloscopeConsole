; Writes an 16 bit data to @dptr + offset
; note: overwrites 'a' register
.macro write16ToDptrWithOffset lData, hData, offset
    ; Push the address
    push dpl
    push dph

    ; Add offset to dptr
    mov a, offset
    add a, dpl
    mov dpl, a
    clr a
    addc a, dph
    mov dph, a

    ; Write the low data to the address
    mov a, lData
    movx @dptr, a

    ; Write the high data
    inc dptr
    mov a, hData
    movx @dptr, a

    ; Pop the address
    pop dph
    pop dpl
.endm

; Reads 16 bit data from @dptr + offset to r0:r1
; note: overwrites 'a' register
.macro read16FromDptrWithOffset offset
    ; Push the address
    push dpl
    push dph

    ; Add offset to dptr
    mov a, offset
    add a, dpl
    mov dpl, a
    clr a
    addc a, dph
    mov dph, a

    ; Read the lower data
    movx a, @dptr
    mov r0, a

    ; Read the upper data
    inc dptr
    movx a, @dptr
    mov r1, a

    ; Pop the address
    pop dph
    pop dpl
.endm