; file: macros.asm      target: ATmega128L-4MHz-STK300
; General use macros to avoid duplication.

; === Register manipulation === ;

; Load Stack Pointer
; @0: Data address
.macro LDSP
    ldi     w, low(@0)
    out     spl,r16
    ldi     w, high(@0)
    out     sph,r16
.endmacro

; Out Immediate
.macro OUTI
    ldi     w, @1
    out     @0, w
.endmacro

; Out Extended Immediate
.macro OUTEI
    ldi     w, @1
    sts     @0, w
.endmacro

; Set bits in an I/O register
; @0: I/O register
; @1: Bit index
.macro SMBI
    in      w, @0
    sbr     w, @1
    out     @0, w
.endmacro

; Clear bits in an I/O register
; @0: I/O register
; @1: Bit index
.macro CMBI
    in      w, @0
    cbr     w, @1
    out     @0, w
.endmacro

; Add constant to register
.macro  ADDI
    subi    @0, -@1
.endmacro


; === Bit manipulation === ;

; Load an I/O bit to Register bit
; @0: Register      @1: Bit
; @2: I/O register  @2: I/O bit
.macro  INB
    cbr     @0, 1<<@1   ; Equivilent to andi ~(...), requires mask
    sbic    @2, @3
    sbr     @0, 1<<@1
.endmacro

; Store Register bit to I/O bit
; @0: I/O register  @1: I/O bit
; @2: Register      @3: Bit
.macro  OUTB
    cbi     @0, @1
    sbrc    @2, @3
    sbi     @0, @1
.endmacro

; Copy bit
; @0: Destination register  @1: Desitnation bit
; @2: Source register       @3: Source bit
.macro  MOVB
    bst     @2, @3
    bld     @0, @1
.endmacro

; Compare two bits.
; All conditional branches can be used after this instruction.
; @0: Register 0    @1: Bit 0
; @2: Register 1    @3: Bit 1
.macro  CPB
    MOVB    _w, @1, @2, @3
    eor     _w, @0
    cbr     _w, ~(1<<@1)
    tst     _w
.endmacro

; Invert a bit
; @0: Register      @1: Bit
.macro  INVB
    ldi     _w, (1<<@1)
    eor     @0, _w
.endmacro


; === Pointers === ;

; Load an immediate value into the Z register
.macro LDIZ
    ldi     zl, low(@0)
    ldi     zh, high(@0)
.endmacro

; Multiply the Z register by two
.macro MUL2Z
    lsl     zl    ; Shift all bits to the left
    rol     zh    ; Restore the MSB from the SREG_C (Carry flag)
.endmacro

; Divide the Z register by two
.macro  DIV2Z
    lsr     zh
    ror     zl
.endmacro

; == Push/pop functions == ;

.macro  PUSHX
    push    xl
    push    xh
.endmacro
.macro  POPX
    pop     xh
    pop     xl
.endmacro

.macro  PUSHY
    push    yl
    push    yh
.endmacro
.macro  POPY
    pop     yh
    pop     yl
.endmacro

.macro  PUSHZ
    push    zl
    push    zh
.endmacro
.macro  POPZ
    pop zh
    pop zl
.endmacro


; === Conditional jumps === ;

; Jump if register is equal to a consant
; @0: register      @1: constant
; @2: label
.macro  JK
    cpi     @0, @1
    breq    @2
.endmacro

; Jump if bit in register is clear
; @0: register   @1: bit
; @2: label
.macro  JB0
    sbrs    @0, @1
    rjmp    @2
.endmacro

; Jump if bit in register is set
; @0: register   @1: bit
; @2: label
.macro  JB1
    sbrc    @0, @1
    rjmp    @2
.endmacro

; Decrement and jump if not zero
.macro  DJNZ
    dec     @0
    brne    @1
.endmacro


; === Multi-register manipulation === ;

; Push three registers to the stack
.macro  PUSH3
    push    @0
    push    @1
    push    @2
.endmacro

; Pop three registers from the stack
.macro  POP3
    pop     @2
    pop     @1
    pop     @0
.endmacro

; Move three registers
.macro  MOV3
    mov     @2, @5
    mov     @1, @4
    mov     @0, @3
.endmacro

; Push four registers to the stack
.macro  PUSH4
    push    @0
    push    @1
    push    @2
    push    @3
.endmacro

; Pop four values from the stack
.macro  POP4
    pop     @3
    pop     @2
    pop     @1
    pop     @0
.endmacro

; Four-register move
.macro  MOV4
    mov     @3, @7
    mov     @2, @6
    mov     @1, @5
    mov     @0, @4
.endmacro

; Clear four registers, first is cleared with subtract instruction
.macro  CLR4
    sub     @0, @0
    clr     @1
    clr     @2
    clr     @3
.endmacro

; Four-register two's complement
.macro  NEG4
    com     @0
    com     @1
    com     @2
    com     @3
    ldi     w, 0xff
    sub     @3,w
    sbc     @2,w
    sbc     @1,w
    sbc     @0,w
.endmacro

; Four register one's complement
.macro  COM4
    com     @0
    com     @1
    com     @2
    com     @3
.endmacro

; Load four data space values to registers using X pointer
.macro  LDX4
    ld      @3, x+
    ld      @2, x+
    ld      @1, x+
    ld      @0, x+
.endmacro

; Four-register aritmetic shift right
.macro  ASR4
    asr     @0
    ror     @1
    ror     @2
    ror     @3
.endmacro

; Four-register rotate right through carry
.macro  ROR4
    ror     @0
    ror     @1
    ror     @2
    ror     @3
.endmacro

; Four-register rotate left through carry
.macro  ROL4
    rol     @3
    rol     @2
    rol     @1
    rol     @0
.endmacro

; Four-register test
.macro  TST4
    clr     w
    cp      @3, w
    cpc     @2, w
    cpc     @1, w
    cpc     @0, w
.endmacro

; Five-register rotate right through carry
.macro  ROR5
    ror     @0
    ror     @1
    ror     @2
    ror     @3
    ror     @4
.endmacro

; Five-register rotate left through carry
.macro      ROL5
    rol     @4
    rol     @3
    rol     @2
    rol     @1
    rol     @0
.endmacro


; === Utility === ;

; Call With
; Load an immediate value into the w register and rcall a function.
; @0: Function (r-called)
; @1: Constant
.macro CW
    ldi     w, @1
    rcall   @0
.endmacro

; Call With Extended
; Load an immediate value into the w register and call a function.
; @0: Function (called)
; @1: Constant
.macro CWE
    ldi     w, @1
    call    @0
.endmacro
