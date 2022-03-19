; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Pong
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Pong/Headers/Pong.h.asm\
    .include \src/Applications/Pong/Headers/PongGraphics.h.asm\
    .include \src/Applications/Pong/Headers/PongResources.h.asm\
    
    .include \src/Headers/Application.h.asm\
    .include \src/Headers/Controller.h.asm\
    .include \src/Headers/Nixie.h.asm\
    .include \src/Headers/Sound.h.asm\
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
    exitRequested:
        .ds 1
    gameOver:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    pongAppDescriptor:
        .dw stringAppName       ; name ptr
        .dw pongMain            ; entry point
        .dw onMessageReceived   ; message handler
    
    stringAppName:
        .asciz /Pong/
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ BALL_SPEED_X,          3
    .equ BALL_SPEED_Y,          2
    .equ BALL_START_X,          128
    .equ BALL_START_Y,          128
    .equ WINNING_SCORE,         9
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Pong entry.
;--------------------------------------------
; Parameters:
;	/dptr - Args pointer.
; Returns:
;	nothing
;--------------------------------------------
pongMain:
    push r0

    clr exitRequested
    clr frameFlag
    clr gameOver
    
    lcall resetGame
    gameLoop:
    jb gameOver, postGameTick
    
    lcall updatePlayers    
    lcall gameFrame
    
    sjmp waitFrame
    postGameTick:
    mov r0, #0
    lcall controllerReadNewButtonPress
    mov a, r0
    jz  waitFrame

    lcall resetGame
    clr gameOver
    
    waitFrame:
    jnb  frameFlag, waitFrame  ; Wait for the next frame.
    clr  frameFlag
    jnb  exitRequested, gameLoop
    
    mov   r0, #nixie_Left       ; Reset the nixies.
    lcall resetNixie
    mov   r0, #nixie_Right
    lcall resetNixie
    
    pop r0
    ret

resetGame:
    ; move the ball to the middle
    mov ballPosX, #BALL_START_X
    mov ballPosY, #BALL_START_Y
    ; set the vector to the initial speed
    mov ballSpeedX, #BALL_SPEED_X
    mov ballSpeedY, #BALL_SPEED_Y
    ; set the directions
    clr ballXDir
    setb ballYDir
    ; set player scores
    mov playerScores, #0

    mov r0, #nixie_Left
    lcall resetNixie
    mov r0, #nixie_Right
    lcall resetNixie
    ret

gameTick:
    
