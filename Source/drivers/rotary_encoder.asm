; file: drivers/rotary_encoder.asm     target: ATmega128L-4MHz-STK300
; Interfaces with the STEC11a03 Rotary Encoder peripheral


; === Definitions === ;

.equ    IOPIN   = PINE
.equ    IODDR   = DDRE
.equ    IOPORT  = PORTE

.equ    IOPINS  = (1<<ENCOD_A)+(1<<ENCOD_B)+(1<<ENCOD_I)


; Bit positions for the state register
.equ    RE_BUTTON       = 0 ; Button pressed
.equ    RE_TURN_RDY     = 1 ; Turn is completed
.equ    RE_TURN_DIR     = 2 ; Turn direction (0 anti-clockwise, 1 clockwise)
.equ    RE_TURN_START   = 3 ; The initial state at the beginning of the turn


; === Public subroutines === ;

RE_init:
    CMBI    IODDR, IOPINS   ; Configure as input (high-impedance)
    SMBI    IOPORT, IOPINS  ; Enable pull-up resistor
    ret


; Block until the rotary encoder completes a turn.
; This is the simplest way to use the rotary encoder.
; Modifies:
;   w, a0, a1, a2
; Returns:
;   w: The turn direction (0x00 anti-clockwise, 0x01 clockwise)
RE_turn_block:
    rcall   _RE_wait_full ; Read initial state
    mov     a0, w

    _RE_turn_block_restart:
    rcall   _RE_wait_half
    mov     a1, w

    rcall   _RE_wait_full
    mov     a2, w

    cp      a0, a2
    breq    _RE_turn_block_restart

    clr     w
    eor     a1, a2       ; Direction depends on final value
    sbrs    a1, 0        ; If clockwise
    ldi     w, 0x01
    ret


; Initialises the a0 register for use with RE_nonblocking
; Assumes that the rotary encoder is not mid-turn!
; Returns:
;   a0: Initial state
RE_init_nonblocking:
    clr     a0
    INB     a0, RE_TURN_START, IOPIN, ENCOD_A
    INB     a0, RE_BUTTON, IOPIN, ENCOD_I
    INVB    a0, RE_BUTTON
    ret


; Use the rotary in non-blocking mode by polling for changes.
;
; By passing in previous state stored in the a0 register,
; this subroutine can check detect a turn, and update the
; a0 register accordingly. When a turn is complete, the
; RE_TURN_RDY bit is set. Also checks button status.
;
; Should be called as often as possible to be able to
; check for turn transition states.
;
; Modifies:
;   w, a0
; Params:
;   a0: The previous state
; Returns:
;   a0: The current state
RE_nonblocking:
    INB     a0, RE_BUTTON, IOPIN, ENCOD_I
    INVB    a0, RE_BUTTON

    INB     w, 0, IOPIN, ENCOD_A
    INB     w, 1, IOPIN, ENCOD_B
    CPB     w, 0, w, 1
    breq    _RE_nonblocking_same

    ; Update the turn direction
    cbr     a0, (1<<RE_TURN_DIR)
    sbrs    w, 0    ; Skip if anti-clockwise
    sbr     a0, (1<<RE_TURN_DIR)

    ; Compenstate for initial position
    bst     a0, RE_TURN_START
    brtc    _RE_nonblocking_early_return
    INVB    a0, RE_TURN_DIR
    ret

    ; Check for completed turn
    _RE_nonblocking_same:
    CPB     w, 0, a0, RE_TURN_START
    breq    _RE_nonblocking_early_return
    sbr     a0, (1<<RE_TURN_RDY)

    ; Update the new start position
    MOVB    a0, RE_TURN_START, w, 0

    _RE_nonblocking_early_return:
    ret


; Reset the RE_TURN_RDY bit to allow for subsequent turns
; Modifies
;   a0
RE_nonblocking_acknowledge:
    cbr     a0, (1<<RE_TURN_RDY)
    ret


; === Private subroutines === ;

; Loop until the rotary encoder has completed a half turn.
; The value of ENCOD_A and ENCOD_B are stored in bit 0 of
; a0 and a0 respectivly.
_RE_wait_half:
    clr     w
    INB     w, 0, IOPIN, ENCOD_A
    INB     w, 1, IOPIN, ENCOD_B
    CPB     w, 0, w, 1
    breq    _RE_wait_half
    ret


; Loop until the rotary encoder has completed a half turn.
; The value of ENCOD_A and ENCOD_B are stored in bit 1 of
; a0 and a0 respectivly.
_RE_wait_full:
    clr     w
    INB     w, 0, IOPIN, ENCOD_A
    INB     w, 1, IOPIN, ENCOD_B
    CPB     w, 0, w, 1
    brne    _RE_wait_full
    ret
