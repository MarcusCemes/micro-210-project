; file: temperature     target: ATmega128L-4MHz-STK300
; Reads the temperature and displays on LCD and servo.


; === Definitions === ;

.equ    npt = 1484  ; effective/observed neutral point of individual servo


; === Subroutines === ;

run:
    rcall   LCD_clear
    rcall   RE_init_nonblocking

    P1      DDRC, SERVO1
    P0      PORTC, SERVO1   ; pin=0
    LDI2    b1, b0, npt     ; stock npt dans a0 et a1
_set_unit:
    mov     w, d3
    cpi     w, 0b00000001
    breq    _initF
_initC:
    PRINTF  LCD
        .db "Set 20C", LF, 0, 0
    ldi     r28, 0b10100
    rjmp    npset
_initF:
    PRINTF  LCD
        .db "Set 68F", LF , 0, 0
    ldi     r28, 0b01000100


npset:                      ; neutral point setting
    ldi     a3, 50
    rcall	RE_nonblocking

    sbrc	a0, RE_BUTTON
    rjmp	_npmem

    sbrs	a0, RE_TURN_RDY
    rjmp	npset
    rcall	RE_nonblocking_acknowledge

    sbrs	a0, RE_TURN_DIR
    rjmp	_cw
    rjmp	_ccw
_exec:
    rcall   servoreg_pulse
    rjmp    npset
_cw:
    PRINTF LCD
    .db CR, "_cw   ", 0
    ADDI2   b1, b0, 2       ; increase pulse timing
    rcall   servoreg_pulse
    dec     a3
    brne    _cw
    rjmp    npset
_ccw:
    PRINTF LCD
    .db CR, "_ccw   ", 0
    SUBI2   b1, b0, 2       ; decrease pulse timing
    rcall   servoreg_pulse
    dec     a3
    brne    _ccw
    rjmp    npset
_npmem:
    rcall   RE_nonblocking
    sbrc    a0, RE_BUTTON
    rjmp    _npmem

    rcall   servoreg_pulse
    sei

temp:
    rcall   wire1_reset             ; send a reset pulse
    CA      wire1_write, skipROM    ; skip ROM identification
    CA      wire1_write, convertT   ; initiate temp conversion
    WAIT_MS 750                     ; wait 750 msec

    rcall   lcd_home                ; place r28 to home position
    rcall   wire1_reset             ; send a reset pulse
    CA      wire1_write, skipROM
    CA      wire1_write, readScratchpad
    rcall   wire1_read              ; read temperature LSB
    mov     c0, a0
    rcall   wire1_read              ; read temperature MSB
    mov     a1, a0
    mov     a0, c0
    push    a0
    push    a1
    ldi     r30, 50


_change_unit:
    mov     w, d3
    cpi     w, 0b00000001
    brne    _displayC

_displayF:
    rcall   mul21
    MOV2    a1, a0, c1, c0
    rcall   div21
    MOV2    a1, a0, c1, c0
    ADDI    a1, 0b0010
    PRINTF  LCD
        .db "temp=", FFRAC2+FSIGN, a, 4, $42, "F ", LF, 0, 0
    rjmp    _test_temp

_displayC:
    PRINTF  LCD
        .db "temp=", FFRAC2+FSIGN, a, 4, $42, "C ", LF, 0, 0

_test_temp:
    ROR24   a0, a1
    mov     w, d3
    cpi     w, 0b00000001
    brne    PC + 2
    ldi     r30,25

_temp_lower:
    cln
    cp      a0, r28
    brlo    ccw2
_temp_higher:
    cln
    cp      r28, a0
    brlo    cw2

_exec2:
    clz
    rcall   servoreg_pulse
    pop     a1
    pop     a0
    rjmp    temp
ccw2:
    subi    r28, 1
_ccw2:
    ADDI2   b1, b0, 2
    rcall   servoreg_pulse
    dec     r30
    brne    _ccw2
    pop     a0
    rjmp    temp
cw2:
    ADDI    r28, 1
_cw2:
    SUBI2   b1, b0, 2
    rcall   servoreg_pulse
    dec     r30
    brne    _cw2
    pop     a0
    rjmp    temp

; servoreg_pulse, in a1,a0, out servo port, mod a3,a2
; purpose generates pulse of length a1,a0
servoreg_pulse:
    WAIT_US 20000
    MOV2    b3, b2, b1, b0
    P1      PORTC, SERVO1       ; pin=1
lpssp01:
    DEC2    b3, b2
    brne    lpssp01
    P0      PORTC, SERVO1       ; pin=0
    ret

; clean les commentaires, vérifier les variables, avec les définitions, droits d'usage, les _ etc
; Fonctions reprises du fichier math.asm, mais modifié pour notre usage afin d'éviter tout conflit dans l'usage de registre
div21:
    ldi     r29, 0b01010000
    MOV2    c1, c0, a1, a0      ; c will contain the result
    clr     d0                  ; d will contain the remainder
    ldi     w, 16               ; load bit counter
_d21:
    ROL3    d0, c1, c0          ; shift carry into result c
    sub     d0,r29              ; subtract b from remainder
    brcc    PC + 2
    add     d0, r29             ; restore if remainder became negative
    DJNZ    w, _d21             ; Decrement and Jump if bit-count Not Zero
    ROL2    c1, c0              ; last shift (carry into result c)
    COM2    c1, c0              ; complement result
    ret


mul21:
    ldi     r29, 0b10010000
    CLR2    c2, c1              ; clear upper half of result c
    mov     c0, r29             ; place b in lower half of c
    lsr     c0                  ; shift LSB (of b) into carry
    ldi     w, 8                ; load bit counter
_m21:
    brcc    PC + 3              ; skip addition if carry=0
    ADD2    c2, c1, a1, a0      ; add a to upper half of c
    ROR3    c2, c1, c0          ; shift-right c, LSB (of b) into carry
    DJNZ    w, _m21             ; Decrement and Jump if bit-count Not Zero
    ret
