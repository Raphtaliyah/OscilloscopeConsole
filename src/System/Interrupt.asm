; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Interrupt
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Interrupt.h.asm\
    .include \src/Headers/Stack.h.asm\
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
    interruptCounter:
        .ds 4
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
; Initializes the interrupt controller.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initInterruptSystem:
    push acc
    push dpl
    push dph
    
    mov  dptr,  #interruptCounter  ; Set the interrupt counter to 0
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    
    setb EA                        ; Enable global interrupts
    
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Gets the number of interrupts since startup.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   stack(4) - Interrupt count.
;--------------------------------------------
getInterruptCount:
    push acc
    push r0
    push dpl
    push dph
    
    disableIntRestorable
    
    mov  r0,   bp                  ; Copy the value to the stack.
    mov  dptr, #interruptCounter
    movx a,    @dptr
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr
    mov  @r0,  a
    inc  r0
    
    restoreInt
    
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

onInterrupt:
    push acc
    push psw
    push dpl
    push dph
    
    mov  dptr,  #interruptCounter  ; Increment the interrupt counter.
    movx a,     @dptr              ; 1st byte
    add  a,     #1
    movx @dptr, a
    jnc  incremented
    inc  dptr                      ; 2nd byte
    movx a,     @dptr
    addc a,     #0
    movx @dptr, a
    jnc  incremented
    inc  dptr                      ; 3rd byte
    movx a,     @dptr
    addc a,     #0
    movx @dptr, a
    jnc  incremented
    inc  dptr                      ; 4th byte
    movx a,     @dptr
    addc a,     #0
    movx @dptr, a
    incremented:
    
    pop dph
    pop dpl
    pop psw
    pop acc
    ret