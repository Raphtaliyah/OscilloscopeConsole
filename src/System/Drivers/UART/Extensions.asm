; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module UARTExtensions
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    ; External functions
    .globl serialSendByte

    ; External symbols
    .globl byteToHexStringTable

    ; Global functions
    .globl serialSendBuffer, serialSendBuffer16, serialSendString
    .globl serialSendStringNewLine, serialSendByteAsHexString
    .globl serialSendFullHex, serialSendFullHex16
    .globl serialSendStringFromROM, serialSendStringFromROMNewLine
    .globl serialSendNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    
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
    .equ newLine,   0x0A
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Sends an array of bytes through the serial port
; Parameters:
; dptr - array pointer
; r0 - length
; Returns: none
serialSendBuffer:
    ; Push registers
    push acc
    push r0
    push r1
    push dpl
    push dph

    mov r1, r0

    ; Check for 0 length
    mov a, r1
    jz sbZeroLength
    sbBufferCopyLoop:

    ; Send byte
    movx a, @dptr
    inc dptr
    mov r0, a
    lcall serialSendByte

    ; Go next
    djnz r1, sbBufferCopyLoop
    sbZeroLength:

    ; Pop registers
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret

; Sends an array of bytes through the serial port with a 16 bit length
; Parameters:
; dptr - array pointer
; r0:r1 - length
; Returns: none
serialSendBuffer16:
    ; Push registers
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    push dplb
    push dphb

    ; Move length (r0:r1) to (r1:r2)
    mov r1, r0
    mov r2, r1

    ; /dptr = dptr + r0:r1
    mov a, r1
    add a, dpl
    mov dplb, a
    mov a, r2
    addc a, dph
    mov dphb, a
    
    ; Check for 0 length
    mov a, r1
    jnz sb16BufferCopy
    mov a, r2
    jnz sb16BufferCopy
    sjmp sb16ZeroLength
    sb16BufferCopy:

    ; Send byte
    movx a, @dptr
    mov r0, a
    lcall serialSendByte
    inc dptr

    ; At the end?
    mov a, dpl
    cjne a, dplb, sb16BufferCopy
    mov a, dph
    cjne a, dphb, sb16BufferCopy
    sb16ZeroLength:
    
    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret

; Sends a null terminated string through the serial port
; Parameters:
; dptr - string pointer
; Returns: none
serialSendString:
    ; Push registers
    push acc
    push r0
    push dpl
    push dph


    stringCopy:
    ; Get next byte
    movx a, @dptr

    ; Only send if the byte is not null
    jnz notNull
    ; Byte is null, at the end of the string
    sjmp sentString
    notNull:

    ; Send the byte and go next
    inc dptr
    mov r0, a
    lcall serialSendByte
    sjmp stringCopy
    sentString:

    ; Pop register
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

; Sends a null terminated string throught the serial port and a new line (\n)
; Parameters:
; dptr - string pointer
; Returns: none
serialSendStringNewLine:
    ; Push registers
    push r0

    ; Send the string
    lcall serialSendString

    ; Send new line
    mov r0, #newLine
    lcall serialSendByte

    ; Pop registers
    pop r0
    ret

; Converts a byte to hex and send it through the serial port
; Parameters:
; r0 - byte
; Returns: none
serialSendByteAsHexString:
    ; Push registers
    push acc
    push b
    push dpl
    push dph
    
    ; Get the pointer for the table
    mov dptr, #byteToHexStringTable ; note: in ToString.asm

    ; Multiply by 3 (2 character + null terminator) and add it to dptr
    mov a, r0
    mov b, #3
    mul ab
    add a, dpl
    mov dpl, a
    mov a, b
    addc a, dph
    mov dph, a

    ; Send 2 bytes (ignore the null)
    clr a
    movc a, @a + dptr
    mov r0, a
    lcall serialSendByte
    inc dptr
    clr a
    movc a, @a + dptr
    mov r0, a
    lcall serialSendByte

    ; Pop registers
    pop dph
    pop dpl
    pop b
    pop acc
    ret

; Converts a byte to hex and sends it through the serial port wiht a "0x" prefix
; Parameters:
; r0 - byte
; Returns: none
serialSendFullHex:
    ; Send the prefix
    push r0
    mov r0, #0x30 ; 0
    lcall serialSendByte
    mov r0, #0x78 ; x
    lcall serialSendByte
    pop r0

    ; Send the byte
    lcall serialSendByteAsHexString
    ret

; Converts a 16 bit number to hex and sends it through the serial port with a "0x" prefix
; Parameters
; r0:r1 - number
; Returns: none
serialSendFullHex16:
    ; Push registers
    push acc
    
    ; Send the prefix
    push r0
    mov r0, #0x30 ; 0
    lcall serialSendByte
    mov r0, #0x78 ; x
    lcall serialSendByte
    pop r0

    ; Send the high byte
    mov a, r0
    mov r0, r1
    lcall serialSendByteAsHexString

    ; Send the low byte
    mov r0, a
    lcall serialSendByteAsHexString

    ; Pop registers
    pop acc
    ret

; Sends a null terminated string through the serial port from ROM
; Parameters:
; dptr - string pointer
; Returns: none
serialSendStringFromROM:
    ; Push registers
    push acc
    push r0
    push dpl
    push dph


    stringCopyROM:
    ; Get next byte
    clr a
    movc a, @a + dptr

    ; Only send if the byte is not null
    jnz notNullROM
    ; Byte is null, at the end of the string
    sjmp sentStringROM
    notNullROM:

    ; Send the byte and go next
    inc dptr
    mov r0, a
    lcall serialSendByte
    sjmp stringCopyROM
    sentStringROM:
    
    ; Pop register
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

; Sends a null terminated string from ROM through the serial port and a new line (\n)
; Parameters:
; dptr - string pointer
; Returns: none
serialSendStringFromROMNewLine:
    ; Push registers
    push r0

    ; Send the string
    lcall serialSendStringFromROM

    ; Send new line
    mov r0, #newLine
    lcall serialSendByte
    
    ; Pop registers
    pop r0
    ret

; Sends a new line through the serial port
; Parameters: none
; Returns: none
serialSendNewLine:
    push r0
    
    mov r0, #newLine
    lcall serialSendByte
    
    pop r0
    ret