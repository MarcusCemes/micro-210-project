; file	servo36218.asm   target ATmega128L-4MHz-STK300
; purpose 360-servo motor control as a classical 180-servo
; with increased angle capability
; module: M4, P7 servo Futaba S3003, output port: PORTB
.include "macros.asm"		; macro definitions
.include "definitions.asm"	; register/constant definitions

.equ	npt = 1484			; effective/observed neutral point of individual servo		
;.def cst = r29
;.def thr = r28
;.def loop = r30

reset:
	LDSP	RAMEND			; set up stack pointer (SP)
	OUTI	DDRB,0xff		; configure portB to output
	rcall	wire1_init		; initialize 1-wire(R) interface
	rcall	LCD_init		; initialize the LCD	
	rjmp	main			; jump to the main program
	
.include "lcd.asm"			; include the LCD routines
.include "printf.asm"		; include formatted print routines
.include "drivers/wire1.asm"		; include Dallas 1-wire(R) routines


; main -----------------
main:	
init:							; initializations
	P0	PORTB,SERVO1			; pin=0
	LDI2	b1,b0,npt			; stock npt dans a0 et a1
_set_unit:
	mov w, d1
	cpi w, 0b00000001
	breq _initF
_initC:
	PRINTF	LCD					; print formatted
	.db	"Set 20C",LF,0, 0
	ldi r28, 0b10100
	rjmp npset
_initF:
	PRINTF	LCD					; print formatted
	.db	"Set 68F",LF,0, 0
	ldi r28, 0b01000100


npset:							; neutral point setting
	in	r21,PIND				// changer pour utiliser le rotatory ancoder
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
	rcall	servoreg_pulse


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
	push a0
	push a1
	
	ldi r30, 50

_change_unit:
	mov w, d1
	cpi w, 0b00000001
	brne _displayC

_displayF:
	rcall mul21
	MOV2 a1,a0, c1, c0
	rcall div21
	MOV2 a1,a0, c1, c0
	ADDI a1, 0b0010
	PRINTF	LCD
	.db	"temp=",FFRAC2+FSIGN,a,4,$42,"F ",LF,0, 0
	rjmp _test_temp
_displayC:
	PRINTF	LCD
	.db	"temp=",FFRAC2+FSIGN,a,4,$42,"C ",LF,0, 0

_test_temp:		
	ROR24 a0, a1
	mov w, d1
	cpi w, 0b00000001
	brne PC+2
	ldi r30,25

_temp_lower:
	cln
	cp a0, r28
	brlo ccw2
_temp_higher:
	cln
	cp r28, a0
	brlo cw2

_exec2:	
	clz
	rcall	servoreg_pulse 
	pop a1
	pop a0
	rjmp temp
ccw2:
	SUBI	r28, 1
_ccw2:
	ADDI2	b1,b0,2
	rcall servoreg_pulse
	DEC r30
	brne _ccw2
	pop a0
	rjmp temp
cw2:
	ADDI	r28, 1	
_cw2:
	SUBI2	b1,b0,2
	rcall servoreg_pulse
	DEC r30
	brne _cw2
	pop a0
	rjmp temp

; servoreg_pulse, in a1,a0, out servo port, mod a3,a2
; purpose generates pulse of length a1,a0
servoreg_pulse:
	WAIT_US	20000
	MOV2	b3,b2, b1,b0	
	P1	PORTB,SERVO1		; pin=1	
lpssp01:	DEC2	b3,b2
	brne	lpssp01
	P0	PORTB,SERVO1		; pin=0
	ret

;clean les commentaires, vérifier les variables, avec les définitions, droits d'usage, les _ etc
div21:	 ; Fonctions reprises du fichier math.asm, mais modifié pour notre usage afin d'éviter tout conflit dans l'usage de registre
	ldi r29,  0b01010000
	MOV2	c1,c0, a1,a0		; c will contain the result
	clr	d0			; d will contain the remainder
	ldi	w,16			; load bit counter
_d21:	
	ROL3	d0,c1,c0		; shift carry into result c
	sub	d0,r29			; subtract b from remainder
	brcc	PC+2		
	add	d0,r29			; restore if remainder became negative
	DJNZ	w,_d21			; Decrement and Jump if bit-count Not Zero
	ROL2	c1,c0			; last shift (carry into result c)
	COM2	c1,c0			; complement result
	ret


mul21:	
	ldi r29, 0b10010000
	CLR2	c2,c1			; clear upper half of result c
	mov	c0,r29			; place b in lower half of c
	lsr	c0			; shift LSB (of b) into carry
	ldi	w,8			; load bit counter
_m21:	
	brcc	PC+3			; skip addition if carry=0
	ADD2	c2,c1, a1,a0		; add a to upper half of c
	ROR3	c2,c1,c0		; shift-right c, LSB (of b) into carry
	DJNZ	w,_m21			; Decrement and Jump if bit-count Not Zero
	ret

	/* utiliser  des push et pop pour utiliser moins de registres ? */