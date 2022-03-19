; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module RomApplicationLoader
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl romStringLength, malloc, free, memset, loadFromROM16
    .globl stdoutSendFullHex16, stdoutSendFullHex, stdoutSendNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Macro/DptrMacro.asm\
    .include \src/Definitions/System.asm\
    .include \src/Headers/ApplicationLoaders.h.asm\
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
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; TODO: Clean up, use the offsets from typedef file

; Loads an application descriptor from ROM to RAM and hands it to the
; application manager
; Parameters:
;  /dptr - pointer in ROM to add descriptor
; Returns:
;  /dptr - pointer to the loaded application
;  r0 - status code (0x00 for success, 0xFF for fail)
loadApplicationFromROM:
    push acc
    push r1
    push r2
    push r3
    push r4
    push dpl
    push dph
    
    mov   dptr, #sizeof_APPCONTEXT  ; Allocate space for the app
    lcall malloc                    ; context.
    
    mov r3, dpl                     ; Store the address in r3:r4
    mov r4, dph
    
    mov  a,  dpl                    ; Check mallo return.
    cjne a,  #0xFF, contextAllocated
    mov  a,  dph
    cjne a,  #0xFF, contextAllocated
    mov  r0, #0xFF                  ; Malloc fail, return fail.
    ljmp failed
    contextAllocated:
    
    .swapDptr
    lcall loadName          ; Load the name of the application.
    mov   a,  r0            ; Success?
    jz    nameLoaded
    .swapDptr               ; Failed to load name,
    lcall free              ; free previous allocation.
    mov   r0, #0xFF
    ljmp  failed
    nameLoaded:
    
    .addDptr8Imm    2       ; Move past the name ptr
    .addAltDptr8Imm 2       ; (both address spaces).
    
    lcall loadPointer       ; Load the entry point.
    .addDptr8Imm    2       ; Move to next ptr.
    .addAltDptr8Imm 2
    
    lcall loadPointer       ; Load the message pointer.
    .addDptr8Imm    2       ; Move to next ptr.
    .addAltDptr8Imm 2
    
    .swapDptr               ; Null the rest.
    mov   r0, #<(sizeof_APPCONTEXT - (3 * sizeof_POINTER))
    mov   r1, #>(sizeof_APPCONTEXT - (3 * sizeof_POINTER))
    mov   r2, #NULL
    lcall memset
    .swapDptr
    
    mov r0, #0x00           ; Return success.
    failed:

    mov dplb, r3            ; Restore the pointer in r3:r4
    mov dphb, r4
    
    pop dph
    pop dpl
    pop r4
    pop r3
    pop r2
    pop r1
    pop acc
    ret

;--------------------------------------------
; Loads a pointer from the descriptor on the
; ROM to the RAM (swaps endinaness).
;--------------------------------------------
; Parameters:
;   dptr  - App descriptor pointer (adjusted).
;   /dptr - App context pointer (adjusted).
; Returns:
;	nothing
;--------------------------------------------
loadPointer:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    clr  a                  ; Load the address.
    movc a,   @a + dptr
    push acc
    inc  dptr
    clr  a
    movc a,   @a + dptr
    mov  dpl, a
    pop  dph
    
    .swapDptr
    mov  a,     dplb        ; Write the address.
    movx @dptr, a
    inc  dptr
    mov  a,     dphb
    movx @dptr, a
    .swapDptr
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Loads the name of the application.
;--------------------------------------------
; Parameters:
;   dptr  - app descriptor pointer (adjusted) (ROM)
;   /dptr - app context pointer (adjusted) (RAM)
; Returns:
;   r0 - 0x00 for success, 0xFF for fail
;--------------------------------------------
loadName:
    push acc
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    clr  a                  ; Get the pointer to name.
    movc a,   @a + dptr
    push acc
    inc  dptr
    clr  a
    movc a,   @a + dptr
    pop  dph
    mov  dpl, a
    
    push dpl                ; Push the pointer.
    push dph
    
    lcall romStringLength   ; Get the length of the string.
    
    mov  a,  r0             ; Add one to include the NULL terminator.
    add  a,  #1
    mov  r0, a
    mov  a,  r1
    addc a,  #0
    mov  r1, a
    
    mov dpl, r0             ; Allocate memory.
    mov dph, r1
    lcall malloc
    
    mov  a,  dpl            ; Check malloc return.
    cjne a,  #0xFF, stringAllocated
    mov  a,  dph
    cjne a,  #0xFF, stringAllocated
    pop  dph                ; Failed.
    pop  dpl
    mov  r0, #0xFF
    sjmp failedToLoadName
    stringAllocated:
    
    .swapDptr               ; Set the pointer in the application
    writeADptrToDptr        ; context.
    
    pop dph                 ; Copy the string.
    pop dpl
    lcall loadFromROM16
    .swapDptr
    
    mov r0, #0x00           ; Return success.
    failedToLoadName:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop acc
    ret