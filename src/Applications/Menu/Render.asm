; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MenuRender
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Menu/Headers/MenuRender.h.asm\
    .include \src/Applications/Menu/Headers/MenuItem.h.asm\
    .include \src/Applications/Menu/Headers/MenuResources.h.asm\
    .include \src/Headers/Graphics.h.asm\
    .include \src/Headers/Drawing.h.asm\
    .include \src/Macro/DptrMacro.asm\
    .include \src/Macro/LoadStore16.asm\
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
    cursorRestingX:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ menuTitleScale,            4
    .equ menuTitleX,                10
    .equ menuTitleY,                230
    
    .equ menuItemTextScale,         3
    .equ menuItemX,                 20
    .equ menuItemXLimit,            147
    .equ menuItemSeparatorY,        30
    .equ menuItemBaseY,             180
    
    .equ menuSeparatorX,            150
    .equ menuSeparatorY,            0
    .equ menuSeparatorLength,       255
    
    .equ menuItemPreviewImageX,     160
    .equ menuItemPreviewImageY,     160
    .equ menuItemPreviewImageScale, 1
    
    .equ menuItemPreviewTextX,      158
    .equ menuItemPreviewTextY,      128
    .equ menuItemPreviewTextScale,  2
    .equ menuItemPreviewTextXLimit, 255
    
    .equ menuItemSelectorX,         0
    .equ menuItemSelectorScale,     3

    .equ cursorX,           255
    .equ cursorY,           0
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Draws the menu.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
drawMenuFrame:
    push a
    push b
    push r0
    push r1
    push r2
    push r3
    push r4
    push dpl
    push dph
    push dplb
    push dphb
    
    ; Title
    ;--------------------------------------------
    mov r0, #menuTitleX
    mov r1, #menuTitleY
    lcall drawMoveToCoordinate

    mov dptr, #stringMenuTitle  ; String ptr
    mov r0,   #menuTitleScale   ; Scale
    mov r1,   #true             ; From ROM
    mov r2,   #menuTitleX       ; X start
    mov r3,   #0xFF             ; X limit
    lcall drawAsciiString       ; Draw the title.
    
    ; Menu items
    ;--------------------------------------------
    mov dptr, #menuItems  ; Load the pointer to the names.
    .addDptr8Imm 2

    mov r4, #menuItemBaseY  ; Use r4 to keep track of the Y coordinate
    
    menuItemDrawLoop:
    clr  a                  ; Load the name pointer from ROM.
    movc a,    @a+dptr
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a+dptr
    mov  dplb, a
    inc  dptr
    
    mov a, dplb             ; Break on NULL ptr.
    jnz validNamePtr
    mov a, dphb
    jnz validNamePtr
    sjmp itemsDrawn
    validNamePtr:
    
    mov r0, #menuItemX    ; Move to the coordinate for the menu
    mov r1, r4            ; item.
    lcall drawMoveToCoordinate
    
    .swapDptr                       ; Draw text
    mov   r0, #menuItemTextScale    ; Scale
    mov   r1, #true                 ; From ROM
    mov   r2, #menuItemX            ; X start
    mov   r3, #menuItemXLimit       ; X limit
    lcall drawAsciiString
    .swapDptr
    
    mov  a,  r4             ; Subtract the size of the text from Y(r4)
    clr  c
    subb a,  #menuItemSeparatorY + charHeight + charVerticalSpace
    mov  r4, a
    
    .addDptr8Imm 6          ; Next element name pointer.
    sjmp menuItemDrawLoop
    itemsDrawn:
    
    ; Selector
    ;--------------------------------------------
    mov  dptr, #selectedItem    ; Get the selected item and calculate
    movx a,    @dptr            ; the Y position based on the index.
    mov  b,    #menuItemSeparatorY + charHeight + charVerticalSpace
    mul  ab
    mov  b,    a
    clr  c
    mov  a,     #menuItemBaseY
    subb a,    b
    mov  r1,   a
    
    mov   r0, #menuItemSelectorX  ; Move to the coordinate for the
    lcall drawMoveToCoordinate    ; selector.
    
    mov   dptr, #stringItemSelector    ; Symbol string
    mov   r0,   #menuItemSelectorScale ; Scale
    mov   r1,   #true                  ; From ROM
    mov   r2,   #menuItemSelectorX     ; X start
    mov   r3,   #menuItemXLimit        ; X limit
    lcall drawAsciiString              ; Draw the selector symbol.
    
    ; Middle line
    ;--------------------------------------------
    mov   r0, #menuSeparatorX
    mov   r1, #menuSeparatorY
    lcall drawMoveToCoordinate
    
    mov   r0, #menuSeparatorLength
    lcall drawLineY
    
    ; Preview image
    ;--------------------------------------------
    mov  dptr, #selectedItem    ; Calculate the address of the
    movx a,    @dptr            ; preview image from the index.
    mov  b,    #8   ; Size of one item struct.
    mul  ab
    add  a,    #4   ; Offset of image ptr
    push a                      ; Save for the preview text.
    mov  dptr, #menuItems       ; offset + base address
    add  a,    dpl
    mov  dpl,  a
    mov  a,    dph
    addc a,    #0
    mov  dph,  a
    
    clr  a                      ; Load the image pointer from ROM.
    movc a,    @a+dptr
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a+dptr
    mov  dplb, a
    inc  dptr
    
    mov  r0, #menuItemPreviewImageX  ; Move to the image coordinates.
    mov  r1, #menuItemPreviewImageY
    lcall drawMoveToCoordinate
    
    .swapDptr
    mov   r0, #menuItemPreviewImageScale ; Scale
    mov   r1, #true                      ; From ROM
    lcall drawVectorArray                ; Draw the image.
    .swapDptr
    
    ; Preview text
    ;--------------------------------------------
    pop  a                  ; Get the offset of the preview image.
    add  a,    #2           ; Add the relative offset of the text.
    mov  dptr, #menuItems   ; offset + base address
    add  a,    dpl
    mov  dpl,  a
    mov  a,    dph
    addc a,    #0
    mov  dph,  a
    
    clr  a                      ; Load the text pointer from ROM.
    movc a,    @a+dptr
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a+dptr
    mov  dplb, a
    inc  dptr
    
    mov   r0, #menuItemPreviewTextX  ; Move to the text coordinates.
    mov   r1, #menuItemPreviewTextY
    lcall drawMoveToCoordinate
    
    .swapDptr
    mov   r0, #menuItemPreviewTextScale     ; Scale
    mov   r1, #true                         ; From ROM
    mov   r2, #menuItemPreviewTextX         ; X start
    mov   r3, #menuItemPreviewTextXLimit    ; X limit
    lcall drawAsciiString
    .swapDptr
    
    ; Clean up
    ;--------------------------------------------
    mov   dptr,  #cursorRestingX   ; Move the cursor to the side.
    movx  a,     @dptr
    inc   a
    movx  @dptr, a
    mov   r0,    a
    mov   r1,    #cursorY
    lcall drawMoveToCoordinate
    lcall drawUpdateCoordinates
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    pop b
    pop a
    ret