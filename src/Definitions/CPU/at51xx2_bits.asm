;---------------------------------------------------------------------
; Non bit addressable register bits
;---------------------------------------------------------------------

; Generic bit definitions
;--------------------------------------------
    .equ BIT0, 0b00000001
    .equ BIT1, 0b00000010
    .equ BIT2, 0b00000100
    .equ BIT3, 0b00001000
    .equ BIT4, 0b00010000
    .equ BIT5, 0b00100000
    .equ BIT6, 0b01000000
    .equ BIT7, 0b10000000

; AUXR
;--------------------------------------------
    .equ DPU,       BIT7
    .equ WS1,       BIT6
    .equ WS0,       BIT5
    .equ XRS2,      BIT4
    .equ XRS1,      BIT3
    .equ XRS0,      BIT2
    .equ EXTRAM,    BIT1
    .equ AO,        BIT0

; AUXR1
;--------------------------------------------
    .equ ENBOOT,    BIT5    ; Map bootloader to 0xF800-0xFFFF
    .equ XSTK,      BIT4    ; Extended stack enable
    .equ GF3,       BIT3    ; General purpose user flag
    .equ DPS,       BIT0    ; Data pointer select

; WDTPRG
;--------------------------------------------
    .equ WDTOVF,    BIT7    ; Watchdog overflow flag
    .equ SWRST,     BIT6    ; Software reset flag
    .equ WDTEN,     BIT5    ; Watchdog enable flag
    .equ WDIDLE,    BIT4    ; WDT disable during idle
    .equ DISRTO,    BIT3    ; Disable reset output
    .equ WTO2,      BIT2    ; Watchdog timeout
    .equ WTO1,      BIT1    ; ^
    .equ WTO0,      BIT0    ; ^

; TMOD
;--------------------------------------------
    .equ GATE1,     BIT7    ; Timer 1 gate control
    .equ CT1,       BIT6    ; Timer or counter selector 1
    .equ T1M1,      BIT5    ; Timer 1 operating mode
    .equ T1M0,      BIT4    ; ^
    .equ GATE0,     BIT3    ; Timer 0 gating control
    .equ CT0,       BIT2    ; Timer or counter select 0
    .equ T0M1,      BIT1    ; Timer 0 operating mode
    .equ T0M0,      BIT0    ; ^

; IPH0
;--------------------------------------------
    .equ IP1DIS,    BIT7    ; Interrupt level 1 disable
    .equ PPCH,      BIT6    ; PCA interrupt priority high
    .equ PT2H,      BIT5    ; Timer 2 interrupt priority high
    .equ PSH,       BIT4    ; Serial port interrupt priority high
    .equ PT1H,      BIT3    ; Timer 1 interrupt priority high
    .equ PX1H,      BIT2    ; External interrupt 1 priority high
    .equ PT0H,      BIT1    ; Timer 0 interrupt priority high
    .equ PX0H,      BIT0    ; External interrupt 0 priority high

; DADC
;--------------------------------------------
    .equ ADIF,      BIT7    ; ADC interrupt flag
    .equ GO_BSY,    BIT6    ; Conversion start/busy flag
    .equ DAC,       BIT5    ; Digital-to-analog conversion enable
    .equ ADCE,      BIT4    ; DADC enable
    .equ LADJ,      BIT3    ; Left adjust enable
    .equ ACK2,      BIT2    ; DADC clock select
    .equ ACK1,      BIT1    ; ^
    .equ ACK0,      BIT0    ; ^

; DADI
;--------------------------------------------
    .equ ACON,      BIT7
    .equ IREF,      BIT6
    .equ TRG1,      BIT5
    .equ TRG0,      BIT4
    .equ DIFF,      BIT3
    .equ ACS2,      BIT2
    .equ ACS1,      BIT1
    .equ ACS0,      BIT0

; SPCON
;--------------------------------------------
    .equ SPR2,      BIT7    ; Serial peripheral clock rate 2
    .equ SPEN,      BIT6    ; Serial peripheral enable
    .equ SSDIS,     BIT5    ; Slave select disable
    .equ MSTR,      BIT4    ; Master/Slave select
    .equ CPOL,      BIT3    ; Clock polarity
    .equ CPHA,      BIT2    ; Clock phase
    .equ SPR1,      BIT1    ; Serial peripheral clock rate 1
    .equ SPR0,      BIT0    ; Serial peripheral clock rate 0

; FCON
;--------------------------------------------
    .equ FPL3,      BIT7    ; Programming launch command bits
    .equ FPL2,      BIT6    ; ^
    .equ FPL1,      BIT5    ; ^
    .equ FPL0,      BIT4    ; ^
    .equ FPS,       BIT3    ; Flash map program space
    .equ FMOD1,     BIT2    ; Flash mode
    .equ FMOD0,     BIT1    ; ^
    .equ FBUSY,     BIT0    ; Flush busy

; IPL1
;--------------------------------------------
    .equ IP2DIS,    BIT7
    .equ PADCL,     BIT5
    .equ PCMPL,     BIT4
    .equ PSPL,      BIT2
    .equ PTWL,      BIT1
    .equ PKBL,      BIT0

; IPH1
;--------------------------------------------
    .equ IP3DIS,    BIT7
    .equ PADCH,     BIT5
    .equ PCMPH,     BIT4
    .equ PSPH,      BIT2
    .equ PTWH,      BIT1
    .equ PKBH,      BIT0