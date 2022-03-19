; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Main
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl boot, serialIntHandler, pcaInterruptHandler
    .globl unexpectedInterrupt, onInterrupt, soundInterrupt
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Definitions/InterruptVectors.asm\
    .include \src/Macro/InterruptMacro.asm\
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
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Interrupt vectors
;--------------------------------------------
    .area VECTOR (CSEG, ABS)
    .org RESET_VECTOR
        ljmp    boot
    
    .intvector SERIAL_VECTOR,   serialIntHandler
    .intvector PCA_VECTOR,      pcaInterruptHandler
    .intvector TIMER1_VECTOR,   soundInterrupt
    
    .unusedInterrupt EXTERNAL0_VECTOR
    .unusedInterrupt EXTERNAL1_VECTOR
    .unusedInterrupt TIMER0_VECTOR
    .unusedInterrupt TIMER2_VECTOR
    .unusedInterrupt KEYBOARD_VECTOR
    .unusedInterrupt TWOWIRE_VECTOR
    .unusedInterrupt SPI_VECTOR
    .unusedInterrupt ANALOGCOMP_VECOTR
    .unusedInterrupt ADC_VECTOR