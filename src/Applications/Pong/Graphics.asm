; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module PongGraphics
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Pong/Headers/PongGraphics.h.asm\
    .include \src/Applications/Pong/Headers/PongResources.h.asm\
    
    .include \src/Headers/Graphics.h.asm\
    .include \src/Headers/Drawing.h.asm\
    
    .include \src/Macro/DptrMacro.asm\

    .include \src/Definitions/Bool.asm\
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

pongFrame:
    push a
    push r0
    push r1
    push dpl
    push dph

    ; Player 1
    ;--------------------------------------------
    mov   r0,   #player1X       ; Move to the player's coordinates
    mov   r1,   player1Coord
    lcall drawMoveToCoordinate
    
    mov   dptr, #playerGraphics ;Graphics
    mov   r0,   #1              ;Scale
    mov   r1,   #true           ;From ROM
    lcall drawVectorArray
    
    ; Player 2
    ;--------------------------------------------
    mov   r0,   #player2X
    mov   r1,   player2Coord    ; Move to the player's coordinates
    lcall drawMoveToCoordinate
    
    mov   dptr, #playerGraphics ;Graphics
    mov   r0,   #1              ;Scale
    mov   r1,   #true           ;From ROM
    lcall drawVectorArray

    ; Separator
    ;--------------------------------------------
    mov   r0,   #netX         ; Move to the net's coordinates.
    mov   r1,   #netY
    lcall drawMoveToCoordinate
    
    mov   dptr, #netGraphics  ;Graphics
    mov   r0,   #1            ;Scale
    mov   r1,   #true         ;From ROM
    lcall drawVectorArray     ; Draw the net.

    ; Ball
    ;--------------------------------------------
    mov r0, ballPosX
    mov r1, ballPosY
    lcall drawMoveToCoordinate  ; Draw the ball.
    lcall drawUpdateCoordinates
    
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret