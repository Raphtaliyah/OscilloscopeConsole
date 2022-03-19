; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef MemoryController.h.asm
    .define MemoryController.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl memorySetWaitStates, memoryMapFullExternal
    .globl memorySetInternalRamSize, memoryALEmode
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Internal memory sizes.
    ;--------------------------------------------
    .equ internal256,   0x00
    .equ internal512,   0x01
    .equ internal768,   0x02
    .equ internal1024,  0x03
    .equ internal1792,  0x04
    .equ internal2048,  0x05

    .endif