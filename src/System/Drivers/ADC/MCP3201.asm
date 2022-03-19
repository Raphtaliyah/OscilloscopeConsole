; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MCP3201Driver
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/MCP3201.h.asm\
    .include \src/Headers/Spi.h.asm\
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
    .equ spiClockRate,  SPI_DIV16
    .equ dummyByte,     0xFF
    .equ highByteMask,  0b00011111
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Reads the analog value from an MCP3201 ADC.
;--------------------------------------------
; Parameters:
;   r0    - SPI address of the device.
; Returns:
;   r0:r1 - the 12 bit value.
;--------------------------------------------
mcp3201ReadAnalog:
    push acc
    
    push  r0                    ; Set SPI speed.
    mov   r0, #spiClockRate
    lcall spiChangeSpeed
    
    pop r0                      ; Select device.
    lcall spiSelectDevice
    
    mov SPDAT, #dummyByte       ; Get the high byte.
    waitSPItranfer
    mov a,     SPDAT
    anl a,     #highByteMask
    clr c   ; The lower byte will have D1 as the lowest byte,
    rrc a   ; this fixes that.
    mov r1,    a
    
    mov SPDAT, #dummyByte       ; Get the low byte.
    waitSPItranfer
    mov a,     SPDAT
    rrc a                       ; Remove the duplicate bit.
    mov r0, a
    
    lcall spiDisableDevice      ; Disable device.
    
    pop acc
    ret