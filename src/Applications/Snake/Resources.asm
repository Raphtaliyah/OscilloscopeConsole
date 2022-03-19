; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module SnakeResources
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Snake/Headers/SnakeResources.h.asm\
    
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
    snakeCollision:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    snakeHeadCoords:
        .ds 2
    foodCoords:
        .ds 2

    snakeHead:
        .ds 1 ; Direction
        .ds 2 ; Next head
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    snakeBody:
        .db 3
        .db vectDrawLineX | (vectDrawLineY << 4)
        .db snakeCellSize
        .db snakeCellSize
        .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
        .db snakeCellSize
        .db snakeCellSize
        .db snakeCellSize
        .db vectDrawLineX
        .db snakeCellSize
    
    food:
        .db 3
        .db vectMoveX | (vectDrawDiagL << 4)
        .db snakeCellSize/2
        .db snakeCellSize/2
        .db vectDrawDiagR | (vectMoveYNeg << 4)
        .db snakeCellSize/2
        .db snakeCellSize
        .db vectDrawDiagR | (vectDrawDiagL << 4)
        .db snakeCellSize/2
        .db snakeCellSize/2
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

