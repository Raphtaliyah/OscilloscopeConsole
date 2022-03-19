; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef StandardOut.h.asm
    .define StandardOut.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl initStandardOut, stdoutSendByte, stdoutGetAddress
    .globl stdoutSetFallbackFunction, stdoutEnterStandalone
    .globl stdoutLeaveStandalone
    
    .endif