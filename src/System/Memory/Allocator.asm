; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module MemoryAllocator
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    .include "src/Macro.asm"
    .include \src/Headers/Malloc.h.asm\
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
    allocatedCount:
        .ds 2
    freeCount:
        .ds 2
;---------------------------------------------------------------------
; Constant data
;---------------------------------------------------------------------
    .area CODE (CSEG)
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ startOffset,       0x4000
    .equ addressLimit,      0x8000
    .equ minBlockSize,      0x0004 ; The minimum size a block can be after breaking it
    .equ allocatedBitMask,  0x7F
    .equ headerSize,        0x04
    .equ allocated,         0x80
    .equ unallocated,       0x00
    .equ failedAlloc,       0xFFFF
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

;--------------------------------------------
; Initializes the memory allocator.
;--------------------------------------------
; Parameters:
;	none
; Returns:
;	nothing
;--------------------------------------------
initMalloc:
    ; Push registers
    push acc
    push r0
    push dpl
    push dph
    push dplb
    push dphb
    
    ; Calculate the size of allocatable space
    ; addressLimit (/dptr) - startOffset (dptr)
    lcall getStartOffset
    inc AUXR1
    lcall getAddressLimit
    inc AUXR1
    ; -
    mov a, dplb
    clr a
    subb a, dpl
    mov dplb, a
    mov a, dphb
    subb a, dph
    mov dphb, a

    ; TODO: add carry checks to check if addressLimit is less then startOffset

    ; Subtract the header size
    ; dptr - headerSize
    mov a, dplb
    clr c
    subb a, #headerSize
    mov dplb, a
    mov a, dphb
    subb a, #0
    mov dphb, a

    ; Add the first block
    mov r0, #unallocated
    lcall setBlock
    
    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r0
    pop acc
    ret

;--------------------------------------------
; Allocates memory on the heap.
;--------------------------------------------
; Parameters:
;	dptr - Number of bytes to allocate.
; Returns:
;	dptr - The address of the allocated memory
;          or -1 for error.
;--------------------------------------------
malloc:
    ; Push registers
    push acc
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push dplb
    push dphb    
    
    ; Check if the size is larger then 2^15
    mov a, dph
    anl a, #0b10000000
    jnz mallocFailed

    ; Swap DPTRs
    inc AUXR1

    ; Load the address limit into r4:r5
    lcall getAddressLimit
    mov r4, dpl
    mov r5, dph

    ; Move the start offset into dptr
    lcall getStartOffset

    mallocLoop:
    
    ; Read the header
    push dpl
    push dph
    movx a, @dptr
    mov r2, a
    inc dptr
    movx a, @dptr
    mov r3, a
    pop dph
    pop dpl

    ; Check if it's allocated, if it is, go to next block
    anl a, #allocated
    jnz mallocLoopGoNext
    ; not allocated

    ; Check if block is breakable or the data fits
    lcall isBreakable

    ; Is it breakable?
    mov a, r0
    jnz mallocBreakable
    ; not breakable

    ; but is it large enough?
    mov a, r1
    jz mallocLoopGoNext ; nope, it's not
    ; it is, allocate the whole block
    ; set size to the block size
    mov dplb, r2
    mov dphb, r3
    sjmp mallocAllocate
    mallocBreakable:

    ; Break the block
    lcall breakBlock

    mallocAllocate:
    ; Allocate the current block

    ; Set the allocated bit
    mov r0, #allocated
    lcall setBlock

    ; Point to the first byte
    inc dptr
    inc dptr

    ; Increase the allocation count
    push dpl
    push dph
    mov dptr, #allocatedCount
    movx a, @dptr
    add a, #1
    movx @dptr, a
    inc dptr
    movx a, @dptr
    addc a, #0
    movx @dptr, a
    pop dph
    pop dpl

    sjmp mallocSuccess

    mallocLoopGoNext:

    ; Calculate the address of the next block
    ; addressOfNextBlock = dptr + readSize(r2:r3) + headerSize
    ; mask the allocated bit
    anl r3, #allocatedBitMask
    ; dptr + readSize(r2:r3)
    mov a, dpl
    add a, r2
    mov dpl, a
    mov a, dph
    addc a, r3
    mov dph, a
    ; previous + headerSize
    mov a, dpl
    add a, #headerSize
    mov dpl, a
    mov a, dph
    addc a, #0
    mov dph, a

    ; Check if the address is over the limit (current(dptr) - limit(r4:r5))
    mov a, dpl
    clr c
    subb a, r4
    mov a, dph
    subb a, r5
    jc mallocLoop
    mallocFailed:
    ; Allocation failed
    mov dptr, #failedAlloc

    mallocSuccess:

    pop dphb
    pop dplb
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    pop acc
    ret

