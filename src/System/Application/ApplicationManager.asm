; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module ApplicationManager
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl loadApplicationFromROM
    .globl rootApplicationDescriptor
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include \src/Headers/ApplicationManager.h.asm\
    .include \src/Definitions/System.asm\
    .include \src/Macro/DptrMacro.asm\
    .include \src/Macro/Interrupt.asm\
    .include \src/Headers/Malloc.h.asm\
    .include \src/Headers/Memset.h.asm\
    .include \src/Headers/StandardOut.h.asm\
    .include \src/Headers/StandardOutEx.h.asm\
    .include \src/Headers/Render.h.asm\
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
    currentAppPointer:
        .ds sizeof_POINTER
    defaultLoaderPointer:
        .ds sizeof_POINTER
    
    ; Cache
    ; 0xFFFF for invalid, stores the stdout pointer for the current application
    ; note: not necessarily = to the one in the appcontext
    cacheStdoutPointer:
        .ds sizeof_POINTER
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
    stringCreating:
        .asciz /Creating application manager./
    stringLoadRootApp:
        .asciz /Loading root application.../
    stringSuccessResult:
        .asciz / Success./
    stringFailResult:
        .asciz / Failed./
    stringFailedToLoadRootApp:
        .asciz /Failed to load root app!/
    stringStdoutLeftStandalone:
        .asciz /Standard out is no longer in standalone mode./
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Creates the application manager with the
; root application.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
createApplicationManager:
    push acc
    push r0
    push r1
    push r2
    push dpl
    push dph
    push dplb
    push dphb
    
    mov dptr, #stringCreating         ; Print init message.
    lcall stdoutSendStringFromROMNewLine
    
    mov dptr, #defaultLoaderPointer   ; Set the default loader to
    writeVarDptr16 #loadApplicationFromROM ; ROM loader.
    
    lcall appManagerInvalidateCache   ; Invalidate caches
    
    mov   dptr, #sizeof_APPCONTEXT    ; Allocate a dummy region.
    lcall malloc
    mov   a,    dpl
    cjne  a,    #0xFF, dummyContextAllocated
    mov   a,    dph
    cjne  a,    #0xFF, dummyContextAllocated
    sjmp  .                           ; TODO: Crash: out of memory
    dummyContextAllocated:
    mov   r0,   #sizeof_APPCONTEXT    ; Set it to NULL.
    mov   r1,   #0
    mov   r2,   #NULL
    lcall memset
    
    inc   AUXR1                       ; Set this dummy context as the,
    mov   dptr, #currentAppPointer    ; current appcontext
    writeADptrToDptr
    inc   AUXR1
    
    mov   dptr, #newApplicationFrame  ; Set the render function to the
    lcall setRenderFunction           ; application manager's frame
                                      ; handler.
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r2
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Hands control over to the applications.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
enterApplicationMode:
    push a
    push r0
    push r1
    push dpl
    push dph
    push dplb
    push dphb

    mov   dptr, #stringLoadRootApp         ; Print the 'loading...' 
    lcall stdoutSendStringFromROM          ; message.
    
    mov   dptr, #rootApplicationDescriptor ; Create the root
    mov   r0, #NULL                        ; application with the
    mov   r1, #NULL                        ; default loader.
    lcall createApplication
    push  dpl
    push  dph
    
    mov   a,    r0
    jz    rootAppLoaded
    mov   dptr, #stringFailResult          ; Failed to load.
    lcall stdoutSendStringFromROMNewLine
    mov   dptr, #stringFailedToLoadRootApp
    lcall stdoutSendStringFromROMNewLine
    sjmp  .                                ; TODO: Crash?
    rootAppLoaded:
        
    mov dptr, #stringSuccessResult         ; Print success result.
    lcall stdoutSendStringFromROMNewLine
    
    lcall stdoutLeaveStandalone            ; Leave stdout standalone
    mov   dptr, #stringStdoutLeftStandalone; mode.
    lcall stdoutSendStringFromROMNewLine
    
    pop   dph                              ; Start the application.
    pop   dpl
    mov   /dptr, #NULL
    lcall runApplication
    
    ;TODO: Check exit code and crash if it's not 0.
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop r0
    pop a
    ret

;--------------------------------------------
; Starts a new application.
;--------------------------------------------
; Parameters:
;   dptr  - application pointer
;   /dptr - args pointer
; Returns:
;   r0 - application exit code
;--------------------------------------------
runApplication:
    push acc
    push r1
    push dpl
    push dph
    push dplb
    push dphb
    
    push dplb
    push dphb
    
    .swapDptr                       ; Get the currently running
    ldVarDptr #currentAppPointer    ; application.
    .swapDptr
    
    ; Change the parent app of the new application.
    write16ToDptrWithOffset dplb, dphb, #appcontext_ParentAppPtrOffset
    
    disableIntRestorable            ; Set the current application to
    .swapDptr                       ; the new application ptr.
    mov   dptr, #currentAppPointer
    writeADptrToDptr
    .swapDptr
    lcall appManagerInvalidateCache ; Invalidate caches
    restoreInt
    
    read16FromDptrWithOffset #appcontext_EntryPtrOffset ; Get and call
    mov dpl, r0                     ; the entry point.
    mov dph, r1
    
    pop dphb                        ; Args.
    pop dplb
    mov r0,  dplb
    mov r1,  dphb
    callDptr
    
    push r0                         ; Push exit code.
    
    
    disableIntRestorable            ; Disable interrupts while swaping
                                    ; back to the parent application.
    
    ldVarDptr #currentAppPointer    ; Read parent application.
    read16FromDptrWithOffset #appcontext_ParentAppPtrOffset
    
    
    mov dpl,   r0                   ; Set parent application as the
    mov dph,   r1                   ; current application.
    mov /dptr, #currentAppPointer
    .swapDptr
    writeADptrToDptr
    .swapDptr
    
    lcall appManagerInvalidateCache ; Invalidate caches
    
    
    restoreInt                      ; Application swap done, restore
                                    ; interrupts.
    
    pop r0                          ; Pop exit code.
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r1
    pop acc
    ret

;--------------------------------------------
; Returns the currently running application.
;--------------------------------------------
; Parameters:
;   none
; Returns:
;   dptr - Pointer to the currently running
;          application.
;--------------------------------------------
getCurrentApplication:
    push acc
    
    disableIntRestorable
    ldVarDptr #currentAppPointer
    restoreInt
    
    pop acc
    ret

;--------------------------------------------
; Loads and creates the application in dptr.
;--------------------------------------------
; Parameters:
;   dptr  - Pointer to the application for
;           the loader.
;   r0:r1 - Application loader (null to use
;           default ROM loader).
; Returns:
;   dptr  - Application pointer.
;   r0    - 0x00 for success, 0xFF for fail.
;--------------------------------------------
createApplication:
    push acc
    push dplb
    push dphb
    
    .swapDptr
    lcall getAppLoaderPtr   ; Get and call the loader.
    callDptr
    .swapDptr
    
    pop dphb
    pop dplb
    pop acc
    ret

;--------------------------------------------
; Sets the stdout for an application.
;--------------------------------------------
; Parameters:
;   dptr  - stdout pointer
;   /dptr - application pointer (NULL for current)
; Returns:
;	nothing
;--------------------------------------------
setApplicationStdout:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    mov a, dplb        ; Check if /dptr is null, if it is,
    jnz appPtrNotNull  ; load the current application ptr.
    mov a, dphb
    jnz appPtrNotNull
    
    .swapDptr          ; Application ptr is null, load the current.
    ldVarDptr #currentAppPointer
    .swapDptr
    appPtrNotNull:
    
    .swapDptr          ; Write the stdout to the appcontext.
    write16ToDptrWithOffset dplb, dphb, #appcontext_StdoutPtrOfsset
    .swapDptr
    
    lcall appManagerInvalidateCache ; Invalidate teh cache.
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Invalidates the appmanager caches.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
appManagerInvalidateCache:
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    
    disableIntRestorable            ; Invalidates stdout cache.
    mov dptr,  #cacheStdoutPointer
    mov /dptr, #0xFFFF
    writeADptrToDptr
    restoreInt
    
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