; Returns: 
; r0 - 0x00 if the game is still running, anything else if not
gameFrame:
    ; Save registers
    push acc
    push r1
    push r2
    
    ; Save Y coordinate
    push ballPosY
    
    ; Move ball on Y axis
    mov a, ballPosY
    jnb ballYDir, pong_yDown
    add a, ballSpeedY
    sjmp pong_yDone
    pong_yDown:
    clr c
    subb a, ballSpeedY
    pong_yDone:
    mov ballPosY, a
    
    ; Check for overflow on Y axis
    jnc pong_noYOverflow
    ; Reverse dir
    cpl ballYDir
    ; Restore coordinate
    pop ballPosY
    inc sp
    pong_noYOverflow:
    
    ; Clean up stack
    dec sp
    

    ; Save X coordinate
    push ballPosX
    
    ; Move ball on X axis
    mov a, ballPosX
    jnb ballXDir, pong_xDown
    add a, ballSpeedX
    sjmp pong_xDone
    pong_xDown:
    clr c
    subb a, ballSpeedX
    pong_xDone:
    mov ballPosX, a
    
    ; Check for overflow on X axis
    jnc pong_noXOverflow
    
    ; Restore the coordinate for checking which player scored
    pop ballPosX
    inc sp
    ; Reverse X dir
    cpl ballXDir
    
    ; Check if the player hit the ball back or the other player scored

    ; Get the player's Y coordinate
    lcall pong_getPlayerFromBall
    jz pong_getP1Y
    ; => Player 2
    mov r0, #player2Coord
    sjmp pong_gotPlayerY
    pong_getP1Y:
    ; => Player 1
    mov r0, #player1Coord
    pong_gotPlayerY:
    
    ; ball Y - Player coordinate
    mov b, @r0
    mov a, ballPosY
    clr c
    subb a, b
    jc pong_miss ; If there is a carry, the player missed for sure

    ; Player coordinate + size
    mov a, @r0
    add a, #playerSize
    
    ; (player coordinate + size) - Ball Y
    clr c
    subb a, ballPosY
    jc pong_miss ; carry = miss
    
    ; => player hit the ball back
    ; Do nothing, the direction is already reversed
    lcall playBeep
    sjmp pong_noXOverflow
    
    pong_miss:
    ; => miss, other payer scored
    
    ; Get which side the ball is on, and get the opposite player
    lcall pong_getPlayerFromBall
    cpl a
    anl a, #0b00000001
    
    ; Increment the score of the player
    jz pong_Player1Score
    ; => Player 2
    ; Increment upper nibble
    mov a, playerScores
    swap a
    inc a
    swap a
    mov playerScores, a

    mov r0, #nixie_Right     ; Update nixie
    lcall incrementNixie
    
    sjmp pong_scoreAdded
    pong_Player1Score:
    ; => Player 1
    ; Increment lower nibble
    inc playerScores

    mov r0, #nixie_Left     ; Update nixie
    lcall incrementNixie

    pong_scoreAdded:
    ; => Score added to player
    
    ; ; Set a small timeout
    ; mov pong_timeoutLength, #pong_scoreTimeoutLength
    ; setb pong_timeoutActive
    
    ; check if any player won
    mov a, playerScores
    mov r2, #2
    pong_winCheck:
    anl a, #0b00001111
    cjne a, #WINNING_SCORE, pong_noWinner
    ; Player won
    setb gameOver
    pong_noWinner:
    mov a, playerScores
    swap a
    djnz r2, pong_winCheck
    
    ; move the ball back
    mov ballPosX, #BALL_START_X
    mov ballPosY, #BALL_START_Y
    
    pong_noXOverflow:
    
    ; Stack cleaning
    dec sp
    
    ; Pop registers
    pop r2
    pop r1
    pop acc
    ret

; Gets which player's side the ball is on
; Returns 'a' : 0 - Player 1; 1 - Player 2
pong_getPlayerFromBall:
    mov a, ballPosX
    subb a, #128
    jc pong_onPlayer1Side
    mov a, #1
    ret
    pong_onPlayer1Side:
    mov a, #0
    ret

updatePlayers:
    push a
    push dpl
    push dph
    
    mov   dptr,  #controllerAValue
    movx  a,     @dptr
    acall adjustAnalog
    mov   player1Coord, a
    
    mov   dptr,  #controllerBValue
    movx  a,     @dptr
    acall adjustAnalog
    mov   player2Coord, a
    
    pop dph
    pop dpl
    pop a
    ret

adjustAnalog:
    push a
    add  a, #playerSize
    
    jnc  controllerInRange  ; If it overflows on the top move the
    pop  a                  ; player to 255-playerSize.
    mov  a, #255-playerSize
    push a
    controllerInRange:
    
    pop  a
    ret

;--------------------------------------------
; Message handler.
;--------------------------------------------
; Parameters:
;   r0    - Message id.
;   /dptr - Message object.
; Returns:
;	nothing
;--------------------------------------------
onMessageReceived:
    cjne  r0, #AMSG_DRAW, notDrawMsg        ; Handle draw message
    setb  frameFlag
    lcall pongFrame
    sjmp  msgHandled
    
    notDrawMsg:
    cjne  r0, #AMSG_EXIT, notExitMsg
    setb  exitRequested
    sjmp msgHandled
    
    notExitMsg:
    
    lcall defaultApplicationMessageHandler  ; Use default handler
    msgHandled:
    ret