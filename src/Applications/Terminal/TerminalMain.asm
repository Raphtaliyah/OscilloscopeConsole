; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Terminal
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl terminalAppDescriptor
    
    .globl malloc
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Memcpy.h.asm\
    .include \src/Macro/DptrMacro.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/MemoryDump.h.asm\
    .include \src/Headers/Drawing.h.asm\
    .include \src/Definitions/Bool.asm\
    .include \src/Headers/Graphics.h.asm\
    .include \src/Headers/Application.h.asm\
;---------------------------------------------------------------------
; Memory initializers
;---------------------------------------------------------------------
    .area INIT (CSEG)
    .area XINIT (CSEG)
;---------------------------------------------------------------------
; Memory
;---------------------------------------------------------------------
    .area BIT   (DSEG)
    allowDraw:
        .ds 1
    .area DATA  (DSEG)
    .area XDATA (DSEG)
    struct_vectorTest:
        .ds vectorTestLength
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    terminalAppDescriptor:
        .dw stringAppName    ; name ptr
        .dw terminalMain     ; entry point
        .dw onMessageRec     ; message handler
    
    stringAppName:
        .asciz /Terminal/
    
    stringTest:
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .ascii /THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG./
        .db 0
        
        ;.ascii \THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. \
        ;.asciz \1234567890 OWO<OWO>OWO\
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ scale, 2
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

vectorTest:
    .db 1
    .db vectDrawLineY | (vectDrawLineX << 4)
    .db 255
    .db 255
.equ vectorTestLength, (. - vectorTest)

terminalMain:
    setb allowDraw
    sjmp .
    ret

drawHandler:
    jb allowDraw, draw
    ret

    draw:
    push dpl
    push dph
    push r0
    push r1
    push r2
    push r3
    
    mov   r0, #0
    mov   r1, #255-(4*scale)-1
    lcall drawMoveToCoordinate
    
    ;mov dptr, #vectorTest
    ;mov r0,   #1
    ;mov r1,   #1
    ;lcall drawVectorArray
    
    mov   dptr, #stringTest
    mov   r0,   #scale
    mov   r1,   #1
    mov   r2,   #0
    mov   r3,   #255
    lcall drawAsciiString
    
    mov   r0, #255
    mov   r1, #255
    lcall drawMoveToCoordinate
    lcall drawUpdateCoordinates
    
    pop r3
    pop r2
    pop r1
    pop r0
    pop dph
    pop dpl
    ret

onMessageRec:
    cjne  r0, #0x01, notDrawMsg        ; Handle draw message
    lcall drawHandler
    sjmp  msgHandled
    notDrawMsg:
    lcall defaultApplicationMessageHandler  ; Use default handler
    msgHandled:
    ret