;--------------------------------------------
; Returns the pointer to the stdout for the
; current application.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;   dptr - Stdout pointer.
;--------------------------------------------
getCurrentStdout:
    push acc
    
    ldVarDptr #cacheStdoutPointer       ; Try from cache.
    mov  a, dpl
    cjne a, #0xFF, stdoutCacheValid
    mov  a, dph
    cjne a, #0xFF, stdoutCacheValid
    
    push dplb
    push dphb
    
    ldVarDptr #currentAppPointer        ; Find the stdout pointer.
    lcall getStdOutRecursive
    
    disableIntRestorable                ; Write cache.
    .swapDptr
    mov dptr, #cacheStdoutPointer
    writeADptrToDptr
    .swapDptr
    restoreInt
    
    pop dphb
    pop dplb

    stdoutCacheValid:
    pop acc
    ret

;--------------------------------------------
; Returns the stdout pointer recursively.
;--------------------------------------------
; Parameters:
;   dptr - Appcontext.
; Returns:
;   dptr - Stdout pointer.
;--------------------------------------------
getStdOutRecursive:
    push acc
    push r0
    push r1
    
    read16FromDptrWithOffset #appcontext_StdoutPtrOfsset ; Read the
    mov a, r0                       ; stdout pointer of this
    jnz stdoutPtrFound              ; appcontext.
    mov a, r1
    jnz stdoutPtrFound
    
    read16FromDptrWithOffset #appcontext_ParentAppPtrOffset ; Was
                                    ; null, check parent.
    
    mov a, r0                       ; If the parent is null than it
    jnz parentAppNotNull            ; hit the bottom, return null and
    mov a, r1                       ; stdout will use fallback.
    jnz parentAppNotNull
    sjmp stdoutPtrFound
    parentAppNotNull:
    
    mov   dpl, r0                   ; Call this again.
    mov   dph, r1
    lcall getStdOutRecursive
    sjmp  stdoutPtrFoundDeep

    stdoutPtrFound:
    mov dpl, r0                     ; Found, move to return register.
    mov dph, r1
    stdoutPtrFoundDeep:
    
    pop r1
    pop r0
    pop acc
    ret

;--------------------------------------------
; Returns the pointer to the application
; loader.
;--------------------------------------------
; Parameters:
;   r0:r1 - Loader.
; Returns:
;   dptr  - Loader pointer.
;--------------------------------------------
getAppLoaderPtr:
    push acc
    
    mov a, r0                       ; Is r0:r1 null?
    jnz notDefault
    mov a, r1
    jnz notDefault
    mov dptr, #defaultLoaderPointer ; yes, return the default loader.
    ldPtrFromDptr
    pop acc
    ret
    
    notDefault:
    mov dpl, r0                      ; No, dptr = r0:r1.
    mov dph, r1
    pop acc
    ret

;--------------------------------------------
; Sends the draw message to the current
; application.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
newApplicationFrame:
    push acc
    push r0
    push r1
    push dpl
    push dph
    
    disableIntRestorable
    lcall getCurrentApplication       ; Load message handler.
    read16FromDptrWithOffset #appcontext_MsgRecPtrOffset
    restoreInt
    
    cjne r0, #NULL, validMsgHandler   ; Check for null.
    cjne r1, #NULL, validMsgHandler
    sjmp frameDone                    ; Null, don't do anything.
    validMsgHandler:
    
    mov r0,   #AMSG_DRAW              ; Send draw message.
    mov dptr, #NULL                   ; No args.
    lcall sendApplicationMessage
    
    frameDone:
    pop dph
    pop dpl
    pop r1
    pop r0
    pop acc
    ret