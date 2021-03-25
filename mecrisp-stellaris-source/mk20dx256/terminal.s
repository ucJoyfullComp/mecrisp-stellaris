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
@

@ Terminalroutinen
@ Terminal code and initialisations.
@ Porting: Rewrite this !


@ 32 Bit Register

.equ SIM_SCGC4,  0x40048034
.equ SIM_SCGC5,  0x40048038

.equ SIM_SCGC4_UART0_MASK, 0x0400

.equ SIM_SCGC5_PORTA_MASK, 0x0200
.equ SIM_SCGC5_PORTB_MASK, 0x0400
.equ SIM_SCGC5_PORTC_MASK, 0x0800
.equ SIM_SCGC5_PORTD_MASK, 0x1000
.equ SIM_SCGC5_PORTE_MASK, 0x2000


.equ SIM_SOPT5,  0x40048010
.equ SIM_SOPT5_UART0RXSRC_1,   1
.equ SIM_SOPT5_UART0TXSRC_1,   3

@ 32 Bit Register

.equ PORTB_PCR16,  0x4004A040
.equ PORTB_PCR17,  0x4004A044


.equ PORT_PCR_MUX_3, 3<<8 		@ pg 227 defines MUX concept. 011 = Alternative 3 defined on pg 208.  Puts UART0 on 0/1 of teensy 


@ Byte-Registers
.equ UART0_BDH,   0x4006A000
.equ UART0_BDL,   0x4006A001
.equ UART0_C1,    0x4006A002
.equ UART0_C2,    0x4006A003
.equ UART0_S1,    0x4006A004
.equ UART0_S2,    0x4006A005
.equ UART0_C3,    0x4006A006
.equ UART0_D,     0x4006A007
.equ UART0_MA1,   0x4006A008
.equ UART0_MA2,   0x4006A009
.equ UART0_C4,    0x4006A00A
.equ UART0_C5,    0x4006A00B

.equ UARTLP_C2_RE_MASK, 0x4
.equ UARTLP_C2_TE_MASK, 0x8

.equ UART_S1_OR_MASK,   0x8

@ -----------------------------------------------------------------------------
uart_init: @ ( -- )
@ -----------------------------------------------------------------------------

  @ Allgemeine Systemeinstellungen
  @ Global system settings

  ldr  r1, = 0x00000000 | SIM_SCGC5_PORTA_MASK | SIM_SCGC5_PORTB_MASK | SIM_SCGC5_PORTC_MASK | SIM_SCGC5_PORTD_MASK | SIM_SCGC5_PORTE_MASK
  ldr  r0, =SIM_SCGC5 @ Alle GPIO-Ports aktivieren  Switch on clock for all GPIO ports
  str  r1, [r0]

  @ Turn on clock to UART0 module and select 48Mhz clock (FLL/PLL source)

  ldr  r1, = 0x00000000 | SIM_SCGC4_UART0_MASK @ UART enable
  ldr  r0, =SIM_SCGC4
  str  r1, [r0]

  ldr  r1, = 0x00000000  @ pg 245 - select UART Pins as Sources
  ldr  r0, =SIM_SOPT5
  str  r1, [r0]
 
  @ Select "Alt 3" usage to enable UART0 on pins
  ldr r1, =PORT_PCR_MUX_3

  ldr r0, =PORTB_PCR16
  str r1, [r0]
  ldr r0, =PORTB_PCR17
  str r1, [r0]

  @ Init UART
  movs r1, #0
  ldr  r0, =UART0_C2
  strb r1, [r0]
  ldr  r0, =UART0_C1
  strb r1, [r0]  
  ldr  r0, =UART0_C3
  strb r1, [r0]
  ldr  r0, =UART0_S2
  strb r1, [r0]


  @ Set the baud rate divisor

    @ After exiting reset, or recovering from a very low leakage state, the MCG will be in FLL
    @ engaged internal (FEI) mode with MCGCLKOUT at 20.97 MHz, assuming a factory
    @ trimmed slow IRC frequency of 32.768 kHz. If a different MCG mode is required, the
    @ MCG can be transitioned to that mode under software control.

    @ divisor = (20.97MHz / 16) / 115200 = 11.377
    @ --> bdh = 0
    @ --> bdl = 11
    @ --> BRFD = .375 ; BRFA = %01100
  
  movs r1,  0x0C 
  ldr  r0, =UART0_C4
  strb r1, [r0]

  movs r1, #0 @ Baudrate High
  ldr  r0, =UART0_BDH
  strb r1, [r0]

  movs r1, #11 @ Baudrate Low
  ldr  r0, =UART0_BDL
  strb r1, [r0]

  movs r1, #UARTLP_C2_RE_MASK | UARTLP_C2_TE_MASK
  ldr  r0, =UART0_C2
  strb r1, [r0]

  bx lr


.include "../common/terminalhooks.s"

@ Werte für den UART0_S1-Register
@ Values for the UART0_S1 Register
.equ UART_S1_RDRF_MASK, 0x20  @ Receive  Data Register Full
.equ UART_S1_TDRE_MASK, 0x80  @ Transmit Data Register Empty

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit"
serial_emit: @ ( c -- ) Emit one character
@ -----------------------------------------------------------------------------
   push {lr}

1: bl serial_qemit
   cmp tos, #0
   drop
   beq 1b

   ldr r0, =UART0_D  @ Abschicken
   strb tos, [r0]
   drop

   pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key"
serial_key: @ ( -- c ) Receive one character
@ -----------------------------------------------------------------------------
   push {lr}

1: bl serial_qkey
   cmp tos, #0
   drop
   beq 1b

   ldr r0, =UART0_D   @ Einkommendes Zeichen abholen
   pushdatos          @ Platz auf dem Datenstack schaffen

   ldrb tos, [r0]     @ Register lesen
   uxtb tos, tos      @ 8 Bits davon nehmen, Rest mit Nullen auffüllen.
  
   pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?"
serial_qemit:  @ ( -- ? ) Ready to send a character ?
@ -----------------------------------------------------------------------------
   push {lr}
   bl pause

   @ Clear receiver overrun flag as it could stall communication completely.
   ldr  r0, =UART0_S1
   movs r1, #UART_S1_OR_MASK
   strb r1, [r0]

   pushdaconst 0

   ldr r0, =UART0_S1
   movs r2, #UART_S1_TDRE_MASK

   ldrb r1, [r0]     @ Warte solange bis Receive-Register voll ist.
   ands r1, r2
   beq 1f
     mvns tos, tos
1: pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key?"
serial_qkey:  @ ( -- ? ) Is there a key press ?
@ -----------------------------------------------------------------------------
   push {lr}
   bl pause

   @ Clear receiver overrun flag as it could stall communication completely.
   ldr  r0, =UART0_S1
   movs r1, #UART_S1_OR_MASK
   strb r1, [r0]

   pushdaconst 0

   ldr r0, =UART0_S1
   movs r2, #UART_S1_RDRF_MASK

   ldrb r1, [r0]     @ Warte solange bis Receive-Register voll ist.
   ands r1, r2
   beq 1f
     mvns tos, tos
1: pop {pc}

  .ltorg @ Hier werden viele spezielle Hardwarestellenkonstanten gebraucht, schreibe sie gleich !
