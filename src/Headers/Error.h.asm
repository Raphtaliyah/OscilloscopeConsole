; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Error.h.asm
    .define Error.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl setLastError, getLastError, getLastErrorAddress
    
;---------------------------------------------------------------------
; Error definitions
;---------------------------------------------------------------------
    .equ ERR_UNDEFINED,  0x00
    .equ ERR_NO_SPACE,   0x01
    .equ ERR_NO_MATCH,   0x02
    .equ ERR_INVALID_OP, 0x03
    
    .endif