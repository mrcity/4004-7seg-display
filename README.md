# Intel 4004 Happy 2022

This repository contains the code and schematic for a project involving the modern [MCS-4 Development Kit](https://www.cpushack.com/mcs-4-test-boards-for-sale/) using an Intel 4004 CPU to display "Intel 4004 Says Happy 2022." on a common-anode 7-segment LED display.

## Preview

![Video of Intel 4004 Happy New Year message, also showing full board and breadboard wiring](4004-board.gif)

## Schematic

![Schematic for this project](Intel%204004%20Happy%202022.png)

## Theory of Operation

The 4004 only provides four ports for handling address and data information.  The 4289 chip at least separates address and data, but still only provides four I/O lines.  The 4289's address lines A10:A8 (controlled by using the `SRC` instruction on the 4004) are routed into a 74HC138 1-of-8 decoder that can act like a Chip Select line (i.e. "output strobe").

On the MCS-4 board itself, output strobes 0 and 1 go to their own banks of four LEDs.  Strobes 2 through 7 don't manifest themselves on the board.  As such, this code writes the "natural" data pattern to the LED banks on the board when strobes 0 and 1 are selected, but then writes the inverted (or totally off) data pattern onto the output port when the other strobes are selected so that the LOW signal output can sink current from the LED (since the LED display is common-anode).

However, writing 0 to the I/O pin to enable the LED is only half the story.  To select exactly which group of four LEDs get activated, we use eight OR gates.  Each 74HC32 (quad 2-input OR gate) chip has, as inputs, each of the four I/O signals from the 4289; in addition, each chip gets its own chip select signal driven by the 74HC138 decoder (from decoder lines / output strobes 2 and 3, specifically).  Because the LEDs are active low and the decoder outputs are active low, then we can use the OR gate to drive the desired LED low by sending each bit of I/O HIGH (except for the desired LED, whose corresponding I/O line is driven LOW).  This way, only one LED is on at a time, therefore preventing a drop in brightness from running multiple LEDs at once.

## Software

Data is encoded where LEDs that are ON are 1, and LEDs that are OFF are 0.  In a particular byte of data, here are the LED segments that map to each bit:
| Pattern | LED segment |
|---------|-------------|
| 0x80    |   dot
| 0x40    |   C
| 0x20    |   D
| 0x10    |   E
| 0x8     |   G
| 0x4     |   F
| 0x2     |   A
| 0x1     |   B

For example, 0x3C is a lowercase "t".

Exactly what LED segment corresponds to what letter can be found in the [LED datasheet](https://www.jameco.com/Jameco/Products/ProdDS/335101.pdf).  In general, A is the top bar, then each subsequent letter goes clockwise.  G is the bar through the middle.

The software takes into account that gates must be driven LOW in order for LEDs to activate, and that we only desire for one LED to be on at a time in order to maximize brightness.  (However, putting resistors on each gate rather than on the common anode might negate this notion.)

The program takes up 102 bytes of ROM, from 0x00 through 0x66.  Data for the message starts at 0xB0 in the ROM and goes through 0xCC.  Once the address pointer (R1R0) gets to 0xCD, the pointer is wrapped back around to 0xB0.  The contents at ROM address (R1R0) are stored into R3R2.  The program takes either R3 or R2 and loads it into R15.  Then, in order to decide if we toggle the LED or not, R15 is rotated left, where the bit rotated out becomes the "Carry" bit.  If the Carry bit is 1, then we present the value of R12 onto the output pins.  If the Carry bit is 0, then we present the value of R14 (all 1's) onto the output pins.

The program is kept short by also rotating the "desired LED output pattern" kept in R12 for one nybble from 0x7 to 0xB to 0xD to 0xE.  Once the 0 is rotated out, it ends up as the "Carry" bit, where we can detect it and then run instructions to find out what to do next -- either load the next nybble in the character data, or go on to check the status of our delay counter.

For the first nybble of character data, 0 is loaded into R13.  Then, when the Carry bit becomes 0 as described above, the program checks for the value of R13.  If it is found to be zero (i.e. the Zero flag is set after loading the register into the accumulator), then the other nybble of data is loaded into R15, R12 is reinstantiated as 0x7, and R13 is reinstantiated as all 1's  Next time the carry bit from rotating R12 becomes 0, and R13 is seen to be all 1's, the program stops messing with character data for a bit to check the delay counter.

In order for a character to register as visible to the human eye, it must be drawn several times before the next character is rendered.  Otherwise, the display will show an "8" with different vanes showing different brightnesses depending on what characters have been shown recently.  As such, registers R8 and R9 govern how many times the same character is rendered.  In this code, both start out as 0, and both get incremented until both roll to 0 again.  This means the character is drawn 256 times before it changes.  There is also a "FLASH" segment after each letter is drawn that clears all LED segments so it appears blank.  This gets iterated 64 times, and its purpose is to give the viewer the essence of changing characters, even if the same character gets repeated multiple times, so they know the next data was rendered.  However, this effect does not show up on-camera, so this delay would need to be increased by initializing R8 to a lower value so that it gets iterated more times. 

## Potential Improvement

The LED output is rather dim when seen in-person.  The video looks good, but it's worth noting that no resistors are in series with the 7-segment display, thus they cannot be made to shine any brighter.  In order to brighten up the display, one could consider using a 74HC373 or 74HC573 latch, or even a 74HC161 4-bit counter/latch, then writing the desired LED output pattern to the I/O port, and then setting the chip select line active for the desired latch chip so that the latch can store the desired pattern while the CPU goes on to calculate other things.  This way, the LED duty cycle might become higher, thus brightening up the display.  However, it is not apparent where the LEDs stop getting driven in a particular pattern -- that is to say, they should be on at full duty cycle anyway.
