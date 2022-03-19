; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Nixie
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Nixie.h.asm\
    .include \src/Headers/Render.h.asm\
    .include \src/Headers/MCP32S17.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Macro/Interrupt.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    inSlotMachine:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    nixieFrameCounter:
        .ds 2
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringNixieInit:
        .asciz /Initializing Nixies.../
    
    stringNixieReady:
        .asciz /Nixies ready./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Frame thresholds.
    ;--------------------------------------------
    .equ frameCountThreshold,       3600
    .equ slotMachineFrameThreshold, 5
    
    ; SPI
    ;--------------------------------------------
    .equ gpioAddress, 0x01
    
    ; GPIO port
    ;--------------------------------------------
    .equ nixiePort,           MCP32S17_GPIOA
    .equ leftNixieClockMask,  0b00000100
    .equ leftNixieResetMask,  0b00001000
    .equ rightNixieClockMask, 0b00010000
    .equ rightNixieResetMask, 0b00100000
    .equ modeMask, ~(leftNixieResetMask | leftNixieClockMask | rightNixieResetMask | rightNixieClockMask)
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Creates the nixie device.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
createNixieDevice:
    push a
    push r0
    push r1
    push r2
    push r3
    push dpl
    push dph
    
    mov   dptr, #stringNixieInit
    lcall stdoutSendStringFromROMNewLine
    
    mov  dptr,  #nixieFrameCounter; Reset the frame counter.
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    
    ; TODO: Combine with the current value, don't overwrite.
    mov   r0, #nixiePort          ; Set IO mode as output.
    mov   r1, #gpioAddress
    mov   r2, #modeMask
    lcall mcp32s17SetPinMode
    
    ; Reset is active low, and clock is active high.
    mov   r0, #nixiePort                                ; Port
    mov   r1, #gpioAddress                              ; SPI address
    mov   r2, #leftNixieResetMask | rightNixieResetMask ; Value
    mov   r3, #~modeMask                                ; Mask
    lcall mcp32s17WritePortMasked
    
    mov   r0, #nixie_Left         ; Reset nixies.
    lcall resetNixie
    mov   r0, #nixie_Right
    lcall resetNixie
    
    clr inSlotMachine             ; Reset slot machine mode.
    
    mov   dptr, #postFrameHandler ; Add the nixie frame function after
    lcall addPostRenderFunction   ; the graphics frame.
    
    mov   dptr, #stringNixieReady
    lcall stdoutSendStringFromROMNewLine
    
    pop dph
    pop dpl
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Returns the pin mask for a nixie based on
; the value in 'a'.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	a - Pin mask.
;--------------------------------------------
.macro getNixieMask rightNixieMask, leftNixieMask, ?selectLeftNixie, ?selectRightNixie
    jz   selectLeftNixie
    mov  a, rightNixieMask
    sjmp selectRightNixie
    selectLeftNixie:
    mov  a, leftNixieMask
    selectRightNixie:
.endm

