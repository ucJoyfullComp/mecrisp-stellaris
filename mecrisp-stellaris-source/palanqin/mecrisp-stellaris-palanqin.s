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

.syntax unified
.cpu cortex-m0
.thumb

@ -----------------------------------------------------------------------------
@ Swiches for capabilities of this chip
@ -----------------------------------------------------------------------------

.equ m0core, 1
.equ m0core_start_offset, 0x00000000
.equ does_above_64kb, 1
.equ withoutunicode, 1

@ Not available:  .equ charkommaavailable, 1

@ -----------------------------------------------------------------------------
@ Start with some essential macro definitions
@ -----------------------------------------------------------------------------

.include "../common/datastackandmacros.s"
.include "macros.s"

@ -----------------------------------------------------------------------------
@ Speicherkarte für Flash und RAM
@ Memory map for Flash and RAM
@ -----------------------------------------------------------------------------

@ Konstanten für die Größe des Ram-Speichers

.equ RamAnfang, 0x00014000 @ Start of RAM          Porting: Change this !
.equ RamEnde,   0x00018000 @ End   of RAM.  16 kb. Porting: Change this !

@ Konstanten für die Größe und Aufteilung des Flash-Speichers

.equ Kernschutzadresse,     0x00004000 @ Darunter wird niemals etwas geschrieben ! Mecrisp core never writes flash below this address.
.equ FlashDictionaryAnfang, 0x00004000 @ 16 kb für den Kern reserviert...           16 kb Flash reserved for core.
.equ FlashDictionaryEnde,   0x00014000 @ 64 kb Platz für das Flash-Dictionary       64 kb Flash available. Porting: Change this !
.equ Backlinkgrenze,        RamAnfang  @ Ab dem Ram-Start.


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
Reset: @ Einsprung zu Beginn
@ -----------------------------------------------------------------------------

   @ Willkommen im Palanqin !
   @ palanqin_debug

   @ Initialisierungen der Hardware, habe und brauche noch keinen Datenstack dafür
   @ Initialisations for Terminal hardware, without Datastack.
   bl uart_init

   @ Catch the pointers for Flash dictionary
   .include "../common/catchflashpointers.s"

   welcome " with M0 core for Palanqin by Matthias Koch"

   @ Ready to fly !
   .include "../common/boot.s"

.org FlashDictionaryAnfang+4, 0xffffffff @ Der erste Link im Flash-Speicher muss "gelöscht" sein. fehl.
