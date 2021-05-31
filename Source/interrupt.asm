; file: interrupt.asm       target: ATmega128L-4MHz-STK300
; Handle program interruptions


; === Interrupts === ;

; Enter a temperature selection menu
int6_handler:
    in      _sreg, SREG
    push    b3

    rcall   _int6_wait_on
    rcall   show_menu
    rcall   _int6_wait_on
    rcall   LCD_clear

    ; Simulate reti but jump to specific point
    pop     _w
    pop     _w
    out     SREG, _sreg
    jmp    _set_unit



; === Private subroutines === ;

; Wait until the interrupt wire is active-high
; to avoid glitches
_int6_wait_on:
    in      _w, PINE
    sbrs    _w, 6
    rjmp    _int6_wait_on
    ret
