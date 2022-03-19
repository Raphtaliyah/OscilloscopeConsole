; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module StdoutExtensions
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl byteToHexStringTable
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/StandardOut.h.asm\
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

;--------------------------------------------
; Sends an array of bytes to stdout.
;--------------------------------------------
; Parameters:
;	dptr - array pointer
;   r0   - length
; Returns:
;	nothing
;--------------------------------------------
stdoutSendBuffer:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    mov   r1, r0
    mov   a,  r1        ; Check for 0 length
    jz    sbZeroLength
    sbBufferCopyLoop:
    
    movx  a,  @dptr
    inc   dptr
    mov   r0, a
    lcall stdoutSendByte
    
    djnz  r1, sbBufferCopyLoop
    sbZeroLength:
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Sends an array of bytes to stdout.
;--------------------------------------------
; Parameters:
;   dptr  - array pointer
;   r0:r1 - length
; Returns:
;   nothing
;--------------------------------------------
stdoutSendBuffer16:
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    push dplb
    push dphb
    
    mov r1, r0          ; Move length (r0:r1) to (r1:r2)
    mov r2, r1
    
    mov  a,    r1       ; /dptr = dptr + r0:r1
    add  a,    dpl
    mov  dplb, a
    mov  a,    r2
    addc a,    dph
    mov  dphb, a
    
    mov  a, r1          ; Check for 0 length
    jnz  sb16BufferCopy
    mov  a, r2
    jnz  sb16BufferCopy
    sjmp sb16ZeroLength
    sb16BufferCopy:
    
    movx a, @dptr       ; Send byte
    mov r0, a
    lcall stdoutSendByte
    inc dptr
    
    mov  a, dpl         ; At the end?
    cjne a, dplb, sb16BufferCopy
    mov  a, dph
    cjne a, dphb, sb16BufferCopy
    sb16ZeroLength:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Sends a null terminated string to stdout.
;--------------------------------------------
; Parameters:
;   dptr - string pointer
; Returns:
;   nothing
;--------------------------------------------
stdoutSendString:
    push acc
    push r0
    push dpl
    push dph
    
    stringCopy:
    movx  a,  @dptr  ; Get next byte.
    jnz   notNull    ; Only send if the byte is not null.
    sjmp  sentString ; Byte is null, at the end of the string.
    notNull:
    inc   dptr       ; Send the byte and go next.
    mov   r0, a
    lcall stdoutSendByte
    sjmp  stringCopy
    sentString:
    
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

;--------------------------------------------
; Sends a null terminated string to stdout
; and a new line (\n)
;--------------------------------------------
; Parameters:
;   dptr - string pointer
; Returns:
;   nothing
;--------------------------------------------
stdoutSendStringNewLine:
    push r0
    
    lcall stdoutSendString ; Send the string
    mov   r0, #newLine     ; Send new line
    lcall stdoutSendByte
    
    pop r0
    ret

;--------------------------------------------
; Converts a byte to hex and send it to
; stdout.
;--------------------------------------------
; Parameters:
;   r0 - byte
; Returns:
;   nothing
;--------------------------------------------
stdoutSendByteAsHexString:
    push acc
    push r0
    push b
    push dpl
    push dph
    
    mov dptr, #byteToHexStringTable ; Get the pointer to the table.
    
    mov  a,   r0 ; Multiply by 3 (2 character + null terminator)
    mov  b,   #3 ; and add it to dptr.
    mul  ab
    add  a,   dpl
    mov  dpl, a
    mov  a,   b
    addc a,   dph
    mov  dph, a
    
    clr   a      ; Send 2 bytes (ignore the null).
    movc  a,  @a + dptr
    mov   r0, a
    lcall stdoutSendByte
    inc   dptr
    clr   a
    movc  a,  @a + dptr
    mov   r0, a
    lcall stdoutSendByte
    
    pop dph
    pop dpl
    pop b
    pop r0
    pop acc
    ret

;--------------------------------------------
; Converts a byte to hex and sends it to
; stdout wiht a "0x" prefix.
;--------------------------------------------
; Parameters:
;	r0 - byte
; Returns:
;	nothing
;--------------------------------------------
stdoutSendFullHex:
    push  r0                         ; Send the prefix
    mov   r0, #0x30                  ; 0
    lcall stdoutSendByte
    mov   r0, #0x78                  ; x
    lcall stdoutSendByte
    pop   r0
    lcall stdoutSendByteAsHexString  ; Send the byte
    ret

;--------------------------------------------
; Converts a 16 bit number to hex and sends
; it to stdout with a "0x" prefix Parameters.
;--------------------------------------------
; Parameters:
;	r0:r1 - number
; Returns:
;	nothing
;--------------------------------------------
stdoutSendFullHex16:
    push acc
    push r0
    
    push  r0              ; Send the prefix
    mov   r0, #0x30       ; 0
    lcall stdoutSendByte
    mov   r0, #0x78       ; x
    lcall stdoutSendByte
    pop   r0
    mov   a,  r0          ; Send the high byte
    mov   r0, r1
    lcall stdoutSendByteAsHexString
    mov   r0, a           ; Send the low byte
    lcall stdoutSendByteAsHexString
    
    pop r0
    pop acc
    ret

;--------------------------------------------
; Converts a 32 bit number to hex and sends
; it to stdout with a "0x" prefix.
;--------------------------------------------
; Parameters:
;	r0:r1:r2:r3 - number
; Returns:
;	nothing
;--------------------------------------------
stdoutSendFullHex32:
    push acc
    push r0
    
    push  r0        ; Send the prefix
    mov   r0, #0x30 ; 0
    lcall stdoutSendByte
    mov   r0, #0x78 ; x
    lcall stdoutSendByte
    pop   r0
    
    push  r0        ; Send the 4th byte
    mov   r0, r3
    lcall stdoutSendByteAsHexString
    mov   r0, r2    ; Send the 3rd bute
    lcall stdoutSendByteAsHexString
    mov   r0, r1    ; Send the 2nd byte
    lcall stdoutSendByteAsHexString
    pop   r0        ; Send the 1st byte
    lcall stdoutSendByteAsHexString
    
    pop r0
    pop acc
    ret

;--------------------------------------------
; Sends a null terminated string to stdout
; from ROM.
;--------------------------------------------
; Parameters:
;   dptr - string pointer
; Returns:
;   nothing
;--------------------------------------------
stdoutSendStringFromROM:
    push a
    push r0
    push dpl
    push dph
    
    stringCopyROM:
    clr   a             ; Get next byte.
    movc  a,  @a + dptr
    jnz   notNullROM    ; Only send if the byte is not null.
    sjmp  sentStringROM ; Byte is null, at the end of the string.
    notNullROM:
    inc   dptr          ; Send the byte and go next.
    mov   r0, a
    lcall stdoutSendByte
    sjmp  stringCopyROM
    sentStringROM:
    
    pop dph
    pop dpl
    pop r0
    pop a
    ret

;--------------------------------------------
; Sends a null terminated string from ROM to
; stdout and a new line (\n).
;--------------------------------------------
; Parameters:
;   dptr - string pointer
; Returns:
;   nothing
;--------------------------------------------
stdoutSendStringFromROMNewLine:
    push  r0
    lcall stdoutSendStringFromROM   ; Send the string
    mov   r0, #newLine              ; Send new line
    lcall stdoutSendByte
    pop   r0
    ret

;--------------------------------------------
; Sends a new line to stdout.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
stdoutSendNewLine:
    push  r0
    mov   r0, #newLine
    lcall stdoutSendByte
    pop   r0
    ret