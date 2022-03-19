; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
    .ifndef MenuItem.h.asm
    .define MenuItem.h.asm
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    
;---------------------------------------------------------------------
; Constants
;---------------------------------------------------------------------
    .equ sizeof_MenuItem,        0x08
    .equ menuItem_AppDescriptor, 0x00
    .equ menuItem_Name,          0x02
    .equ menuItem_PreviewImage,  0x04
    .equ menuItem_PreviewText,   0x06
    .endif