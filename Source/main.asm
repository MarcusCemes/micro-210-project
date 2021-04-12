.include "definitions.inc"
.include "macros.asm"

reset:
    LDSP    RAMEND

main:
    inc r16
    rjmp main
