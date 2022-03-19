; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef SPI.h.asm
    .define SPI.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl configureSPI, spiChangeSpeed, spiSelectDevice
    .globl spiDisableDevice, spiGetDivider

;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Speed
    ;--------------------------------------------
    .equ SPI_DIV2,   0x0
    .equ SPI_DIV4,   0x1
    .equ SPI_DIV8,   0x2
    .equ SPI_DIV16,  0x3
    .equ SPI_DIV32,  0x4
    .equ SPI_DIV64,  0x8
    .equ SPI_DIV128, 0x9
    .equ SPI_T1OF2,  0xA

;---------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------

;--------------------------------------------
; Waits for an SPI transfer to complete.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
.macro waitSPItranfer, ?waitLoop
    waitLoop:
    mov a, SPSTA
    anl a, #SPIF
    jz  waitLoop
.endm

;--------------------------------------------
; Sends a byte and waits for transmission
; to complete.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
.macro sendSpiByteBlocking, byte, ?waitTrans
    mov SPDAT, byte
    
    waitTrans:
    mov a, SPSTA
    anl a, #SPIF
    jz  waitTrans
.endm

    .endif