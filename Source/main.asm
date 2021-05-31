; file: main.asm        target: ATmega128L-4MHz-STK300
; An EPFL MT-BA4 microcontroller project
; Authors: Marcus Cemes, Julien Moreno, Charlotte Vadori


; === Top-level includes === ;
; May only contain definitions and macros.

.include "m128def.inc"
.include "definitions.inc"
.include "macros.asm"


; === Interrupt vector table === ;

.org    0x0000
    jmp     reset
.org    INT6addr
    jmp     int6_handler


; === Device reset === ;

reset:
    LDSP    RAMEND                      ; initialise stack pointer
    OUTI    DDRB, 0xff                  ; LED Data Direction
    OUTI    LED, 0xff                   ; Reset LED state
    OUTI    DDRD, 0x00                  ; Button Data Direction
    SMBI    MCUCR, (1<<SRE)+(1<<SRW10)  ; enable external SRAM
    rcall   LCD_init                    ; initialise LCD
    rcall   RE_init                     ; initialise Rotary Encoder
    rcall   wire1_init                  ; initialize 1-wire(R) interface
    OUTI    EIMSK, (1<<6)               ; Configure interrupts
    OUTI    EICRB, 0x00                 ; Interrupt on low-level
    clr     d3                          ; Reset Application Configuration Register
    jmp     main


; === Imports === ;

.include "lib/printf.asm"

.include "drivers/lcd.asm"
.include "drivers/rotary_encoder.asm"
.include "drivers/wire1.asm"

.include "run.asm"

.include "interrupt.asm"
.include "menu.asm"



; === Entry point === ;

main:
    LCD_PL  greet_msg_0, greet_msg_1
    sei

    ; jmp     run


; === Program termination === ;

stop_msg:
    rcall LCD_clear
    PRINTF LCD
        .db "    Program", LF, "   terminated", 0
stop:
    rjmp    stop


; === Binary payloads === ;

greet_msg_0: .db "MICRO-210 proj.", 0
greet_msg_1: .db "EPFL MT-BA4 2021", 0, 0
