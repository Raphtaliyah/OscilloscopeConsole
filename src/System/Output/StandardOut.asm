; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module StandardOut
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl getCurrentStdout
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Macro/DptrMacro.asm\
    .include \src/Headers/Stack.h.asm\
    .include \src/Headers/StandardOut.h.asm\
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
    ; When set, stdout operates in standalone mode.
    ;--------------------------------------------
    inStandalone:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    ; pointer to a write byte function.
    ;--------------------------------------------
    stdoutPointer:
        .ds 2 
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

;--------------------------------------------
; Initializes standard out.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initStandardOut:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    disableIntRestorable
    
    lcall stdoutEnterStandalone ; Start in standalone mode with null
    mov   /dptr, #0             ; pointer.
    mov   dptr, #stdoutPointer
    writeADptrToDptr
    
    restoreInt
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Sets a fallback function to be used for
; stdout in standalone mode or when no
; applications have standardouts set.
;--------------------------------------------
; Parameters:
;	dptr - write byte function
; Returns:
;	nothing
;--------------------------------------------
stdoutSetFallbackFunction:
    push acc
    push dplb
    push dphb

    .swapDptr           ; Load the stdout pointer address.
    mov dptr, #stdoutPointer
    writeADptrToDptr
    .swapDptr
    
    pop dphb
    pop dplb
    pop acc
    ret

;--------------------------------------------
; Causes standard out to leave standlone
; mode.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
stdoutLeaveStandalone:
    clr inStandalone
    ret

;--------------------------------------------
; Causes standard out to enter standalone
; mode.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
stdoutEnterStandalone:
    setb inStandalone
    ret

;--------------------------------------------
; Sends a byte to standard out.
;--------------------------------------------
; Parameters:
;   r0 - Byte to send.
; Returns:
;   nothing
;--------------------------------------------
stdoutSendByte:
    push acc
    push dpl
    push dph
    
    lcall stdoutGetPointer  ; Get the stdout pointer.
    mov   a, dpl            ; Check for null ptr.
    jnz   validPtr
    mov   a, dph
    jnz   validPtr
    sjmp  stdoutNullPointer
    validPtr:
    
    callDptr                ; Call the function
    
    stdoutNullPointer:
    pop dph
    pop dpl
    pop acc
    ret


; note: doesn't save registers
;--------------------------------------------
; Returns the pointer to the current stdout
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	dptr - stdout pointer.
;--------------------------------------------
stdoutGetPointer:
    ; Return the fallback pointer in standalone mode
    jb    inStandalone, stdoutStandalone
    
    lcall getCurrentStdout      ; Load the stdout pointer from the
    mov   a, dpl                ; application manager and check null.
    jnz   stdoutAppPointerValid
    mov   a, dph
    jnz   stdoutAppPointerValid
    sjmp  stdoutStandalone      ; App manager returned null,
                                ; use the fallback pointer.
    stdoutAppPointerValid:
    ret                         ; The returned pointer was valid.
    
    stdoutStandalone:
    ldVarDptr #stdoutPointer    ; In standalone mode,
                                ; use the fallback pointer
    ret

;--------------------------------------------
; Returns the address stdout points to now.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	dptr - the address
;--------------------------------------------
stdoutGetAddress:
    ldVarDptr #stdoutPointer
    ret