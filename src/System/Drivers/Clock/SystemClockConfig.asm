; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module SystemClockConfig
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Clocks.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
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
    stringInit:
        .asciz /Configuring system clocks./
    stringReady:
        .asciz /System clocks configured./
    stringTpsSet:
        .asciz / TPS is set to: /
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ tps,   7 ; +1
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Configures the system clocks.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   r0 - status code
;--------------------------------------------
configureSystemClocks:
    push dpl
    push dph
    
    mov   dptr, #stringInit         ; Print the init text.
    lcall stdoutSendStringFromROMNewLine
    
    lcall configTPS                 ; tps
    
    ; TODO: Set the clocks that can be set with fuses to make sure
    ; the system works with misconfigured fuses.
    
    mov   dptr, #stringReady        ; Print the ready text.
    lcall stdoutSendStringFromROMNewLine
    
    mov   r0,   #success            ; Set status code to success.
    
    pop dph
    pop dpl
    ret

;--------------------------------------------
; Configures the tps.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
configTPS:
    push r0
    push dpl
    push dph
    
    mov r0, #tps                    ; Set the tps.
    lcall setTPS
    inc r0 ; tps is always 1 + the value
    
    mov dptr, #stringTpsSet         ; Print the value.
    lcall stdoutSendStringFromROM
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine
    
    pop dph
    pop dpl
    pop r0
    ret