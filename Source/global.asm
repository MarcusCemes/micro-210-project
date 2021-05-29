; file	servo36218.asm   target ATmega128L-4MHz-STK300
; purpose 360-servo motor control as a classical 180-servo
; with increased angle capability
; module: M4, P7 servo Futaba S3003, output port: PORTB
.include "macros.asm"		; macro definitions
.include "definitions.asm"	; register/constant definitions

.equ	npt = 1484			; effective/observed neutral point of individual servo		

reset:
	LDSP	RAMEND			; set up stack pointer (SP)
	OUTI	DDRB,0xff		; configure portB to output
	rcall	wire1_init		; initialize 1-wire(R) interface
	rcall	LCD_init		; initialize the LCD	
	rjmp	main			; jump to the main program
	
.include "lcd.asm"			; include the LCD routines
.include "printf.asm"		; include formatted print routines
.include "drivers/wire1.asm"		; include Dallas 1-wire(R) routines


.macro CA3		;call a subroutine with three arguments in a1:a0 b0
	ldi	b0, low(@1)		;speed and rotation direction
	ldi b1, high(@1)	;speed and rotation direction
	ldi r29, @2			;angle
	rcall	@0
.endmacro

; main -----------------
main:	
init:							; initializations
	P0	PORTB,SERVO1			; pin=0
	LDI2	b1,b0,npt			; stock np dans a0 et a1

	PRINTF	LCD					; print formatted
.db	"Set 20C",LF,0, 0

npset:							; neutral point setting
	in	r21,PIND
	cpi	r21, 0b11111110
	breq _cw
	cpi	r21, 0b11111101
	breq _ccw
	cpi	r21, 0b01111111
	breq _npmem
_exec:
	rcall	servoreg_pulse
	rjmp	npset
_cw:
	ADDI2	b1,b0,2				; increase pulse timing
	rjmp	_exec
_ccw:
	SUBI2	b1,b0,2				; decrease pulse timing
	rjmp	_exec
_npmem:
	LDI2	b1,b0,npt
	rcall	servoreg_pulse
	
	ldi r28, 0b0100			; a modifier, défini 20 degrés

temp:
	rcall	wire1_reset			; send a reset pulse
	CA	wire1_write, skipROM	; skip ROM identification			
	CA	wire1_write, convertT	; initiate temp conversion
	WAIT_MS	750					; wait 750 msec
	
	rcall	lcd_home			; place r28 to home position
	rcall	wire1_reset			; send a reset pulse
	CA	wire1_write, skipROM						
	CA	wire1_write, readScratchpad	
	rcall	wire1_read			; read temperature LSB
	mov	c0,a0
	rcall	wire1_read			; read temperature MSB
	mov	a1,a0
	mov	a0,c0

_display:
	PRINTF	LCD
	.db	"temp=",FFRAC2+FSIGN,a,4,$42,"C ",LF,0, 0
	PRINTF	LCD
	.db	"a= ",FBIN, a,LF, 0,0  // trouver un moyen dafficher qu'un seul bit
	// a enlever dans le truc final

_test_temp:
	mov r29, a0
	SHIFT4 r29		//Nouvelle macro dans macros.asm Renommer ? SR4 ? (Shift right 4)
	cp r29, r28
	brne PC+2
	rjmp temp
_temp_higher:
	cp r29, r28
	brlo PC+3
	rcall _cw2
	rjmp temp
_temp_lower:
	rcall _ccw2
	rjmp temp

_jump: // au cas où on se trouve trop loins de temp pour utiliser un branch
	jmp temp

_ccw2:
	ADDI2	b1,b0,50
	SUBI	r28, 1		
	rcall	servoreg_pulse
	ret
_cw2:
	SUBI2	b1,b0,50	
	ADDI	r28, 1		
	rcall 	servoreg_pulse
	ret

; servoreg_pulse, in a1,a0, out servo port, mod a3,a2
; purpose generates pulse of length a1,a0
servoreg_pulse:
	WAIT_US	20000
	MOV2	b3,b2, b1,b0	; fait des copies "locales"
	P1	PORTB,SERVO1		; pin=1	
lpssp01:	DEC2	b3,b2
	brne	lpssp01
	P0	PORTB,SERVO1		; pin=0
	ret

;clean les commentaires, vérifier les variables, avec les définitions, droits d'usage, les _ etc
div21:	 /* Fonctions reprises du fichier math.asm, mais modifié pour notre usage afin d'éviter
			 tout conflit dans l'usage de registre*/
	MOV2	c1,c0, a1,a0		; c will contain the result
	clr	d0			; d will contain the remainder
	ldi	w,16			; load bit counter
_d21:	
	ROL3	d0,c1,c0		; shift carry into result c
	sub	d0,5			; subtract b from remainder
	brcc	PC+2		
	add	d0,5			; restore if remainder became negative
	DJNZ	w,_d21			; Decrement and Jump if bit-count Not Zero
	ROL2	c1,c0			; last shift (carry into result c)
	COM2	c1,c0			; complement result
	ret


mul21:	
	CLR2	c2,c1			; clear upper half of result c
	mov	c0,9			; place b in lower half of c
	lsr	c0			; shift LSB (of b) into carry
	ldi	w,8			; load bit counter
_m21:	
	brcc	PC+3			; skip addition if carry=0
	ADD2	c2,c1, a1,a0		; add a to upper half of c
	ROR3	c2,c1,c0		; shift-right c, LSB (of b) into carry
	DJNZ	w,_m21			; Decrement and Jump if bit-count Not Zero
	ret