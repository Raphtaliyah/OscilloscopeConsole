; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MCP32S17Driver
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl stdoutSendStringFromROMNewLine, stdoutSendStringFromROM
    .globl stdoutSendFullHex, stdoutSendNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/MCP32S17.h.asm\
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
    stringAssumedAddress:
        .asciz /Assuming SPI address for MCP32S17: /
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Register addresses.
    ;--------------------------------------------
    .equ GPIOA,         0x12
    .equ GPIOB,         0x13
    .equ GPIOA_MODE,    0x00
    .equ GPIOB_MODE,    0x01

    .equ dummyByte,     0xFF
    .equ spiClock,      SPI_DIV4
    
    ; Op codes.
    ;--------------------------------------------
    .equ readOpCode,    0b01000001
    .equ writeOpCode,   0b01000000
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Selects the port register based on the
; value on the top of the stack.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	r0 - Port register.
;--------------------------------------------
.macro getPortAddress portAreg, portBreg, ?portA, ?portB
    pop  acc                ; Select the address of the port.
    jz   portA
    mov  r0, portBreg      ; Port B
    sjmp portB
    portA:
    mov  r0, portAreg      ; Port A
    portB:
.endm

;--------------------------------------------
; Reads the value from a port.
;--------------------------------------------
; Parameters:
;   r0 - Zero for port A, non zero for port B.
;   r1 - SPI address of the device.
; Returns:
;	r0 - The data from the port.
;--------------------------------------------
mcp32s17ReadPort:
    push acc
    
    push  r0                ; Set the SPI clock.
    mov   r0, #spiClock
    lcall spiChangeSpeed
    
    mov   r0, r1            ; Select device.
    lcall spiSelectDevice
    
    pop  acc                ; Select the address of the port.
    jz   readPortA
    mov  r0, #GPIOB         ; Port B
    sjmp readPort
    readPortA:
    mov  r0, #GPIOA         ; Port A
    readPort:
    
    lcall readRegister      ; Read the port register.
    
    lcall spiDisableDevice  ; Disable device.
    
    pop acc
    ret

;--------------------------------------------
; Sets the pin mode for a port.
;--------------------------------------------
; Parameters:
;   r0 - Zero for port A, non zero for port B.
;   r1 - SPI address of the device.
;   r2 - Mode mask.
; Returns:
;	nothing
;--------------------------------------------
mcp32s17SetPinMode:
    push acc
    push r0
    push r1
    
    push  r0                ; Set the SPI clock.
    mov   r0, #spiClock
    lcall spiChangeSpeed
    
    mov   r0, r1            ; Select device.
    lcall spiSelectDevice
    
    getPortAddress #GPIOA_MODE, #GPIOB_MODE
    
    mov   r1, r2
    lcall writeRegister     ; Write the mode mask.
    
    lcall spiDisableDevice  ; Disable device.
    
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Writes data to a port of an MCP32S17.
;--------------------------------------------
; Parameters:
;   r0 - Zero for port A, non zero for port B.
;   r1 - SPI address of the device.
;   r2 - Data.
; Returns:
;   nothing
;--------------------------------------------
mcp32s17WritePort:
    push acc
    push r0
    push r1
    
    push  r0                ; Set the SPI clock.
    mov   r0, #spiClock
    lcall spiChangeSpeed
    
    mov   r0, r1            ; Select device.
    lcall spiSelectDevice
    
    getPortAddress #GPIOA, #GPIOB
    
    mov   r1, r2
    lcall writeRegister     ; Write the port register.
    
    lcall spiDisableDevice  ; Disable device.
    
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; 
;--------------------------------------------
; Parameters:
;   r0 - Zero for port A, non zero for port B.
;   r1 - SPI address of the device.
;   r2 - Data.
;   r3 - Mask.
; Returns:
;   nothing
;--------------------------------------------
mcp32s17WritePortMasked:
    push a
    push r0
    push r1
    push r4
    
    mov   a,  r3                  ; Mask the data to make sure the
    anl   r2, a                   ; other bits are cleared.
    
    push  r0                      ; Set the SPI clock.
    mov   r0, #spiClock
    lcall spiChangeSpeed
    
    mov   r0, r1                  ; Select device.
    lcall spiSelectDevice
    
    getPortAddress #GPIOA, #GPIOB ; Get the register address.
    mov   r4, r0
    
    lcall readRegister            ; Read the current value and clear
    mov   a, r3                   ; the masked bits in the current
    cpl   a                       ; value.
    anl   a, r0
    orl   a, r2                   ; OR the current value (with masked
                                  ; bits cleared) with the data.
    
    lcall spiDisableDevice        ; Has to be re-enable between
    mov   r0, r1                  ; commands.
    lcall spiSelectDevice
    
    mov   r0, r4                  ; Write the new data to the port.
    mov   r1, a
    lcall writeRegister
    
    lcall spiDisableDevice         ; Disable device.
    
    pop r4
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Reads a register from the currently
; selected MCP32S17.
;--------------------------------------------
; Parameters:
;   r0 - Register address.
; Returns:
;   r0 - The value of the register.
;--------------------------------------------
readRegister:
    mov SPDAT, #readOpCode  ; Send the opcode.
    waitSPItranfer
     
    mov SPDAT, r0           ; Send register address.
    waitSPItranfer
    
    mov SPDAT, #dummyByte   ; Read in the value.
    waitSPItranfer
    mov r0, SPDAT
    ret

;--------------------------------------------
; Writes to a register of the currently
; selected MCP32S17.
;--------------------------------------------
; Parameters:
;   r0 - Register address.
;   r1 - Register data.
; Returns:
;   nothing
;--------------------------------------------
writeRegister:
    mov SPDAT, #writeOpCode
    waitSPItranfer
    
    mov SPDAT, r0
    waitSPItranfer
    
    mov SPDAT, r1
    waitSPItranfer
    ret