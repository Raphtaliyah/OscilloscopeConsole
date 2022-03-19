; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Millis
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Millis.h.asm\
    .include \src/Headers/Stack.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/PCA.h.asm\
    .include \src/Macro/DptrMacro.asm\
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
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    ; Millis counter.
    ;--------------------------------------------
    millisSinceStartup:
        .ds 4
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringFailedToTakeModule:
        .ascii /Failed to take PCA module for millis. /
        .asciz /Millis will not be enabled./
    stringMillisEnabled:
        .asciz /Millis has been enabled./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; One millisecond in PCA cycles.
    ;--------------------------------------------
    .equ millisecInPcaCycles,           3125
    ; Millis PCA module.
    ;--------------------------------------------
    .equ millisPCAmodule,               0x01
    ; PCA module control register.
    ;--------------------------------------------
    .equ millisModuleControlRegister,   CCAPM1
    ; PCA module value registers.
    ;--------------------------------------------
    .equ millisModuleRegisterLow,       CCAP1L
    .equ millisModuleRegisterHigh,      CCAP1H
    ; PCA module interrupt flag.
    ;--------------------------------------------
    .equ millisModuleInterruptFlag,     CCF1
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Initializes millis.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	r0 - Status code.
;--------------------------------------------
initMillis:
    push acc
    push dpl
    push dph
    
    mov  dptr,  #millisSinceStartup  ; Set the counter to 0.
    clr  a
    movx @dptr, a                    ; Byte #0
    inc  dptr
    movx @dptr, a                    ; Byte #1
    inc  dptr
    movx @dptr, a                    ; Byte #2
    inc  dptr
    movx @dptr, a                    ; Byte #3
    
    mov r0,     #success             ; Set the status code.
    
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Enables millis.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
enableMillis:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    mov   r0,   #millisPCAmodule ; Take the PCA module.
    mov   dptr, #millisInterrupt
    lcall pcaTakeModule
    mov   a,    r0               ; Success?
    jz    PcaTaken
    mov   dptr, #stringFailedToTakeModule ; Failed to take, 
    lcall stdoutSendStringFromROMNewLine  ; print fail message.
    sjmp  millisEnableExit                ; TODO: Return a status code
    PcaTaken:
    
    ; Set the value in the module to be 1 ms from now.
    lcall pcaReadValue
    mov   a,                        r0
    add   a,                        #<millisecInPcaCycles
    mov   millisModuleRegisterLow,  a
    mov   a,                        r1
    addc  a,                        #>millisecInPcaCycles
    mov   millisModuleRegisterHigh, a
    
    ; Enable module, Match enable, Enbal CCF interrupt
    mov millisModuleControlRegister, #ECOM | MAT | ECCF
    
    mov   dptr, #stringMillisEnabled  ; Print success message.
    lcall stdoutSendStringFromROMNewLine
    
    millisEnableExit:
    
    mov r0, #success    ; This is called as driver init.

    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Returns the number of milliseconds since
; startup.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	stack (4) - The number of milliseconds.
;--------------------------------------------
millis:
    push acc
    push r0
    push dpl
    push dph
    
    disableIntRestorable
    
    mov  r0, bp
    mov  dptr, #millisSinceStartup  ; Load the value
    movx a,    @dptr                ; Byte #0
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr                ; Byte #1
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr                ; Byte #2
    mov  @r0,  a
    inc  r0
    inc  dptr
    movx a,    @dptr                ; Byte #3
    mov  @r0,  a
    
    restoreInt
    
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

; Copies the milliseconds passed since startup to a buffer
; Parameters:
; dptr - pointer to buffer
; Returns: none
copyMillisToBuffer:
    push acc
    push r0
    push dpl
    push dph
    
    ENTER 4        ; Get the millis value
    lcall millis
    
    mov r0, bp
    mov  a,     @r0
    inc  r0
    movx @dptr, a  ; byte #0
    inc  dptr
    mov  a,     @r0
    inc  r0
    movx @dptr, a  ; byte #1
    inc  dptr
    mov  a,     @r0
    inc  r0
    movx @dptr, a  ; byte #2
    inc  dptr
    mov  a,     @r0
    movx @dptr, a  ; byte #3
    
    LEAVE
    
    pop dph
    pop dpl
    pop r0
    pop acc
    ret


;--------------------------------------------
; Millis PCA module interrupt handler
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
millisInterrupt:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    ; Calculate the next interrupt time
    ; note: using the PCA value might not be accurate because
    ; note: interrupts are not serviced immediately but it's better
    ; note: than potentially skipping a lot of milliseconds because 
    ; note: the new value is still behind the counter.
    ; note: (Could happen if interrupts are disabled for long enough)
    lcall pcaReadValue
    mov   a,                        r0
    add   a,                        #<millisecInPcaCycles
    mov   millisModuleRegisterLow,  a
    mov   a,                        r1
    addc  a,                        #>millisecInPcaCycles
    mov   millisModuleRegisterHigh, a
    
    mov  dptr,  #millisSinceStartup ; Increment the counter
    movx a,     @dptr               ; byte #0
    add  a,     #1
    movx @dptr, a
    jnc  incremented
    inc  dptr
    movx a,     @dptr               ; byte #1
    addc a,     #0
    movx @dptr, a
    jnc  incremented
    inc  dptr
    movx a,     @dptr               ; byte #2
    addc a,     #0
    movx @dptr, a
    jnc incremented
    inc  dptr
    movx a,     @dptr               ; byte #3
    addc a,     #0
    movx @dptr, a
    incremented:
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret