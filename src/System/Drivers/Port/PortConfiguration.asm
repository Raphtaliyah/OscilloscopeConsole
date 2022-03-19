; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module PortConfiguration
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    
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
    .equ P0M0, 0xE6
    .equ P0M1, 0xE7
    .equ P1M0, 0xD6
    .equ P1M1, 0xD7
    .equ P2M0, 0xCE
    .equ P2M1, 0xCF
    .equ P3M0, 0xC6
    .equ P3M1, 0xC7
    .equ P4M0, 0xBE
    .equ P4M1, 0xBF
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Configures the mode of a pin on a port.
;--------------------------------------------
; Parameters:
;   r0 - Port
;   r1 - Pins (bit field)
;   r2 - Mode
; Returns:
;   nothing
;--------------------------------------------
pinMode:
    push a
    push r1
    push r2
    push r3
    push r4

    mov  a,   r2            ; Create the lower mode mask for the pins.
    mov  r3,  #0x00         ; Extend acc bit 0, and with pin mask,
    jb   a.0, accBit0Is0    ; store it in r3.
    mov  r3,  #0xFF
    accBit0Is0:
    mov  a,   r3
    anl  a,   r1
    mov  r3,  a

    mov  a,   r2            ; Create the upper mode mask for the pins.
    mov  r4,  #0x00         ; Extend acc bit 1, and with pin mask,
    jb   a.1, accBit1Is0    ; store it in r4.
    mov  r4,  #0xFF
    accBit1Is0:
    mov  a,   r4
    anl  a,   r1
    mov  r4,  a
    
    mov a, r1               ; Create an inverse mask of the pin mask.
    cpl a
    mov r1, a
    
    cjne r0, #0, notPort0   ; Set the port mode.
    mov a,    P0M0   ; Clear the pin bits in the port mode0 register.
    anl a,    r1
    orl a,    r2     ; Apply lower mode mask.
    mov P0M0, a      ; Set the mode.
    
    mov a,    P0M1   ; Clear the pin bits in the port mode1 register.
    anl a,    r1
    orl a,    r3     ; Apply upper mode mask.
    mov P0M1, a      ; Set the mode.
    
    notPort0:
    cjne r0, #1, notPort1
    mov a,    P1M0   ; Clear the pin bits in the port mode0 register.
    anl a,    r1
    orl a,    r2     ; Apply lower mode mask.
    mov P1M0, a      ; Set the mode.
    
    mov a,    P1M1   ; Clear the pin bits in the port mode1 register.
    anl a,    r1
    orl a,    r3     ; Apply upper mode mask.
    mov P1M1, a      ; Set the mode.
    
    notPort1:
    cjne r0, #2, notPort2
    mov a,    P2M0   ; Clear the pin bits in the port mode0 register.
    anl a,    r1
    orl a,    r2     ; Apply lower mode mask.
    mov P2M0, a      ; Set the mode.
    
    mov a,    P2M1   ; Clear the pin bits in the port mode1 register.
    anl a,    r1
    orl a,    r3     ; Apply upper mode mask.
    mov P2M1, a      ; Set the mode.
    
    notPort2:
    cjne r0, #3, notPort3
    mov a,    P3M0   ; Clear the pin bits in the port mode0 register.
    anl a,    r1
    orl a,    r2     ; Apply lower mode mask.
    mov P3M0, a      ; Set the mode.
    
    mov a,    P3M1   ; Clear the pin bits in the port mode1 register.
    anl a,    r1
    orl a,    r3     ; Apply upper mode mask.
    mov P3M1, a      ; Set the mode.
    
    notPort3:
    cjne r0, #4, notPort4
    mov a,    P4M0   ; Clear the pin bits in the port mode0 register.
    anl a,    r1
    orl a,    r2     ; Apply lower mode mask.
    mov P4M0, a      ; Set the mode.
    
    mov a,    P4M1   ; Clear the pin bits in the port mode1 register.
    anl a,    r1
    orl a,    r3     ; Apply upper mode mask.
    mov P4M1, a      ; Set the mode.
    
    notPort4:
    
    pop r4
    pop r3
    pop r2
    pop r1
    pop a
    ret