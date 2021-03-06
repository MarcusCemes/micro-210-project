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


; Clear port bit
.macro  P0
    cbi     @0, @1
.endmacro

; Set port bit
.macro  P1
    sbi     @0, @1
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

; Load three registers immediate
.macro  LDI2
    ldi     @1, low(@2)
    ldi     @0, high(@2)
.endmacro

; Add two registers
.macro  ADD2
    add     @1, @3
    adc     @0, @2
.endmacro

; Add immediate two registers
.macro  ADDI2
    subi    @1, low(-@2)
    sbci    @0, high(-@2)
.endmacro

; Subtract immediate two registers
.macro  SUBI2
    subi    @1, low(@2)
    sbci    @0, high(@2)
.endmacro

; Decrement two registers
.macro  DEC2
    ldi     w, 0xff
    add     @1, w
    adc     @0, w
.endmacro

; Copy two registers
.macro  MOV2
    mov     @1, @3
    mov     @0, @2
.endmacro

; Rotate left through carry two registers
.macro  ROL2
    rol     @1
    rol     @0
.endmacro

; One's complement two registers
.macro  COM2
    com     @0
    com     @1
.endmacro

; Clear two registers
.macro  CLR2
    sub     @0,@0
    clr     @1
.endmacro

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

; Rotate left through carry three registers
.macro  ROL3
    rol     @2
    rol     @1
    rol     @0
.endmacro

; ortate right through carry
.macro  ROR3
    ror     @0
    ror     @1
    ror     @2
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


; == Custom implementations == ;

; Rotate two registers
.macro ROR24
    ldi     _w, 4
_ror24:
    lsr     @0
    lsr     @1
    brcc    PC+2
    ADDI    @0, 0b10000000
    dec     _w
    brne    _ror24
.endmacro


; === Utility === ;

; Call Working
; Load an immediate value into the w register and rcall a subroutine
; @0: Function (r-called)
; @1: Constant
.macro CW
    ldi     w, @1
    rcall   @0
.endmacro

; Call Working Extended
; Load an immediate value into the w register and call a subroutine
; @0: Function (called)
; @1: Constant
.macro CWE
    ldi     w, @1
    call    @0
.endmacro

; Call a0
; Load an immediate value into a0 and call a subroutine
.macro  CA
    ldi     a0, @1
    rcall   @0
.endmacro


; === Time === ;

; Wait micro-seconds (us)
; us = x*3*1000'000/clock)  ==> x=us*clock/3000'000
.macro  WAIT_US
    ldi     w, low((clock/1000*@0/3000)-1)
    mov     u, w
    ldi     w, high((clock/1000*@0/3000)-1)+1 ; set up: 3 cyles
    dec     u
    brne    PC - 1      ; inner loop: 3 cycles
    dec     u           ; adjustment for outer loop
    dec     w
    brne    PC - 4
.endmacro

; Wait milli-seconds (ms)
.macro  WAIT_MS
    ldi     w, low(@0)
    mov     u, w            ; u = LSB
    ldi     w, high(@0)+1   ; w = MSB
wait_ms:
    push    w               ; wait 1000 usec
    push    u
    ldi     w, low((clock/3000)-5)
    mov     u, w
    ldi     w, high((clock/3000)-5)+1
    dec     u
    brne    PC-1        ; inner loop: 3 cycles
    dec     u           ; adjustment for outer loop
    dec     w
    brne    PC-4
    pop     u
    pop     w

    dec     u
    brne    wait_ms
    dec     w
    brne    wait_ms
.endmacro
