;--------------------------------------------
; Defines an interrupt service routine.
;--------------------------------------------
; Parameters:
; 	Vector - The interrupt vector address.
;   ISR - The interrupt service routine address.
; Returns:
; 	nothing
;--------------------------------------------
.macro .intvector, vector, isr
    .org vector
    clr     EA
    lcall   onInterrupt
    ljmp    isr
.endm

;--------------------------------------------
; Defines an unused interrupt.
;--------------------------------------------
; Parameters:
; 	Vector - The interrupt vector addressw.
; Returns:
; 	nothing
;--------------------------------------------
.macro .unusedInterrupt, vector
    .org vector
    clr EA
    lcall onInterrupt
    ljmp unexpectedInterrupt
.endm