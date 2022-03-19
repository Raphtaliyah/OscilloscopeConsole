; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module SnakeGraphics
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Snake/Headers/Snake.h.asm\
    .include \src/Applications/Snake/Headers/SnakeResources.h.asm\
    .include \src/Applications/Snake/Headers/SnakeGraphics.h.asm\
    
    .include \src/Headers/Graphics.h.asm\
    .include \src/Headers/Drawing.h.asm\
    
    .include \src/Definitions/Bool.asm\

    .include \src/Macro/DptrMacro.asm\
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

snakeFrame:
    push a
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push dpl
    push dph
    push dplb
    push dphb

    ; Border
    ;--------------------------------------------
    mov   r0, #0
    mov   r1, #0
    lcall drawMoveToCoordinate
    mov   r0, #0 ;(256)
    lcall drawLineX
    
    mov   r0, #0
    mov   r1, #0
    lcall drawMoveToCoordinate
    mov   r0, #0 ;(256)
    lcall drawLineY
    
    mov   r0, #0
    mov   r1, #255
    lcall drawMoveToCoordinate
    mov   r0, #0 ;(256)
    lcall drawLineX

    mov   r0, #255
    mov   r1, #255
    lcall drawMoveToCoordinate
    mov   r0, #0 ;(256)
    lcall drawLineY
    
    ; Body
    ;--------------------------------------------
    jnb   snakeVisible, bodyDone ; Don't draw if snake is not visible.
    mov   dptr, #snakeHeadCoords ; Read the starting coords.
    movx  a,    @dptr
    mov   r2,   a      ; X
    mov   r4,   a                ; Also save it to r4:r5 for collision
    inc   dptr                   ; detection with body.
    movx  a,    @dptr
    mov   r3,   a      ; Y
    mov   r5,   a
    
    mov  dptr,  #snakeHead       ; Linked list for snake
    mov  /dptr, #snakeBody       ; Graphics
    
    sjmp bodyDrawLoopEnter
    
    bodyDrawLoop:
    mov  a, r2                  ; Check if the next piece collaids
    cjne a, r4, bodyDrawLoopEnter ; with the head.
    mov  a, r3
    cjne a, r5, bodyDrawLoopEnter
    setb snakeCollision         ; Set the flag and handle it in the
                                ; next game tick.
    bodyDrawLoopEnter:
    mov   r0,   r2               ; Move to the coordinates.
    mov   r1,   r3
    lcall drawMoveToCoordinate
    
    .swapDptr                    ; Draw the body part.
    mov   dptr, #snakeBody       ; Graphics
    mov   r0,   #1               ; Scale
    mov   r1,   #true            ; From ROM
    lcall drawVectorArray
    .swapDptr
    
    inc  dptr                    ; Read the pointer to the next snake
    movx a,    @dptr
    push a
    inc  dptr
    movx a,    @dptr
    mov  dph, a
    pop  dpl
    
    mov  a, dph                  ; Break on NULL ptr
    jz   bodyDone
    mov  a, dpl
    jz   bodyDone

    movx a, @dptr               ; Read the direction and move the
                                ; coordinates in the opposite direction.
    cjne a,  #snake_Up, bodyNotUp; Up -> down
    mov  a,  r3                 ; Subtract the cell size from Y.
    clr  c
    subb a,  #snakeCellSize
    mov  r3, a
    sjmp bodyDrawLoop

    bodyNotUp:                  ; Down -> up
    cjne a,  #snake_Down, bodyNotDown
    mov  a,  r3                 ; Add the cell size to Y.
    add  a,  #snakeCellSize
    mov  r3, a
    sjmp bodyDrawLoop
    
    bodyNotDown:                ; Left -> right
    cjne a, #snake_Left, bodyNotLeft
    mov  a,  r2                 ; Add the cell size to X.
    add  a,  #snakeCellSize
    mov  r2, a
    sjmp bodyDrawLoop
    
    bodyNotLeft:                ; Right -> left
    mov  a,  r2                 ; Subtract the cell size from X.
    clr  c
    subb a,  #snakeCellSize
    mov  r2, a
    sjmp bodyDrawLoop
    
    bodyDone:
    
    ; Food
    ;--------------------------------------------
    mov  dptr, #foodCoords      ; Move to the food's coordinates.
    movx a,    @dptr
    mov  r0,   a
    inc  dptr
    movx a,    @dptr
    mov  r1,   a
    lcall drawMoveToCoordinate
    
    mov   dptr, #food           ; Vector array
    mov   r0,   #1              ; Scale
    mov   r1,   #true           ; From ROM
    lcall drawVectorArray       ; Draw the food.
    
    ; Clean up
    ;--------------------------------------------
    mov   r0, #0
    mov   r1, #0
    lcall drawMoveToCoordinate
    lcall drawUpdateCoordinates
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret