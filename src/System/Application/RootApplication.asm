; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module RootApplication
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    ; Global symbols
    .globl rootApplicationDescriptor
    
    ; External symbols
    .globl menuAppDescriptor
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Application.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Definitions/System.asm\
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
    rootApplicationDescriptor:
        .dw stringAppName           ; name ptr
        .dw rootApplicationMain     ; entry point
        .dw rootAppMessageReceived  ; message handler
    
    stringAppName:
        .asciz /Root app/
    
    stringTerminalLoaded:
        .asciz /Starting menu.../
    
    stringFailedToLoadTerminal:
        .asciz /Failed to load menu: /
    
    stringTerminalExited:
        .asciz /Menu exited with code / 
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Root application entry point.
;--------------------------------------------
; Parameters:
;   /dptr - Arg pointer.
; Returns:
;   r0    - Exit code.
;--------------------------------------------
rootApplicationMain:
    push acc
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    ; DEBUG
    ; Create the menu app
    .globl terminalAppDescriptor
    mov dptr, #menuAppDescriptor
    mov r0, #NULL
    mov r1, #NULL
    lcall createApplication
    push dpl
    push dph
    
    ; Check for success
    mov a, r0
    jz pongLoaded
    ; Failed!
    mov dptr, #stringFailedToLoadTerminal
    lcall stdoutSendStringFromROMNewLine
    ; TODO: Crash
    sjmp .
    pongLoaded:
    
    ; Print loaded
    mov dptr, #stringTerminalLoaded
    lcall stdoutSendStringFromROMNewLine

    ; Start terminal!
    pop dph
    pop dpl
    mov /dptr, #NULL
    lcall runApplication

    ; Print exit code
    mov dptr, #stringTerminalExited
    lcall stdoutSendStringFromROM
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine
    ; DEBUG end
    
    ; Set exit code
    mov r0, #0
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

; Message handler for the app
; Parameters:
; r0    - message id
; /dptr - message object
; Returns: none
rootAppMessageReceived:
    lcall defaultApplicationMessageHandler
    ret