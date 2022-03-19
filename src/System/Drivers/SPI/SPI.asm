; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module SPI
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/SPI.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/IntegerMath.h.asm\
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
    stringInit:
        .asciz /Configuring SPI port.../
    stringDivider0:
        .asciz / Clock divider is set to /
    stringDivider1:
        .asciz /./
    stringReady:
        .asciz /SPI port ready./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ addressBit0,           P1.0
    .equ addressBit1,           P1.1
    .equ addressBit2,           P1.2
    .equ addressDecoderEnable,  P1.3
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Configures the SPI port.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	r0 - Status code.
;--------------------------------------------
configureSPI:
    push dpl
    push dph
    
    mov   dptr, #stringInit              ; Send the init text
    lcall stdoutSendStringFromROMNewLine
    
    ; Enable, Slave select disable, master mode, fPERIPH/64
    mov   SPCON, #SPEN | SSDIS | MSTR | SPR2 | SPR0
    
    mov   dptr, #stringDivider0          ; Clock divider is set to...
    lcall stdoutSendStringFromROM
    lcall spiGetDivider                  ; ... n ...
    lcall stdoutSendFullHex
    mov   dptr, #stringDivider1          ; ....
    lcall stdoutSendStringFromROMNewLine
    
    mov   SPSTA, #0                      ; Clear flags, MSB first,
                                         ; REMAP = 0
    
    anl   P1M0,  #~(P1M0_0 | P1M0_1 | P1M0_2 | P1M0_3) ; Setup port
    orl   P1M1,  #P1M1_0 | P1M1_1 | P1M1_2 | P1M1_3    ; registers.
    
    mov   dptr, #stringReady             ; Send ready text
    lcall stdoutSendStringFromROMNewLine
    
    mov   r0, #success                   ; Set the status code
    
    pop dph
    pop dpl
    ret

;--------------------------------------------
; Changes the speed of the spi port.
;--------------------------------------------
; Parameters:
;	r0 - Speed: fPERIPH/(2^(r0 + 1))
; Returns:
;	nothing
;--------------------------------------------
spiChangeSpeed:
    push acc
    
    mov a,   r0       ; Move the 3rd bit to the 8th position and mask
    mov c,   a.2      ; the rest.
    mov a.7, c
    anl a,   #0b10000011
    
    anl SPCON, #0b01111100  ; Set the clock bits.
    orl SPCON, a
    
    pop acc
    ret

;--------------------------------------------
; Returns the clock divider for the spi
; port.
; TODO: Make it accurate for T1 overflow/2.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   r0 - divider
;--------------------------------------------
spiGetDivider:
    push a
    push r1
    
    mov a, SPCON     ; Read port config register.
    
    mov c, a.7       ; Move the 8th bit to the 3rd position and
    mov a.2, c       ; mask the rest.
    anl a, #0b00000111
    
    inc   a          ; +1
    mov   r0, #2     ; 2^value in register
    mov   r1, a
    lcall powerOf
    
    pop r1
    pop a
    ret

;--------------------------------------------
; Selects an SPI device on the bus.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   r0 - device address
;--------------------------------------------
spiSelectDevice:
    push acc
    
    disableIntRestorable
    
    mov a, r0
    mov c, a.2          ; Lower bit
    mov addressBit0, c
    mov c, a.1          ; Middle bit
    mov addressBit1, c
    mov c, a.0          ; Upper bit
    mov addressBit2, c
    
    clr addressDecoderEnable ; Enable the address decoder and buffers.
    
    restoreInt
    
    pop acc
    ret

;--------------------------------------------
; Disables the currently selected SPI device.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
spiDisableDevice:
    setb addressDecoderEnable
    ret