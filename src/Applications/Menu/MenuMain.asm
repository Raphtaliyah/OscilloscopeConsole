; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Menu
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Applications/Menu/Headers/Menu.h.asm\
    .include \src/Applications/Menu/Headers/MenuRender.h.asm\
    .include \src/Applications/Menu/Headers/MenuResources.h.asm\
    .include \src/Headers/Application.h.asm\
    .include \src/Headers/Controller.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/Render.h.asm\
    .include \src/Headers/Sound.h.asm\
    .include \src/Macro/DptrMacro.asm\
    .include \src/Definitions/System.asm\
    
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
    exitCounter:
        .ds 1
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    menuAppDescriptor:
        .dw stringAppName       ; name ptr
        .dw menuMain            ; entry point
        .dw onMessageReceived   ; message handler
    
    stringAppName:
        .asciz /Menu/
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ exitFrames, 120
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

menuMain:
    mov   dptr, #menuServicePostFrame
    lcall addPostRenderFunction
    
    mov r0, #128
    lcall soundSetVolume
    
    menuLoop:
    mov  dptr, #selectedItem
    movx a,    @dptr
    mov  r0,   a

    mov  dptr,  #controllerAValue
    movx a,     @dptr    ; Calculate the index based on the pot value.
    mov  b,     #256/3+1 ; TODO: Don't use magic numbers.
    div  ab
    mov  dptr,  #selectedItem
    movx @dptr, a        ; Set the menu index.
    
    cjne a, r0, menuSelectChanged
    beeped:
    
    mov   r0, #0         ; Read A button for new press.
    lcall controllerReadNewButtonPress
    mov   a, r0
    jz    aNotPressed
    lcall executeSelected  ; Execute the currently selected item.
    aNotPressed:
    
    sjmp menuLoop
    ret

    menuSelectChanged:
    lcall playBeep
    sjmp beeped

;--------------------------------------------
; Executes the selected program.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
executeSelected:
    push a
    push b
    push r0
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    lcall playBeep
    
    mov  dptr, #selectedItem  ; Calculate the offset into the menu
    movx a,    @dptr          ; items.
    mov  b,    #8   ; Size of menu item struct.
    mul  ab
    mov  b,    a
    
    mov  a,   #<menuItems     ; Offset + base address
    add  a,   b
    mov  dpl, a
    mov  a,   #>menuItems
    addc a,   #0
    mov  dph, a
    
    clr  a                    ; Load the application descriptor
    movc a,    @a+dptr        ; pointer.
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a+dptr
    mov  dplb, a
    
    .swapDptr
    mov   r0, #NULL
    mov   r1, #NULL
    lcall createApplication
    
    mov a, r0
    jnz loadFailed
    
    mov /dptr, #NULL
    lcall runApplication

    ;TODO: Validate exit code.
    
    loadFailed:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop r0
    pop b
    pop a
    ret

menuServicePostFrame:
    
    mov c, controllerAButton    ; Check if both buttons are pressed.
    anl c, controllerBButton
    jc  buttonsPressed

    mov  dptr,  #exitCounter    ; Buttons are released, reset counter.
    clr  a
    movx @dptr, a
    sjmp noExitCommand
    
    buttonsPressed:
    mov  dptr,  #exitCounter    ; Increment btn press length counter.
    movx a,     @dptr
    inc  a
    movx @dptr, a

    clr  c                      ; Has it been pressed for long enough?
    subb a, #exitFrames
    jc   noExitCommand
    
                                ; Send exit message.
    mov   r0,    #AMSG_EXIT     ;Message id
    mov   /dptr, #NULL          ;Args 
    lcall sendApplicationMessage

    noExitCommand:
    
    ret

onMessageReceived:
    cjne  r0, #AMSG_DRAW, notDrawMsg        ; Handle draw message
    lcall drawMenuFrame
    sjmp  msgHandled
    notDrawMsg:
    lcall defaultApplicationMessageHandler  ; Use default handler
    msgHandled:
    ret