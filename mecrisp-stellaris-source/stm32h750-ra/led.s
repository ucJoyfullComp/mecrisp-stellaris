.equ MODER  , 0x00
.equ OTYPER , 0x04
.equ OSPEEDR, 0x08
.equ PUPDR  , 0x0C
.equ IDR    , 0x10
.equ ODR    , 0x14
.equ BSRR   , 0x18
.equ LCKR   , 0x1C
.equ AFRL   , 0x20
.equ AFRH   , 0x24

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "init-led" @ ( -- )
@ -----------------------------------------------------------------------------
init_led:
    @ Enable GPIOA and GPIOE
    ldr r0, =RCC_AHB4ENR
    ldr r1, [r0]
    orr r1, #RCC_AHB4ENR_GPIOAEN
    orr r1, #RCC_AHB4ENR_GPIOEEN
    str r1, [r0]

    @ Configure GPIO PE0 and PA1 as follows:
    @ MODE = 01 (output), OTYPE = 1 (open drain)
    ldr r0, =GPIOA_BASE

    @ Set PA1 to high = led off
    movs r1, #0b10
    str  r1, [r0, #BSRR]

    @ PA1 otype = open drain
    ldr  r1, [r0, #OTYPER]
    orr  r1, #0b10
    str  r1, [r0, #OTYPER]

    @ PA1 mode = output
    ldr  r1, [r0, #MODER]
    bic  r1, #0b1000
    str  r1, [r0, #MODER]

    @ Lock configuration
    movs r1, #0b10
    orr  r1, #GPIOA_LCKR_LCKK
    str  r1, [r0, #LCKR]
    bic  r1, #GPIOA_LCKR_LCKK
    str  r1, [r0, #LCKR]
    orr  r1, #GPIOA_LCKR_LCKK
    str  r1, [r0, #LCKR]
    ldr  r1, [r0, #LCKR]

    ldr r0, =GPIOE_BASE

    @ Set PE0 to high = led off
    movs r1, #0b1
    str  r1, [r0, #BSRR]

    @ PE0 otype = open drain
    ldr  r1, [r0, #OTYPER]
    orr  r1, #0b1
    str  r1, [r0, #OTYPER]

    @ PE0 mode = output
    ldr  r1, [r0, #MODER]
    bic  r1, #0b10
    str  r1, [r0, #MODER]

    @ Lock configuration
    movs r1, #0b1
    orr  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    bic  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    orr  r1, #GPIOE_LCKR_LCKK
    str  r1, [r0, #LCKR]
    ldr  r1, [r0, #LCKR]

    bx   lr

@ -----------------------------------------------------------------------------
Wortbirne Flag_visible, "led2!" @ ( on? -- )
@ -----------------------------------------------------------------------------
led2_write:

    @ Write to PA1
    movs r0, #(0b10 << 16)

    subs tos, #1
    sbcs tos, tos
    ands tos, #0x10
    lsrs r0, tos
    ldr  tos, =GPIOA_BASE
    str  r0, [tos, #BSRR]
    drop
    
    bx   lr

@ -----------------------------------------------------------------------------
Wortbirne Flag_visible, "led3!" @ ( on? -- )
@ -----------------------------------------------------------------------------
led3_write:

    @ Write to PE0
    movs r0, #(0b01 << 16)

    subs tos, #1
    sbcs tos, tos
    ands tos, #0x10
    lsrs r0, tos
    ldr  tos, =GPIOE_BASE
    str  r0, [tos, #BSRR]
    drop
    
    bx   lr
