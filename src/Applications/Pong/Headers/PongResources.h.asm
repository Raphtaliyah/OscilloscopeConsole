; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef PongResources.h.asm
    .define PongResources.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl ballYDir, ballXDir, ballPosX, ballPosY, ballSpeedX
    .globl ballSpeedY, player1Coord, player2Coord, playerScores
    .globl netGraphics, playerGraphics
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Start positions
    ;--------------------------------------------
    .equ ballStartX,         128
    .equ ballStartYmin,      128-16
    .equ ballStartYmax,      128+16
    
    ; Ball speed
    ;--------------------------------------------
    .equ ballSpeedXreal,     1
    .equ ballSpeedXdecimal,  128
    .equ ballSpeedYreal,     1
    .equ ballSpeedYdecimal,  128
    .equ ballSpeedXincrease, 10     ; Decimal!
    .equ ballSpeedYincrease, 10     ; ^
    
    ; Ball directions
    ;--------------------------------------------
    .equ ballDir_XUpYUp,     0b00
    .equ ballDir_XUpYDown,   0b01
    .equ ballDir_XDownYUp,   0b10
    .equ ballDir_XUpYUp,     0b11
    
    ; Net
    ;--------------------------------------------
    .equ netX,               128
    .equ netY,               0

    ; Player
    ;--------------------------------------------
    .equ player1X,           5
    .equ player2X,           250
    .equ playerSize,         48
    .endif