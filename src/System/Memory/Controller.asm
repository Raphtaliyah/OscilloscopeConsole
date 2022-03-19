; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MemoryController
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/MemoryController.h.asm\
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
    .area DATA  (DSEG)
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ wsMask,        0x9F
    .equ extramMask,    0xFD
    .equ sizeMask,      0xE3
    .equ aoMask,        0xFE
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Sets how many wait states to use for external memory accesses
; Parameters:
; r0 - wait states
; Returns: none
memorySetWaitStates:
    ; Push registers
    push acc
    
    ; Rotate bit 1 and 0 to bit 6 and 5
    mov a, r0
    rr a
    rr a
    rr a
    
    ; Mask the rest
    anl a, #~wsMask

    ; Disable interrupts while changing wait states
    disableIntRestorable
    
    ; Set the ws bits
    anl AUXR, #wsMask
    orl AUXR, a
    
    ; Restore interrupts
    restoreInt
    
    ; Pop registers
    pop acc
    ret

; Maps the full XDATA address space to external memory
; Parameters:
; r0 - 0x1 to map full to external
; Returns: none
memoryMapFullExternal:
    ; Push registers
    push acc

    ; Rotate bit 0 to bit 1
    mov a, r0
    rl a
    
    ; Mask the other bits
    anl a, #~extramMask
    
    ; Disable interrupts
    disableIntRestorable

    ; Set EXTRAM bit
    anl AUXR, #extramMask
    orl AUXR, a

    ; Restore interrupts
    restoreInt
    
    ; Pop registers
    pop acc
    ret

; Sets the size of the internal XDATA
; Parameters:
; r0 - size code (0x0-0x5)
; Returns: none
memorySetInternalRamSize:
    ; Push registers
    push acc
    
    ; Rotate bit 0-1-2 to 2-3-4
    mov a, r0
    rl a
    rl a

    ; Mask the other bits
    anl a, #~sizeMask
    
    ; Disable interrupts
    disableIntRestorable

    ; Set XRS0-XRS1-XRS2
    anl AUXR, #sizeMask
    orl AUXR, a

    ; Restore interrupts
    restoreInt
    
    ; Pop registers
    pop acc
    ret

; Sets the mode of the ALE signal
; Parameters:
; r0 - 0x0 always on, 0x1 only when memory is accessed
; Returns: none
memoryALEmode:
    ; Push registers
    push acc
    
    ; Mask the other bits
    mov a, r0
    anl a, #~aoMask
    
    ; Disable interrupts
    disableIntRestorable
    
    ; Set AO bit
    anl AUXR, #aoMask
    orl AUXR, a
    
    ; Restore interrrupts
    restoreInt
    
    ; Pop registers
    pop acc
    ret