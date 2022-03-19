; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module ASCIIdrawing
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Graphics.h.asm\
    .include \src/Headers/Drawing.h.asm\
    .include \src/Definitions/Bool.asm\
    .include \src/Definitions/ASCII.asm\
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
    .equ ASCIIoffsetLow,      0x20
    .equ ASCIIoffsetHigh,     0x7E
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Draws an ascii character.
;--------------------------------------------
; Parameters:
;   r0 - ASCII byte.
;   r1 - Size
; Returns:
;   nothing
;--------------------------------------------
drawAscii:
    push a
    push b
    push r0
    push r1
    push r2
    push dpl
    push dph
    
    mov   a, r0                  ; Check if the character
    clr   c                      ; is below the printable range.
    subb  a, #ASCIIoffsetLow
    jc    asciiNotPrintable
    
    aboveOffset:
    mov   a, #ASCIIoffsetHigh    ; Check if the character
    clr   c                      ; is above the printable range.
    subb  a, r0
    jc    asciiNotPrintable
    
    mov   a, r0                  ; Subtract the offset and multiply by
    clr   c                      ; 2 to get the index into the table.
    subb  a, #ASCIIoffsetLow
    rl    a
    mov   r2, a
    
    asciiAfterRangeChecks:
    mov   dptr, #asciiTable      ; Load the table address.
    
    movc  a, @a+dptr             ; Load the address from the table.
    push  a
    mov   a, r2
    inc   a
    movc  a, @a+dptr
    mov   dpl, a
    pop   dph

    push  drawingXCoordinate    ; Save the coordinates to later be
    push  drawingYCoordinate    ; able to calculate the coords for
                                ; the next character.
    
    mov   r0, r1                ; Size
    mov   r1, #true             ; From ROM
    lcall drawVectorArray       ; Draw the character.
    
    pop   drawingYCoordinate    ; Calculate the coordinates of the
    pop   r1                    ; next character.
    mov   a, #charWidth + charHorizontalSpace
    mov   b, r0                 ; Has to be scaled.
    mul   ab
    add   a, r1
    mov   drawingXCoordinate, a
    
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop b
    pop a
    ret
    
    asciiNotPrintable:      ; Not printable, draw undefined char.
    mov   a, #95*2          ; Index of the undefined character.
    sjmp  asciiAfterRangeChecks

;--------------------------------------------
; Draws a string of ASCII characters.
;--------------------------------------------
; Parameters:
;   dptr - String pointer
;   r0   - Size
;   r1   - ROM?
;   r2   - X start
;   r3   - X limit
; Returns:
;   nothing
;--------------------------------------------
drawAsciiString:
    push a
    push b
    push r0
    push r1
    push r4
    push dpl
    push dph
    
    mov  r4, r1                      ; Rearrange registers
    mov  r1, r0                      ; for drawAscii.
    
    drawLoop:
    cjne  r4, #false, charFromRom    ; Read the next character
    movx  a,  @dptr                  ; from RAM.
    sjmp  charReadFromRam
    charFromRom:
    clr   a                          ; from ROM.
    movc  a,  @a+dptr
    charReadFromRam:
    
    inc   dptr
    
    jz    nullFound                  ; Check for null termination.
    mov   r0, a
    clr   c
    subb  a, #ASCIIoffsetLow         ; Check if it's a control char.
    jc    asciiControlChar
    
    mov   a, #charWidth + charHorizontalSpace ; Make sure the next
    mov   b, r1                      ; character fits in the current
    mul   ab                         ; line.
    add   a, drawingXCoordinate
    jc    doesntFit
    clr   c
    mov   b, a
    mov   a, r3
    subb  a, b
    jnc   drawCharacter
    
    doesntFit:
    acall asciiNewLine               ; Create a new line
    cjne  r0, #0x20, drawCharacter   ; Don't draw the character if
    sjmp  drawLoop                   ; it's a space after an implicit
                                     ; new line.
    drawCharacter:
    lcall drawAscii                  ; Draw the character.
    sjmp  drawLoop
    
    nullFound:
    pop dph
    pop dpl
    pop r4
    pop r1
    pop r0
    pop b
    pop a
    ret
    
    asciiControlChar:
    cjne r0, #0x0A, drawLoop         ; Ignore everything that's not a
                                     ; new line.
    acall asciiNewLine
    sjmp drawLoop

