; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Controller
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    
    .include \src/Headers/Render.h.asm\
    .include \src/Headers/MCP3201.h.asm\
    .include \src/Headers/MCP32S17.h.asm\
    .include \src/Headers/Controller.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    controllerAAlreadyRead:
        .ds 1
    controllerBAlreadyRead:
        .ds 1
    controllerAButton:
        .ds 1
    controllerBButton:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    controllerAValue:
        .ds 1
    controllerBValue:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringInit:
        .asciz /Initializing controller.../
    stringAssumedAddresses0:
        .asciz / Assuming SPI addresses:/
    stringAssumedAddresses1:
        .asciz /  Controller A ADC at: /
    stringAssumedAddresses2:
        .asciz /  Controller B ADC at: /
    stringReady:
        .asciz /Controller ready./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ gpioAddress,               0x01 ; spi addresses
    .equ controllerAAnalogAddress,  0x02 ; ^^^
    .equ controllerBAnalogAddress,  0x03 ; ^^^
    .equ portA,                     0x00
    .equ controllerButtonPressed,   0xFF
    .equ controllerButtonReleased,  0x00
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Creates the controller device.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   r0 - status code
;--------------------------------------------
createControllerDevice:
    push dpl
    push dph
    
    mov   dptr, #stringInit               ; Send init text.
    lcall stdoutSendStringFromROMNewLine
    
    mov   dptr, #stringAssumedAddresses0  ; Assuming spi addresses:\n...
    lcall stdoutSendStringFromROMNewLine
    mov   dptr, #stringAssumedAddresses1  ; ...Controller A adc at: ...
    lcall stdoutSendStringFromROM
    mov   r0,   #controllerAAnalogAddress ; ... n\n...
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine
    mov   dptr, #stringAssumedAddresses2  ; Controller B adc at: ...
    lcall stdoutSendStringFromROM
    mov   r0,   #controllerBAnalogAddress ; ... n\n
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine
    
    mov  dptr, #controllerAValue        ; Clear analog values.
    clr  a                              ; A analog
    movx @dptr, a
    mov  dptr, #controllerBValue        ; B analog
    clr  a
    movx @dptr, a
    
    clr  controllerAButton              ; Clear button values.
    clr  controllerBButton

    mov   dptr, #updateData             ; Add the update function
    lcall addPreRenderFunction          ; before the frame.
    
    mov   dptr, #stringReady            ; Send ready text.
    lcall stdoutSendStringFromROMNewLine
    
    mov r0, #success                    ; Return success.
    
    pop dph
    pop dpl
    ret

;--------------------------------------------
; Reads the state of the controller button
; and only returns true if it's a new button
; press.
;--------------------------------------------
; Parameters:
;   r0 - Zero for controller A, non zero for
;      - controller B button.
; Returns:
;   r0 - Button state.
;--------------------------------------------
controllerReadNewButtonPress:
    push a

    mov  a, r0                         ; Read A for 0, B otherwise.
    jz   readNewA
    
    readNewB:                          ; Read B state.
    jb   controllerBButton, BIsPressed ; Check if it's pressed
    mov  r0, #0x00                     ; Not pressed, return 0.
    sjmp newBtnPressReturn
    
    BIsPressed:
    jb controllerBAlreadyRead, BAlreadyRead ; Has it been read before?
    mov  r0, #0xFF                     ; No, return true and mark read.
    setb controllerBAlreadyRead
    sjmp newBtnPressReturn
    
    BAlreadyRead:
    mov  r0, #0x00                     ; Yes, return 0.
    sjmp newBtnPressReturn
    
    
    readNewA:                          ; Read A state.
    jb   controllerAButton, AIsPressed ; Check if it's pressed
    mov  r0, #0x00                     ; Not pressed, return 0.
    sjmp newBtnPressReturn
    
    AIsPressed:
    jb   controllerAAlreadyRead, AAlreadyRead ; Has it been read
    mov  r0, #0xFF                     ; before?
    setb controllerAAlreadyRead        ; No, return true and mark read
    sjmp newBtnPressReturn
    
    AAlreadyRead:
    mov  r0, #0x00                     ; Yes, return 0.
    sjmp newBtnPressReturn
    
    newBtnPressReturn:
    
    pop a
    ret


;--------------------------------------------
; Reads the state of the controllers.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
updateData:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    mov   r0, #MCP32S17_GPIOA; Read controller A and controller B buttons
    mov   r1, #gpioAddress   ; SPI address
    lcall mcp32s17ReadPort
    mov   a,  r0
    mov   c,  a.0            ; A controller
    cpl   c
    jc    aStillPressed      ; If it's not pressed, clear the already
    clr   controllerAAlreadyRead ; read flag.
    aStillPressed:
    mov   controllerAButton, c
    mov   c,  a.1            ; B controller
    cpl   c
    jc    bStillPressed      ; If it's not pressed, clear the already
    clr   controllerBAlreadyRead ; read flag.
    bStillPressed:
    mov   controllerBButton, c
    
    mov   r0,   #controllerAAnalogAddress  ; Read controller A analog.
    mov   dptr, #controllerAValue
    lcall readControllerAnalog
    
    mov   r0,   #controllerBAnalogAddress  ; Read controller B analog.
    mov   dptr, #controllerBValue
    lcall readControllerAnalog
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret


; Parameters:

; Returns: none
;--------------------------------------------
; Reads the analog value of a controller.
;--------------------------------------------
; Parameters:
;   r0   - SPI ADC address.
;   dptr - Pointer to where to write the
;          value.
; Returns:
;   nothing
;--------------------------------------------
readControllerAnalog:
    lcall mcp3201ReadAnalog
    lcall convert12To8bit
    mov   a,     r0
    movx  @dptr, a
    ret

;--------------------------------------------
; Converts the 12 bit output of the adc to an
; 8 bit value.
;--------------------------------------------
; Parameters:
;	r0:r1 - 12 bit value.
; Returns:
;	r0    - 8 bit value.
;--------------------------------------------
convert12To8bit:
    ; Push registers
    push acc
    push r1
    push r2
    
    mov r2, #4 ; rotate by 4 bit
    rotateLoop:
    clr c
    mov a, r0
    rlc a
    mov r0, a
    mov a, r1
    rlc a
    mov r1, a
    djnz r2, rotateLoop
    
    mov r0, r1
    
    pop r2
    pop r1
    pop acc
    ret