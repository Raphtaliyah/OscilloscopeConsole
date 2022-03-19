; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
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
    sd_cmdBuffer:
        .ds sd_bufferLength
    .area XDATA (DSEG)
    sd_dataBuffer:
        .ds sd_blockSize
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    .equ sd_spiAddress,      4
    .equ sd_dummyByte,       0xFF
    .equ sd_bufferLength,    6
    .equ sd_errorTokenMask,  0b10000000
    .equ sd_maxResponseTime, 8 ;(in bytes sent)
    .equ sd_dataReadTimeout, 65535 ;(in bytes sent)

    ;Tokens
    .equ sd_CMD17dataToken, 0xFE
    
    ;Commands
    .equ sd_CMD0,  0x40
    .equ sd_CMD1,  0x41
    .equ sd_CMD8,  0x48
    .equ sd_CMD16, 0x50
    .equ sd_CMD17, 0x51
    .equ sd_CMD41, 0x69
    .equ sd_CMD55, 0x77
    .equ sd_CMD58, 0x7A

    ;CRC
    .equ sd_CMD0crc, 0x95
    .equ sd_CMD8crc, 0x87
    .equ sd_ANYcrc,  0xFF
    
    ;R1 bits
    .equ sd_R1Idle,               0b00000001
    .equ sd_R1EraseReset,         0b00000010
    .equ sd_R1IllegalCommand,     0b00000100
    .equ sd_R1CRCerror,           0b00001000
    .equ sd_R1EraseSequenceError, 0b00010000
    .equ sd_R1AddressError,       0b00100000
    .equ sd_R1ParameterError,     0b01000000

    ;Error codes
    .equ sd_Timeout, 128 ;note: This response is not possible normally so it's safe to use it as an error code

    ;Response types
    .equ sdResponse_R1, 0
    .equ sdResponse_R1withData, 1
    .equ sdResponse_R3, 2

    ;Tokens
    .equ sd_DataToken1, 0xFE ;for CMD17/18/24
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; HACK: Implementation of a legacy API
spi_writeBufferBlocking:
    ;Push registers
    push acc
    
    spi_bufferSend:
    sendSpiByteBlocking @r0

    ;Read the received byte
    mov @r0, SPDAT
    
    ;Next byte
    inc r0

    djnz r2, spi_bufferSend
    
    ;Pop registers
    pop acc
    ret

;Copies a block of XRAM from 'source' to 'destination'
;dptr - source
;/dptr - destination
;r2:r3 - size
legacy_memcpy:
    ;Push registers
    push acc
    push r2
    push r3
    push psw
    push dpl
    push dph
    push dplb
    push dphb

    memcpy_loop:
    ;Get byte from source
    movx a, @dptr
    inc dptr

    ;Write byte to destination
    movx @/dptr, a
    inc /dptr
    
    ;Next
    mov a, r2
    clr c
    subb a, #1
    mov r2, a
    mov a, r3
    subb a, #0
    mov r3, a
    cjne r2, #0, memcpy_loop
    cjne r3, #0, memcpy_loop
    
    ;Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop psw
    pop r3
    pop r2 
    pop acc
    ret


;Sends the packet buffer to the SD card and waits for response
;r2 - response type
;Return: r2 - R1 response code (if the response type is R1)
sd_sendPacket:
    ;Push registers
    push acc
    push r0
    
    ;Save the parameters for later
    push r2

    ;Select card
    sendSpiByteBlocking #sd_dummyByte
    mov r0, #sd_spiAddress
    lcall spiSelectDevice
    sendSpiByteBlocking #sd_dummyByte
    
    ;Send the packet
    mov r0, #sd_cmdBuffer
    mov r2, #sd_bufferLength
    lcall spi_writeBufferBlocking
    
    ;Get the response
    pop acc
    cjne a, #sdResponse_R1, sd_notR1Response
    ;=> R1 response
    lcall sd_getR1Response
    sjmp sd_gotResponse

    sd_notR1Response:
    cjne a, #sdResponse_R1withData, sd_notR1withDataResponse
    ;=> R1 response with data
    lcall sd_getR1withDataResponse
    sjmp sd_gotResponse

    sd_notR1withDataResponse:
    cjne a, #sdResponse_R3, sd_notR3Response
    ;=> R3 response
    lcall sd_getR3response
    sjmp sd_gotResponse
    
    sd_notR3Response:
    ;=> Unknown response type?
    
    mov r2, #error_BadParameter
    lcall crash_Display
    
    sd_gotResponse:
    
    ;Finish command
    push r2
    sendSpiByteBlocking #sd_dummyByte
    lcall spiDisableDevice
    sendSpiByteBlocking #sd_dummyByte
    pop r2
    
    ;Pop registers
    pop r0
    pop acc
    ret

;Clears the SD command buffer
sd_clearCmdBuffer:
    mov sd_cmdBuffer + 0, #0
    mov sd_cmdBuffer + 1, #0
    mov sd_cmdBuffer + 2, #0
    mov sd_cmdBuffer + 3, #0
    mov sd_cmdBuffer + 4, #0
    mov sd_cmdBuffer + 5, #0
    ret

;Waits for an R1 type response
;Returns: r2 - response
sd_getR1Response:
    ;Push registers
    push acc
    push r3
    
    mov r3, #sd_maxResponseTime
    sd_waitR1responseLoop:
    ;Send a dummy byte and read the response
    sendSpiByteBlocking #sd_dummyByte
    mov r2, SPDAT

    ;Check if the received byte isn't 255 (AKA got a response)
    cjne r2, #255, sd_gotR1Response
    djnz r3, sd_waitR1responseLoop
    ;=> No response
    mov r2, #sd_Timeout
    sd_gotR1Response:

    ;Pop registers
    pop r3
    pop acc
    ret

;Waits for an R1 type response and continues to wait for a token and a data block
;Returns: r2 - r1 response or token ;note: msb is set for tokens
sd_getR1withDataResponse:
    ;Push registers
    push acc
    push r3
    push r4
    push dpl
    push dph

    ;Wait for the R1 type response
    lcall sd_getR1Response
    mov a, r2
    jz sd_responseOK
    ;=> bad response
    sjmp sd_gr1wdReturn
    sd_responseOK:

    ;if the received token is a data token start reading
    mov r3, #<sd_dataReadTimeout ;TODO: Measure the latency
    mov r4, #>sd_dataReadTimeout
    sd_tokenWaitLoop:
    sendSpiByteBlocking #sd_dummyByte
    cjne r2, #0xFF, sd_tokenReceived
    ;=> No response
    mov a, r3
    clr c
    subb a, #1
    mov r3, a
    jnc sd_tokenWaitLoop
    mov a, r4
    subb a, #0
    mov r4, a
    jnc sd_tokenWaitLoop
    ;=> Timeout
    mov r2, #sd_Timeout
    sjmp sd_gr1wdReturn
    sd_tokenReceived:
    ;=> Token received

    ;Error token?
    cjne r2, #sd_CMD17dataToken, sd_erroTokenReceived
    ;=> Data token
    sjmp sd_dataTokenReceived
    sd_erroTokenReceived:
    ;Set the MSB to indicate that this is an error token
    anl r2, #sd_errorTokenMask
    sjmp sd_gr1wdReturn
    
    sd_dataTokenReceived:
    ;=> Received correct token
    push r2

    ;Start reading
    mov dptr, #sd_dataBuffer
    mov r3, #<sd_blockSize ;always 0
    mov r4, #>sd_blockSize
    sd_readLoop:

    ;Read next byte
    sendSpiByteBlocking #sd_dummyByte
    mov a, SPDAT

    ;Write and move to the next location
    movx @dptr, a
    inc dptr

    djnz r3, sd_readLoop
    djnz r4, sd_readLoop

    ;Read CRC
    sendSpiByteBlocking #sd_dummyByte
    sendSpiByteBlocking #sd_dummyByte

    ;Get the token back
    pop r2

    sd_gr1wdReturn:
    
    ;Pop registers
    pop dph
    pop dpl
    pop r4
    pop r3
    pop acc
    ret

;Waits for an R3 type response
;Returns: r2 - R1 response and the R3 response data in command buffer ;note: in reverse order!
sd_getR3response:
    ;Push registers
    push acc
    push r0
    push r3

    ;Wait for the R1 response
    lcall sd_getR1Response
    mov a, r2
    jz sd_wr3rResponseOK
    dec a ;idle is also fine?
    jz sd_wr3rResponseOK
    ;=> bad response
    sjmp sd_gr3rReturn
    sd_wr3rResponseOK:

    ;Push response for later
    push r2

    ;and read the rest
    lcall sd_clearCmdBuffer
    mov r0, #sd_cmdBuffer
    mov r2, #4 ;r3 response has a length of 4
    lcall spi_writeBufferBlocking
    
    ;Get the response back
    pop r2

    sd_gr3rReturn:

    ;Pop registers
    pop r3
    pop r0
    pop acc
    ret

;Prints the error message with the response code
;r2 - r1 response
sd_printError:
    cjne r2, #sd_Timeout, sd_notTimeout
    ;=>Timeout
    mov r2, #error_Timeout
    lcall crash_Display
    sd_notTimeout:
    
    ;Print error message
    mov dptr, #sd_errorMessage
    lcall stdoutSendStringFromROM
    
    ;Print response code
    mov r0, r2
    lcall stdoutSendFullHex
    
    ;Freeze
    sjmp .
    ret

; HACK: Just print the error to stdout for now
crash_Display:
    mov dptr, #stdoutErrorMessage
    lcall stdoutSendStringFromROM
    mov r0, r2
    lcall stdoutSendFullHex
    sjmp .

.equ error_Timeout,      0x01
.equ error_BadParameter, 0x02

stdoutErrorMessage:
    .asciz \SD error: \

sd_errorMessage: 
    .asciz \SD card responded with \