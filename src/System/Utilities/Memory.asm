; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MemoryUtilities
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl loadFromROM, loadFromROM16

    .globl stdoutSendByte
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    .area DATA  (DSEG)
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Loads an array from a ROM address to a RAM address
; Parameters
; dptr  - ROM pointer
; /dptr - RAM pointer
; r0    - length
loadFromROM:
    ; Push registers
    push acc
    push r0
    push dpl
    push dph
    push dplb
    push dphb

    mov a, r0
    jz zeroLength

    loop:

    ; Load from ROM
    clr a
    movc a, @a + dptr

    ; Write to RAM
    movx @/dptr, a

    ; Increment both pointers
    inc /dptr
    inc dptr

    ; Go next
    djnz r0, loop
    zeroLength:
    
    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

; Loads an array from a ROM address to a RAM address with a 16 bit length
; Parameters
; dptr  - ROM pointer
; /dptr - RAM pointer
; r0:r1 - length
loadFromROM16:
    ; Push registers
    push acc
    push r0
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    ; r0:r1 = r0:r1 + dptr
    mov a, r0
    add a, dpl
    mov r0, a
    mov a, r1
    addc a, dph
    mov r1, a

    loop16:

    ; Load from ROM
    clr a
    movc a, @a + dptr

    ; Write to RAM
    movx @/dptr, a
    
    ; Increment both pointers
    inc /dptr
    inc dptr
    
    ; Check if the address is at the limit
    mov a, r0
    cjne a, dpl, loop16
    mov a, r1
    cjne a, dph, loop16

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret