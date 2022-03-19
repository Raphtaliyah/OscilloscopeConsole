; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Sound
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Sound.h.asm\
    .include \src/Headers/Memset.h.asm\
    .include \src/Headers/SPI.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/SD.h.asm\
    .include \src/Macro/Interrupt.asm\
    .include \src/Definitions/System.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    bufferSelect:
        .ds 1   ; 0 - buffer A; 1 - buffer B
    beepPlaying:
        .ds 1
    soundPendingBufferRequest:
        .ds 1
    .area DATA  (DSEG)
    bufferPointer:
        .ds 2
    beepPointer:
        .ds 2
    .area XDATA (DSEG)
    bufferA:
        .ds bufferSize
    bufferB:
        .ds bufferSize
    soundVolume:
        .ds 1
    sound_SDaddress:
        .ds 4
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    beepRaw:
        .incbin \src/Binary/Beep-22050-mono-8bit-unsigned.raw\
    beepLimit:

    stringCreatingDevice:
        .asciz \Creating sound device...\
    stringDeviceReady:
        .asciz \Sound device ready.\
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ bufferSize,  2048
    .equ beepSize,    beepLimit-beepRaw
    .equ timerReload, 0xFDC9
    .equ soundDac,    0x8002
    
    ; Volume
    ;--------------------------------------------
    .equ volumePotAddress,     0x00
    .equ volumePotCommandByte, 0b00010001
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

createSoundDevice:
    push dpl
    push dph

    mov   dptr, #stringCreatingDevice
    lcall stdoutSendStringFromROMNewLine
    
    anl TMOD, #0b00001111   ; Setup timer 1 (Mode 1, gating disabled,
    orl TMOD, #0b00010000   ; timer mode, PWM operation).
    
    setb ET1
    
    mov TL1, #0x0           ; Set frequency.
    mov TH1, #0x0
    mov RL1, #<timerReload
    mov RH1, #>timerReload
    
    lcall createBuffers
    clr   beepPlaying
    
    setb  TR1               ; Start the timer.

    mov   dptr, #stringDeviceReady
    lcall stdoutSendStringFromROMNewLine
    
    pop dph
    pop dpl
    ret

createBuffers:
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    mov dptr, #bufferA      ; Clear buffer A
    mov r0,   #<bufferSize
    mov r1,   #>bufferSize
    mov r2,   #NULL
    lcall memset
    
    mov dptr, #bufferB      ; Clear buffer B
    mov r0,   #<bufferSize
    mov r1,   #>bufferSize
    mov r2,   #NULL
    lcall memset
    
    clr  bufferSelect       ; Reset flags
    setb soundPendingBufferRequest
    
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    ret

;--------------------------------------------
; Changes the sound volume.
;--------------------------------------------
; Parameters:
;	r0 - Volume
; Returns:
;	nothing
;--------------------------------------------
soundSetVolume:
    push a
    push r0
    push dpl
    push dph

    disableIntRestorable
    
    push  r0
    mov   r0, #volumePotAddress
    lcall spiSelectDevice
    
    sendSpiByteBlocking #volumePotCommandByte
    
    pop r0
    sendSpiByteBlocking r0
    
    mov  dptr,  #soundVolume
    mov  a,     r0
    movx @dptr, a
    
    lcall spiDisableDevice

    restoreInt
    
    pop dph
    pop dpl
    pop r0
    pop a
    ret

;--------------------------------------------
; Plays the beep sound effect.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
playBeep:
    jb beepPlaying, alreadyPlaying

    mov  beepPointer + 0, #<beepRaw
    mov  beepPointer + 1, #>beepRaw
    setb beepPlaying
    
    alreadyPlaying:
    ret

;Plays a sound from SD card
;r2 - Address 0 (low)
;r3 - Address 1
;r4 - Address 2
;r5 - Address 4 (high)
sound_play:
    ;Push registers
    push acc
    push dpl
    push dph
    
    ;Reset the buffer
    acall createBuffers

    ;Write the address
    mov dptr, #sound_SDaddress
    mov a, r2
    movx @dptr, a
    inc dptr
    mov a, r3
    movx @dptr, a
    inc dptr
    mov a, r4
    movx @dptr, a
    inc dptr
    mov a, r5
    movx @dptr, a

    ;Start the timer
    setb TR1

    ;Pop registers
    pop dph
    pop dpl
    pop acc
    ret

soundUpdate:
    ;Check if a buffer needs reloading
    jb soundPendingBufferRequest, sound_loadBuffer
    ;=> both buffers full
    ret
    sound_loadBuffer:
    ;=> unused buffer is empty

    ;Push registers
    push acc
    push ax
    push b
    push bx
    push psw
    push r2
    push r3
    push dpl
    push dph
    push dplb
    push dphb

    ;Get the empty buffer
    jnb bufferSelect, sound_bPlaying
    mov /dptr, #bufferB
    sjmp sound_gotEmptyBuffer
    sound_bPlaying:
    mov /dptr, #bufferA
    sound_gotEmptyBuffer:

    ;Load buffer in 128 byte chunks
    mov r3, #bufferSize / 128
    sound_loadLoop:
    ;Add the 128 to the sd address and also get the address
    mov dptr, #sound_SDaddress
    ;1st byte
    movx a, @dptr
    add a, #128
    push acc
    movx @dptr, a
    inc dptr
    ;2nd byte
    movx a, @dptr
    addc a, #0
    mov ax, a
    movx @dptr, a
    inc dptr
    ;3rd byte
    movx a, @dptr
    addc a, #0
    mov b, a
    movx @dptr, a
    inc dptr
    ;4th byte
    movx a, @dptr
    addc a, #0
    mov bx, a
    movx @dptr, a
    ;Get the first byte back
    pop acc
    
    ;Fill the buffer from the sd buffer
    mov r2, #128
    lcall sd_readBuffer
    
    ;Add 128 to the buffer pointer
    inc AUXR1
    mov a, dpl
    add a, #128
    mov dpl, a
    mov a, dph
    addc a, #0
    mov dph, a
    inc AUXR1
    
    djnz r3, sound_loadLoop
    
    ;Clear the flag
    clr soundPendingBufferRequest
    
    ;Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r3
    pop r2
    pop psw
    pop bx
    pop b
    pop ax
    pop acc
    ret

soundInterrupt:
    push psw
    push a
    push r0
    push dpl
    push dph
    
    mov dpl, bufferPointer + 0  ; Read the pointer to the next sample.
    mov dph, bufferPointer + 1
    
    movx a,  @dptr              ; Read the next sample.
    mov  r0, a

    inc dptr                    ; Increment and write the pointer back
    mov bufferPointer + 0, dpl
    mov bufferPointer + 1, dph
    
    jb   bufferSelect, checkBufferBlimit    ; Check if the end of the
    mov  a, dpl                             ; buffer is reached.
    cjne a, #<(bufferA + bufferSize), bufferNotEmpty
    mov  a, dph
    cjne a, #>(bufferA + bufferSize), bufferNotEmpty
    sjmp bufferEmpty
    checkBufferBlimit:
    mov  a, dpl
    cjne a, #<(bufferB + bufferSize), bufferNotEmpty
    mov  a, dph
    cjne a, #>(bufferB + bufferSize), bufferNotEmpty
    bufferEmpty:
    
                                ; Check if the other buffer got filled
    jnb soundPendingBufferRequest, bufferWasFilled
    
    ; TODO: Crash?
    
    bufferWasFilled:
    setb soundPendingBufferRequest  ; Signal that a new buffer is
                                    ; empty.
    cpl  bufferSelect               ; Swap buffers.
    jb   bufferSelect, newBufferB   ; Reset the buffer pointer.
    mov  bufferPointer + 0, #<bufferA
    mov  bufferPointer + 1, #>bufferA
    sjmp bufferNotEmpty
    newBufferB:
    mov  bufferPointer + 0, #<bufferB
    mov  bufferPointer + 1, #>bufferB
    
    bufferNotEmpty:
    jnb beepPlaying, noBeep     ; Skip playing the beep if it's not
                                ; enabled.
    
    mov dpl, beepPointer + 0    ; Read the beep pointer.
    mov dph, beepPointer + 1
    
    clr  a                      ; Read the next beep sample.
    movc a, @a+dptr
    
    add a,  r0                  ; Mix the samples.
    rrc a
    mov r0, a
    
    inc dptr                    ; Increment beep pointer.

    mov beepPointer + 0, dpl    ; Write back beep pointer.
    mov beepPointer + 1, dph
    
    mov  a, dpl                 ; Check if the end of the beep is
    cjne a, #<beepLimit, beepNotAtEnd ; reached.
    mov  a, dph
    cjne a, #>beepLimit, beepNotAtEnd
    clr beepPlaying             ; Stop the beep.
    beepNotAtEnd:
    noBeep:
    
    mov  dptr,  #soundDac       ; Write the (mixed) sample.
    mov  a,     r0
    movx @dptr, a

    pop dph
    pop dpl
    pop r0
    pop a
    pop psw
    setb ea
    reti