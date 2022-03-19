; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Error
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Error.h.asm\
    .include \src/Macro.asm\
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
    .area DATA  (DSEG)
    .area XDATA (DSEG)

    ; The code of the last error.
    ;--------------------------------------------
    lastError:
        .ds 1
    
    ; The address of where the last error occurred.
    ;--------------------------------------------
    lastErrorAddress:
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
; Sets the last error.
; Not valid in an interrupt context.
;--------------------------------------------
; Parameters:
;	r0                   - Error code
;   (implicit) stack (2) - Source address.
; Returns:
;	nothing
;--------------------------------------------
setLastError:
    push a
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    ;TODO: Check for interrupt context and reject.
    
    mov  dptr,  #lastError  ; Set the error code.
    mov  a,     r0
    movx @dptr, a
    
    disableIntRestorable
    mov  dplb,  sp                ; Save the current stack pointer.
    mov  dphb,  spx
    pop  r1                       ; Get the return address.
    pop  r0
    mov  dptr,  #lastErrorAddress ; And write it to the
    mov  a,     r0                ; last error address.
    movx @dptr, a
    inc  dptr
    mov  a,     r1
    movx @dptr, a
    mov  sp,    dplb              ; Restore the stack pointer.
    mov  spx,   dphb
    restoreInt
    
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop a
    ret

;--------------------------------------------
; Returns the last error.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	r0 - The last error.
;--------------------------------------------
getLastError:
    push a
    push dpl
    push dph
    
    mov  dptr, #lastError
    movx a, @dptr
    mov  r0, a
    
    pop dph
    pop dpl
    pop a
    ret

;--------------------------------------------
; Returns the address where the last error
; occurred.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	r0:r1 - The address of the last error.
;--------------------------------------------
getLastErrorAddress:
    push a
    push dpl
    push dph
    
    mov  dptr, #lastErrorAddress
    movx a, @dptr
    mov  r0, a
    inc  dptr
    movx a, @dptr
    mov  r1, a
    
    pop dph
    pop dpl
    pop a
    ret