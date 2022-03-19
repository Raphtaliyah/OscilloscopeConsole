; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef ApplicationManager.h.asm
    .define ApplicationManager.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl createApplicationManager, enterApplicationMode
    .globl setApplicationStdout, getCurrentStdout
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \Application.h.asm\
    
    .endif