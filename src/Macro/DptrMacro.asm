;--------------------------------------------
; Calls the function at the address in dptr.
;--------------------------------------------
; Parameters:
; 	dptr - The address of the function.
; Returns:
; 	nothing
;--------------------------------------------
.macro .calldptr, ?returnAddress
    push a                  ; Don't trash acc
    mov  a, #<returnAddress ; Lower half of return address
    push a
    mov  a, #>returnAddress ; Upper half of return address
    clr  a                  ; Zero a for the jump
    jmp  @a + dptr          ; jump!
    
    returnAddress:
    pop a                   ; Restore acc
.endm

;--------------------------------------------
; Adds an 8 bit constant to dptr.
;--------------------------------------------
; Parameters:
; 	d - The 8 bit value to add to dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addDptr8imm, d
.iflt (d - 8)   ; If d is less than or equal to 8, use increments
    .rept d
    inc dptr    ; (2) Increment dptr 'd' times
    .endm
.else
    push a      ; (2) Preserve acc
    mov  a, d   ; (2) Add 'd' to low byte
    add  a, dpl ; (2)
    mov  dpl, a ; (2)
    clr  a      ; (1)
    addc a, dph ; (2) Add 0 to high byte
    mov  dph, a ; (2)
    pop  a      ; (2) Restore acc
                ; (15 cycles)
.endif
.endm

;--------------------------------------------
; Adds an 8 bit constant to the alt dptr.
;--------------------------------------------
; Parameters:
; 	d - The 8 bit value to add to the alt dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addAltDptr8imm, d
.iflt (d - 5)    ; If d is less than or equal to 5, use increments
    .rept d
    inc /dptr    ; (3) Increment dptr 'd' times
    .endm
.else
    push a       ; (2) Preserve acc
    mov  a, d    ; (2) Add 'd' to low byte
    add  a, dplb ; (2)
    mov  dplb, a ; (2)
    clr  a       ; (1)
    addc a, dphb ; (2) Add 0 to high byte
    mov  dphb, a ; (2)
    pop  a       ; (2) Restore acc
                 ; (15 cycles)
.endif
.endm

;--------------------------------------------
; Adds an 8 bit value to dptr.
;--------------------------------------------
; Parameters:
; 	d - The 8 bit value to add to dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addDptr8, d
    push a
    mov  a, d
    add  a, dpl
    mov  dpl, a
    clr  a
    addc a, dph
    mov  dph, a
    pop  a
.endm

;--------------------------------------------
; Adds an 8 bit value to the alt dptr.
;--------------------------------------------
; Parameters:
; 	d - The 8 bit value to add to the alt dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addAltDptr8, d
    push a
    mov  a, d
    add  a, dplb
    mov  dplb, a
    clr  a
    addc a, dphb
    mov  dphb, a
    pop  a
.endm

;--------------------------------------------
; Adds a 16 bit constant to dptr.
;--------------------------------------------
; Parameters:
; 	d - The 16 bit constant to add to dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addDptr16imm, d
    push a
    mov  a, #<d
    add  a, dpl
    mov  dpl, a
    mov  a, #>d
    addc a, dph
    mov  dph, a
    pop  a
.endm

;--------------------------------------------
; Adds a 16 bit constant to the alt dptr.
;--------------------------------------------
; Parameters:
; 	d - The 16 bit constant to add to the alt dptr.
; Returns:
; 	nothing
;--------------------------------------------
.macro .addAltDptr16imm, d
    push a
    mov  a, #<d
    add  a, dplb
    mov  dplb, a
    mov  a, #>d
    addc a, dphb
    mov  dphb, a
    pop  a
.endm

;--------------------------------------------
; Adds two 8 bit values to dptr.
;--------------------------------------------
; Parameters:
; 	low  - low byte
;   high - high byte
; Returns:
; 	nothing
;--------------------------------------------
.macro .addDptr16, low, high
    push a
    mov  a, low
    add  a, dpl
    mov  dpl, a
    mov  a, high
    addc a, dph
    mov  dph, a
    pop  a
.endm

;--------------------------------------------
; Adds two 8 bit values to the alt dptr.
;--------------------------------------------
; Parameters:
; 	low  - low byte
;   high - high byte
; Returns:
; 	nothing
;--------------------------------------------
.macro .addAltDptr16, low, high
    push a
    mov  a, low
    add  a, dplb
    mov  dplb, a
    mov  a, high
    addc a, dphb
    mov  dphb, a
    pop  a
.endm

;--------------------------------------------
; Swaps the dptr and the alt dptr.
;--------------------------------------------
; Parameters:
; 	none
; Returns:
; 	nothing
;--------------------------------------------
.macro .swapDptr
    inc AUXR1
.endm

;--------------------------------------------
; Pushes the dptr onto the stack.
;--------------------------------------------
; Parameters:
; 	none
; Returns:
; 	nothing
;--------------------------------------------
.macro .pushDptr
    push dpl
    push dph
.endm

;--------------------------------------------
; Pushes the alt dptr onto the stack.
;--------------------------------------------
; Parameters:
; 	none
; Returns:
; 	nothing
;--------------------------------------------
.macro .pushAltDptr
    push dplb
    push dphb
.endm

;--------------------------------------------
; Pops the dptr from the stack.
;--------------------------------------------
; Parameters:
; 	none
; Returns:
; 	nothing
;--------------------------------------------
.macro .popDptr
    pop dph
    pop dpl
.endm

;--------------------------------------------
; Pops the alt dptr from the stack.
;--------------------------------------------
; Parameters:
; 	none
; Returns:
; 	nothing
;--------------------------------------------
.macro .popAltDptr
    pop dphb
    pop dplb
.endm