; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef Graphics.h.asm
    .define Graphics.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl drawVectorArray, drawAscii, drawAsciiString
;---------------------------------------------------------------------
; Vector instruction set
;---------------------------------------------------------------------
    .equ vectNop,               0x0
    .equ vectMoveX,             0x1
    .equ vectMoveXNeg,          0x2
    .equ vectMoveY,             0x3
    .equ vectMoveYNeg,          0x4
    .equ vectMoveCoordinate,    0x5
    .equ vectMoveCoordinateNeg, 0x6
    .equ vectDrawLineX,         0x7
    .equ vectDrawLineY,         0x8
    .equ vectDrawDiagL,         0x9
    .equ vectDrawDiagR,         0xA
    .equ vectDrawDiag22XL,      0xB
    .equ vectDrawDiag22XR,      0xC
    .equ vectDrawDiag22YL,      0xD
    .equ vectDrawDiag22YR,      0xE
    
    .endif