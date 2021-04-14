; file: drivers/lcd.asm   target: ATmega128L-4MHz-STK300
; Interfaces with the Hitachi HD44780U LCD peripheral


; === Definitions ===
.equ    LCD_IR      = 0x8000    ; address LCD instruction reg
.equ    LCD_DR      = 0xc000    ; address LCD data register

.equ    LCD_CLR_CLR = 0   ; clear instruction

.equ    LCD_IR_BUSY = 7   ; Bit indicating that LCD is busy

.equ    LCD_EM_SHFT = 0   ; Enable cursor shift
.equ    LCD_EM_INC  = 1   ; Set cursor shift direction
.equ    LCD_EM      = 2   ; Entry Mode instruction

.equ    LCD_DC_BLNK = 0   ; Enable cursor blinking
.equ    LCD_DC_CURS = 1   ; Enable cursor
.equ    LCD_DC_DISP = 2   ; Enable display
.equ    LCD_DC      = 3   ; Display Mode instruction

.equ    LCD_FS_FONT = 2   ; Select charcater font
.equ    LCD_FS_LINE = 3   ; Select number of displayed lines (1/2 lines)
.equ    LCD_FS_DLEN = 4   ; Select data length (4/8 bits)
.equ    LCD_FS      = 5   ; Function Set instruction


.equ    LCD_DA      = 7     ; DRAM Address change
.equ    LCD_POS_L1  = 0x00  ; Beginning of line 1
.equ    LCD_POS_L2  = 0x40  ; Beginning of line 2


; === Macros ===

; Polls the LCD Instruction Register until module
; is ready to receive further instructions/data
.macro  LCD_RDY
LCD_RDY_restart:
    lds     u, LCD_IR
    sbrc    u, LCD_IR_BUSY
    rjmp    LCD_RDY_restart
    rcall   lcd_4us             ; Ensure DRAM address was incremented
.endmacro


; === Subroutines ===

; Initialise the LCD display.
; Requires that external SRAM is enabled (SRE & SRW10).
LCD_init:
    CW      LCD_ir_w, (1<<LCD_CLR_CLR)
    CW      LCD_ir_w, (1<<LCD_EM)+(1<<LCD_EM_INC)
    CW      LCD_ir_w, (1<<LCD_DC)+(1<<LCD_DC_DISP)
    CW      LCD_ir_w, (1<<LCD_FS)+(1<<LCD_FS_DLEN)+(1<<LCD_FS_LINE)
    ret


; Write w -> LCD Instruction Register
LCD_ir_w:
    LCD_RDY
    sts     LCD_IR, w
    ret


; Write a0 -> LCD Data Register
LCD_dr_w:
    LCD_RDY
    sts     LCD_DR, a0
    ret


lcd_4us:
    rcall   lcd_2us
lcd_2us:
    nop
    ret


; Sets the cursor position
LCD_pos:
    sbr     w, (1<<LCD_DA)
    rcall   LCD_ir_w
    ret


; Clears the LCD screen
LCD_clear:
    LCD_RDY
    CW      LCD_ir_w, (1<<LCD_CLR_CLR)
    ret


; === String utilities ===

; Given a program memory address, correctly initialises
; the Z register and calls LCD_print_z.
.macro  LCD_PRINT
    LDIZ    @0
    MUL2Z
    call    LCD_print_z
.endmacro


; Write a null-terminated string from the program memory
; pointed to by the Z register to the LCD screen.
; The pointer must be correctly offset for program memory
; use as required by the lpm instruction. See LCD_PRINT.
LCD_print_z:
    lpm     a0, Z+

    tst     a0
    brbs    SREG_Z, return

    rcall   LCD_dr_w
    rjmp    LCD_print_z