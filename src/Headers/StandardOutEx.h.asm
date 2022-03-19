; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef StandardOutEx.h.asm
    .define StandardOutEx.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl stdoutSendBuffer, stdoutSendBuffer16, stdoutSendString
    .globl stdoutSendStringNewLine, stdoutSendByteAsHexString
    .globl stdoutSendFullHex, stdoutSendFullHex16, stdoutSendFullHex32
    .globl stdoutSendStringFromROM, stdoutSendStringFromROMNewLine
    .globl stdoutSendNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    ; TODO: Include stdout
    .endif