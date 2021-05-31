; file: drivers/lcd.asm   target: ATmega128L-4MHz-STK300
; Interfaces with the Hitachi HD44780U LCD peripheral


; === Definitions ===
.equ    LCD_IR      = 0x8000    ; address LCD instruction reg
.equ    LCD_DR      = 0xc000    ; address LCD data register

.equ    LCD_CLR_CLR = 0   ; clear instruction

.equ    LCD_HOME_I  = 1   ; return home

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

; Subroutine handle for the PRINTF macro, checks for CR and LF,
; before writing to the data register.
LCD:
    JK      a0, CR, LCD_cr   ; Jump if a0=CR
    JK      a0, LF, LCD_lf   ; Jump if a0=LF

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


; Reset the cursor position
; ModifieS:
;   w
LCD_home:
    CW      LCD_ir_w, (1<<LCD_HOME_I)
    ret

; Sets the cursor position based on w register
; Modifies:
;   w
LCD_change_pos:
    sbr     w, (1<<LCD_DA)
    rcall   LCD_ir_w
    ret


; Simulate a line feed by changing cursor position
LCD_lf:
    CW      LCD_change_pos, LCD_POS_L2
    ret


; Simulate a carriage return by changing cursor position
LCD_cr:
    lds     w, LCD_IR       ; Read IR for busy flag
    JB1     w, 7, LCD_cr    ; Wait if busy
    andi    w, (1<<6)       ; Keep line counter bit
    ori     w, (1<<LCD_DA)  ; Create address command
    rcall   LCD_ir_w        ; Write to IR
    ret


; Clears the LCD screen
LCD_clear:
    CW      LCD_ir_w, (1<<LCD_CLR_CLR)
    ret


; === String utilities === ;

; LCD Print
; Given a program memory address, correctly initialises the Z register
; and calls LCD_print_z.
; Example:
;   LCD_P       string_label
;   string_label: .db "Hello world", 0
.macro  LCD_P
    LDIZ    @0
    MUL2Z
    call    LCD_print_z
.endmacro

; LCD Print Lines
; Prints two lines to the screen from the program memory.
; @0: label of line 1     :@2 label of line 2
; Example:
;   LCD_PL      string_1, string_2
.macro  LCD_PL
    rcall   LCD_clear
    LCD_P       @0
    ldi     w, LCD_POS_L2
    rcall   LCD_change_pos
    LCD_P       @1
.endmacro


; Write a null-terminated string from the program memory
; pointed to by the Z register to the LCD screen.
; The pointer must be correctly offset for program memory
; use as required by the lpm instruction. See LCD_PRINT.
LCD_print_z:
    lpm     a0, Z+

    tst     a0
    breq    _LCD_print_z_ret

    rcall   LCD_dr_w
    rjmp    LCD_print_z

    _LCD_print_z_ret:
    ret
