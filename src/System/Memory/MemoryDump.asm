; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MemoryDump
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl stdoutSendStringFromROM, stdoutSendByteAsHexString
    .globl stdoutSendFullHex16, stdoutSendByte
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/MemoryDump.h.asm\
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
    stringDumping:
        .asciz /Dumping /
    stringBytesOfMemoryFrom:
        .asciz / bytes of memory from /
    stringTo:
        .asciz / to /
    stringEnd:
        .ascii /: /
        .db newLine
        .db 0
    stringSeparator:
        .asciz /| /
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ newLine,           0x0A ; \n
    .equ asciiPlaceHolder,  0x2E ; .
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Dumps a memory block to stdout.
;--------------------------------------------
; Parameters:
;   r0    - width
;   dptr  - start address
;   /dptr - stop address
; Returns:
;   nothing
;--------------------------------------------
stdoutDumpMemory:
    push a
    push r0
    push r1
    push r2
    push r3
    push dpl
    push dph
    push dplb
    push dphb
    
    mov  a,  dplb   ; Calculate the number of bytes to print
    clr  c
    subb a,  dpl
    mov  r2, a
    mov  a,  dphb
    subb a,  dph
    mov  r3, a
    
    push r0         ; Push width
    
    ; Send the text
    ; "Dumping numOfBytes byte of memory from startAddress to stopAddress"
    push  dpl
    push  dph
    mov   dptr, #stringDumping            ; Dumping ...
    lcall stdoutSendStringFromROM
    mov   r0,   r2                        ; ...numOfBytes...
    mov   r1,   r3
    lcall stdoutSendFullHex16
    mov   dptr, #stringBytesOfMemoryFrom  ; ... bytes of memory
    lcall stdoutSendStringFromROM         ; from ...
    pop   r1                              ; startAddress
    pop   r0
    push  r0
    push  r1
    lcall stdoutSendFullHex16
    mov   dptr, #stringTo                 ; ... to ...
    lcall stdoutSendStringFromROM
    mov   r0,   dplb                      ; stopAddress
    mov   r1,   dphb
    lcall stdoutSendFullHex16
    mov   dptr, #stringEnd                ; ...:\n
    lcall stdoutSendStringFromROM
    pop   dph
    pop   dpl
    
    pop   r0                              ; Pop width
    
    mov   a, r2          ; Check if the length(r2:r3) is not 0
    jnz   dumpLoop
    mov   a, r3
    jnz   dumpLoop
    sjmp  dumped         ; Length is 0.
    
    dumpLoop:
    push  r0                ; Push width
    
    mov   r0, dpl           ; Write the address
    mov   r1, dph
    lcall stdoutSendFullHex16
    mov   r0, #0x20         ; Insert a space
    lcall stdoutSendByte
    
    pop   r0                ; Peek width
    push  r0
    
    lcall dumpHex           ; Send the hex values
    
    push  dpl               ; Send separator
    push  dph
    mov   dptr, #stringSeparator
    lcall stdoutSendStringFromROM
    pop   dph
    pop   dpl
    
    lcall dumpAscii         ; Send ascii values
    
    mov   r0, #newLine      ; Send new line
    lcall stdoutSendByte
    
    pop r0                  ; Pop width
    
    mov  a,   dpl           ; Add the line length to the address
    add  a,   r0
    mov  dpl, a
    mov  a,   dph
    addc a,   #0
    mov dph,  a

    
    mov   a, dpl    ; Check if the current address is over (or equal)
    clr   c         ; to the stop address.
    subb a, dplb
    mov  a, dph
    subb a, dphb
    
    jc dumpLoop     ; Current address < limit

    dumped:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Dumps a line in hex format.
;--------------------------------------------
; Parameters:
;	r0 - Length
; Returns:
;	nothing
;--------------------------------------------
dumpHex:
    push a
    push r0
    push r1
    push dpl
    push dph

    mov   r1, r0
    
    hexDumpLoop:
    movx  a,  @dptr         ; Send byte.
    mov   r0, a
    lcall stdoutSendByteAsHexString
    mov   r0, #0x20         ; Insert a space.
    lcall stdoutSendByte
    
    inc   dptr              ; Next.
    djnz  r1, hexDumpLoop
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Dumps a line in ASCII format. (Ignoring not
; printable characters.)
;--------------------------------------------
; Parameters:
;   r0 - Length
; Returns:
;	nothing
;--------------------------------------------
dumpAscii:
    push a
    push r0
    push r1
    push dpl
    push dph
    
    mov  r1, r0
    
    asciiDumpLoop:
    movx  a,  @dptr             ; Get next byte
    mov   r0, a
    clr   c                     ; Check if the byte is in printable
    subb  a,  #0x20             ; range (0x20-0x7E (inclusive)).
    jc    notPrintable          ; < 0x20
    mov   a,  r0
    clr   c
    subb  a,  #0x7F
    jnc   notPrintable          ; >0x7E
    lcall stdoutSendByte        ; Printable, send the byte.
    sjmp  byteSent
    notPrintable:
    mov   r0, #asciiPlaceHolder ; Not printable, send the placeholder.
    lcall stdoutSendByte
    byteSent:

    mov   r0, #0x20             ; Insert a space
    lcall stdoutSendByte
    
    inc   dptr                  ; Next
    djnz  r1, asciiDumpLoop
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret