@
@    Mecrisp-Stellaris - A native code Forth implementation for ARM-Cortex M microcontrollers
@    Copyright (C) 2013  Matthias Koch
@
@    This program is free software: you can redistribute it and/or modify
@    it under the terms of the GNU General Public License as published by
@    the Free Software Foundation, either version 3 of the License, or
@    (at your option) any later version.
@
@    This program is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@    GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License
@    along with this program.  If not, see <http://www.gnu.org/licenses/>.

.syntax unified
.cpu cortex-m7
.thumb

.include "svd.s"

@ -----------------------------------------------------------------------------
@ Swiches for capabilities of this chip
@ -----------------------------------------------------------------------------

.equ registerallocator, 1
.equ charkommaavailable, 1
.equ does_above_64kb, 0
.equ color, 1
.equ above_ram, 1

@ -----------------------------------------------------------------------------
@ Start with some essential macro definitions
@ -----------------------------------------------------------------------------

.include "../common/datastackandmacros.s"

@ -----------------------------------------------------------------------------
@ Speicherkarte für Flash und RAM
@ Memory map for Flash and RAM
@ -----------------------------------------------------------------------------

@ Konstanten für die Größe des Ram-Speichers

.equ RamAnfang, 0x20000000 @ Start of DTCM Porting: Change this !
.equ RamEnde,   0x20020000 @ End   of DTCM. 128 kiB. Porting: Change this !

@.equ RamAnfang, 0x24040000  @ Treat the whole 512kiB AXI SRAM as flash
@.equ RamEnde,   0x24080000  @ End   of DTCM. 128 kiB. Porting: Change this !
@ Konstanten für die Größe und Aufteilung des Flash-Speichers

.equ FlashDictionaryAnfang, 0x24000000  @ Treat the whole 512kiB AXI SRAM as flash
.equ FlashDictionaryEnde,   0x24080000  @ 

.equ Backlinkgrenze,        FlashDictionaryAnfang   @ Ab dem Ram-Start.


@ -----------------------------------------------------------------------------
@ Anfang im Flash - Interruptvektortabelle ganz zu Beginn
@ Flash start - Vector table has to be placed here
@ -----------------------------------------------------------------------------
.text    @ Hier beginnt das Vergnügen mit der Stackadresse und der Einsprungadresse
.include "vectors.s" @ You have to change vectors for Porting !

@ -----------------------------------------------------------------------------
@ Include the Forth core of Mecrisp-Stellaris
@ -----------------------------------------------------------------------------

.include "../common/forth-core.s"

@ -----------------------------------------------------------------------------
Reset_ITCM: @ Einsprung zu Beginn
.equ Reset, Reset_ITCM+0x08000000
@ -----------------------------------------------------------------------------

    @ Enable the data and instruction caches first to speed up the bootstrap.
    @bl    enable_caches         @ Have the cache prefetch from internal flash

    @ To maximize performance this Mecrisp Stellaris port copies
    @ the kernel from internal flash to ITCM.
    movs  r0, #0x08000000       @ r0 = start of flash
    movs  r1, #0                @ r1 = start of ITCM
    ldr   r2, =end_of_kernel    @ r2 = size of ITCM
1:  ldmia r0!, {r3}             @ TODO: copy less, copy faster
    stmia r1!, {r3}
    cmp   r1, r2
    bne   1b

    @ The interrupt vector table uses absolute addresses
    @ pointing to the copy in ITCM. Let's hope there are no
    @ interrupts before the code is copied. Now that everything
    @ has been copied we can use the vector table in the ITCM.
    ldr   r0, =0xE000ED08 @ relocate interrupt vector table
    movs  r1, #0
    str   r1, [r0]
    dsb
    isb

    movw  r1, #:lower16:Handover+1  @ relocate execution
    bx    r1

.ltorg

Handover:

    @ Configure the flash for full speed operation
    bl    flash_400mhz
    bl    ldo_on
    bl    vos1
    bl    hse_on
    bl    pll_400mhz
    bl    init_led
    bl    init_spi
    bl    init_crc
    
    @ Wipe the AXI SRAM
    ldr   r0, =FlashDictionaryAnfang
    add   r1, r0, #(FlashDictionaryEnde - FlashDictionaryAnfang)
    mov   r2, #0xffffffff
    movs  r3, r2
2:  stmia r0!, {r2, r3}
    cmp   r0, r1
    bne   2b

    push  {psp}
    ldr   psp, =datenstackanfang

    @ Load the AXI SRAM from SPI flash
    movs  tos, #0
    stmdb psp!, {tos}
    mov   tos, #FlashDictionaryAnfang
    stmdb psp!, {tos}
    mov   tos, #(FlashDictionaryEnde - FlashDictionaryAnfang)
    bl    spi_move
    pop   {psp}

    @ Catch the pointers for Flash dictionary
    .include "../common/catchflashpointers.s"

    @ Initialize the console
    bl uart_init

    welcome " for STM32H750 Nucleo by Matthias Koch, Jan Bramkamp"

    @ Ready to fly !
    .include "../common/boot.s"

.p2align 2, 0xff
end_of_kernel: