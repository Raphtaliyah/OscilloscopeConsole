; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Snake
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Snake/Headers/Snake.h.asm\
    .include \src/Applications/Snake/Headers/SnakeGraphics.h.asm\
    .include \src/Applications/Snake/Headers/SnakeResources.h.asm\
    
    .include \src/Headers/Application.h.asm\
    .include \src/Headers/Controller.h.asm\
    .include \src/Headers/Malloc.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/Random.h.asm\
    .include \src/Headers/Nixie.h.asm\
    .include \src/Headers/Sound.h.asm\
    
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
    frameFlag:
        .ds 1
    snakeVisible:
        .ds 1
    exitRequested:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    nextSnakeDirection:
        .ds 1
    tailPointer:
        .ds 2
    frameDivider:
        .ds 1
    score:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    snakeAppDescriptor:
        .dw stringAppName       ; name ptr
        .dw snakeMain           ; entry point
        .dw onMessageReceived   ; message handler
    
    stringAppName:
        .asciz \Snake\
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; Controller states
    ;--------------------------------------------
    .equ controllerTrigNeg, 60   ; Negative trigger
    .equ controllerTrigPos, 195  ; Positive trigger

    ; Speed
    ;--------------------------------------------
    .equ frameDivison,          17
    .equ gameOverFrameDivision, 20
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

snakeMain:
    push r0

    clr frameFlag
    clr exitRequested
    
    lcall resetGame             ; Prepare for the first game.
    
    gameLoop:
    clr   frameFlag             ; Reset the frame flag
    lcall gameTick              ; Next game tick!
    
    waitFrame:                  ; Wait for a frame.
    lcall updateHeadDirection   ; Keep polling controller for
                                ; responsiveness.
    jnb  frameFlag, waitFrame
    jnb  exitRequested, gameLoop
    
    lcall tearDownGameStructure ; Free memory before exiting.
    
    mov   r0, #nixie_Left       ; Reset the nixies.
    lcall resetNixie
    mov   r0, #nixie_Right
    lcall resetNixie
    
    pop r0
    ret

resetGame:
    push a
    push r0
    push dpl
    push dph

    mov  dptr,  #foodCoords     ; Set the food coordinate.
    mov  a,     #foodStartX
    movx @dptr, a
    inc  dptr
    mov  a,     #foodStartY
    movx @dptr, a
    
    mov  dptr,  #snakeHeadCoords
    mov  a,     #snakeStartX    ; Set the snake head coordinate.
    movx @dptr, a
    inc  dptr
    mov  a,     #snakeStartY
    movx @dptr, a
    
    mov  dptr,  #snakeHead   
    mov  a,     #snake_Up       ; Head going up.
    movx @dptr, a
    inc  dptr
    clr  a                      ; No other pieces.
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    inc  dptr

    mov  dptr,  #tailPointer    ; Set tail pointer to head.
    mov  a,     #<snakeHead
    movx @dptr, a
    inc  dptr
    mov  a,     #>snakeHead
    movx @dptr, a
    
    mov  dptr,  #nextSnakeDirection
    mov  a,     #snake_Up       ; Keep going up.
    movx @dptr, a
    
    mov  dptr,  #score          ; Reset score.
    clr  a
    movx @dptr, a
    
    mov   r0, #nixie_Left       ; Reset the nixies.
    lcall resetNixie
    mov   r0, #nixie_Right
    lcall resetNixie

    mov  dptr,  #frameDivider
    clr  a                      ; Reset the frame divider.
    movx @dptr, a

    clr  snakeCollision         ; Clear the collision flag.
    setb snakeVisible           ; Make the snake visible.
    
    pop dph
    pop dpl
    pop r0
    pop a
    ret

tearDownGameStructure:
    push a
    push dpl
    push dph
    push dplb
    push dphb

    mov  dptr, #snakeHead       ; Get the ptr to the first non-head
    movx a,    @dptr            ; snake piece.
    mov  dplb, a
    inc  dptr
    movx a,    @dptr
    mov  dphb, a
    
    memFreeLoop:
    mov  a, dplb                ; Break on null ptr.
    cjne a, #NULL, notNullPtr
    mov  a, dphb
    cjne a, #NULL, notNullPtr
    
    inc  /dptr                  ; Read the ptr to the next piece.
    movx a,   @/dptr
    mov  dpl, a
    inc  dptr
    movx a,   @/dptr
    mov  dph, a
    
    lcall free                  ; Free the current piece.
    
    .swapDptr                   ; Change to next piece to the current
                                ; piece.
    sjmp memFreeLoop
    notNullPtr:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop a
    ret

