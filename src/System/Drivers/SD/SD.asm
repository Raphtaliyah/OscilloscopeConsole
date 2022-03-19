; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module SD
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/SD.h.asm\
    .include \src/Headers/SPI.h.asm\
    .include \src/Headers/SpinWait.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\

    .include \src/Definitions/ASCII.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    sd_testFlag:
        .ds 1
    .area DATA  (DSEG)
    sd_cardVersion:
        .ds 1
    .area XDATA (DSEG)
    sd_lastRead:
        .ds 4
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ sd_initRetry,     10
    .equ sd_cmd1Timeout,   200 ;* 5 ms
    .equ sd_acmd41Timeout, 200 ;* 5 ms

    .equ sd_blockSize,       512 ;note: only 256 * 2 ^ n values allowed!
    .equ sd_blockOffsetBits, 1   ;note: Has to be calculated manually, the assembler can't do it. log2(sd_blockSize/256) always rounded up

    ;Versions
    .equ sd_MMC3,     0
    .equ sd_SD1,      1
    .equ sd_SD2byte,  2
    .equ sd_SD2block, 3
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;Initializes the SD card
sd_Setup:
    clr sd_testFlag
    
    ;Push registers
    push acc
    push r0
    push r2
    push r3
    push r4
    push dpl
    push dph

    ;Start text
    mov dptr, #sd_setupText1
    lcall stdoutSendStringFromROM
    
    ;~~~~~~~~~~~;
    ; Card init ;
    ;~~~~~~~~~~~;

    ;Startup delay
    mov r0, #100
    lcall spinWaitMilliseconds

    ;Slow down the SPI interface for initialization
    anl SPCON, #~(SPR2 | SPR1 | SPR0)
    orl SPCON, #SPR2 | SPR1
    
    ;Try sending CMD0 a few times
    mov r4, #sd_initRetry
    
    sd_retry:
    
    ;Send dummy bits
    mov r3, #8
    sd_initSendDummyBits:
    sendSpiByteBlocking #sd_dummyByte
    djnz r3, sd_initSendDummyBits

    ;Send cmd0
    mov sd_cmdBuffer + 0, #sd_CMD0
    mov sd_cmdBuffer + 1, #0
    mov sd_cmdBuffer + 2, #0
    mov sd_cmdBuffer + 3, #0
    mov sd_cmdBuffer + 4, #0
    mov sd_cmdBuffer + 5, #sd_CMD0crc
    mov r2, #sdResponse_R1
    lcall sd_sendPacket
    
    ;Check response
    cjne r2, #sd_R1Idle, sd_initInvalidResponse
    ;=> Valid response
    sjmp sd_cmd0Success
    sd_initInvalidResponse:
    ;=> Invalid response
    djnz r4, sd_retry
    ;=> No (valid) sd card detected
    mov dptr, #sd_NoCardDetectedText
    lcall stdoutSendStringFromROM
    sjmp .
    sd_cmd0Success:
    ;=> Got a valid response (0x01 - Idle)
    
    ;Send CMD8
    mov sd_cmdBuffer + 0, #sd_CMD8
    mov sd_cmdBuffer + 1, #0x00
    mov sd_cmdBuffer + 2, #0x00
    mov sd_cmdBuffer + 3, #0x01
    mov sd_cmdBuffer + 4, #0xAA
    mov sd_cmdBuffer + 5, #sd_CMD8crc
    mov r2, #sdResponse_R3
    lcall sd_sendPacket

    ;Check if the returned data matches the sent data
    mov a, sd_cmdBuffer + 0
    cjne a, #0x00, sd_cmd8mismatch
    mov a, sd_cmdBuffer + 1
    cjne a, #0x00, sd_cmd8mismatch
    mov a, sd_cmdBuffer + 2
    cjne a, #0x01, sd_cmd8mismatch
    mov a, sd_cmdBuffer + 3
    cjne a, #0xAA, sd_cmd8mismatch
    sjmp sd_cmd8match
    sd_cmd8mismatch:
    ;=> returned data mismatch
    sjmp sd_unknownCard
    sd_cmd8match:
    ;=> returned data matches
    
    ;Set the SPI bus speed
    mov r0, #SPI_DIV2
    lcall spiChangeSpeed

    ;~~~~Now find out what version the card is!~~~~;

    ;Move the response to a different register for later use
    mov r4, r2
    
    ;Both cards need an ACMD41 so let's send it
    mov r3, #sd_acmd41Timeout
    sd_acmd41Wait:

    ;Small delay between commands
    mov r0, #5
    lcall spinWaitMilliseconds

    ;First the prefix, CMD55
    mov sd_cmdBuffer + 0, #sd_CMD55
    mov sd_cmdBuffer + 1, #0
    mov sd_cmdBuffer + 2, #0
    mov sd_cmdBuffer + 3, #0
    mov sd_cmdBuffer + 4, #0
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R1
    lcall sd_sendPacket

    ;Then send CMD41
    mov sd_cmdBuffer + 0, #sd_CMD41
    mov sd_cmdBuffer + 1, #0x40
    mov sd_cmdBuffer + 2, #0
    mov sd_cmdBuffer + 3, #0
    mov sd_cmdBuffer + 4, #0x00
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R1
    lcall sd_sendPacket
    
    ;Check the response
    ;... if it's sd_R1Idle, try again
    ;... if it ran out of retries (or replied with an error) and CMD8 response was sd_R1Idle => Unkown card
    ;                                                        and CMD8 response was an error or timed out => try CMD1 (MMC ver 3)
    ;... if it's 0x00 => success (either SD ver. 2+ or SD ver 1.)
    
    ;Test success
    mov a, r2
    jz sd_acmd41Success
    ;Test idle
    cjne r2, #sd_R1Idle, sd_notIdle
    ;=> in idle, try again
    djnz r3, sd_acmd41Wait
    ;=> out of retries
    sd_notIdle:
    ;=> ... or error response
    
    ;If cmd8 was success and this failed => unknown card
    cjne r4, #sd_R1Idle, sd_tryCMD1
    ;=> unknown card
    sd_unknownCard:
    mov dptr, #sd_UnknownCardText
    lcall stdoutSendStringFromROM
    sjmp .
    sd_tryCMD1:
    ;=> try cmd1, if that succeeds then it's an mmc card (version 3)

    ;Send CMD1 to leave idle state
    mov r4, #sd_cmd1Timeout
    sd_cmd1wait:
    
    ;Small delay between commands
    mov r0, #5
    lcall spinWaitMilliseconds

    ;Send CMD1
    mov sd_cmdBuffer + 0, #sd_CMD1
    mov sd_cmdBuffer + 1, #sd_dummyByte
    mov sd_cmdBuffer + 2, #sd_dummyByte
    mov sd_cmdBuffer + 3, #sd_dummyByte
    mov sd_cmdBuffer + 4, #sd_dummyByte
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R1
    lcall sd_sendPacket
    
    mov a, r2
    jz sd_cmd1Success 
    djnz r4, sd_cmd1wait
    ;=> timeout or error => unkown card
    sjmp sd_unknownCard
    sd_cmd1Success:
    ;=> 0h response - left idle state => MMC version 3
    mov sd_cardVersion, #sd_MMC3
    sjmp sd_initSuccess

    sd_acmd41Success:
    ;=> acmd41 replied with 0x00 (success)

    ;cmd8 success => sd version 2+
    ;cmd8 fail => sd version 1
    
    ;Check for version 1, that's faster
    cjne r4, #sd_R1Idle, sd_version1
    ;=> Version 2 sd card
    ;Is it block or byte addressable?
    
    ;Send CMD58
    mov sd_cmdBuffer + 0, #sd_CMD58
    mov sd_cmdBuffer + 1, #sd_dummyByte
    mov sd_cmdBuffer + 2, #sd_dummyByte
    mov sd_cmdBuffer + 3, #sd_dummyByte
    mov sd_cmdBuffer + 4, #sd_dummyByte
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R3
    lcall sd_sendPacket

    ;Check R1 response
    mov a, r2
    jz sd_cmd58ResponseOk
    lcall sd_printError
    sd_cmd58ResponseOk:

    ;Check if CCS (bit 30) is set in OCR
    mov a, sd_cmdBuffer + 0
    anl a, #0b01000000
    jz sd_ccsNotSet
    ;=> CCS set => block address mode
    mov sd_cardVersion, #sd_SD2block
    sjmp sd_initSuccess
    sd_ccsNotSet:
    ;=> CCS cleared => byte address mode
    mov sd_cardVersion, #sd_SD2byte
    sjmp sd_initSuccess
    sd_version1:
    ;=> Version 1 sd card
    mov sd_cardVersion, #sd_SD1
    sd_initSuccess:

    ;Set block size
    mov r2, #sd_blockSize/256
    acall sd_setBlockSize
    
    ;Check if the response is ok (0h)
    mov a, r2
    jz sd_blocksizeChangeOK
    ;=> bad response code
    lcall sd_printError
    sd_blocksizeChangeOK:
    
    ;Finish text
    mov dptr, #sd_setupText2
    lcall stdoutSendFullHex
    
    ;Pop registers~
    pop dph
    pop dpl
    pop r4
    pop r3
    pop r2
    pop r0
    pop acc
    ret

;Sets the block size
;r2 - block size * 256
;Returns: r2 - R1 response code
sd_setBlockSize:
    ;Push registers
    push acc

    ;Send CMD16
    mov sd_cmdBuffer + 0, #sd_CMD16
    mov sd_cmdBuffer + 1, #0h
    mov sd_cmdBuffer + 2, #0h
    mov sd_cmdBuffer + 3, r2
    mov sd_cmdBuffer + 4, #0h
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R1
    lcall sd_sendPacket

    ;Pop registers
    pop acc
    ret

;Reads data from the sd card into a buffer
;A & AX - Low half of the address (0-15)
;B & BX - High half of the address (16-31)
;/dptr - buffer
;r2 - size
;Returns: r2 - Response code
sd_readBuffer:
    ;Push registers
    push b
    push psw
    push dpl
    push dph
    push dplb
    push dphb
    push acc
    push r3
    push r4
    push r5

    ;~~~~Calculate block address and the offset~~~~;

    ;The 0th byte is the 0th byte of the offset because the block size is always a multiple of 256
    push acc
    
    ;Shift the whole address to get the block address and the bits shifted out are the high byte of the offset
    mov r4, #0
    mov r3, #sd_blockOffsetBits
    mov a, r3 ;Zero check
    jz sd_offsetAddressCalcLoopExit
    sd_offsetAddressCalcLoop:

    ;Shift the address
    clr c
    ;Highest (3rd)
    mov a, bx
    rrc a
    mov bx, a
    ;2nd
    mov a, b
    rrc a
    mov b, a
    ;1st
    mov a, ax
    rrc a
    mov ax, a
    
    ;Shift the carry bit into r4
    mov a, r4
    rrc a
    mov r4, a
    
    djnz r3, sd_offsetAddressCalcLoop
    sd_offsetAddressCalcLoopExit:

    ;r4 now contains the higher half of the offset but the bits are still shifted, fix that by shifting it with 8 - blockOffsetBits
    mov r3, #8 - sd_blockOffsetBits
    mov a, r3 ;Zero check
    jz sd_offsetFixLoopExit
    mov a, r4
    sd_offsetFixLoop:
    rr a
    djnz r3, sd_offsetFixLoop
    mov r4, a
    sd_offsetFixLoopExit:

    ;Push the other half of the offset
    push r4
    
    ;=> The offset is now on the stack and the block address is in ax, b and bx

    ;~~~~Prepare address~~~~;
    
    ;If the card is block addressable move ax -> a, b -> ax, bx -> b, 0 -> bx
    ;if the card is byte addressable set 'a' to zero and shift left by blockOffsetBits
    mov a, sd_cardVersion
    cjne a, #sd_SD2block, sd_byteAddressable
    ;=> block addressable
    mov a, ax
    mov ax, b
    mov b, bx
    mov bx, #0
    sjmp sd_addressReady
    sd_byteAddressable:
    ;=> byte addressable
    mov r4, #sd_blockOffsetBits
    mov a, r4 ;Zero check
    jz sd_byteAddressCorrectExit
    sd_byteAddressCorrect:
    clr c
    ;1st byte
    mov a, ax
    rlc a
    mov ax, a
    ;2nd byte
    mov a, b
    rlc a
    mov b, a
    ;3rd byte
    mov a, bx
    rlc a
    mov bx, a
    djnz r4, sd_byteAddressCorrect
    sd_byteAddressCorrectExit:
    mov a, #0
    sd_addressReady:
    ;=> a, ax, b and bx now has the correct values for the card

    ;~~~~Load block~~~~;
    
    ;Check if the last read block is the same as this
    mov r4, a
    mov dptr, #sd_lastRead
    movx a, @dptr
    cjne a, r4, sd_cacheMiss
    inc dptr
    movx a, @dptr
    cjne a, ax, sd_cacheMiss
    inc dptr
    movx a, @dptr
    cjne a, b, sd_cacheMiss
    inc dptr
    movx a, @dptr
    cjne a, bx, sd_cacheMiss
    ;=> Hit
    sjmp sd_cacheHit
    sd_cacheMiss:
    ;=> new block
    mov a, r4
    
    ;Load the new block
    push r2
    lcall sd_readBlock

    ;Check response
    cjne r2, #sd_CMD17dataToken, sd_readFail
    sjmp sd_readSuccess
    sd_readFail:
    ;=>Read failed

    ;Clean the stack and return the error code
    pop acc
    pop acc
    pop acc
    pop acc
    
    ;Push response code
    push r2
    ljmp sd_loadBufferExit
    
    sd_readSuccess:
    pop r2

    ;Write the address of the current block to lastRead
    mov dptr, #sd_lastRead
    movx @dptr, a
    inc dptr
    mov a, ax
    movx @dptr, a
    inc dptr
    mov a, b
    movx @dptr, a
    inc dptr
    mov a, bx
    movx @dptr, a

    sd_cacheHit:
    ;=> same block
    mov a, r4

    ;~~~~Copy to destination~~~~;
    
    ;Get the offset from stack and push the block address
    pop r4
    pop r3
    push acc
    push ax
    push b
    push bx
    
    ;Calculate the source address
    mov dptr, #sd_dataBuffer
    mov a, dpl
    add a, r3
    mov dpl, a
    mov a, dph
    addc a, r4
    mov dph, a

    ;blockSize - offset
    mov a, #<sd_blockSize
    clr c
    subb a, r3
    mov r3, a
    mov a, #>sd_blockSize
    subb a, r4
    mov r4, a
    ;note: blockSize is always smaller then offset, carry will never be set
    
    ;~r5 = min(size, blockSize - offset)~;
    ;(blockSize - offset) - size
    mov a, r3
    clr c
    subb a, r2
    mov a, r4
    subb a, #0
    jc sd_blockSizeMinusOffsetLessThenSize
    ;=> (blockSize - offset) >= size
    mov r5, r2
    sjmp sd_minSizeBlockSizeMinusOffsetDone
    sd_blockSizeMinusOffsetLessThenSize:
    ;=> (blockSize - offset) < size
    mov r5, r3 ;note: 'size' is 8 bit, if 'blockSize-offset' was smaller r4 is 0 so it can be discarded
    sd_minSizeBlockSizeMinusOffsetDone:
    
    ;Copy
    push r2
    push r3
    mov r2, r5
    mov r3, #0 ;TODO: Make it accept 16 bit inputs
    lcall legacy_memcpy
    pop r3
    pop r2
    
    ;~~~~Load the remaining (if there are any)~~~~;
    
    ;If the result of min(size, blockSize - offset) != size then this block didn't contain all the data needed
    mov a, r5
    cjne a, r2, sd_nextBlock
    ;=> Everything was in this block, done
    ;Clean stack
    pop acc ;bx
    pop acc ;b
    pop acc ;ax
    pop acc ;a
    
    ;Push response code (if this was reached the response code has to be the data token for cmd17)
    mov a, #sd_CMD17dataToken
    push acc

    ;Finish
    sjmp sd_loadBufferExit
    sd_nextBlock:
    ;=> Some of the requested data is in the next block

    ;Calculate the destination (current destination + (blockSize - offset))
    inc AUXR1
    mov a, dpl
    add a, r3
    mov dpl, a
    mov a, dph
    addc a, r4 ;r4 will be zero but this is faster then using a constant
    mov dph, a
    inc AUXR1

    ;Calculate the remaining data (size - (blockSize - offset))
    ;note: if this is reached (blockSize - offset) is less then 'size' which means r4 is 0
    mov a, r2
    clr c
    subb a, r3
    mov r2, a

    ;Calculate the address of the next block
    ;if the card is block addressable just add 1
    ;if the card is byte addressable add blockSize
    mov a, sd_cardVersion
    cjne a, #sd_SD2block, sd_nextNotBlock
    ;=> block addressable

    ;get the current address from stack
    pop bx
    pop b
    pop ax
    pop acc

    ;next block
    add a, #1

    sjmp sd_readNext
    sd_nextNotBlock:
    ;=> byte addressable
    pop bx
    pop b
    pop ax
    mov a, ax
    add a, #sd_blockSize/256
    mov ax, a
    pop acc
    sd_readNext:

    ;Read next
    lcall sd_readBuffer
    
    ;Push the response code
    push r2

    sd_loadBufferExit:

    ;Get the response code
    pop r2
    
    ;Pop registers
    pop r5
    pop r4
    pop r3
    pop acc
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop psw
    pop b
    ret

;Reads a block from the SD card
;A & AX - Low half of the address (0-15)
;B & BX - High half of the address (16-31)
;Returns: r2: the token received before data
sd_readBlock:
    ;Send CMD17
    mov sd_cmdBuffer + 0, #sd_CMD17
    mov sd_cmdBuffer + 1, bx
    mov sd_cmdBuffer + 2, b
    mov sd_cmdBuffer + 3, ax
    mov sd_cmdBuffer + 4, a
    mov sd_cmdBuffer + 5, #sd_ANYcrc
    mov r2, #sdResponse_R1withData
    acall sd_sendPacket
    ret

;Texts
sd_NoCardDetectedText:
    .asciz \No SD card detected\
sd_UnknownCardText:
    .asciz \Unknown or bad card\
sd_setupText1:
    .ascii \Initializing SD card\
    .db newLine, 0
sd_setupText2:
    .ascii \SD card ready\
    .db newLine, 0

.include \src/System/Drivers/SD/SDCommand.asm\