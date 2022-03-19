; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module InvocationArray
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl malloc, free, memset
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Macro/dptrMacro.asm\
    .include \src/Headers/Error.h.asm\
    .include \src/Headers/InvocationArray.h.asm\
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
    .area DATA  (DSEG)
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; The size of the 'size' field in bytes
    ;--------------------------------------------
    .equ sizeSize, 1
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Constructs an invocation array.
;--------------------------------------------
; Parameters:
;	r0   - Size of the array in elements.
;   dptr - Pointer to the array.
; Returns:
;	nothing
;--------------------------------------------
constructInvocationArray:
    push acc
    push r1
    push r2
    
    mov a,  r0          ; Multiply size by 2 (r1:r2 = r0 << 1).
    clr c
    rlc a
    mov r1, a
    clr a
    rlc a
    mov r2, a
    
    mov  a,  r1         ; Add the size needed to store the size
    add  a,  #sizeSize  ; to the previous result.
    mov  r1, a
    mov  a,  r2
    addc a,  #0
    mov  r2, a
    
    push  r0            ; Fill the region with NULL.
    mov   r0, r1
    mov   r1, r2
    mov   r2, #NULL
    lcall memset
    pop   r0
    
    mov  a,     r0      ; Write the array size to the first byte.
    movx @dptr, a

    pop r2
    pop r1
    pop acc
    ret

;--------------------------------------------
; Deconstructs the invocation array.
;--------------------------------------------
; Parameters:
;	dptr - Pointer to the array.
; Returns:
;	nothing
;--------------------------------------------
deconstructInvocationArray:
    ret

;--------------------------------------------
; Invokes the non-null functions.
;--------------------------------------------
; Parameters:
;	dptr - Array pointer.
; Returns:
;	nothing
;--------------------------------------------
invocationArrayExecute:
    push acc
    push r1
    push dpl
    push dph

    movx a, @dptr       ; Read the size
    mov  r1, a
    inc  dptr
    jz   invokeLoopExit ; Check zero length
    
    invokeLoop:
    push dpl            ; Push address
    push dph

    ldPtrFromDptr       ; Read pointer
    
    mov  a, dpl         ; Check for null
    jnz  execPtrNotNull
    mov  a, dph
    jnz  execPtrNotNull
    sjmp execPtrNull    ; Ptr was null, skip
    execPtrNotNull:
    callDptr            ; Ptr not null, call the function
    execPtrNull:
    
    pop dph             ; Move the array pointer to the next element.
    pop dpl
    .addDptr8imm 2
    
    djnz r1, invokeLoop
    invokeLoopExit:
    
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

;--------------------------------------------
; Adds a pointer to the invocation array.
;--------------------------------------------
; Parameters:
;   dptr  - Function pointer to add.
;   /dptr - Array pointer.
; Returns:
;   r0    - 0x00 for success, 0xFF for fail.
;--------------------------------------------
invocationArrayAdd:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    .swapDptr
    
    ; Read the size
    movx a,  @dptr
    mov  r0, a
    inc  dptr
    
    nullSearchLoop:
    push dpl          ; Push array address.
    push dph
    
    ldPtrFromDptr     ; Check if there is a null at the current index.
    mov  a, dpl
    jnz  addPtrNotNull
    mov  a, dph
    jnz  addPtrNotNull
    pop  dph          ; There is! Pop the address.
    pop  dpl
    writeADptrToDptr  ; Write the function pointer.
    mov  r0, #0x00    ; Write success.
    sjmp addDone      ; Done!
    addPtrNotNull:
    
    pop dph           ; Pop array address.
    pop dpl
    .addDptr8imm 2
    
    djnz  r0, nullSearchLoop

    mov   r0, #ERR_NO_SPACE  ; Set the error and return.
    lcall setLastError
    mov   r0, #0xFF
    
    addDone:
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Removes a function from the invocation
; array.
;--------------------------------------------
; Parameters:
;	dptr  - Function pointer.
;   /dptr - Array pointer.
; Returns:
;   r0    - 0x00 for success, 0xFF for fail.
;--------------------------------------------
invocationArrayRemove:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    .swapDptr
    
    movx a, @dptr ; Read the size
    mov  r0, a
    inc  dptr
    
    searchLoop:
    push dpl                     ; Push the array address.
    push dph
    ldPtrFromDptr                ; Load the next pointer.
    mov  a, dpl                  ; Check if it's equal to the
    cjne a, dplb, remPtrNotEqual ; one in the parameter.
    mov  a, dph
    cjne a, dphb, remPtrNotEqual
    pop  dph                     ; Equal, found the index, pop the
    pop  dpl                     ; array address.
    clr  a                       ; Replace original pointer with null.
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    mov  r0, #0x00               ; Write success.

    sjmp remDone
    remPtrNotEqual:
    
    pop dph                      ; Pop array address
    pop dpl
    .addDptr8imm 2

    djnz r0, searchLoop
    
    mov   r0, #ERR_NO_MATCH      ; Set the error and return.
    lcall setLastError
    mov   r0, #0xFF
    
    remDone:
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret