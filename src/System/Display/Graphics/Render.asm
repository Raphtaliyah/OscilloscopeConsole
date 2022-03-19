; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Render
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl setFrameHandlerCallback, onFrameInterrupt
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Render.h.asm\
    .include \src/Headers/InvocationArray.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Macro/Interrupt.asm\
    .include "src/Macro.asm"
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
    renderFunction:
        .ds 2
    preRenderInvocArray:
        .ds preRenderArraySize * 2 + 1
    postRenderInvocArray:
        .ds postRenderArraySize * 2 + 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringInit:
        .asciz /Setting up rendering... /
    stringReady:
        .asciz /Done!/
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ preRenderArraySize,    5
    .equ postRenderArraySize,   5
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Initializes the renderer.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
initRender:
    push acc
    push r0
    push dpl
    push dph
    
    mov   dptr, #stringInit         ; Print the init text.
    lcall stdoutSendStringFromROM
    
    mov  dptr,  #renderFunction     ; Set the render function to null.
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    
    mov   dptr, #preRenderInvocArray  ; Create the pre-render array
    mov   r0, #preRenderArraySize
    lcall constructInvocationArray
    mov   dptr, #postRenderInvocArray ; and the post-render array.
    mov   r0, #postRenderArraySize
    lcall constructInvocationArray
    
    mov   dptr, #onFrame              ; Set the frame handler to the
    lcall setFrameHandlerCallback     ; renderer's frame function.
    
    mov   dptr, #stringReady          ; Print ready text.
    lcall stdoutSendStringFromROMNewLine
    
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

;--------------------------------------------
; Frame event handler.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
onFrame:
    push acc
    push dpl
    push dph
    
    mov   dptr, #preRenderInvocArray; Call the pre-render functions
    lcall invocationArrayExecute
    
    ldVarDptr #renderFunction       ; Load the render function pointer
    mov  a, dpl                     ; Check if it's null, if it is,
    jnz  renderPtrNotNull           ; don't call.
    mov  a, dph
    jnz  renderPtrNotNull
    sjmp renderPtrNull
    renderPtrNotNull:
    callDptr                        ; Not null, Call the function.
    renderPtrNull:
    
    mov   dptr, #postRenderInvocArray; Call the post-render functions
    lcall invocationArrayExecute
    
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Sets the function called for rendering.
;--------------------------------------------
; Parameters:
;   dptr - function pointer
; Returns:
;	nothing
;--------------------------------------------
setRenderFunction:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    disableIntRestorable
    inc AUXR1
    mov dptr, #renderFunction
    writeADptrToDptr
    restoreInt
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Adds a function to the list of functions to
; be called before rendering a frame.
;--------------------------------------------
; Parameters:
;   dptr - function pointer.
; Returns:
;   r0 - 0x00 for success, 0xFF for fail
;--------------------------------------------
addPreRenderFunction:
    push a
    push dplb
    push dphb
    
    disableIntRestorable
    mov   /dptr, #preRenderInvocArray
    lcall invocationArrayAdd
    restoreInt
    
    pop dphb
    pop dplb
    pop a
    ret

;--------------------------------------------
; Removes a function from the list of
; functions to be called before rendering a
; frame.
;--------------------------------------------
; Parameters:
;   dptr - function pointer.
; Returns:
;   r0 - 0x00 for success, 0xFF for fail.
;--------------------------------------------
removePreRenderFunction:
    push a
    push dplb
    push dphb
    
    disableIntRestorable
    mov   /dptr, #preRenderInvocArray
    lcall invocationArrayRemove
    restoreInt
    
    pop dphb
    pop dplb
    pop a
    ret

;--------------------------------------------
; Adds a function to the list of functions
; to be called after rendering a frame.
;--------------------------------------------
; Parameters:
;   dptr - function pointer.
; Returns:
;   r0 - 0x00 for success, 0xFF for fail.
;--------------------------------------------
addPostRenderFunction:
    push a
    push dplb
    push dphb
    
    disableIntRestorable
    mov   /dptr, #postRenderInvocArray
    lcall invocationArrayAdd
    restoreInt
    
    pop dphb
    pop dplb
    pop a
    ret

;--------------------------------------------
; Removes a function from the list of
; functions to be called after rendering a
; frame.
;--------------------------------------------
; Parameters:
;   dptr - function pointer.
; Returns:
;   r0 - 0x00 for success, 0xFF for fail.
;--------------------------------------------
removePostRenderFunction:
    push a
    push dplb
    push dphb
    
    disableIntRestorable
    mov   /dptr, #postRenderInvocArray
    lcall invocationArrayRemove
    restoreInt
    
    pop dphb
    pop dplb
    pop a
    ret