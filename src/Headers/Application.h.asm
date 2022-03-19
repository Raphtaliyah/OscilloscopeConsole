; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Application.h.asm
    .define Application.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl runApplication, getCurrentApplication, createApplication
    .globl defaultApplicationMessageHandler, sendApplicationMessage
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Application messages
    ;--------------------------------------------
    .equ AMSG_DUMMY,  0x00
    .equ AMSG_DRAW,   0x01
    .equ AMSG_EXIT,   0x02
    
    ; Exit codes
    ;--------------------------------------------
    .equ EXIT_NOERROR, 0x00
    
    .endif