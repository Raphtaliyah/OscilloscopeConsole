; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Display
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl initDisplay
    
    .globl pcaTakeModule
    .globl onFrameInterrupt, initFrameHandler
    .globl firstFrame
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/SpinWait.h.asm\
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
    stringStarting:
        .asciz /Starting display system./
    stringTookModule:
        .asciz /Frame timing is bound to PCA module /
    stringFailedToTakeModule:
        .asciz /Failed to take PCA module!/
    stringInitDisplayFail:
        .asciz /Failed to initialize the display system./
    stringWaitingForFrame:
        .asciz /Waiting for first frame flag.../
    stringFirstFrameOkResult:
        .asciz / OK/
    stringFirstFramedTimeoutResult:
        .asciz / Timed out/
    stringFrameTimeout:
        .ascii /First frame flag was not set in time! /
        .asciz /Potential hardware timer error./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ framePCAmodule,            0x00
    .equ waitFirstFrame,            10
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Starts the display system
; Parameters: none
; Returns:
; r0 - status code (0x00 for success, 0xFF for fail)
initDisplay:
    ; Push registers
    push acc
    push r0
    push r1
    push dpl
    push dph

    ; Print starting message
    mov dptr, #stringStarting
    lcall stdoutSendStringFromROMNewLine

    ; Take the PCA module used for timing frames
    mov r0, #framePCAmodule
    mov dptr, #onFrameInterrupt
    lcall pcaTakeModule

    ; Validate that the module was successfuly taken
    mov a, r0
    jz frameTimerSuccessfulyTaken
    ; Failed?
    mov dptr, #stringFailedToTakeModule
    lcall stdoutSendStringFromROMNewLine
    sjmp initDisplayFailed
    frameTimerSuccessfulyTaken:
    
    ; Print the module that does the frame timing
    mov dptr, #stringTookModule
    lcall stdoutSendStringFromROM
    mov r0, #framePCAmodule
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine

    ; Init the frame handler
    lcall initFrameHandler

    ; Print waiting for frame message
    mov dptr, #stringWaitingForFrame
    lcall stdoutSendStringFromROM

    ; Wait for first frame
    mov r1, #waitFirstFrame
    fistFrameWaitLoop:
    ; Wait for ~10 ms
    mov r0, #10
    lcall spinWaitMilliseconds
    ; Frame happened since?
    jb firstFrame, frameNoTimeout
    ; No, wait more or crash
    djnz r1, fistFrameWaitLoop
    ; timeout, print the status and the message
    mov dptr, #stringFirstFramedTimeoutResult
    lcall stdoutSendStringFromROMNewLine
    mov dptr, #stringFrameTimeout
    lcall stdoutSendStringFromROMNewLine
    ; TODO: Crash
    sjmp .
    frameNoTimeout:

    ; Print that the flag was set
    mov dptr, #stringFirstFrameOkResult
    lcall stdoutSendStringFromROMNewLine
    
    displayInitExit:

    ; Pop registers
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret

initDisplayFailed:
    ; Print the fail message
    mov dptr, #stringInitDisplayFail
    lcall stdoutSendStringFromROMNewLine
    
    ; Jump back to exit the function
    sjmp displayInitExit