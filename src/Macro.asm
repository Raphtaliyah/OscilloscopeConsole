; Only exists for compatibility reasons

.include "src/Macro/Buffer.asm"
.include "src/Macro/FunctionCall.asm"
;.include "src/Macro/Interrupt.asm"
.include "src/Macro/LoadStore.asm"
.include "src/Macro/LoadStore16.asm"

; Bool values
; note: some code relies on true being 0x1!
false == 0x00
true  == 0x01

; Sizes
sizeof_POINTER       == 2
sizeof_UINT32        == 4

; States
success      == 0x00
fail_generic == 0xFF

; NULL
NULL_PTR == 0x0000

; AppDescriptor type
; note: in case of ROM and RAM loads, sd loads have yet to be implemented
; App load descriptor layout:
; string ptr   - address of name
; function ptr - entry point
; message ptr  - message handler function ptr
sizeof_APPDESCRIPTOR          == 3 * sizeof_POINTER
appdescriptor_NamePtrOffset   == 0
appdescriptor_EntryPtrOffset  == appdescriptor_NamePtrOffset + sizeof_POINTER
appdescriptor_MsgRecPtrOffset == appdescriptor_EntryPtrOffset + sizeof_POINTER


; AppContext type
; App context layout:
; stringPtr    - name
; functionptr  - entry point
; functionPtr  - message received function
; ptr          - graphics context
; ptr          - parent app ptr ; note: this also defines state (app is RUNNING if it's null)
; ptr          - ptr to stdout for this app
sizeof_APPCONTEXT             == 6 * sizeof_POINTER
appcontext_NamePtrOffset      == 0
appcontext_EntryPtrOffset     == appcontext_NamePtrOffset + sizeof_POINTER
appcontext_MsgRecPtrOffset    == appcontext_EntryPtrOffset + sizeof_POINTER
appcontext_GraphicsPtrOffset  == appcontext_MsgRecPtrOffset + sizeof_POINTER
appcontext_ParentAppPtrOffset == appcontext_GraphicsPtrOffset + sizeof_POINTER
appcontext_StdoutPtrOfsset    == appcontext_ParentAppPtrOffset + sizeof_POINTER

; Registers

; CMDO
CIDL == 0b10000000
WDTE == 0b01000000
CPS1 == 0b00000100
CPS0 == 0b00000010
ECF  == 0b00000001

; CCON
CF   == 0b10000000
CR   == 0b01000000
CCF4 == 0b00010000
CCF3 == 0b00001000
CCF2 == 0b00000100
CCF1 == 0b00000010
CCF0 == 0b00000001

; CCAPMn
ECOM == 0b01000000
CAPP == 0b00100000
CAPN == 0b00010000
MAT  == 0b00001000
TOG  == 0b00000100
PWM  == 0b00000010
ECCF == 0b00000001

; AUXR1
ENBOOT == 0b00100000
XSTK   == 0b00010000
GF3    == 0b00001000
DPS    == 0b00000001

; BDRCON
BRR  == 0b00010000 ; Baud rate run control
TBCK == 0b00001000 ; Transmission baud rate select
RBCK == 0b00000100 ; Receive baud rate select
SPD  == 0b00000010 ; BRG Speed control
SRC  == 0b00000001 ; Baud rate source for mode 0

; PCON
SMOD1 == 0b10000000
SMOD0 == 0b01000000

; SCON
SM1 == 0b01000000

; SPCON
SPR2  == 0b10000000 ; SPI clock rate 2
SPEN  == 0b01000000 ; SPI enable
SSDIS == 0b00100000 ; Slave select disable
MSTR  == 0b00010000 ; Master/Slave select
CPOL  == 0b00001000 ; Clock polarity
CPHA  == 0b00000100 ; Clock phase
SPR1  == 0b00000010 ; SPI clock rate 1
SPR0  == 0b00000001 ; SPI clock rate 0

; SPSTA
SPIF  == 0b10000000 ; SPI Transfer complete interrupt flag
WCIK  == 0b01000000 ; Write collision flag
SSERR == 0b00100000 ; SS Slave error flag
MODF  == 0b00010000 ; Mode fault flag
TXE   == 0b00001000 ; Transmit buffer empty flag
DORD  == 0b00000100 ; Data order
REMAP == 0b00000010 ; Remap SPI Pins
TBIE  == 0b00000001 ; TX Buffer interrupt enable

; IPL0
IP0DIS == 0b10000000
PPCL   == 0b01000000
PT2L   == 0b00100000
PSL    == 0b00010000
PT1L   == 0b00001000
PX1L   == 0b00000100
PT0L   == 0b00000010
PX0L   == 0b00000001

; IPH0
IP1DIS == 0b10000000
PPCH   == 0b01000000
PT2H   == 0b00100000
PSH    == 0b00010000
PT1H   == 0b00001000
PX1H   == 0b00000100
PT0H   == 0b00000010
PX0H   == 0b00000001

; CKCON0
TWIX2 == 0b10000000
WDX2  == 0b01000000
PCAX2 == 0b00100000
SIX2  == 0b00010000
T2X2  == 0b00001000
T1X2  == 0b00000100
T0X2  == 0b00000010
X2    == 0b00000001

; P0M0
P0M0_0 == 0b00000001
P0M0_1 == 0b00000010
P0M0_2 == 0b00000100
P0M0_3 == 0b00001000
P0M0_4 == 0b00010000
P0M0_5 == 0b00100000
P0M0_6 == 0b01000000
P0M0_7 == 0b10000000

; P0M1
P0M1_0 == 0b00000001
P0M1_1 == 0b00000010
P0M1_2 == 0b00000100
P0M1_3 == 0b00001000
P0M1_4 == 0b00010000
P0M1_5 == 0b00100000
P0M1_6 == 0b01000000
P0M1_7 == 0b10000000

; P1M0
P1M0_0 == 0b00000001
P1M0_1 == 0b00000010
P1M0_2 == 0b00000100
P1M0_3 == 0b00001000
P1M0_4 == 0b00010000
P1M0_5 == 0b00100000
P1M0_6 == 0b01000000
P1M0_7 == 0b10000000

; P1M1
P1M1_0 == 0b00000001
P1M1_1 == 0b00000010
P1M1_2 == 0b00000100
P1M1_3 == 0b00001000
P1M1_4 == 0b00010000
P1M1_5 == 0b00100000
P1M1_6 == 0b01000000
P1M1_7 == 0b10000000

; P2M0
P2M0_0 == 0b00000001
P2M0_1 == 0b00000010
P2M0_2 == 0b00000100
P2M0_3 == 0b00001000
P2M0_4 == 0b00010000
P2M0_5 == 0b00100000
P2M0_6 == 0b01000000
P2M0_7 == 0b10000000

; P2M1
P2M1_0 == 0b00000001
P2M1_1 == 0b00000010
P2M1_2 == 0b00000100
P2M1_3 == 0b00001000
P2M1_4 == 0b00010000
P2M1_5 == 0b00100000
P2M1_6 == 0b01000000
P2M1_7 == 0b10000000

; P3M0
P3M0_0 == 0b00000001
P3M0_1 == 0b00000010
P3M0_2 == 0b00000100
P3M0_3 == 0b00001000
P3M0_4 == 0b00010000
P3M0_5 == 0b00100000
P3M0_6 == 0b01000000
P3M0_7 == 0b10000000

; P3M1
P3M1_0 == 0b00000001
P3M1_1 == 0b00000010
P3M1_2 == 0b00000100
P3M1_3 == 0b00001000
P3M1_4 == 0b00010000
P3M1_5 == 0b00100000
P3M1_6 == 0b01000000
P3M1_7 == 0b10000000

; Bit registers
; SCON
SCON.RI == 0x98
SCON.TI == 0x99

; CCON
CCON.CCF0 == 0xD8
CCON.CCF1 == 0xD9
CCON.CCF2 == 0xDA
CCON.CCF3 == 0xDB
CCON.CCF4 == 0xDC
CCON.CR   == 0xDE
CCON.CF   == 0xDF

; IEN0
IEN0.EC == 0xAE ; PCA interrupt enable
IEN0.ES == 0xAC