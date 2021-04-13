; === Top-level includes ===
; May only contain definitions and macros.

.include "definitions.inc"
.include "macros.asm"


; === Device reset ===

reset:
    LDSP    RAMEND                      ; initialise stack pointer
    OUTI    DDRB, 0xff                  ; LED Data Direction
    OUTI    LED, 0xff                   ; Reset LED state
    OUTI    DDRD, 0x00                  ; Button Data Direction
    IOS     MCUCR, (1<<SRE)+(1<<SRW10)  ; enable external SRAM
    rcall   LCD_init                    ; initialise LCD
    jmp     main


; === Imports ===

.include "drivers/lcd.asm"
.include "utility.asm"


; === Entry point ===

main:
    LCD_PRINT str1

    ldi     w, LCD_POS_L2   ; Change line
    rcall   LCD_pos

    LCD_PRINT str2


; === Program termination ===

stop:
    rjmp    stop


; === Binary payloads ===

str1: .db "MICRO-210 proj.", 0
str2: .db "EPFL MT-BA4 2021", 0, 0
