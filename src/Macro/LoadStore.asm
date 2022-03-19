; Loads a pointer from an address
; 'pointer' is a constant
.macro ldVarDptr, pointer
    push acc            ; Save 'a'
    
    mov dptr, pointer   ; Load and push first byte from pointer
    movx a, @dptr
    push acc
    inc dptr
    movx a, @dptr       ; Load second byte and move it to dph
    mov dph, a
    pop dpl             ; Pop first byte into dpl
    
    pop acc             ; Restore 'a'
.endm

; Loads a pointer from an address in dptr
.macro ldPtrFromDptr
    push acc            ; Save 'a'
    
    movx a, @dptr       ; Load and push first byte
    push acc
    inc dptr
    movx a, @dptr       ; Load second byte and move it to dph
    mov dph, a
    pop dpl             ; Pop first byte into dpl
    
    pop acc             ; Restore 'a'
.endm

; Writes a 16 bit constant to where dptr points
.macro writeVarDptr16, value
    ; Push registers
    push dpl
    push dph

    ; Write lower byte
    mov a, #<value
    movx @dptr, a
    
    ; Write upper byte
    inc dptr
    mov a, #>value
    movx @dptr, a

    ; Pop registers
    pop dph
    pop dpl
.endm

; Writes the 16 bit data in /dptr to the address dptr points to
; note: overwrites 'a' register
.macro writeADptrToDptr
    ; Push registers
    push dpl
    push dph
    push dplb
    push dphb

    ; Write low byte
    mov a, dplb
    movx @dptr, a

    ; Write high byte
    inc dptr
    mov a, dphb
    movx @dptr, a

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
.endm

; Writes an 8 bit data to @dptr + offset
.macro writeToDptrWithOffset data, offset
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

    ; Write the data to the address
    mov a, data
    movx @dptr, a

    ; Pop the address
    pop dph
    pop dpl
.endm

; Reads 8 bit data from @dptr + offset to r0
; note: overwrites 'a' register
.macro readFromDptrWithOffset offset
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

    ; Read the data
    movx a, @dptr
    mov r0, a

    ; Pop the address
    pop dph
    pop dpl
.endm