; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Serial
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl serialSendStringFromROMNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Serial.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/Memset.h.asm\
    .include \src/Headers/SpinWait.h.asm\
    .include \src/Definitions/System.asm\
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
    inTransmission:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    sendBuffer:
        .ds sendBufferSize
    sendBufferReadPointer:
        .ds 2
    sendBufferWritePointer:
        .ds 2
    sendBufferLength:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringUartReady:
        .asciz \UART ready. o/\
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ sendBufferSize,    32 ; note: has to be an 8 bit value
    .equ BRLvalue,          0xE5
    ; Values for different baud rates (SMOD1 and SPD are set):
    ; 9600   - 0x5D
    ; 57600  - 0xE5
    ; 156250 - 0xF6
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Initializes the serial driver
; Parameters: none
; Returns: none
serialDriverInit:
    ; Push registers
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    ; Disable interrupts
    disableIntRestorable

    ; Set the pointers to the base
    ; read pointer
    mov dptr, #sendBufferReadPointer
    mov a, #<sendBuffer
    movx @dptr, a
    inc dptr
    mov a, #>sendBuffer
    movx @dptr, a
    ; write pointer
    mov dptr, #sendBufferWritePointer
    mov a, #<sendBuffer
    movx @dptr, a
    inc dptr
    mov a, #>sendBuffer
    movx @dptr, a

    ; Set the length to 0
    mov dptr, #sendBufferLength
    clr a
    movx @dptr, a

    ; Clear transmission flag
    clr inTransmission

    ; Set the send buffer to all NULLs
    mov dptr, #sendBuffer
    mov r0, #sendBufferSize
    mov r1, #0
    mov r2, #NULL
    lcall memset
    
    ; Restore interrupts
    restoreInt

    ; Select mode 1
    mov SCON, #SM1
    
    ; Select baud rate generator for transmitting and receiving and set brg to fast mode
    mov BDRCON, #TBCK | RBCK | SPD

    ; Double baud rate bit
    orl PCON, #SMOD1

    ; Set reload value for 9600 baud
    mov BRL, #BRLvalue

    ; Set interrupt level to level 3
    orl IPL0, #PSL
    orl IPH0, #PSH

    ; Enable interrupt
    setb IEN0.ES

    ; Baud rate generator go BRR
    orl BDRCON, #BRR

    ; Let the BRG stabilize before sending anything
    mov r0, #5
    lcall spinWaitMilliseconds

    ; Send ready message
    mov dptr, #stringUartReady
    lcall serialSendStringFromROMNewLine

    ; Pop registers
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret

; Sends a byte through the serial port
; Parameters:
; r0 - the byte to be sent
; Returns: none
serialSendByte:
    ; Push registers
    push acc
    push dpl
    push dph
    push dplb
    push dphb

    ; Disable interrupts
    disableIntRestorable

    ; If there is data being transmitted, queue the new byte in the buffer
    ; else send it directly
    jb inTransmission, sendByteQueueInBuffer

    ; no ongoing transmission, send directly

    ; Set transmission flag and send the byte
    setb inTransmission
    mov SBUF, r0

    sjmp serialSent
    sendByteQueueInBuffer:
    
    ; data is being transmitted, queue in buffer

    ; Check if the length is equal to the size
    mov dptr, #sendBufferLength
    movx a, @dptr
    clr c
    subb a, #sendBufferSize
    jc sendBufferHasFreeSpace
    
    ; buffer is full, wait for free space

    ; wait for an interrupt request to happen
    sendIrqWait:
    nop
    jnb SCON.TI, sendIrqWait

    ; Manually handle the interrupt request
    lcall serialInt

    sendBufferHasFreeSpace:

    ; Load the write pointer
    ldVarDptr #sendBufferWritePointer
    
    ; Write the byte to the buffer
    mov a, r0
    movx @dptr, a

    ; Increment the pointer
    cirBufferGoNext sendBuffer, sendBufferSize

    ; Update the pointer
    inc AUXR1
    mov dptr, #sendBufferWritePointer
    mov a, dplb
    movx @dptr, a
    inc dptr
    mov a, dphb
    movx @dptr, a

    ; Increment the buffer length
    mov dptr, #sendBufferLength
    movx a, @dptr
    inc a
    movx @dptr, a

    serialSent:

    ; Restore interrupts
    restoreInt

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

; The hardware interrupt handler for the serial port
serialIntHandler:
    ; Call the int handler
    acall serialInt
    
    ; Enable interrupts
    setb EA
    
    ; Return from int level
    reti

; Serial interrupt handler
serialInt:
    ; Push registers
    push acc
    
    ; Disable interrupts
    ; note: restorable is used because this might be called directly to bypass irq levels
    disableIntRestorable
    
    ; Call the handler for the int type
    jbc SCON.TI, serialTransmitInt
    jbc SCON.RI, serialReceiveInt

; Transmit interrupt handler
serialTransmitInt:
    ; Push registers
    push psw
    push dpl
    push dph
    push dplb
    push dphb

    ; Clear transmission flag
    clr inTransmission

    ; Return if the buffer is empty
    mov dptr, #sendBufferLength
    movx a, @dptr
    jz transmitIntReturn

    ; Read next byte from the buffer
    ldVarDptr #sendBufferReadPointer
    movx a, @dptr

    ; Send the read byte
    mov SBUF, a

    ; Set transmission flag
    setb inTransmission
    
    ; Increment the pointer
    cirBufferGoNext sendBuffer, sendBufferSize

    ; Update the pointer
    inc AUXR1
    mov dptr, #sendBufferReadPointer
    mov a, dplb
    movx @dptr, a
    inc dptr
    mov a, dphb
    movx @dptr, a

    ; Decrement the buffer length
    mov dptr, #sendBufferLength
    movx a, @dptr
    dec a
    movx @dptr, a

    transmitIntReturn:

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop psw

    ; Restore interrupts
    restoreInt

    ; Pop rest of the registers
    pop acc
    ret

; Receive interrupt handler
serialReceiveInt:
    
    ; TODO: Receive

    ; Restore interrupts
    restoreInt
    
    ; Pop rest of the registers
    pop acc
    ret