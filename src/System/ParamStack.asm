; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module ParamStack
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Stack.h.asm\
    .include \src/Macro/Interrupt.asm\
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
    ; Base pointer
    ;--------------------------------------------
    bp:
        .ds 1
    
    ; Frame pointer
    ;--------------------------------------------
    fp:
        .ds 1
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ stackStart, 0x80
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

createParamStack:
    mov fp, #stackStart
    mov bp, fp
    ret