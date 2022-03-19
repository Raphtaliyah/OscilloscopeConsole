; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Nixie.h.asm
    .define Nixie.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl createNixieDevice, resetNixie, displayNixie, incrementNixie
    
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Nixies
    ;--------------------------------------------
    .equ nixie_Right, 0xFF
    .equ nixie_Left,  0x00
    .endif