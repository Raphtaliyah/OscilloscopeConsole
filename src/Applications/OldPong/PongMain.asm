; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Pong
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl pongAppDescriptor
    
    .globl stdoutSendStringFromROMNewLine, sendAppMessage, useDefaultAppMessageHandler
    .globl pongDrawHandler, controllerUpdateData
    
    .globl controllerAValue, controllerBValue
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    graphFrame:
        .ds 1
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
    
    testX:
        .ds 1
    testY:
        .ds 1
    .area XDATA (DSEG)
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    pongAppDescriptor:
        .dw stringAppName           ; name ptr
        .dw pongMain                ; entry point
        .dw pongMessageReceived     ; message handler
    
    stringAppName:
        .asciz /Pong game application/
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ BALL_SPEED_X,          3
    .equ BALL_SPEED_Y,          2
    .equ BALL_START_X,          128
    .equ BALL_START_Y,          128
    .equ WINNING_SCORE,         9
    .equ X_DAC,                 0x8003
    .equ Y_DAC,                 0x8000
    .equ PLAYER_SIZE,           70
    .equ MIDDLETHINGYLENGTH,    15
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Application main
; Parameters:
; dptr - arg pointer
; Returns:
; r0 - exit code
pongMain:
    ; Push registers
    push acc
    push dpl
    push dph
    
    ; Setup stuff
    ; move the ball to the middle
    mov ballPosX, #BALL_START_X
    mov ballPosY, #BALL_START_Y
    ; set the vector to the initial speed
    mov ballSpeedX, #BALL_SPEED_X
    mov ballSpeedY, #BALL_SPEED_Y
    ; set the directions
    clr ballXDir
    setb ballYDir
    ; clear sync bit
    clr graphFrame
    ; set player scores
    mov playerScores, #0
    ; note: player pos will be set up by gameFrame

    gameLoop:

    ; Wait for graphics frame
    waitForGraphicsFrame:
    jnb graphFrame, waitForGraphicsFrame
    clr graphFrame

    lcall updatePlayerPos

    ; Next game frame
    lcall gameFrame

    ; Break on game ending
    mov a, r0
    jz gameLoop

    ; Set exit code
    mov r0, #0
    
    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

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
    mov r0, #0
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
    
    ; Player coordinate - ball Y
    mov a, @r0
    clr c
    subb a, ballPosY
    jc pong_miss ; If there is a carry, the player missed for sure

    ; Player coordinate - size
    mov a, @r0
    clr c
    subb a, #PLAYER_SIZE
    mov r0, a
    
    ; Ball Y - (player coordinate - size)
    mov a, ballPosY
    clr c
    subb a, r0
    jc pong_miss ; carry = miss
    
    ; => player hit the ball back
    ; Do nothing, the direction is already reversed
    mov r0, #0 ; Don't exit game
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
    
    sjmp pong_scoreAdded
    pong_Player1Score:
    ; => Player 1
    ; Increment lower nibble
    inc playerScores

    pong_scoreAdded:
    ; => Score added to player
    
    ; ; Set a small timeout
    ; mov pong_timeoutLength, #pong_scoreTimeoutLength
    ; setb pong_timeoutActive
    
    mov r0, #0
    
    ; check if any player won
    mov a, playerScores
    mov r2, #2
    pong_winCheck:
    anl a, #0b00001111
    cjne a, #WINNING_SCORE, pong_noWinner
    ; Player won
    mov r0, #1
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

updatePlayerPos:
    ; Push registers
    push acc
    push dpl
    push dph

    ; Update the values
    lcall controllerUpdateData

    ; Read the values
    ; p1
    mov dptr, #controllerAValue
    movx a, @dptr
    lcall pong_AdjustAnalog
    mov player1Coord, a
    ; p2
    mov dptr, #controllerBValue
    movx a, @dptr
    lcall pong_AdjustAnalog
    mov player2Coord, a

    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Adjusts the analog value to represent the middle of the player
pong_AdjustAnalog:
    add a, #PLAYER_SIZE/2
    
    ; If it overflew on the top move the player to 255
    jnc pong_TopOk
    mov a, #255
    pong_TopOk:
   
    ; Save adjusted coordinate
    push acc
    
    ; Check for bottom overflow, move to the smallest possible coordinate (the size)
    clr c
    subb a, #PLAYER_SIZE
    jnc pong_BottomOk
    mov a, #PLAYER_SIZE
    dec sp
    ret
    pong_BottomOk:
    
    ; Restore the coordinate
    pop acc
    ret