; Frees memory
; Parameters:
; dptr - memory address
; Returns:
; dptr - 0 if success, -1 if fail
free:
    ; Push registers
    push acc
    push r0
    push r2
    push r3
    push dplb
    push dphb

    ; Point to the start of the header
    ; dptr = dptr - headerSize/2
    mov a, dpl
    clr c
    subb a, #headerSize/2
    mov dpl, a
    mov a, dph
    subb a, #0
    mov dph, a

    ; Read the header(/dptr)
    push dpl
    push dph
    movx a, @dptr
    mov dplb, a
    inc dptr
    movx a, @dptr
    mov dphb, a
    pop dph
    pop dpl
    
    ; Is it allocated? if it is, return fail
    mov a, dphb
    anl a, #allocated
    jz freeFail

    ; Clear the allocated bit
    mov r0, #unallocated
    lcall setBlock
    
    ; Attempt to merge with the one above it
    lcall attemptMergeBlock

    ; Check if the pointer points to the first block
    ; /dptr = startOffset
    inc AUXR1
    lcall getStartOffset
    inc AUXR1
    ; /dptr == dptr? if yes, it's the first block, return
    mov a, dpl
    cjne a, dplb, freeNotFirstBlock
    mov a, dph
    cjne a, dphb, freeNotFirstBlock
    ; current block is first blokc
    sjmp freed
    freeNotFirstBlock:

    ; Move to the block below it
    ; dptr = dptr - headerSize/2
    mov a, dpl
    clr c
    subb a, #headerSize/2
    mov dpl, a
    mov a, dph
    subb a, #0
    mov dph, a
    
    ; Read the header (r2:r3)
    movx a, @dptr
    mov r2, a
    inc dptr
    movx a, @dptr
    mov r3, a
    inc dptr ; move to the end of the header, saves pushing dptr

    ; Check if the block is allocated, if it is, return
    anl a, #allocated
    jnz freed

    ; Move to the start of the lower header (dptr = dptr - size(r2:r3) - headerSize)
    ; dptr - size(r2:r3)
    mov a, dpl
    clr c
    subb a, r2
    mov dpl, a
    mov a, dph
    subb a, r3
    mov dph, a
    ; previous - headerSize
    mov a, dpl
    clr c
    subb a, #headerSize
    mov dpl, a
    mov a, dph
    subb a, #0
    mov dph, a

    ; Attempt to merge with the original block
    lcall attemptMergeBlock
    sjmp freed

    freeFail:
    ; Block was not allocated
    mov dptr, #failedAlloc
    sjmp returnFree
    freed:
    ; Increase free count
    mov dptr, #freeCount
    movx a, @dptr
    add a, #1
    movx @dptr, a
    inc dptr
    movx a, @dptr
    addc a, #0
    movx @dptr, a

    ; Success
    mov dptr, #0
    returnFree:

    ; Pop registers
    pop dphb
    pop dplb
    pop r3
    pop r2
    pop r0
    pop acc
    ret


; Breaks a large unallocated block into 2 parts
; Parameters:
; dptr  - block address
; /dptr - size
; Returns: none
; note: should not be called on allocated blocks
breakBlock:
    ; Push registers
    push acc
    push dpl
    push dph
    push dplb
    push dphb
    push r0
    push r1
    push r2
    
    ; Read the header
    ; r1:r2 = originalSize
    push dpl
    push dph
    movx a, @dptr
    mov r1, a
    inc dptr
    movx a, @dptr
    mov r2, a
    pop dph
    pop dpl

    ; Create the first block
    mov r0, #unallocated
    lcall setBlock

    ; Calculate the size of the 2nd block
    ; sizeOf2ndBlock(r1:r2) = originalSize - (requested)size - headerSize
    ; originalSize - requestedSize
    mov a, r1
    clr c
    subb a, dplb
    mov r1, a
    mov a, r2
    subb a, dphb
    mov r2, a
    ; previous - headerSize
    mov a, r1
    clr c
    subb a, #headerSize
    mov r1, a
    mov a, r2
    subb a, #0
    mov r2, a

    ; Calcaulte the address of the 2nd block
    ; addressOf2ndBlock = baseAddress(dptr) + requestedSize(/dptr) + headerSize
    ; dptr + /dptr
    mov a, dpl
    add a, dplb
    mov dpl, a
    mov a, dph
    addc a, dphb
    mov dph, a
    ; previous + headerSize
    mov a, dpl
    add a, #headerSize
    mov dpl, a
    mov a, dph
    addc a, #0
    mov dph, a

    ; Create the second block
    mov r0, #unallocated
    mov dplb, r1
    mov dphb, r2
    lcall setBlock

    ; Pop registers
    pop r2
    pop r1
    pop r0
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

