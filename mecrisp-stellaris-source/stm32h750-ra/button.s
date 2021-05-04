@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "init-button" @ ( -- )
@ -----------------------------------------------------------------------------
init_button:
    @ Enable GPIOC
    ldr  r0, =RCC_AHB4ENR
    ldr  r1, [r0]
    orr  r1, #RCC_AHB4ENR_GPIOCEN
    str  r1, [r0] 

    @ Enable GPIOE
    ldr  r0, =RCC_AHB4ENR
    ldr  r1, [r0]
    orr  r1, #RCC_AHB4ENR_GPIOEEN
    str  r1, [r0] 

    @ Configure GPIO PC5 as follows:
    @ digital input, internal weak pullup
    ldr  r0, =GPIOC_BASE
    
    ldr  r1, [r0, #MODER]
    bic  r1, #(0b11<<10)
    str  r1, [r0, #MODER]

    ldr  r1, [r0, #PUPDR]
    orr  r1, #(0b01<<10)
    str  r1, [r0, #PUPDR]
    
    @ Lock configuration
    movs r1, #(0b1<<5)
    orr  r1, #GPIOC_LCKR_LCKK
    str  r1, [r0, #LCKR]
    bic  r1, #GPIOC_LCKR_LCKK
    str  r1, [r0, #LCKR]
    orr  r1, #GPIOC_LCKR_LCKK
    str  r1, [r0, #LCKR]
    ldr  r1, [r0, #LCKR]

    @ Configure GPIO PE3 as follows:
    @ digital input, internal weak pullup
    ldr  r0, =GPIOE_BASE
    
    ldr  r1, [r0, #MODER]
    bic  r1, #(0b11<<6)
    str  r1, [r0, #MODER]

    ldr  r1, [r0, #PUPDR]
    orr  r1, #(0b01<<6)
    str  r1, [r0, #PUPDR]
    
    @ Lock configuration
    movs r1, #(0b1<<3)
    orr  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    bic  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    orr  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    ldr  r1, [r0, #LCKR]

    bx   lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "button2?" @ ( -- ? )
@ -----------------------------------------------------------------------------
button2:
    dup
button2_nostack:
    ldr  r0, =GPIOE_BASE
    ldr  tos, [r0, #IDR]
    mvn  tos, tos, LSL #28
    asrs tos, #31
    bx   lr

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "button3?" @ ( -- ? )
@ -----------------------------------------------------------------------------
button3:
    dup
button3_nostack:
    ldr  r0, =GPIOC_BASE
    ldr  tos, [r0, #IDR]
    mvn  tos, tos, LSL #26
    asrs tos, #31
    bx   lr

.ltorg
