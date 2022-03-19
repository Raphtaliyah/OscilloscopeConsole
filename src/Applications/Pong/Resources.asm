; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module PongResources
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Pong/Headers/PongResources.h.asm\
    
    .include \src/Headers/Graphics.h.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    ballYDir:
        .ds 1
    ballXDir:
        .ds 1
    .area DATA  (DSEG)
    ballPosX:
        .ds 1
    ballPosY:
        .ds 1
    ballSpeedX:
        .ds 1
    ballSpeedY:
        .ds 1
    player1Coord:
        .ds 1
    player2Coord:
        .ds 1
    playerScores:
        .ds 1
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    netGraphics:
        .db (256/netSectionLength)/2
    .rept (256/netSectionLength)/2
        .db vectDrawLineY | (vectMoveY << 4)
        .db netSectionLength
        .db netSectionLength
    .endm

    playerGraphics:
        .db 1
        .db vectDrawLineY
        .db playerSize
        
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ netSectionLength, 8
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)
