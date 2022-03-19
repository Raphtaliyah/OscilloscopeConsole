; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module StringUtilities
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl romStringLength
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

; Returns the length of a string in ROM
; Parameters:
; dptr - pointer to string
; Returns:
; r0:r1 - length
romStringLength:
    ; Push registers
    push acc
    push dpl
    push dph
    push dplb
    push dphb

    ; Counter
    mov /dptr, #0
    
    lengthCountLoop:
    
    ; Load character
    clr a
    movc a, @a + dptr
    
    ; Is it null?
    jz endFound

    ; Nope, go next
    inc dptr
    inc /dptr
    sjmp lengthCountLoop
    endFound:
    
    ; Move the length to r0:r1
    mov r0, dplb
    mov r1, dphb

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret