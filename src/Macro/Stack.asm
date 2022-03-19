; Pushes 2 8 bit registers
.macro push16 low, high
    push low
    push high
.endm

.macro pop16 low, high
    pop high
    pop low
.endm