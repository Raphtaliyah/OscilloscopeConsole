; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MenuResources
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Menu/Headers/MenuResources.h.asm\
    .include \src/Headers/Graphics.h.asm\
    .include \src/Definitions/ASCII.asm\
    .include \src/Definitions/System.asm\
    
    .include \src/Applications/Snake/Headers/Snake.h.asm\
    .include \src/Applications/Pong/Headers/Pong.h.asm\
    .include \src/Applications/Options/Headers/Options.h.asm\
    
    .include "src/Macro.asm"
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
    selectedItem:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    ; Menu title.
    ;--------------------------------------------
    stringMenuTitle:
        .asciz /Menu/
    
    ; Item selector symbol.
    ;--------------------------------------------
    stringItemSelector:
        .asciz />/
    
    ; Array of menu elements.
    ;--------------------------------------------
    menuItems:
        ; Pong menu item
        ;--------------------------------------------
        .dw pongAppDescriptor
        .dw stringPongName
        .dw pongPreviewImage
        .dw stringPongPreview

        ; Snake menu item
        ;--------------------------------------------
        .dw snakeAppDescriptor
        .dw stringSnakeName
        .dw snakePreviewImage
        .dw stringSnakePreview
    
        ; Options menu item
        ;--------------------------------------------
        .dw optionsAppDescriptor
        .dw stringOptionsName
        .dw optionsPreviewImage
        .dw stringOptionsPreview
        
        ; Terminator
        ;--------------------------------------------
        .dw NULL
        .dw NULL
        .dw NULL
        .dw NULL
    menuItemsLimit:
    
    stringPongName:
        .asciz /Pong/
    
    stringPongPreview:
        .ascii /Classic 2 player pong/
        .db newLine
        .ascii /game./
        .db newLine
        .asciz /First to 9 wins./
    
    stringSnakeName:
        .asciz /Snake/
    
    stringSnakePreview:
        .ascii /32x32/
        .db newLine
        .ascii /Snake/
        .db newLine
        .ascii /with/
        .db newLine
        .ascii /controllers or/
        .db newLine
        .asciz /keyboard/
    
    stringOptionsName:
        .asciz /Options/
    
    stringOptionsPreview:
        .ascii /Change/
        .db newLine
        .asciz /settings/
    
    pongPreviewImage:
        .db 7
        .db vectDrawLineX | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db previewImageHeight
        .db vectDrawLineX | (vectMoveCoordinateNeg << 4)
        .db previewImageWidth
        .db 5   ; Player 2 X from the side
        .db 30  ; Player 2 Y from the top
        .db vectDrawLineY | (vectMoveXNeg << 4)
        .db 20  ; Player 2 size
        .db previewImageWidth/2 ; Ball from player 2 X
        .db vectMoveYNeg
        .db 40
        .db vectDrawLineX | (vectDrawLineY << 4)
        .db 1
        .db 1   ; Ball size
        .db vectMoveXNeg | (vectDrawLineY << 4); Player 1 pos
        .db previewImageWidth - (previewImageWidth/2) - 5 + 1 - 5
        .db 20  ; Player 1 size
    
    snakePreviewImage:
        .db 8
        .db vectDrawLineX | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db previewImageHeight
        .db vectDrawLineX | (vectMoveCoordinateNeg << 4)
        .db previewImageWidth
        .db 85
        .db 35
        .db vectDrawLineY | (vectDrawLineX << 4) ; |-
        .db 10
        .db 15
        .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
        .db 15
        .db 10
        .db 30
        .db vectMoveYNeg | (vectDrawLineX << 4)  ; _
        .db 35
        .db 1
        .db vectDrawLineY | (vectMoveXNeg << 4) ; Food
        .db 1
        .db 1
        .db vectMoveY | (vectDrawLineY << 4)    ; |
        .db 15
        .db 20
    
    optionsPreviewImage:
        .db 3
        .db vectDrawLineX | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
        .db previewImageWidth
        .db previewImageHeight
        .db previewImageHeight
        .db vectDrawLineX
        .db previewImageWidth
    
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ menuItemCount, ((menuItemsLimit-menuItems)/8)-1
    
    ; Preview image size.
    ;--------------------------------------------
    .equ previewImageHeight, 95
    .equ previewImageWidth,  95
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

