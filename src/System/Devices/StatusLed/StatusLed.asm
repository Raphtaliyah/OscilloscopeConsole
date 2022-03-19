; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module StatusLed
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/StatusLed.h.asm\
    .include \src/Headers/MCP32S17.h.asm\
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
    ; GPIO port
    ;--------------------------------------------
    .equ ledPort,     MCP32S17_GPIOB
    .equ redLedMask,  0b01000000
    .equ blueLedMask, 0b10000000
    
    ; SPI
    ;--------------------------------------------
    .equ gpioAddress, 0x01
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Creates the status led device.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
createStatusLedDevice:
    push r0
    push r1
    push r2

    mov r0, #ledPort        ; Set LED pins as output.
    mov r1, #gpioAddress
    mov r2, #~(redLedMask | blueLedMask)
    lcall mcp32s17SetPinMode
    
    mov r0, #0
    mov r1, #1
    lcall writeLed

    pop r2
    pop r1
    pop r0
    ret

;--------------------------------------------
; Writes to a status led.
;--------------------------------------------
; Parameters:
;	r0 - Zero for red, non zero for blue.
;   r1 - data
; Returns:
;	nothing
;--------------------------------------------
writeLed:
    push a
    push r0
    push r1
    push r2
    push r3
    
    mov a,   r1             ; Copy bit 0 to bit 6 and 7.
    mov c,   a.0
    mov a.6, c
    mov a.7, c
    mov r2,  a
    
    mov  a,  r0             ; Select the correct mask.
    jz   redLed
    mov  r3, #blueLedMask
    sjmp blueLed
    redLed:
    mov  r3, #redLedMask
    blueLed:

    disableIntRestorable
    
    mov   r0, #ledPort      ; Write to the port.
    mov   r1, #gpioAddress
    lcall mcp32s17WritePortMasked

    restoreInt
    
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret