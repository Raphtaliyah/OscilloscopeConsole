; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Stack.h.asm
    .define Stack.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl bp, fp, createParamStack
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------

;--------------------------------------------
; Creates a stack frame with the specified
; size.
;--------------------------------------------
; Parameters:
;	frameSize - The size of the frame.
; Returns:
;	nothing
;--------------------------------------------
.macro ENTER, frameSize
    push bp
    mov  bp,        fp
    mov  a,         fp
    add  a,         frameSize
    mov  frameSize, fp
.endm

;--------------------------------------------
; Leaves the current stack frame.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
.macro LEAVE
    mov fp, bp
    pop bp
.endm
    
    .endif