;--------------------------------------------
; Increments the nixie counter.
;--------------------------------------------
; Parameters:
;   r0 - 0x00 for left nixie, non 0x00 for
;        right nixie.
; Returns:
;	nothing
;--------------------------------------------
incrementNixie:
    push a
    push r0
    push r1
    push r2
    push r3
    
    disableIntRestorable
    
    mov a, r0
    getNixieMask #rightNixieClockMask, #leftNixieClockMask
    
    mov   r0, #nixiePort    ; Port
    mov   r1, #gpioAddress  ; SPI address
    mov   r2, a             ; Data
    mov   r3, a             ; Mask
    lcall mcp32s17WritePortMasked
    
    mov   r0, #nixiePort    ; Port
    mov   r1, #gpioAddress  ; SPI address
    mov   r2, #0x00         ; Data
    mov   r3, a             ; Mask
    lcall mcp32s17WritePortMasked
    
    restoreInt
    
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Resets the nixie counter.
;--------------------------------------------
; Parameters:
;   r0 - 0x00 for left nixie, non 0x00 for
;        right nixie.
; Returns:
;	nothing
;--------------------------------------------
resetNixie:
    push a
    push r0
    push r1
    push r2
    push r3
    
    disableIntRestorable
    
    jnb  inSlotMachine, resetNotInSlotMachine    ; If the slot machine
    clr  inSlotMachine                           ; is active, disable
    mov  dptr,  #nixieFrameCounter               ; it, and clear the
    movx @dptr, a                                ; frame counter.
    inc  dptr
    movx @dptr, a
    resetNotInSlotMachine:

    mov a, r0
    getNixieMask #rightNixieResetMask, #leftNixieResetMask
    
    mov   r0, #nixiePort    ; Port
    mov   r1, #gpioAddress  ; SPI address
    mov   r2, #0x00         ; Data
    mov   r3, a             ; Mask
    lcall mcp32s17WritePortMasked
    
    mov   r0, #nixiePort    ; Port
    mov   r1, #gpioAddress  ; SPI address
    mov   r2, a             ; Data
    mov   r3, a             ; Mask
    lcall mcp32s17WritePortMasked
    
    restoreInt
    
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Displays a number on the nixie display.
;--------------------------------------------
; Parameters:
;   r0 - 0x00 for left nixie, non 0x00 for
;        right nixie.
;   r1 - Value.
; Returns:
;	nothing
;--------------------------------------------
displayNixie:
    push a
    push r1
    
    lcall resetNixie     ; Get to a known state (0)
    
    mov a, r1
    jz  zeroNixie
    
    nixieIncrementLoop:  ; Increment by one, till it reaches the
    lcall incrementNixie ; specified value.
    djnz  r1, nixieIncrementLoop
    
    zeroNixie:
    
    pop r1
    pop a
    ret

postFrameHandler:
    jb   inSlotMachine, nextSlotMachine
    
    push a
    push r0
    push r1
    push dpl
    push dph

    mov  dptr,  #nixieFrameCounter ; Get the frame counter and add one
    movx a,     @dptr              ; Lower byte
    add  a,     #1
    movx @dptr, a
    mov  r0,    a
    inc  dptr
    movx a,     @dptr              ; Upper byte
    addc a,     #0
    movx @dptr, a
    mov  r1,    a
    
    mov  a, r0                     ; Only continue if the frame
    clr  c                         ; counter is over the threshold.
    subb a, #<frameCountThreshold
    mov  a, r1
    subb a, #>frameCountThreshold
    jc   underThreshold
    
    mov  dptr,  #nixieFrameCounter ; Reset the frame counter.
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a

    setb inSlotMachine             ; Enter slot machine mode.
    
    underThreshold:
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret

nextSlotMachine:
    push a
    push r0
    push r1
    push dpl
    push dph

    mov  dptr,  #nixieFrameCounter ; Get the slot machine frames
    movx a,     @dptr              ; and add one.
    inc  a                         ; It's always under 255,
    movx @dptr, a                  ; only use the lower byte.

    clr  c                         ; Check if it's at threshold.
    subb a, #slotMachineFrameThreshold
    jc   underSlotMachineThreshold
    
    clr  a                         ; Clear the counter.
    movx @dptr, a
    
    mov   r0, #nixie_Left          ; Increment left nixie.
    lcall incrementNixie
    mov   r0, #nixie_Right         ; Increment right nixie.
    lcall incrementNixie
    
    inc  dptr                      ; Use upper byte to count slot
    movx a,     @dptr              ; machine iterations.
    inc  a
    movx @dptr, a

    clr  c                         ; Check if a full rotation is
    subb a, #10                    ; complete.
    jc   noFullRotation
    
    clr inSlotMachine              ; Exit slot machine mode.

    mov  dptr,  #nixieFrameCounter ; Reset the frame counter.
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    
    noFullRotation:
    underSlotMachineThreshold:
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret