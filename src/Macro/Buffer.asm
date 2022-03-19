; Compares dptr with bufferBase + bufferSize - 1, if it's equal dptr is
; set to bufferBase, else it is incremented
.macro cirBufferGoNext, bufferBase, bufferSize, ?inrange, ?pointerAdjusted
    ; Compare pointer with limit
    mov a, dpl
    cjne a, #<(bufferBase + bufferSize - 1), inrange
    mov a, dph
    cjne a, #>(bufferBase + bufferSize - 1), inrange
    ; Points to last byte
    ; Set pointer to buffer base
    mov dptr, #bufferBase
    sjmp pointerAdjusted
    inrange:
    ; Not at the end of the buffer
    ; Increment pointer
    inc dptr
    pointerAdjusted:
.endm