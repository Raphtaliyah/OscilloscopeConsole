; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef SnakeResources.h.asm
    .define SnakeResources.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl snakeHeadCoords, snakeHead, foodCoords, snakeCollision
    .globl snakeBody, food
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Snake size
    ;--------------------------------------------
    .equ snakeBoardSize, 32    
    .equ snakeCellSize,  256/snakeBoardSize
    
    ; Snake direction
    ;--------------------------------------------
    .equ snake_Up,    0x00
    .equ snake_Left,  0x01
    .equ snake_Right, 0x02
    .equ snake_Down,  0x03
    
    ; Game start parameters
    ;--------------------------------------------
    .equ snakeStartX,      10 *snakeCellSize
    .equ snakeStartY,      10 *snakeCellSize
    .equ foodStartX,       16 *snakeCellSize
    .equ foodStartY,       16 *snakeCellSize
    .endif