; Message handler for the app
; Parameters:
; r0    - message id
; /dptr - message object
; Returns: none
pongMessageReceived:
    
    ; Handle draw message
    cjne r0, #0x01, notDrawMsg
    lcall pongDrawHandler
    sjmp msgHandled
    notDrawMsg:
    
    ; Use default handler
    lcall useDefaultAppMessageHandler
    
    
    msgHandled:
    
    ret

; Draw message handler for pong
pongDrawHandler:
    ; Push registers
    push r0
    push r1
    push dpl
    push dph
    

    mov r0, #255
    loop:
    ; X
    mov dptr, #X_DAC
    inc testX
    mov a, testX
    movx @dptr, a
    
    ; Y
    mov dptr, #Y_DAC
    inc testY
    mov a, testY
    movx @dptr, a

    djnz r0, loop

;    lcall drawSquare
; 
;    mov r0, #10
;    mov r1, player1Coord
;    lcall drawPlayer
;    
;    mov r0, #245
;    mov r1, player2Coord
;    lcall drawPlayer
; 
;    lcall drawMiddleThing
;    
;    mov r0, ballPosX
;    mov r1, ballPosY
;    lcall goToBall

;    ; Signal game thread
;    setb graphFrame
    
    ; Pop registers
    pop dph
    pop dpl
    pop r1
    pop r0
    ret

; Parameters:
; r0 - x
; r1 - y
goToBall:
    ; Push registers
    push dpl
    push dph
    push acc
    
    ; X
    mov dptr, #X_DAC
    mov a, r0
    movx @dptr, a
    
    ; Y
    mov dptr, #Y_DAC
    mov a, r1
    movx @dptr, a
    
    ; Pop registers
    pop acc
    pop dph
    pop dpl
    ret

; Draws the player
; Parameters:
; r0 - x
; r1 - y
drawPlayer:
    ; Push registers
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    ; Move to place
    mov dptr, #X_DAC
    mov a, r0
    movx @dptr, a
    
    mov r2, #PLAYER_SIZE
    dLoop:
    
    ; Draw player
    mov dptr, #Y_DAC
    mov a, r1
    movx @dptr, a

    ; Dec
    dec r1
    
    djnz r2, dLoop
    
    ; Pop registers
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret

drawMiddleThing:
    ; Push registers
    push acc
    push dpl
    push dph
    push r0
    push r1
    push r2

    ; Move to the middle (X)
    mov dptr, #X_DAC
    mov a, #128
    movx @dptr, a

    ; Set dac to Y
    mov dptr, #Y_DAC
    
    mov r1, #0
    mov r0, #255
    middleThingLoop:
    
    mov a, r1
    jz fillThingy
    ; r1 == 1

    ; Subb empty length
    mov a, r0
    subb a, #MIDDLETHINGYLENGTH
    mov r0, a

    ; Change state
    mov r1, #0
    sjmp next
    fillThingy:
    ; r1 == 0
    
    ; Fill the line
    mov r2, #MIDDLETHINGYLENGTH
    middleLineLoop:
    mov a, r0
    dec r0
    movx @dptr, a
    djnz r2, middleLineLoop

    ; Change state
    mov r1, #1
    next:
    
    ; Next or quit
    mov a, r0
    jnz middleThingLoop

    ; Pop registers
    pop r2
    pop r1
    pop r0
    pop dph
    pop dpl
    pop acc
    ret

drawSquare:
    ; Push registers
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    ; X
    mov dptr, #X_DAC
    mov a, #0
    movx @dptr, a
    ; Y
    mov r1, #255
    mov dptr, #Y_DAC
    ; Draw
    aLoop:
    mov a, r1
    movx @dptr, a
    djnz r1, aLoop

    ; Y
    mov dptr, #Y_DAC
    mov a, #0
    movx @dptr, a
    ; X
    mov r1, #255
    mov dptr, #X_DAC
    ; Draw
    bLoop:
    mov a, r1
    movx @dptr, a
    djnz r1, bLoop
    
    ; X
    mov dptr, #X_DAC
    mov a, #255
    movx @dptr, a
    ; Y
    mov r1, #255
    mov dptr, #Y_DAC
    ; Draw
    cLoop:
    mov a, r1
    movx @dptr, a
    djnz r1, cLoop
    
    ; Y
    mov dptr, #Y_DAC
    mov a, #255
    movx @dptr, a
    ; X
    mov r1, #255
    mov dptr, #X_DAC
    ; Draw
    eLoop:
    mov a, r1
    movx @dptr, a
    djnz r1, eLoop
    
    ; Pop registers
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret