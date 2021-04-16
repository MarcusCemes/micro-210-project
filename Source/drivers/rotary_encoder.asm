; file: drivers/rotary_encoder.asm     target: ATmega128L-4MHz-STK300
; Interfaces with the STEC11B03 Rotary Encoder peripheral


; === Definitions ===

.equ    IOPIN   = PINE
.equ    IODDR   = DDRE
.equ    IOPORT  = PORTE

.equ    IOPINS  = (1<<ENCOD_A)+(1<<ENCOD_B)+(1<<ENCOD_I)


; === Subroutines ===

RE_init:
    CMBI    IODDR, IOPINS   ; Configure as input (high-impedance)
    SMBI    IOPORT, IOPINS  ; Enable pull-up resistor
    ret


; Wait until the encoder completes a turn.
; Returns:
;   w: The turn direction (0x00 anti-clockwise, 0x01 clockwise)
RE_wait_turn:
    rcall   RE_wait_full    ; Read initial state
    mov     a0, w

    _RE_wait_turn_restart:
    rcall   RE_wait_half
    mov     a1, w

    rcall   RE_wait_full
    mov     a2, w

    cp      a0, a2
    breq    _RE_wait_turn_restart

    clr     w
    eor     a1, a2       ; Direction depends on final value
    sbrs    a1, 0        ; clockwise
    ldi     w, 0x01
    ret


; Loop until the rotary encoder has completed a half turn.
; The value of ENCOD_A and ENCOD_B are stored in bit 0 of
; a0 and b0 respectivly.
RE_wait_half:
    clr     w
    INB     w, 0, IOPIN, ENCOD_A
    INB     w, 1, IOPIN, ENCOD_B
    CPB     w, 0, w, 1
    breq    RE_wait_half
    ret


; Loop until the rotary encoder has completed a half turn.
; The value of ENCOD_A and ENCOD_B are stored in bit 1 of
; a0 and b0 respectivly.
RE_wait_full:
    clr     w
    INB     w, 0, IOPIN, ENCOD_A
    INB     w, 1, IOPIN, ENCOD_B
    CPB     w, 0, w, 1
    brne    RE_wait_full
    ret
