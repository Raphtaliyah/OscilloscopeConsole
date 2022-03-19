; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Drawing
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Drawing.h.asm\
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
    drawingXCoordinate:
        .ds 1
    drawingYCoordinate:
        .ds 1
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ YDAC, 0x8000
    .equ XDAC, 0x8003
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Draws a line on the X axis.
;--------------------------------------------
; Parameters:
;   r0 - Length.
; Returns:
;   nothing
;--------------------------------------------
drawLineX:
    push a
    push r0
    push dpl
    push dph
    
    mov  dptr,  #YDAC           ; Update the Y coordinate.
    mov  a,     drawingYCoordinate
    movx @dptr, a
    
    mov  dptr,  #XDAC           ; Load the X DAC address.
    mov  a,     drawingXCoordinate ; Use 'a' as the coordinate.
    
    xLineLoop:
    movx @dptr, a
    inc  a
    djnz r0,    xLineLoop
    
    mov drawingXCoordinate, a   ; Update the coordinate.
    
    pop dph
    pop dpl
    pop r0
    pop a
    ret

;--------------------------------------------
; Draws a line on the Y axis.
;--------------------------------------------
; Parameters:
;   r0 - Length.
; Returns:
;	nothing
;--------------------------------------------
drawLineY:
    push a
    push r0
    push dpl
    push dph

    mov  dptr,  #XDAC           ; Update the X coordinate.
    mov  a,     drawingXCoordinate
    movx @dptr, a
    
    mov  dptr,  #YDAC           ; Load the Y DAC address.
    mov  a,     drawingYCoordinate ; Use 'a' as the coordinate.
    
    yLineLoop:
    movx @dptr, a
    inc  a
    djnz r0,    yLineLoop
    
    mov drawingYCoordinate, a   ; Update the coordinate.

    pop dph
    pop dpl
    pop r0
    pop a
    ret

;--------------------------------------------
; Moves to a new coordinate.
;--------------------------------------------
; Parameters:
;   r0 - New X coordinate.
;   r1 - New Y coordinate.
; Returns:
;   nothing
;--------------------------------------------
drawMoveToCoordinate:
    mov drawingXCoordinate, r0
    mov drawingYCoordinate, r1
    ret

;--------------------------------------------
; Forces the beam to the current coordinate.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
drawUpdateCoordinates:
    push a
    push dpl
    push dph
    
    mov  dptr,  #XDAC
    mov  a,     drawingXCoordinate
    movx @dptr, a
    
    mov  dptr,  #YDAC
    mov  a,     drawingYCoordinate
    movx @dptr, a
    
    pop dph
    pop dpl
    pop a
    ret