; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module FrameHandler
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl setFrameHandlerCallback, getFrameCounter
    .globl getDelayedFrameCounter, onFrameInterrupt, initFrameHandler
    .globl firstFrame
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/PCA.h.asm\
    .include \src/Macro/Interrupt.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
    frameCallback:
        .ds 2
    frameCounter:
        .ds 3
    delayedFrames:
        .ds 2
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    inFrame: ; A frame is currently being rendered
        .ds 1
    attemptedNewFrame: ; Attempted to start a new frame while inFrame as set
        .ds 1
    frameCallbackWarningSent: ; No frame callback is set warning
        .ds 1
    firstFrame: ; Gets set on the first frame
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringFrameCallbackEmptyWarning:
        .ascii / [Warning! No frame callback was set. /
        .asciz /This warning will only be displayed once.] /
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ frameCoolDown,          9375  ; 3ms
    .equ nextFrame,             52081 ; ~60FPS
    .equ handlerSwapThreshold,     15 ; 0.25 sec to change frame handler
    .equ moduleControlRegister,     CCAPM0
    .equ moduleRegisterLow,         CCAP0L
    .equ moduleRegisterHigh,        CCAP0H
    .equ moduleInterruptFlag,       CCF0
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Initializes the frame handler
initFrameHandler:
    ; Push registers
    push acc
    push dpl
    push dph

    ; Clear flags
    clr inFrame
    clr attemptedNewFrame
    clr frameCallbackWarningSent
    clr firstFrame

    ; Set frame callback
    mov dptr, #frameCallback
    mov a, #<defaultFrameHandler
    movx @dptr, a
    inc dptr
    mov a, #>defaultFrameHandler
    movx @dptr, a

    ; Reset frame counters
    ; Frame counter
    mov dptr, #frameCounter
    clr a
    ; Low
    movx @dptr, a
    ; Middle
    inc dptr
    movx @dptr, a
    ; Upper
    inc dptr
    movx @dptr, a

    ; Delayed frame counter
    mov dptr, #delayedFrames
    clr a
    ; Low
    movx @dptr, a
    ; Upper
    inc dptr
    movx @dptr, a

    ; Setup the PCA module
    ; Set the register to 0:0
    mov moduleRegisterLow, #0
    mov moduleRegisterHigh, #0

    ; Enable module, Match enable, Enbal CCF interrupt
    mov moduleControlRegister, #ECOM | MAT | ECCF
    
    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Sets the frame handler callback
; Parameters:
; dptr - pointer to the function
; Returns: none
setFrameHandlerCallback:
    ; Push registers
    push acc
    push dplb
    push dphb
    
    ; Disable interrupts
    disableIntRestorable
    
    ; Write the address
    inc AUXR1
    mov dptr, #frameCallback
    mov a, dplb
    movx @dptr, a
    inc dptr
    mov a, dphb
    movx @dptr, a
    inc AUXR1
    
    ; Restore interrupts
    restoreInt

    ; Pop registers
    pop dphb
    pop dplb
    pop acc
    ret

; Called when a frame interrupt happened but a frame was being rendered
; note: moved here because of the jump range of jb
frameAlreadyRendering:
    ; Push registers
    push acc
    push dpl
    push dph

    ; Set the attempted frame flag
    setb attemptedNewFrame

    ; Increment delayed frame counter
    mov dptr, #delayedFrames
    movx a, @dptr
    inc a
    movx @dptr, a
    inc dptr
    movx a, @dptr
    inc a
    movx @dptr, a

    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Called when a frame interrupt happens
onFrameInterrupt:
    ; Check if a frame is being rendered
    jb inFrame, frameAlreadyRendering
    ; Not in frame, start a new one
    setb inFrame
    
    ; Push registers
    push psw
    push acc
    push r0
    push r1
    push r2
    push r3
    push dpl
    push dph

    ; Read the current PCA counter
    lcall pcaReadValue

    ; Calculate the value for the next interrupt
    mov a, r0
    add a, #<nextFrame
    mov r0, a
    mov a, r1
    addc a, #>nextFrame
    mov r1, a
    
    ; Set the value
    ; note: the hardware protects against false matches when the value is changed
    mov moduleRegisterLow, r0
    mov moduleRegisterHigh, r1
    
    ; Increment frame counter
    mov dptr, #frameCounter
    ; Lower
    movx a, @dptr
    add a, #1
    movx @dptr, a
    ; Middle
    inc dptr
    movx a, @dptr
    addc a, #0
    movx @dptr, a
    ; Upper
    inc dptr
    movx a, @dptr
    addc a, #0
    movx @dptr, a

    ; Leave interrupt level
    ; note: this might not be safe but let's try it
    ; TODO: cleaner solution?
    ; TODO: make sure this is atleast safe
    mov a, #<leaveIntLvl
    push acc
    mov a, #>leaveIntLvl
    push acc
    reti
    leaveIntLvl:
    setb EA ; This started out as an interrupt handler, so interrupts are disabled
    
    ; Call the frame handler callback
    ldVarDptr #frameCallback
    callDptr

    ; Disable interrupts
    disableIntRestorable

    ; Check if a frame has been attempted while this was running
    jbc attemptedNewFrame, nextFrameTooSoon

    ; Check if the frame timer has to be changed
    lcall pcaReadValue
    mov r2, moduleRegisterLow
    mov r3, moduleRegisterHigh
    ; if the time to the next frame is too small (triggerValue(r2:r3) - pcaValue(r0:r1) < cooldown)
    ; increase the trigger value
    ; r2:r3 = r2:r3 - r0:r1
    mov a, r2
    clr c
    subb a, r0
    mov r2, a
    mov a, r3
    subb a, r1
    mov r3, a
    ; cooldown-r2:r3
    mov a, #<frameCoolDown
    clr c
    subb a, r2
    mov a, #>frameCoolDown
    subb a, r3
    jc enoughTimeToNextFrame
    nextFrameTooSoon:

    ; Set the trigger value to be 'frameCoolDown' later
    lcall pcaReadValue
    mov a, r0
    add a, #<frameCoolDown
    mov moduleRegisterLow, a
    mov a, r1
    addc a, #>frameCoolDown
    mov moduleRegisterHigh, a

    ; In case the interrupt happened while interrupts were disabled, clear the interrupt flag
    anl CCON, #~moduleInterruptFlag

    enoughTimeToNextFrame:

    ; Clear inFrame
    clr inFrame

    restoreInt

    ; Pop registers
    pop dph
    pop dpl
    pop r3
    pop r2
    pop r1
    pop r0
    pop acc
    pop psw
    ret

; Returns the number of frames since startup
; Parameters: none
; Returns:
; r0:r1:r2 - the number of frames
getFrameCounter:
    ; Push registers
    push acc
    push dpl
    push dph

    mov dptr, #frameCounter
    ; lower byte
    movx a, @dptr
    mov r0, a
    inc dptr
    ; middle byte
    movx a, @dptr
    mov r1, a
    inc dptr
    ; high byte
    movx a, @dptr
    mov r2, a

    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Returns the number of delayed frames since startup
; Parameters: none
; Returns:
; r0:r1 - the number of delayed frames
getDelayedFrameCounter:
    ; Push registers
    push acc
    push dpl
    push dph

    mov dptr, #frameCounter
    ; lower byte
    movx a, @dptr
    mov r0, a
    inc dptr
    ; high byte
    movx a, @dptr
    mov r1, a
    
    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Default implementation of frame handler
; signals frist frame and prints a warning after still being called for more then the set threshold
defaultFrameHandler:
    ; Push registers
    push dpl
    push dph
    push r0
    push r1
    push r2

    ; Set first frame flag
    setb firstFrame

    ; Skip if the warning have already been printed
    jb frameCallbackWarningSent, wSent

    ; Check if there have been more frames then the threshold
    lcall getFrameCounter
    mov a, r0
    clr c
    subb a, #handlerSwapThreshold
    mov a, r1
    subb a, #0
    mov a, r2
    subb a, #0
    jc wSent
    
    ; Set the warning flag to prevent printing it multiple times
    setb frameCallbackWarningSent
    
    ; Print warning
    mov dptr, #stringFrameCallbackEmptyWarning
    lcall stdoutSendStringFromROMNewLine
    
    wSent:

    ; Pop registers
    pop r2
    pop r1
    pop r0
    pop dph
    pop dpl
    ret