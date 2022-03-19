; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Port.h.asm
    .define Port.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl pinMode
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Pin modes
    ;--------------------------------------------
    .equ pinMode_QuasiBidirectional, 0x0
    .equ pinMode_PushPull            0x1
    .equ pinMode_Input               0x2
    .equ pinMode_OpenDrain           0x3
    
    .endif