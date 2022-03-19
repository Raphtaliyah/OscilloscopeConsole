; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Interrupt.h.asm
    .define Interrupt.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl initInterruptSystem, onInterrupt, getInterruptCount
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Macro/Interrupt.asm\
    
    .endif