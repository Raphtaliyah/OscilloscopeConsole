; Copyright 2022 Raphtaliyah <me@raphtaliyah.moe>
;---------------------------------------------------------------------
; Module
;---------------------------------------------------------------------
    .module ToString
;---------------------------------------------------------------------
; Global symbols
;---------------------------------------------------------------------
    .globl byteToHexStringTable
;---------------------------------------------------------------------
; Includes
;---------------------------------------------------------------------
    
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
    
;---------------------------------------------------------------------
; Code
;---------------------------------------------------------------------
    .area CODE (CSEG)

byteToHexStringTable:
    .asciz /00/
    .asciz /01/
    .asciz /02/
    .asciz /03/
    .asciz /04/
    .asciz /05/
    .asciz /06/
    .asciz /07/
    .asciz /08/
    .asciz /09/
    .asciz /0a/
    .asciz /0b/
    .asciz /0c/
    .asciz /0d/
    .asciz /0e/
    .asciz /0f/
    .asciz /10/
    .asciz /11/
    .asciz /12/
    .asciz /13/
    .asciz /14/
    .asciz /15/
    .asciz /16/
    .asciz /17/
    .asciz /18/
    .asciz /19/
    .asciz /1a/
    .asciz /1b/
    .asciz /1c/
    .asciz /1d/
    .asciz /1e/
    .asciz /1f/
    .asciz /20/
    .asciz /21/
    .asciz /22/
    .asciz /23/
    .asciz /24/
    .asciz /25/
    .asciz /26/
    .asciz /27/
    .asciz /28/
    .asciz /29/
    .asciz /2a/
    .asciz /2b/
    .asciz /2c/
    .asciz /2d/
    .asciz /2e/
    .asciz /2f/
    .asciz /30/
    .asciz /31/
    .asciz /32/
    .asciz /33/
    .asciz /34/
    .asciz /35/
    .asciz /36/
    .asciz /37/
    .asciz /38/
    .asciz /39/
    .asciz /3a/
    .asciz /3b/
    .asciz /3c/
    .asciz /3d/
    .asciz /3e/
    .asciz /3f/
    .asciz /40/
    .asciz /41/
    .asciz /42/
    .asciz /43/
    .asciz /44/
    .asciz /45/
    .asciz /46/
    .asciz /47/
    .asciz /48/
    .asciz /49/
    .asciz /4a/
    .asciz /4b/
    .asciz /4c/
    .asciz /4d/
    .asciz /4e/
    .asciz /4f/
    .asciz /50/
    .asciz /51/
    .asciz /52/
    .asciz /53/
    .asciz /54/
    .asciz /55/
    .asciz /56/
    .asciz /57/
    .asciz /58/
    .asciz /59/
    .asciz /5a/
    .asciz /5b/
    .asciz /5c/
    .asciz /5d/
    .asciz /5e/
    .asciz /5f/
    .asciz /60/
    .asciz /61/
    .asciz /62/
    .asciz /63/
    .asciz /64/
    .asciz /65/
    .asciz /66/
    .asciz /67/
    .asciz /68/
    .asciz /69/
    .asciz /6a/
    .asciz /6b/
    .asciz /6c/
    .asciz /6d/
    .asciz /6e/
    .asciz /6f/
    .asciz /70/
    .asciz /71/
    .asciz /72/
    .asciz /73/
    .asciz /74/
    .asciz /75/
    .asciz /76/
    .asciz /77/
    .asciz /78/
    .asciz /79/
    .asciz /7a/
    .asciz /7b/
    .asciz /7c/
    .asciz /7d/
    .asciz /7e/
    .asciz /7f/
    .asciz /80/
    .asciz /81/
    .asciz /82/
    .asciz /83/
    .asciz /84/
    .asciz /85/
    .asciz /86/
    .asciz /87/
    .asciz /88/
    .asciz /89/
    .asciz /8a/
    .asciz /8b/
    .asciz /8c/
    .asciz /8d/
    .asciz /8e/
    .asciz /8f/
    .asciz /90/
    .asciz /91/
    .asciz /92/
    .asciz /93/
    .asciz /94/
    .asciz /95/
    .asciz /96/
    .asciz /97/
    .asciz /98/
    .asciz /99/
    .asciz /9a/
    .asciz /9b/
    .asciz /9c/
    .asciz /9d/
    .asciz /9e/
    .asciz /9f/
    .asciz /a0/
    .asciz /a1/
    .asciz /a2/
    .asciz /a3/
    .asciz /a4/
    .asciz /a5/
    .asciz /a6/
    .asciz /a7/
    .asciz /a8/
    .asciz /a9/
    .asciz /aa/
    .asciz /ab/
    .asciz /ac/
    .asciz /ad/
    .asciz /ae/
    .asciz /af/
    .asciz /b0/
    .asciz /b1/
    .asciz /b2/
    .asciz /b3/
    .asciz /b4/
    .asciz /b5/
    .asciz /b6/
    .asciz /b7/
    .asciz /b8/
    .asciz /b9/
    .asciz /ba/
    .asciz /bb/
    .asciz /bc/
    .asciz /bd/
    .asciz /be/
    .asciz /bf/
    .asciz /c0/
    .asciz /c1/
    .asciz /c2/
    .asciz /c3/
    .asciz /c4/
    .asciz /c5/
    .asciz /c6/
    .asciz /c7/
    .asciz /c8/
    .asciz /c9/
    .asciz /ca/
    .asciz /cb/
    .asciz /cc/
    .asciz /cd/
    .asciz /ce/
    .asciz /cf/
    .asciz /d0/
    .asciz /d1/
    .asciz /d2/
    .asciz /d3/
    .asciz /d4/
    .asciz /d5/
    .asciz /d6/
    .asciz /d7/
    .asciz /d8/
    .asciz /d9/
    .asciz /da/
    .asciz /db/
    .asciz /dc/
    .asciz /dd/
    .asciz /de/
    .asciz /df/
    .asciz /e0/
    .asciz /e1/
    .asciz /e2/
    .asciz /e3/
    .asciz /e4/
    .asciz /e5/
    .asciz /e6/
    .asciz /e7/
    .asciz /e8/
    .asciz /e9/
    .asciz /ea/
    .asciz /eb/
    .asciz /ec/
    .asciz /ed/
    .asciz /ee/
    .asciz /ef/
    .asciz /f0/
    .asciz /f1/
    .asciz /f2/
    .asciz /f3/
    .asciz /f4/
    .asciz /f5/
    .asciz /f6/
    .asciz /f7/
    .asciz /f8/
    .asciz /f9/
    .asciz /fa/
    .asciz /fb/
    .asciz /fc/
    .asciz /fd/
    .asciz /fe/
    .asciz /ff/