; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module Boot
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl boot, unexpectedInterrupt

    .globl initDisplay
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Macro/DptrMacro.asm\
    .include \src/Definitions/System.asm\
    .include \src/Headers/Stack.h.asm\
    .include \src/Headers/Applicationmanager.h.asm\
    .include \src/Headers/MemoryController.h.asm\
    
    .include \src/Headers/Interrupt.h.asm\
    .include \src/Headers/StandardOut.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/Malloc.h.asm\
    .include \src/Headers/Millis.h.asm\
    .include \src/Headers/SPI.h.asm\
    .include \src/Headers/PCA.h.asm\
    .include \src/Headers/TLC7226.h.asm\
    .include \src/Headers/Serial.h.asm\
    .include \src/Headers/Controller.h.asm\
    .include \src/Headers/Clocks.h.asm\
    .include \src/Headers/Render.h.asm\
    .include \src/Headers/Nixie.h.asm\
    .include \src/Headers/MCP32S17.h.asm\
    .include \src/Headers/StatusLed.h.asm\
    .include \src/Headers/SD.h.asm\
    .include \src/Headers/Sound.h.asm\
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
    ; The message to display on boot.
    ;--------------------------------------------
    stringReadyMessage:
        .asciz \Eeeep!\
    
    ; The message to display on halt.
    ;--------------------------------------------
    stringHaltMessage:
        .asciz \Reached the end! You may now appre- remove power.\
    
    ; Driver init begin text.
    ;--------------------------------------------
    stringInitializingDrivers:
        .asciz /Initializing drivers.../
    
    ; Drivers ready texts.
    ;--------------------------------------------
    stringDriversReady0:
        .asciz /Driver initialization completed in /
    stringDriversReady1:
        .asciz / ms./
    
    ; Driver init failed texts.
    ;--------------------------------------------
    stringInitFailed1:
        .asciz /Driver at /
    stringInitFailed2:
        .asciz / failed initialization. Status code: /
    
    ; Device initialization texts.
    ;--------------------------------------------
    stringInitDevices1:
        .asciz /Initializing devices.../
    stringInitDevices2:
        .asciz /Devices ready./
    ;TODO: Device init fail.

    ; Modules to load before driver init.
    ;--------------------------------------------
    preloadModules:
        .dw initInterruptSystem
        .dw initStandardOut
        .dw initMalloc
        .dw initMillis
        .dw NULL
    
    ; Modules to load after driver init.
    ;--------------------------------------------
    postloadModules:
        .dw initDisplay
        .dw initRender
        .dw NULL
    
    ; Pointers to driver init functions.
    ;--------------------------------------------
    driverAddresses:
        .dw configureSystemClocks
        .dw initPCA
        .dw enableMillis
        .dw initTLC7226
        .dw configureSPI
        ;.dw sd_Setup    ; Legacy SD driver
        .dw NULL
    
    ; Device initializer functions.
    ;--------------------------------------------
    deviceInitializers:
        .dw createStatusLedDevice
        .dw createControllerDevice
        ;.dw initKeyboard
        .dw createNixieDevice
        .dw createSoundDevice
        .dw NULL
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    ; The number of memory wait states to use
    ; for booting.
    ;--------------------------------------------
    .equ bootExtWaitStates,     0x03
    
    ; The start of the stack.
    ;--------------------------------------------
    .equ stackStart,            0x0100
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Boots the system.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	(doesn't)
;--------------------------------------------
boot:
    lcall setupMemory             ; Configure the memory controller
    orl   AUXR1, #XSTK            ; Move the stack to the on-chip XRAM
    mov   sp,    #<stackStart     ; Set the stack
    mov   spx,   #>stackStart
    lcall createParamStack        ; Create the stack for parameters.
    
    ; TODO: Memory test
    ; TODO: Lower wait state
    
    lcall initPreloadModules      ; Initialize preload modules.
    lcall initializeDrivers       ; Initialize drivers.
    lcall initPostloadModules     ; Initialize postload modules.
    lcall stdoutSendNewLine
    lcall initializeDevices       ; Initialize devices.
    
    lcall stdoutSendNewLine       ; Write ready message.
    mov   dptr, #stringReadyMessage
    lcall stdoutSendStringFromROMNewLine
    lcall stdoutSendNewLine

    lcall createApplicationManager        ; Create application manager
    lcall enterApplicationMode            ; and enter application mode
    
    mov   dptr, #stringHaltMessage        ; Print halt message.
    lcall stdoutSendStringFromROMNewLine
    
    sjmp .                                ; halt

;--------------------------------------------
; Initializes the modules that have to be
; initialized before loading the drivers.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   nothing
;--------------------------------------------
initPreloadModules:
    push dpl
    push dph
    
    mov   dptr, #preloadModules  ; Execute the init functions.
    lcall executeList
    
    pop dph
    pop dpl
    ret

;--------------------------------------------
; Initializes the modules that have to be
; initialized after loading the drivers.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initPostloadModules:
    push dpl
    push dph
    
    mov   dptr, #postloadModules  ; Execute the init functions.
    lcall executeList
    
    pop dph
    pop dpl
    ret

;--------------------------------------------
; Initializes the drivers.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initializeDrivers:
    push acc
    push r0
    push r1
    push r2
    push r3
    push dpl
    push dph
    push dplb
    push dphb
    
    ENTER 4                         ; Get the current milliseconds.
    lcall millis
    
    lcall serialDriverInit          ; Initialize the serial port.
    mov   dptr, #serialSendByte     ; Create the standard out and
    lcall stdoutSetFallbackFunction ; point it to serial.
    
    mov   dptr, #stringInitializingDrivers  ; Send the init message.
    lcall stdoutSendStringFromROMNewLine
    
    mov   dptr, #driverAddresses
    driverInitLoop:
    
    clr  a                    ; Load the next pointer.
    movc a,    @a+dptr
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a+dptr
    mov  dplb, a
    inc  dptr
    
    mov  a, dplb             ; Check if the pointer is null.
    jnz  driverAddressNotNull
    mov  a, dphb
    jnz  driverAddressNotNull
    sjmp driverInitDone      ; null found, done.
    driverAddressNotNull:
    
    lcall stdoutSendNewLine  ; Add a new line before
    
    push dplb                ; Save the driver address
    push dphb
    
    .swapDptr                ; Call the init function
    callDptr
    .swapDptr
    
    pop dphb                 ; Restore driver address
    pop dplb
    
    mov a, r0                ; Check the return code
    jnz driverInitFailed
    
    sjmp driverInitLoop
    driverInitDone:
    
    mov r0, bp      ; Read the first 2 bytes of the millis from the start.
    mov r1, @r0
    inc r0
    mov r2, @r0
    
    lcall millis    ; Get the current millis.
    mov   r0, bp    ; Calculate the number of milliseconds this took
    mov   a,  @r0
    clr   c
    subb  a,  r1
    mov   r3, a
    inc   r0        ; Next byte
    mov   a,  @r0
    subb  a,  r2
    mov   r0, a
    mov   r1, r3
    
    lcall stdoutSendNewLine               ; \n
    mov   dptr, #stringDriversReady0      ; Driver initialization...
    lcall stdoutSendStringFromROM         ; ... completed in ...
    lcall stdoutSendFullHex16             ; ... n ...
    mov   dptr, #stringDriversReady1      ; ...ms
    lcall stdoutSendStringFromROMNewLine
    lcall stdoutSendNewLine               ; \n
    
    LEAVE
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r3
    pop r2
    pop r1
    pop r0
    pop acc
    ret
    
    driverInitFailed:
    push r0
    
    lcall stdoutSendNewLine          ; \n
    mov   dptr, #stringInitFailed1   ; Driver at ...
    lcall stdoutSendStringFromROM
    mov   r0,   dplb                 ; ...address...
    mov   r1,   dphb
    lcall stdoutSendFullHex16
    mov   dptr, #stringInitFailed2   ; ... failed init. status: ...
    lcall stdoutSendStringFromROM
    pop   r0                         ; ...code
    lcall stdoutSendFullHex
    lcall stdoutSendNewLine          ; ...\n
    
    ; TODO: No.
    sjmp .                           ; Freeze

;--------------------------------------------
; Initializes the devices.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initializeDevices:
    push dpl
    push dph
    
    mov   dptr, #stringInitDevices1     ; Initializing devices...
    lcall stdoutSendStringFromROMNewLine
    lcall stdoutSendNewLine
    
    ;TODO: Fix new lines.

    mov   dptr, #deviceInitializers     ; Execute the init functions.
    lcall executeList
    
    lcall stdoutSendNewLine
    mov   dptr, #stringInitDevices2     ; Devices ready.
    lcall stdoutSendStringFromROMNewLine

    pop dph
    pop dpl
    ret

;--------------------------------------------
; Executes a list of function pointers in
; ROM.
;--------------------------------------------
; Parameters:
;   dptr - Pointer to the list.
; Returns:
;   nothing
;--------------------------------------------
executeList:
    push acc
    push r0
    push dpl
    push dph
    push dplb
    push dphb

    execLoop:
    clr  a                ; Load the next pointer.
    movc a,    @a + dptr
    mov  dphb, a
    inc  dptr
    clr  a
    movc a,    @a + dptr
    mov  dplb, a
    inc  dptr
    
    mov  a, dplb          ; Is it null?
    jnz  validPointer
    mov  a, dphb
    jnz  validPointer
    sjmp listDone         ; null ptr, done.
    validPointer:
    
    .swapDptr             ; Call the function.
    callDptr
    .swapDptr
    
    ; TODO: Handle the status code of the modules.
    
    sjmp execLoop
    listDone:
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

;--------------------------------------------
; Configures the memory controller.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
setupMemory:
    push r0
    
    mov   r0, #internal2048         ; Set internal size to 2K.
    lcall memorySetInternalRamSize
    mov   r0, #0x01                 ; Disable constant output of ALE
    lcall memoryALEmode             ; to reduce noise.
    mov   r0, #bootExtWaitStates    ; Set (temporary) wait states.
    lcall memorySetWaitStates
    mov   r0, #true                 ; Map full address space to
    lcall memoryMapFullExternal     ; external.
    
    pop r0
    ret

;--------------------------------------------
; Interrupt handler for interrupts that
; should be enabled. This is just a 
; safeguard.
;--------------------------------------------
; Parameters:
;	stack (2) - Interrupt source.
; Returns:
;	nothing
;--------------------------------------------
unexpectedInterrupt:
    ; TODO: This
    sjmp .
    reti