;--------------------------------------------
; Creates a new line.
; Doesn't save registers: a, b
;--------------------------------------------
; Parameters:
;   r1  - Size.
;   r2  - X start.
; Returns:
;   nothing
;--------------------------------------------
asciiNewLine:
    mov  b,  r1                      ; Calculate the Y coordinate
    mov  a,  #charHeight + charVerticalSpace ; of the new line.
    mul  ab
    mov  b, a
    mov  a,  drawingYCoordinate
    clr  c
    subb a,  b
    mov  drawingYCoordinate, a
    
    mov  drawingXCoordinate, r2      ; Update the X coordinate.
    ret

; Table for every printable ASCII character
; graphics.
;--------------------------------------------
asciiTable:
    .dw asciiSpace          ; (Space) (0x20)
    .dw asciiUndefined      ; !
    .dw asciiUndefined      ; "
    .dw asciiUndefined      ; #
    .dw asciiUndefined      ; $
    .dw asciiUndefined      ; %
    .dw asciiUndefined      ; &
    .dw asciiUndefined      ; '
    .dw asciiUndefined      ; (
    .dw asciiUndefined      ; )
    .dw asciiUndefined      ; *
    .dw asciiUndefined      ; +
    .dw asciiUndefined      ; ,
    .dw asciiUndefined      ; -
    .dw ascii_Dot           ; .
    .dw ascii_Slash         ; /
    .dw ascii_0O            ; 0
    .dw ascii_1             ; 1
    .dw ascii_2             ; 2
    .dw ascii_3             ; 3
    .dw ascii_4             ; 4
    .dw ascii_5S            ; 5
    .dw ascii_6             ; 6
    .dw ascii_7             ; 7
    .dw ascii_8             ; 8
    .dw ascii_9             ; 9
    .dw asciiUndefined      ; :
    .dw asciiUndefined      ; ;
    .dw ascii_LessThan      ; <
    .dw asciiUndefined      ; =
    .dw ascii_GreaterThan   ; >
    .dw asciiUndefined      ; ?
    .dw asciiUndefined      ; @
    .dw ascii_A             ; A
    .dw ascii_B             ; B
    .dw ascii_C             ; C
    .dw ascii_D             ; D
    .dw ascii_E             ; E
    .dw ascii_F             ; F
    .dw ascii_G             ; G
    .dw ascii_H             ; H
    .dw ascii_I             ; I
    .dw ascii_J             ; J
    .dw ascii_K             ; K
    .dw ascii_L             ; L
    .dw ascii_M             ; M
    .dw ascii_N             ; N
    .dw ascii_0O            ; O
    .dw ascii_P             ; P
    .dw ascii_Q             ; Q
    .dw ascii_R             ; R
    .dw ascii_5S            ; S
    .dw ascii_T             ; T
    .dw ascii_U             ; U
    .dw ascii_V             ; V
    .dw ascii_W             ; W
    .dw ascii_X             ; X
    .dw ascii_Y             ; Y
    .dw ascii_Z             ; Z
    .dw asciiUndefined      ; [
    .dw asciiUndefined      ; \
    .dw asciiUndefined      ; ]
    .dw asciiUndefined      ; ^
    .dw asciiUndefined      ; _
    .dw asciiUndefined      ; `
    .dw ascii_a             ; a
    .dw ascii_b             ; b
    .dw ascii_c             ; c
    .dw ascii_d             ; d
    .dw ascii_e             ; e
    .dw ascii_f             ; f
    .dw ascii_g             ; g
    .dw ascii_h             ; h
    .dw ascii_i             ; i
    .dw ascii_j             ; j
    .dw ascii_k             ; k
    .dw ascii_l             ; l
    .dw ascii_m             ; m
    .dw ascii_n             ; n
    .dw ascii_o             ; o
    .dw ascii_p             ; p
    .dw ascii_q             ; q
    .dw ascii_r             ; r
    .dw ascii_s             ; s
    .dw ascii_t             ; t
    .dw ascii_u             ; u
    .dw ascii_v             ; v
    .dw ascii_w             ; w
    .dw ascii_x             ; x
    .dw ascii_y             ; y
    .dw ascii_z             ; z
    .dw asciiUndefined      ; {
    .dw asciiUndefined      ; |
    .dw asciiUndefined      ; }
    .dw asciiUndefined      ; ~ (0x7E)
    .dw asciiUndefined      ; Index 95, used for undefined characters.

; A small square character to indicate
; non-printable ASCII codes.
;--------------------------------------------
asciiUndefined:
    .db 3
    .db vectMoveCoordinate | (vectDrawLineX << 4)
    .db charWidth/4
    .db charHeight/4
    .db charWidth/2
    .db vectDrawLineY | (vectMoveCoordinateNeg << 4)
    .db charHeight/2
    .db charWidth/2
    .db charHeight/2
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight/2
    .db charWidth/2

asciiSpace:
    .db 0

ascii_Dot:
    .db 3
    .db vectMoveX | (vectDrawLineX << 4)
    .db 1
    .db 1
    .db vectDrawLineY | (vectMoveCoordinateNeg << 4)
    .db 1
    .db 1
    .db 1
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db 1
    .db 1

ascii_Slash:
    .db 1
    .db vectDrawDiagR
    .db charWidth

ascii_1:
    .db 2
    .db vectMoveY | (vectDrawDiag22XR << 4)
    .db charHeight/2
    .db charWidth/2
    .db vectMoveYNeg | (vectDrawLineY << 4)
    .db charHeight
    .db charHeight

ascii_2:
    .db 4
    .db vectDrawLineX | (vectMoveXNeg << 4)
    .db charWidth
    .db charWidth
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight/2
    .db charWidth
    .db vectDrawLineY | (vectMoveXNeg << 4)
    .db charHeight/2
    .db charWidth
    .db vectDrawLineX
    .db charWidth

ascii_3:
    .db 3
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight
    .db vectMoveXNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth

ascii_4:
    .db 3
    .db vectMoveX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth
    .db vectMoveXNeg | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2

ascii_6:
    .db 4
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight
    .db charWidth
    .db vectDrawLineY | (vectMoveXNeg << 4)
    .db charHeight/2
    .db charWidth
    .db vectDrawLineX
    .db charWidth

ascii_7:
    .db 2
    .db vectDrawDiagR | (vectMoveXNeg << 4)
    .db charHeight
    .db charWidth
    .db vectDrawLineX
    .db charWidth

ascii_8:
    .db 4
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight
    .db charWidth
    .db vectDrawLineY | (vectMoveCoordinateNeg << 4)
    .db charHeight
    .db charWidth
    .db charHeight/2
    .db vectDrawLineX
    .db charWidth

ascii_9:
    .db 4
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth
    .db vectMoveXNeg | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2
    .db vectDrawLineX
    .db charWidth

ascii_LessThan:
    .db 2
    .db vectMoveX | (vectDrawDiag22XL << 4)
    .db charWidth
    .db charHeight/2
    .db vectDrawDiag22XR
    .db charHeight/2

ascii_GreaterThan:
    .db 1
    .db vectDrawDiag22XR | (vectDrawDiag22XL << 4)
    .db charHeight/2
    .db charHeight/2

ascii_a:
ascii_A:
    .db 3
    .db vectDrawLineY   | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveYNeg    | (vectDrawLineY << 4)
    .db charHeight
    .db charHeight
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth

ascii_b:
ascii_B:
    .db 5
    .db vectDrawLineX | (vectDrawDiagR << 4)
    .db charWidth*3/4
    .db charHeight/4
    .db vectDrawDiagL | (vectDrawDiagR << 4)
    .db charHeight/4
    .db charHeight/4
    .db vectDrawDiagL | (vectMoveCoordinateNeg << 4)
    .db charHeight/4
    .db charWidth*3/4
    .db charHeight
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth*3/4
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth*3/4
    .db charHeight/2
    .db charWidth*3/4

ascii_c:
ascii_C:
    .db 2
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight
    .db charWidth

ascii_d:
ascii_D:
    .db 4
    .db vectDrawLineX | (vectDrawDiagR << 4)
    .db charWidth*3/4
    .db charHeight/4
    .db vectDrawLineY | (vectDrawDiagL << 4)
    .db charHeight/2
    .db charHeight/4
    .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
    .db charWidth*3/4
    .db charHeight
    .db charHeight
    .db vectDrawLineX
    .db charWidth*3/4

ascii_e:
ascii_E:
    .db 3
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth

ascii_f:
ascii_F:
    .db 2
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight/2
    .db charWidth

ascii_g:
ascii_G:
    .db 4
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg
    .db charWidth
    .db charHeight
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2
    .db vectMoveXNeg | (vectDrawLineX << 4)
    .db charWidth/2
    .db charHeight/2

ascii_h:
ascii_H:
    .db 3
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight/2
    .db vectDrawLineX | (vectMoveYNeg << 4)
    .db charWidth
    .db charHeight/2
    .db vectDrawLineY
    .db charHeight

ascii_i:
ascii_I:
    .db 1
    .db vectMoveX | (vectDrawLineY << 4)
    .db charWidth/2
    .db charHeight

ascii_j:
ascii_J:
    .db 2
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight/4
    .db charHeight/4
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight

ascii_k:
ascii_K:
    .db 4
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight/2
    .db vectDrawDiag22XR | (vectMoveCoordinateNeg << 4)
    .db charWidth/2
    .db charWidth/2
    .db charWidth/2
    .db vectMoveYNeg | (vectMoveX << 4)
    .db charWidth/2
    .db charWidth/2
    .db vectDrawDiag22XL
    .db charWidth/2

ascii_l:
ascii_L:
    .db 2
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight
    .db vectDrawLineX
    .db charWidth

ascii_m:
ascii_M:
    .db 4
    .db vectDrawLineY   | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth/2
    .db vectMoveYNeg    | (vectDrawLineY << 4)
    .db charHeight/2
    .db charHeight/2
    .db vectDrawLineX   | (vectMoveYNeg << 4)
    .db charWidth/2
    .db charHeight
    .db vectDrawLineY
    .db charHeight

ascii_n:
ascii_N:
    .db 4
    .db vectDrawLineY | (vectMoveX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveYNeg | (vectDrawDiagL << 4)
    .db charHeight
    .db charWidth
    .db vectMoveX | (vectMoveYNeg << 4)
    .db charWidth
    .db charHeight
    .db vectDrawLineY
    .db charHeight

ascii_o:
ascii_0O:
    .db 3
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight
    .db vectMoveCoordinateNeg
    .db charWidth
    .db charHeight
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth

ascii_p:
ascii_P:
    .db 3
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg
    .db charWidth
    .db charHeight/2
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2

ascii_q:
ascii_Q:
    .db 4
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charHeight
    .db charWidth
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight
    .db vectDrawDiagL
    .db charWidth/2

ascii_r:
ascii_R:
    .db 4
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg
    .db charWidth
    .db charHeight/2
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2
    .db vectMoveYNeg | (vectDrawDiag22XL << 4)
    .db charHeight
    .db charHeight/2

ascii_s:
ascii_5S:
    .db 4
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2
    .db vectMoveXNeg | (vectDrawLineX << 4)
    .db charWidth
    .db charWidth
    .db vectMoveXNeg | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight/2
    .db vectDrawLineX
    .db charWidth

ascii_t:
ascii_T:
    .db 2
    .db vectMoveY | (vectDrawLineX << 4)
    .db charHeight
    .db charWidth
    .db vectMoveCoordinateNeg | (vectDrawLineY << 4)
    .db charWidth/2
    .db charHeight
    .db charHeight

ascii_u:
ascii_U:
    .db 2
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth
    .db charHeight

ascii_v:
ascii_V:
    .db 3
    .db vectMoveX | (vectDrawDiag22YL << 4)
    .db charWidth/2
    .db charHeight/2
    .db vectMoveYNeg | (vectMoveX << 4)
    .db charHeight
    .db charWidth/2
    .db vectDrawDiag22YR
    .db charHeight/2

ascii_w:
ascii_W:
    .db 4
    .db vectDrawLineY | (vectMoveYNeg << 4)
    .db charHeight
    .db charHeight
    .db vectDrawLineX | (vectDrawLineY << 4)
    .db charWidth/2
    .db charHeight/2
    .db vectMoveYNeg  | (vectDrawLineX << 4)
    .db charHeight/2
    .db charWidth/2
    .db vectDrawLineY
    .db charHeight

ascii_x:
ascii_X:
    .db 2
    .db vectDrawDiagR | (vectMoveYNeg << 4)
    .db charWidth
    .db charHeight
    .db vectDrawDiagL
    .db charWidth

ascii_y:
ascii_Y:
    .db 3
    .db vectMoveX | (vectDrawLineY << 4)
    .db charWidth/2
    .db charHeight/2
    .db vectDrawDiagR | (vectMoveXNeg << 4)
    .db charWidth/2
    .db charWidth/2
    .db vectMoveYNeg | (vectDrawDiagL << 4)
    .db charHeight/2
    .db charWidth/2

ascii_z:
ascii_Z:
    .db 3
    .db vectDrawLineX | (vectMoveXNeg << 4)
    .db charWidth
    .db charWidth
    .db vectDrawDiagR | (vectMoveXNeg << 4)
    .db charWidth
    .db charWidth
    .db vectDrawLineX
    .db charWidth