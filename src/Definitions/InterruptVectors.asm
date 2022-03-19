; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Interrupt vectors
;---------------------------------------------------------------------
    .equ    RESET_VECTOR,       0x00
    .equ    EXTERNAL0_VECTOR,   0x03
    .equ    TIMER0_VECTOR,      0x0B
    .equ    EXTERNAL1_VECTOR,   0x13
    .equ    TIMER1_VECTOR,      0x1B
    .equ    SERIAL_VECTOR,      0x23
    .equ    TIMER2_VECTOR,      0x2B
    .equ    PCA_VECTOR,         0x33
    .equ    KEYBOARD_VECTOR,    0x3B
    .equ    TWOWIRE_VECTOR,     0x43
    .equ    SPI_VECTOR,         0x4B
    ; 053h is reserved
    .equ    ANALOGCOMP_VECOTR,  0x5B
    .equ    ADC_VECTOR,         0x63