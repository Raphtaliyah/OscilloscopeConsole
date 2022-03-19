; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module vGPU
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/Drawing.h.asm\
    .include \src/Headers/Graphics.h.asm\
    .include \src/Macro/DptrMacro.asm\
    .include \src/Definitions/Bool.asm\
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
    .equ YDAC, 0x8000
    .equ XDAC, 0x8003
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Instructions
; The nops are never executed, they are just
; for padding because it's easier to multiply
; by 4 than by 3.
;--------------------------------------------
instructionHandlers:
    ljmp instructionNop
    nop
    ljmp instructionMoveX
    nop
    ljmp instructionMoveXNeg
    nop
    ljmp instructionMoveY
    nop
    ljmp instructionMoveYNeg
    nop
    ljmp instructionMoveCoordinate
    nop
    ljmp instructionMoveCoordinateNeg
    nop
    ljmp instructionDrawLineX
    nop
    ljmp instructionDrawLineY
    nop
    ljmp instructionDrawDiagL
    nop
    ljmp instructionDrawDiagR
    nop
    ljmp instructionDrawDiag22XL
    nop
    ljmp instructionDrawDiag22XR
    nop
    ljmp instructionDrawDiag22YL
    nop
    ljmp instructionDrawDiag22YR
    nop

    ljmp instructionUndefined
    nop

;--------------------------------------------
; Draws a vector array.
;--------------------------------------------
; Parameters:
;	dptr - Vector array pointer.
;   r0   - Scale.
;   r1   - ROM?
; Returns:
;	nothing
;--------------------------------------------
drawVectorArray:
    push a
    push b
    push r0   ; Saved to give one register t0 instruction handlers.
    push r1
    push r2
    push r3
    push r4
    push r5
    push dpl
    push dph
    push dplb
    push dphb
    
    mov  r5, r1
    
    cjne r5, #false, lengthFromROM
    movx a,  @dptr         ; Read the length of the array from RAM.
    sjmp lengthRead
    lengthFromROM:
    clr  a                 ; Read the length of the array from ROM.
    movc a,  @a+dptr
    lengthRead:
    
    jz   exit              ; Don't do anything for 0 length arrays.
    mov  r1, a
    inc  dptr
    
    mov /dptr, #instructionHandlers ; Load the lookup table address.
    mov r3,    #0b0001111  ; Pre-load the mask.
    mov r4,    #2          ; Preset instruction counter to 2.
    
    .swapDptr              ; Can't jump using /dptr.
    
    drawLoop:
    cjne r5, #false, instructionFromROM
    movx a,  @/dptr        ; Read next 2 instructions from RAM.
    sjmp instructionRead
    instructionFromROM:
    clr  a                 ; Read next 2 instructions from ROM.
    movc a,  @a+/dptr
    instructionRead:
    inc  /dptr
    mov  r2, a             ; Save it before masking.
    
    execLoop:
    anl  a, r3             ; Get the instruction from lower nibble.
    rl   a                 ; Multiply by 4.
    rl   a
    jmp  @a+dptr
    
    return:                ; Return label for instruction handlers.
    mov  a, r2             ; Restore the original instruction.
    swap a                 ; Swap nibbles.
    djnz r4, execLoop      ; Execute both instructions.
    mov  r4, #2            ; Reset instruction counter.
    
    djnz r1, drawLoop
    
    exit:
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
    pop b
    pop a
    ret

;--------------------------------------------
; Reads the next operand from the source
; memory.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
.macro readOperand, ?readOperandFromROM, ?operandReadFromRAM
    cjne r5, #false, readOperandFromROM
    movx a, @/dptr                      ; Read the operand from RAM.
    sjmp operandReadFromRAM
    
    readOperandFromROM:
    clr  a                              ; Read the operand from ROM.
    movc a, @a+/dptr
    operandReadFromRAM:
    
    inc /dptr                           ; Next.
.endm

;--------------------------------------------
; No operation instruction.
;--------------------------------------------
; Parameters:
;	r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;	nothing
;--------------------------------------------
instructionNop:
    ljmp return

;--------------------------------------------
; Moves the current X coordinate by the
; specified number of pixels.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveX:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    add  a, drawingXCoordinate  ; Add the scaled value to X.
    mov  drawingXCoordinate, a
    ljmp return

;--------------------------------------------
; Moves the current X coordinate in the
; negative direction by the specified
; number of pixels.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveXNeg:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    mov  b, a                   ; Subtract the scaled value from X.
    clr  c
    mov  a, drawingXCoordinate
    subb a, b
    mov  drawingXCoordinate, a
    ljmp return

;--------------------------------------------
; Moves the current Y coordinate by the
; specified number of pixels.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveY:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab

    add  a, drawingYCoordinate  ; Add the scaled value to Y.
    mov  drawingYCoordinate, a
    ljmp return

;--------------------------------------------
; Moves the current Y coordinate in the
; negative direction by the specified
; number of pixels.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveYNeg:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    mov  b, a                   ; Subtract the scaled value from Y.
    clr  c
    mov  a, drawingYCoordinate
    subb a, b
    mov  drawingYCoordinate, a
    ljmp return

;--------------------------------------------
; Moves the current coordinate by the
; specified number of pixels.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveCoordinate:
    readOperand                 ; Read the first operand (X).
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    add  a, drawingXCoordinate  ; Add the scaled value to X.
    mov  drawingXCoordinate, a
    
    readOperand                 ; Read the second operand (Y).
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    add  a, drawingYCoordinate  ; Add the scaled value to Y.
    mov  drawingYCoordinate, a
    ljmp return

;--------------------------------------------
; Moves the current coordinate by the
; specified number of pixels in the
; negative direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionMoveCoordinateNeg:
    readOperand                 ; Read the first operand (X).
    mov  b, r0                  ; Apply scaling.
    mul  ab

    mov  b, a
    clr  c
    mov  a, drawingXCoordinate
    subb a, b                   ; Subtract the scaled value from X.
    mov  drawingXCoordinate, a
    
    readOperand                 ; Read the second operand (Y).
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    mov  b, a                   ; Subtract the scaled value from Y.
    clr  c
    mov  a, drawingYCoordinate
    subb a, b
    mov  drawingYCoordinate, a
    ljmp return

;--------------------------------------------
; Draws a line in the positive X direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawLineX:
    readOperand
    mov  b, r0
    mul  ab                     ; Apply scaling.
    
    push dpl                    ; Free up dptr to load DAC address.
    push dph
    push r0
    
    mov  r0,    a               ; Use r0 as the counter.
    
    mov  dptr,  #YDAC           ; Update the Y coordinate.
    mov  a,     drawingYCoordinate
    movx @dptr, a
    
    mov  dptr,  #XDAC           ; Load the X DAC address.
    mov  a,     drawingXCoordinate ; Use 'a' as the coordinate.
    
    xLineLoop:
    movx @dptr, a
    inc  a
    djnz r0,    xLineLoop
    
    mov drawingXCoordinate, a   ; Update the coordinate.
    
    pop r0
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a line in the positive Y direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawLineY:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl                    ; Free up dptr to load DAC address.
    push dph
    push r0

    mov  r0,    a               ; Use r0 as the counter
    
    mov  dptr,  #XDAC           ; Update the X coordinate.
    mov  a,     drawingXCoordinate
    movx @dptr, a
    
    mov  dptr,  #YDAC           ; Load the Y DAC address.
    mov  a,     drawingYCoordinate ; Use 'a' as the coordinate.
    
    yLineLoop:
    movx @dptr, a
    inc  a
    djnz r0,    yLineLoop
    
    mov drawingYCoordinate, a   ; Update the coordinate.

    pop r0
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a line diagonally in the left
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiagL:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diagLLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    dec  r1
    inc  r2
    djnz r0,     diagLLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a line diagonally in the right
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiagR:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diagRLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    inc  r1
    inc  r2
    djnz r0,     diagRLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a diagonal line at 22.5 degrees angle
; (between line and X axis) in the left
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiag22XL:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diag22XLLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    dec  r1                     ; X again
    mov  a,      r1
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    
    dec  r1
    inc  r2
    djnz r0,     diag22XLLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a diagonal line at 22.5 degrees angle
; (between line and X axis) in the right
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiag22XR:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diag22XRLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    inc  r1                     ; X again
    mov  a,      r1
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    
    inc  r1
    inc  r2
    djnz r0,     diag22XRLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a diagonal line at 22.5 degrees angle
; (between line and Y axis) in the left
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiag22YL:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diag22YLLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    inc  r2
    mov  a,      r2             ; Y again
    movx @/dptr, a
    
    dec  r1
    inc  r2
    djnz r0,     diag22YLLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Draws a diagonal line at 22.5 degrees angle
; (between line and Y axis) in the right
; direction.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionDrawDiag22YR:
    readOperand
    mov  b, r0                  ; Apply scaling.
    mul  ab
    
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    mov  dptr,  #XDAC           ; Load the DAC addresses.
    mov  /dptr, #YDAC
    
    mov r0, a                   ; Use r0 as the counter.
    mov r1, drawingXCoordinate
    mov r2, drawingYCoordinate
    
    diag22YRLoop:
    mov  a,      r1             ; X
    movx @dptr,  a
    mov  a,      r2             ; Y
    movx @/dptr, a
    inc  r2
    mov  a,      r2             ; Y again
    movx @/dptr, a
    
    inc  r1
    inc  r2
    djnz r0,     diag22YRLoop
    
    mov drawingXCoordinate, r1  ; Update the coordinates.
    mov drawingYCoordinate, r2
    
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    ljmp return

;--------------------------------------------
; Undefined instructions.
;--------------------------------------------
; Parameters:
;   r0    - Scale
;   r5    - ROM?
;   /dptr - Operand pointer
; Returns:
;   nothing
;--------------------------------------------
instructionUndefined:
    ljmp return