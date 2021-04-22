; file: main.asm        target: ATmega128L-4MHz-STK300
; An EPFL MT-BA4 microcontroller project
; Authors: Marcus Cemes, Julien Moreno, Charlotte Vadori


; === Top-level includes ===
; May only contain definitions and macros.

.include "m128def.inc"
.include "definitions.inc"
.include "macros.asm"


; === Interrupt vector table ===

.org    0x0000
    jmp     reset


; === Device reset ===

reset:
    LDSP    RAMEND                      ; initialise stack pointer
    OUTI    DDRB, 0xff                  ; LED Data Direction
    OUTI    LED, 0xff                   ; Reset LED state
    OUTI    DDRD, 0x00                  ; Button Data Direction
    SMBI    MCUCR, (1<<SRE)+(1<<SRW10)  ; enable external SRAM
    rcall   LCD_init                    ; initialise LCD
    rcall   RE_init                     ; initialise Rotary Encoder
    sei                                 ; Enable interrupts
    jmp     main


; === Imports ===

.include "drivers/lcd.asm"
.include "drivers/rotary_encoder.asm"


; === Entry point ===

main:
    LCD_PL      greet_msg_0, greet_msg_1


; === Program termination ===

stop:
    rjmp    stop


; === Binary payloads ===

greet_msg_0: .db "MICRO-210 proj.", 0
greet_msg_1: .db "EPFL MT-BA4 2021", 0, 0
