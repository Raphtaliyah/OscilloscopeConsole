; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module ApplicationMessage
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl stdoutSendStringFromROMNewLine
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Application.h.asm\
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

;--------------------------------------------
; Sends a message to the currently running
; application.
;--------------------------------------------
; Parameters:
;   r0    - Message id
;   /dptr - Message object, can be null if that type of message allows
; Returns:
;	nothing
;--------------------------------------------
sendApplicationMessage:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    lcall getCurrentApplication     ; Get the current application
    
    push  r0                        ; Read the msg handler
    read16FromDptrWithOffset #appcontext_MsgRecPtrOffset
    
    mov   dpl, r0                   ; Call the msg handler
    mov   dph, r1
    pop   r0                        ; Message id
    callDptr
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Provides default implementation for
; application message handlers.
;--------------------------------------------
; Parameters:
;   r0    - message id
;   /dptr - message object
; Returns:
;	nothing
;--------------------------------------------
defaultApplicationMessageHandler:
    ret