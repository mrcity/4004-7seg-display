INIT
	LDM 0			;Load 0 into ACC
	DCL				;Select CM_RAM_0 because 0 is in ACC
	FIM 7,$F0		;R14=1111, R15=0000
START
	FIM 0,DATA		;Load data address into R0 & R1; P0 = address pointer
LETTER
	FIM 3,0			;Load 0 into R6 & R7; P3 = segment delay counter (to keep segments on longer)
	FIM 4,0			;Load 0 into R8 & R9; P4 = letter delay counter (so letters show up for ~1 sec)
LOOP
	FIN 1			;Load (R1R0) into R2 & R3; P1 = data at address
HIBITS
	; Select one nybble of the input character
	FIM 6,$70		;Reinitialize LEDs register to 0111 & WHATBR to 1111
; This has one cause and one side effect:
; - This is because I don't feel like figuring out when to put 1 or 0 into CARRY so 0 stays in the right spot in LEDs
; - It also allows us to simply set WHATBR to the appropriate value, rather than having to analyze its complement
	LD $2			;Load R2
	FIM 2,$10		;Load 0x10 into R4 & R5; P2 = output line (1)
	SRC 2			;Set output address to contents of R4/R5
	WRR				;Write ACC to onboard LEDs to correspond with lit 7-segment LEDs
	FIM 2,$30		;Load 0x30 into R4 & R5; P2 = output line (3)
	SRC 2			;Set output address to contents of R4/R5
	XCH CDR			;Put it into register CDR
	JUN RDBITS		;Jump to RDBITS
LOBITS
	; Select the other nybble of the input character
	FIM 6,$7F		;Reinitialize LEDs register to 0111 & WHATBR to 0000
; This has one cause and one side effect:
; - This is because I don't feel like figuring out when to put 1 or 0 into CARRY so 0 stays in the right spot in LEDs
; - It also allows us to simply set WHATBR to the appropriate value, rather than having to analyze its complement
	LD $3			;Load R3
	FIM 2,$00		;Load 0x10 into R4 & R5; P2 = output line (0)
	SRC 2			;Set output address to contents of R4/R5
	WRR				;Write ACC to onboard LEDs to correspond with lit 7-segment LEDs
	FIM 2,$20		;Load 0x20 into R4 & R5; P2 = output line (2)
	SRC 2			;Set output address to contents of R4/R5
	XCH CDR			;Put it into register CDR
RDBITS
	LD CDR			;Load register CDR into ACC
	RAL				;Rotate it left, so highest bit goes to carry
	JCN CNZ,LEDON	;If carry bit != 0, jump to LEDON
	JMS LEDOFF		;Run subroutine LEDOFF (turns off all LEDs)
	JUN ROTATE		;Always jump to ROTATE (rotates LEDs register)
LEDON
	JMS TOGLED		;Run subroutine TOGLED (outputs LEDs register)
ROTATE
	XCH LEDS		;Switch LEDs register into the accumulator
	STC				;Set carry bit, lest register LEDs ends up as all 0
	RAR				;Rotate LED toggler register to the right
	JCN CZ,BRANCH	;If carry bit == 0, jump to BRANCH
	XCH LEDS		;Save accumulator back to LEDS register
	JUN RDBITS		;Continue reading data from the same input character nybble
BRANCH
	XCH LEDS		;Save LED toggler back to LEDS
	LD WHATBR		;Decide which branch to take by loading this register
	JCN ANZ,DELAY	;If ACC != 0, jump back to LOOP to display all character data again
	JUN LOBITS		;If ACC == 0, jump to LOBITS to display 2nd-nybble character data
DELAY
	; Increment letter loop; if not zero, continue looping
	ISZ 9,LOOP
	ISZ 8,LOOP
	; Increment address pointer
	ISZ 1,FLINIT	;R1=R1+1. If not 0, skip to FLINIT
	INC 0			;Increment R0
FLINIT
	LDM $C			;Load $C into ACC
	XCH 8			;Load ACC into R8 so we only increment it 4* before it goes to 0
FLASH
	; Pulse the outputs HIGH so as to clear the LEDs briefly
	LD ONES			;Load ONES register into ACC
	FIM 2,$30		;Set up 2nd output strobe
	SRC 2
	WRR				;Write ACC to output port
	FIM 2,$20		;Set up 1st output strobe
	SRC 2
	WRR				;Write ACC to output port
	ISZ 9,FLASH		;Do this 64 times so we actually notice
	ISZ 8,FLASH
NXTLTR
	; Prepare for next letter by seeing if the pointer is too high
	CLB				;Clear ACC & status flags
	LDM 3			;Set ACC to 3 (twos complement of D)
	ADD 1			;Subtract R1 from ACC (1s comp.)
	JCN ANZ,LETTER	;If R1 != 0xC, jump to LETTER
	CLB				;Clear ACC & status flags
	LDM 4			;Set ACC to 4 (twos complement of C)
	ADD 0			;Subtract R0 from ACC (1s comp.)
	JCN ANZ,LETTER	;If R0 != 0x5, jump to LETTER
	JUN START		;If we're here, always jump to START

; Subroutines
TOGLED
	XCH $C			;Swap contents of R12 & ACC
	WRR				;Write ACC to output port
	XCH $C			;Swap R12 back to the value of Toggle LEDs register
	XCH CDR			;Store CDR back in $F
	BBL $F			;Return from subroutine with $F in ACC
LEDOFF
	XCH ONES		;Swap contents of the register of all 1's & ACC
	WRR				;Write ACC to output port
	XCH ONES		;Swap ONES register back to being all 1's
	XCH CDR			;Store CDR back in $F
	BBL $F			;Return from subroutine with $F in ACC

; register names
LEDS=$C
WHATBR=$D
ONES=$E
CDR=$F
; statuses/flags
ANZ=$C
CZ=$A
CNZ=$2
; where we put DATA
DATA=$B0

* = $B0
.BYTE $41
.BYTE $58
.BYTE $3C
.BYTE $3E
.BYTE $34
.BYTE $00
.BYTE $4D
.BYTE $77
.BYTE $77
.BYTE $4D
.BYTE $00
.BYTE $6E
.BYTE $5F
.BYTE $6D
.BYTE $6E
.BYTE $00
.BYTE $5D
.BYTE $5F
.BYTE $1F
.BYTE $1F
.BYTE $6D
.BYTE $00
.BYTE $3B
.BYTE $77
.BYTE $3B
.BYTE $3B
.BYTE $80
.BYTE $00
.BYTE $00

; Inverse bytes, unused:
;.BYTE $BE
;.BYTE $A7
;.BYTE $C3
;.BYTE $C1
;.BYTE $CB
;.BYTE $FF
;.BYTE $B2
;.BYTE $88
;.BYTE $88
;.BYTE $B2
;.BYTE $FF
;.BYTE $91
;.BYTE $A0
;.BYTE $92
;.BYTE $91
;.BYTE $FF
;.BYTE $A2
;.BYTE $A0
;.BYTE $E0
;.BYTE $E0
;.BYTE $92
;.BYTE $FF
;.BYTE $C4
;.BYTE $88
;.BYTE $C4
;.BYTE $C4
;.BYTE $7F
;.BYTE $FF
;.BYTE $FF

; OR is 00 | 0
;		01 | 1
;		10 | 1
;		11 | 1
;		AB

;A is our input line (active low), and B is "it should be lit up".
;For the gate to emit GND, we need to send the active LED bit LOW for it to be grounded out, since the LED is common anode (high).
;Have BBL write "1111" to the port in order to clear all LEDs after each cycle
;Use "on" LED nomenclature but invert the registers.