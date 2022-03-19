; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Exponentiation
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/IntegerMath.h.asm\
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

; Raises base (r0) to the power of n(r1). ; note: unsigned only
; Parameters:
; r0 - base
; r1 - exponent
; Returns:
; r0 - result
powerOf:
    ; Push registers
    push acc
    push r1
    push r2
    push b

    ; Result
    mov r2, #1
    
    ; something raised to the power of 0 is 1, don't run the loop
    mov a, r1
    jz pwDone

    expLoop:
    ; Multiply the current value with the exponent
    mov a, r2
    mov b, r0
    mul ab
    mov r2, a

    ; Go next, if needed
    djnz r1, expLoop
    pwDone:

    ; Move the result to r0
    mov r0, r2

    ; Pop registers
    pop b
    pop r2
    pop r1
    pop acc
    ret