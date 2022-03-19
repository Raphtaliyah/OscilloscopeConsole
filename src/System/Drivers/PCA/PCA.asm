; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module PCA
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/PCA.h.asm\
    .include \src/Headers/Memset.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Macro/Interrupt.asm\
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
    pcaInterruptTable:
        .ds tableLength
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringInit:
        .asciz /Configuring PCA.../
    stringChangingClock0:
        .asciz / Setting PCA mode to /
    stringChangingClock1:
        .asciz /./
    stringReady:
        .asciz /PCA ready!/
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ tableLength,   10 ; 4 pointers for the 4 modules and one for the overflow flag (but that's unused)
    .equ success,       0x00
    .equ fail,          0xFF
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

; Initializes the PCA driver
; Parameters: none
; Returns:
; r0 - status code
initPCA:
    ; Push registers
    push acc
    push r1
    push r2
    push dpl
    push dph
    
    ; Send the init text
    mov dptr, #stringInit
    lcall stdoutSendStringFromROMNewLine

    ; Reset the interrupt table
    mov dptr, #pcaInterruptTable
    mov r0, #tableLength
    mov r1, #0
    mov r2, #0 ; set to null
    lcall memset

    ; Set to fPERIPH/(TPS+1)
    anl CMOD, #~(CPS0 | CPS1)
    
    ; Enable TPS
    orl CKCON0, #PCAX2
    
    ; Send the clock settings
    ; read the clock settings back and only leave the clock bits
    mov r0, CMOD 
    anl r0, #CPS0 | CPS1
    ; send it to stdout
    mov dptr, #stringChangingClock0
    lcall stdoutSendStringFromROM
    lcall stdoutSendFullHex
    mov dptr, #stringChangingClock1
    lcall stdoutSendStringFromROMNewLine
    
    ; Start the counter
    orl CCON, #CR

    ; Enable the interrupt
    setb IEN0.EC
    
    ; TODO: Interrupt priority

    ; Send ready text
    mov dptr, #stringReady
    lcall stdoutSendStringFromROMNewLine
    
    ; Write status code
    mov r0, #success
    
    ; Pop registers
    pop dph
    pop dpl
    pop r2
    pop r1
    pop acc
    ret

; Attempts to take a module.
; Parameters:
; dptr - interrupt handler
; r0   - module number
; Returns:
; r0 - zero for success, -1 for fail
pcaTakeModule:
    ; Push registers
    push acc
    push r1
    push dpl
    push dph
    push dplb
    push dphb

    ; Disable interrupts
    disableIntRestorable
    
    ; Make sure r0 is a valid module number
    mov r1, r0
    lcall validateModuleNumber
    mov a, r1
    jnz failedToTake

    ; Get the pointer to the module entry in the table
    inc AUXR1
    lcall getModulePointer

    ; Check if the module is already taken (pointer is not a null pointer)
    movx a, @dptr
    jnz failedToTake
    push dpl
    push dph
    inc dptr
    movx a, @dptr
    pop dph
    pop dpl
    jnz failedToTake
    ; null pointer

    ; Write the new interrupt pointer
    mov a, dplb
    movx @dptr, a
    mov a, dphb
    inc dptr
    movx @dptr, a
    
    ; Successfuly taken
    mov r0, #0x00
    sjmp taken
    
    failedToTake:
    mov r0, #fail
    taken:
    
    ; Restore interrupts
    restoreInt
    
    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

; Disposes a module
; Parameters:
; r0 - module number
; Returns:
; r0 - 0x00 for success, 0xFF for fail
; note: allows disposing already disposed modules.
pcaDisposeModule:
    ; Push registers
    push acc
    push r1
    push dpl
    push dph
    
    ; Disable interrupts
    disableIntRestorable
    
    ; Make sure the module number is valid
    mov r1, r0
    lcall validateModuleNumber
    mov a, r1
    jnz failedToDispose

    ; Get the pointer for the module
    lcall getModulePointer
    
    ; Change the interrupt pointer to null
    clr a
    movx @dptr, a
    inc dptr
    movx @dptr, a
    
    ; Success
    mov r0, #success
    sjmp disposed
    
    failedToDispose:
    ; Failed
    mov r0, #fail
    
    disposed:
    
    ; Restore interrupts
    restoreInt
    
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

; Returns the 16 bit value of the pca counter
; Parameters: none
; Returns:
; r0:r1 - the value of the counter
pcaReadValue:
    ; Push registers
    push acc
    
    highChanged:
    mov r1, CH
    mov r0, CL
    
    mov a, r1
    cjne a, CH, highChanged

    ; Pop registers
    pop acc
    ret

; Checks whether the 
; Parameters:
; r1 - module number
; Returns:
; r1 - 0x00 for valid, 0xFF for invalid
validateModuleNumber:
    ; Push registers
    push acc
    
    mov a, r1
    clr c
    subb a, #4
    jnc invalidNumber
    mov r1, #success ; valid
    pop acc
    ret
    invalidNumber:
    mov r1, #fail ; invalid
    pop acc
    ret

; Returns the pointer to the entry in the interrupt table for the module
; Parameters:
; r0 - module number
; Returns:
; dptr - module entry pointer
getModulePointer:
    ; Push registers
    push acc
    push r0

    ; Multiply the module number by 2
    mov a, r0
    rl a
    mov r0, a

    ; Calculate the address in the interrupt table
    mov dptr, #pcaInterruptTable
    mov a, dpl
    add a, r0
    mov dpl, a
    mov a, dph
    addc a, #0
    mov dph, a
    
    ; Pop registers
    pop r0
    pop acc
    ret

pcaInterruptHandler:
    push psw
    push dpl
    push dph
    push acc
    
;    push r0
;    push r1
;    push r2
;    push r3
;    push r4
;    push r5
;    push r6
;    push r7
;    push a
;    push b
;    push dpl
;    push dph
;    push dplb
;    push dphb

    ; TODO: More efficient or atleast cleaner solution?
    
    ; Convert the interrupt bits into the module interrupt address
    mov dptr, #pcaInterruptTable
    jbc CCON.CCF0, interruptFound
    inc dptr
    inc dptr
    jbc CCON.CCF1, interruptFound
    inc dptr
    inc dptr
    jbc CCON.CCF2, interruptFound
    inc dptr
    inc dptr
    jbc CCON.CCF3, interruptFound
    inc dptr
    inc dptr
    jbc CCON.CCF4, interruptFound
    inc dptr
    inc dptr
    jbc CCON.CF, interruptFound
    ; TODO: this can't happen but add something to handle this

    interruptFound:
    
    ; Load the pointer
    movx a, @dptr
    push acc
    inc dptr
    movx a, @dptr
    mov dph, a
    pop dpl

    ; Check for null pointer
    mov a, dpl
    jnz intValidAddress
    mov a, dph
    jnz intValidAddress
    ; TODO: Handle null pointer
    sjmp skipCall

    intValidAddress:

    ; Call the interrrupt handler
    callDptr
    
    skipCall:
    
;    pop dphb
;    pop dplb
;    pop dph
;    pop dpl
;    pop b
;    pop a
;    pop r7
;    pop r6
;    pop r5
;    pop r4
;    pop r3
;    pop r2
;    pop r1
;    pop r0
    
    pop acc
    pop dph
    pop dpl
    pop psw
    
    ; Re-enable interrupts
    setb EA
    reti