gameTick:
    push a
    push dpl
    push dph
    
    mov  dptr,  #frameDivider   ; Update frame divider.
    movx a,     @dptr
    inc  a
    movx @dptr, a
    
    clr  c                      ; Check if it's time for a game tick.
    subb a, #frameDivison
    jc   skipGameTick

    clr  a                      ; Reset frame divider.
    movx @dptr, a
    
    jb snakeCollision, gameOverTick ; Check for collision.
    
    lcall tickSnake             ; Do a game tick.
    lcall checkFoodCollision
    
    skipGameTick:

    pop dph
    pop dpl
    pop a
    ret

gameOverTick:
    cpl snakeVisible
    
    mov   r0, #0x00         ; Check if either controller buttons are
    lcall controllerReadNewButtonPress  ; pressed and reset the game
    mov   a,  r0            ; if they are.
    mov   r0, #0xFF
    lcall controllerReadNewButtonPress
    orl   a,  r0
    
    jz    noReset
    lcall resetGame         ; Reset the game.
    lcall tearDownGameStructure

    noReset:
    sjmp skipGameTick

updateHeadDirection:
    push a
    push r0
    push dpl
    push dph
    
    mov  dptr, #controllerAValue; Check if controller A is lower than
    movx a,    @dptr            ; the negative trigger value.
    mov  r0,   a
    clr  c
    subb a,    #controllerTrigNeg
    jnc  aNotNegativeTrigger
    mov  r0,   #snake_Left
    sjmp headDirectionUpdated
    aNotNegativeTrigger:
    
    mov  a,    r0              ; Check controller A positive trigger.
    clr  c
    subb a,    #controllerTrigPos
    jc   aNotPositiveTrigger
    mov  r0,   #snake_Right
    sjmp headDirectionUpdated
    aNotPositiveTrigger:
    
    mov  dptr, #controllerBValue; Do the same thing with controller B.
    movx a,    @dptr
    mov  r0,   a
    clr  c
    subb a,    #controllerTrigNeg
    jnc  bNotNegativeTrigger
    mov  r0,   #snake_Down
    sjmp headDirectionUpdated
    bNotNegativeTrigger:

    mov  a,    r0
    clr  c
    subb a,    #controllerTrigPos
    jc   bNotPositiveTrigger
    mov  r0,   #snake_Up
    sjmp headDirectionUpdated
    bNotPositiveTrigger:
    
    ; If this is reached both controllers are in neutral state,
    ; keep the last direction.
    sjmp keepDirection

    headDirectionUpdated:
    
    mov  dptr, #snakeHead       ; Don't let the snake turn back on
    movx a,    @dptr            ; itself.
    mov  dpl,  a
    mov  a,    #3
    clr  c
    subb a,    dpl              ; Invert the current direction.
    cjne a,    r0, validMove
    sjmp keepDirection          ; If it tries to, ignore the move.
    validMove:
    
    mov  dptr,  #nextSnakeDirection ; Write the new direction.
    mov  a,     r0
    movx @dptr, a               
    
    keepDirection:
    
    pop dph
    pop dpl
    pop r0
    pop a
    ret

tickSnake:
    push a
    push r0
    push r1
    push r2
    push r3
    push r4
    push dpl
    push dph
    push dplb
    push dphb
    
    mov  dptr, #nextSnakeDirection  ; Load the next direction.
    movx a,    @dptr
    mov  r4,   a
    
    mov  dptr, #snakeHead               ; Load the head direction.
    movx a,    @dptr
    mov  r0,   a
    
    mov  dptr, #snakeHeadCoords         ; Read the current
    movx a,    @dptr                    ; coordinates.
    mov  r1,   a                        ; X
    inc  dptr
    movx a,    @dptr
    mov  r2,   a                        ; Y
    
    cjne r4, #snake_Up, moveNotUp       ; Up
    mov  a,  r2
    add  a,  #snakeCellSize             ; Y + snakeCellSize
    mov  r2, a
    sjmp moved
    moveNotUp:
    cjne r4, #snake_Down, moveNotDown   ; Down
    mov  a,  r2
    clr  c
    subb a,  #snakeCellSize             ; Y - snakeCellSize
    mov  r2, a
    sjmp moved
    moveNotDown:
    cjne r4, #snake_Left, moveNotLeft   ; Left
    mov  a,  r1
    clr  c
    subb a,  #snakeCellSize             ; X - snakeCellSize
    mov  r1, a
    sjmp moved
    moveNotLeft:
    mov  a,  r1                         ; Right
    add  a,  #snakeCellSize             ; X + snakeCellSize
    mov  r1, a
    moved:
    
    jnc  noWallCollision                ; Check collision with walls.
    setb snakeCollision
    sjmp tickSnakeExit
    noWallCollision:
    
    mov  dptr,  #snakeHeadCoords        ; Update the coordinates.
    mov  a,     r1
    movx @dptr, a
    inc  dptr
    mov  a,     r2
    movx @dptr, a
    
    mov  dptr, #snakeHead           ; Start updating directions from
                                    ; the head.
    snakeDirectionLoop:
    movx a,  @dptr                  ; Read the original direction.
    mov  r0, a
    
    mov  a,     r4                  ; Change the direction to the
    movx @dptr, a                   ; last direction.
    inc  dptr
    
    mov  r4, r0                     ; Save the current direction for
                                    ; the next one.
    
    movx a,    @dptr                ; Read the pointer to the next
    mov  dplb, a                    ; piece.
    inc  dptr
    movx a,    @dptr
    mov  dphb, a
    
    .swapDptr                       ; Swap to the dptr with the
                                    ; ptr to the next piece.
    
    mov a, dpl                      ; Break on NULL ptr.
    jnz snakeDirectionLoop
    mov a, dph
    jnz snakeDirectionLoop
    
    tickSnakeExit:

    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    pop a
    ret

checkFoodCollision:
    push a
    push b
    push r0
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    mov  dptr, #foodCoords              ; Get the food's coordinate.
    movx a,    @dptr
    mov  r0,   a
    inc  dptr
    movx a, @dptr
    mov  r1,   a
    
    mov  dptr, #snakeHeadCoords         ; Compare it with the snake
    movx a,    @dptr                    ; head's coordinates.
    cjne a,    r0, noFoodCollision
    inc  dptr
    movx a,    @dptr
    cjne a,    r1, noFoodCollision

    lcall playBeep                      ; Play beep sound.
    
    mov   dptr,  #foodCoords            ; Generate new random food
    lcall nextRandom                    ; coordinates.
    mov   a,     r0
    mov   b,     #snakeCellSize
    div   ab
    mov   b,     #snakeCellSize
    mul   ab
    movx  @dptr, a
    inc   dptr
    lcall nextRandom
    mov   a,     r0
    mov   b,     #snakeCellSize
    div   ab
    mov   b,     #snakeCellSize
    mul   ab
    movx  @dptr, a
    
    mov   dptr, #3                      ; Size of a snake piece.
    lcall malloc                        ; TODO: Check return value.
    
    mov  dplb, dpl                      ; Set the ptr to the next to
    mov  dphb, dph                      ; NULL.
    inc  dptr
    clr  a
    movx @dptr, a
    inc  dptr
    movx @dptr, a
    
    mov  dptr, #tailPointer ; Load the tail pointer.
    movx a,    @dptr
    push a
    inc  dptr
    movx a,    @dptr
    mov  dph,  a
    pop  dpl
    
    movx a,      @dptr      ; Copy the direction from the tail.
    movx @/dptr, a
    
    disableIntRestorable

    inc  dptr               ; Set the new piece as the next piece of
    mov  a,     dplb        ; the tail.
    movx @dptr, a
    inc  dptr
    mov  a,     dphb
    movx @dptr, a
    
    mov  dptr,  #tailPointer;  Update the tail pointer.
    mov  a,     dplb
    movx @dptr, a
    inc  dptr
    mov  a,     dphb
    movx @dptr, a
    
    restoreInt
    
    lcall incrementScore    ; Update nixies
    
    noFoodCollision:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop r0
    pop b
    pop a
    ret

incrementScore:
    push a
    push b
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    mov  dptr,  #score
    movx a,     @dptr
    inc  a
    movx @dptr, a

    mov   b,  #10           ; Display the lower digit.
    div   ab
    mov   r0, #nixie_Right
    mov   r1, b
    lcall displayNixie

    mov   b, #100           ; Display the upper digit.
    div   ab
    mov   r0, #nixie_Left
    mov   r1, b
    lcall displayNixie
    
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop b
    pop a
    ret

onMessageReceived:
    cjne  r0, #AMSG_DRAW, notDrawMsg        ; Handle draw message
    setb  frameFlag
    lcall snakeFrame
    sjmp  msgHandled
    
    notDrawMsg:
    cjne  r0, #AMSG_EXIT, notExitMsg
    setb  exitRequested
    sjmp msgHandled
    
    notExitMsg:
    
    lcall defaultApplicationMessageHandler  ; Use default handler
    msgHandled:
    ret