; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module TLC7226Driver
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl initTLC7226
    
    .globl dacA, dacB, dacC, dacD
    
    .globl stdoutSendStringFromROMNewLine, stdoutSendStringFromROM
    .globl stdoutSendFullHex16, stdoutSendNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
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
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringAssumedAddresses0:
        .asciz /TLC7226 address range: /
    stringAssumedAddresses1:
        .asciz / - /
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ dacCount,          4
    .equ dacBaseAddress,    0x8000
    .equ dacA,              dacBaseAddress + 0
    .equ dacB,              dacBaseAddress + 1
    .equ dacC,              dacBaseAddress + 2
    .equ dacD,              dacBaseAddress + 3
    .equ defaultValue,      0x00
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Initializes the dac.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   r0 - status code
;--------------------------------------------
initTLC7226:
    push acc
    push dpl
    push dph
    push r1
    
    ; Print address range
    mov   dptr, #stringAssumedAddresses0      ; dac address range: ...
    lcall stdoutSendStringFromROM
    mov   r0,   #<dacBaseAddress              ; ...0xbaseaddress...
    mov   r1,   #>dacBaseAddress
    lcall stdoutSendFullHex16
    mov   dptr, #stringAssumedAddresses1      ; ... - ...
    lcall stdoutSendStringFromROM
    mov   r0,   #<(dacBaseAddress + dacCount - 1) ; ...0xendaddress
    mov   r1,   #>(dacBaseAddress + dacCount - 1)
    lcall stdoutSendFullHex16
    lcall stdoutSendNewLine                   ; \n
    
    mov  a, #defaultValue    ; Set all DACs to default value
    mov  dptr, #dacA
    movx @dptr, a
    mov  dptr, #dacB
    movx @dptr, a
    mov  dptr, #dacC
    movx @dptr, a
    mov  dptr, #dacD
    movx @dptr, a
    
    mov  r0,    #success     ; Set status code
    
    pop r1
    pop dph
    pop dpl
    pop acc
    ret