; Sets the values for a block (doesn't check validity of anything)
; Parameters:
; dptr  - base pointer
; /dptr - size (useful size, could contain the allocated bit, will be masked)
; r0    - allocated? (0x80 for allocted, 0 for unallocated)
; Returns: none
setBlock:
    ; Push registers
    push acc
    push dpl
    push dph
    push dplb
    push dphb

    ; Mask allocated bit from size
    anl dphb, #allocatedBitMask

    ; Write low header
    ; ls byte
    mov a, dplb
    movx @dptr, a
    ; add allocated bit
    mov a, dphb
    orl a, r0
    ; ms byte
    inc dptr
    movx @dptr, a
    inc dptr ; point to the first useful byte

    ; Calculate address of high header (dptr = dptr + /dptr)
    mov a, dpl
    add a, dplb
    mov dpl, a
    mov a, dph
    addc a, dphb
    mov dph, a

    ; Write high header
    ; ls byte
    mov a, dplb
    movx @dptr, a
    ; add allocated bit
    mov a, dphb
    orl a, r0
    ; ms byte
    inc dptr
    movx @dptr, a

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop acc
    ret

; Checks if a block can be broken or not. (allocated blocks cannot be broken)
; Parameters:
; dptr  - block base
; /dptr - requested size
; Returns:
; r0 - true (>0) if breakable, false if not
; r1 - true (>0) if the block is large enough for the data but not big enough to break
isBreakable:
    ; Push registers
    push acc
    push dpl
    push dph

    ; Load the size of the block from the header
    movx a, @dptr
    mov b, a
    inc dptr
    movx a, @dptr
    mov dph, a
    mov dpl, b

    ; If the block is allocated, it cannot be broken
    mov a, dph
    anl a, #~allocatedBitMask
    jnz notBreakable

    ; Mask allocated bit
    anl dph, #allocatedBitMask
    
    ; Check if blockSize (dptr) - minBlockSize - headerSize - requestedSize < 0
    ; blockSize (dptr) - requestedSize
    mov a, dpl
    clr c
    subb a, dplb
    mov dpl, a
    mov a, dph
    subb a, dphb
    mov dph, a
    jc notBreakable ; blockSize - requestedSize already less then 0
    ; previous - minBlockSize
    mov a, dpl
    clr c
    subb a, #<minBlockSize
    mov dpl, a
    mov a, dph
    subb a, #>minBlockSize
    mov dph, a
    jc notBreakableButFits ; previous (blockSize - requestedSize) - minBlockSize is less then 0
    ; previous - headerSize
    ; note: This result can be discarded
    mov a, dpl
    clr c
    subb a, #headerSize
    mov a, dph
    clr c
    subb a, #0 ; header size is 8 bit
    jc notBreakableButFits ; previous - headerSize is less then 0
    ; more then 0, breakable
    mov r0, #true
    mov r1, #true
    sjmp breakableCalculated
    notBreakable:
    ; less then 0, not breakable, doesn't fit
    mov r0, #false
    mov r1, #false
    sjmp breakableCalculated
    notBreakableButFits:
    ; not breakable but the data fits
    mov r0, #false
    mov r1, #true
    breakableCalculated:

    ; Pop registers
    pop dph
    pop dpl
    pop acc
    ret

; Attempts to merge the block with the block above it
; Parameters:
; dptr - block base pointer
; Returns: none
attemptMergeBlock:
    ; Push registers
    push acc
    push r0
    push r2
    push r3
    push dpl
    push dph
    push dplb
    push dphb

    ; Read the size of the block (r2:r3)
    push dpl
    push dph
    movx a, @dptr
    mov r2, a
    inc dptr
    movx a, @dptr
    mov r3, a
    pop dph
    pop dpl

    ; Check if the block is allocated, if it is, return
    anl a, #allocated
    jnz mergeFailed
    
    ; Push the base address
    push dpl
    push dph

    ; Calculate the address of the next block
    ; nextBlockAddress(dptr) = dptr(base pointer) + size(r2:r3) + headerSize
    ; dptr(basePointer) + size(r2:r3)
    mov a, dpl
    add a, r2
    mov dpl, a
    mov a, dph
    addc a, r3
    mov dph, a
    ; previous + headerSize
    mov a, dpl
    add a, #headerSize
    mov dpl, a
    mov a, dph
    addc a, #0
    mov dph, a

    ; Check if the block is outside the address range, if yes return
    inc AUXR1
    ; limit(dptr) - current(/dptr)
    lcall getAddressLimit
    mov a, dpl
    clr c
    subb a, dplb
    mov a, dph
    subb a, dphb
    inc AUXR1
    jc mergeFailedCleanStack

    ; Read the size of this block and add it to the size of the previous(r2:r3)
    ; r2:r3 = r2:r3 + size
    push dpl
    push dph
    movx a, @dptr
    add a, r2
    mov r2, a
    inc dptr
    movx a, @dptr
    addc a, r3
    mov r3, a
    pop dph
    pop dpl

    ; Check if the block is allocated, if it is, return
    anl a, #allocated
    jnz mergeFailedCleanStack

    ; We remove one header, so add that to the size too
    mov a, r2
    add a, #headerSize
    mov r2, a
    mov a, r3
    addc a, #0
    mov r3, a

    ; Now pop the base address
    pop dph
    pop dpl

    ; and create a block with the large size
    mov dplb, r2
    mov dphb, r3
    mov r0, #unallocated
    lcall setBlock

    mergeFailed:

    ; Pop registers
    pop dphb
    pop dplb
    pop dph
    pop dpl
    pop r3
    pop r2
    pop r0
    pop acc
    ret
    ; Cleans the stack before jumping to mergeFailed
    mergeFailedCleanStack:
    pop acc
    pop acc
    sjmp mergeFailed

; Returns the start offset
; Returns:
; dptr - start offset
getStartOffset:
    mov dptr, #startOffset
    ret

getAddressLimit:
    mov dptr, #addressLimit
    ret