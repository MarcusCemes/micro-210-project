; file: macros.asm      target: ATmega128L-4MHz-STK300
; General use macros to avoid duplication.

; === Register manipulation ===

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


; == Bit manipulation ==

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
.macro CPB
    MOVB    _w, @1, @2, @3
    eor     _w, @0
    cbr     _w, ~(1<<@1)
    tst     _w
.endmacro


; == Pointers ==

; Load an immediate value into the Z register
.macro LDIZ
    ldi     zl, low(@0)
    ldi     zh, high(@0)
.endmacro

; Multiply the z register by two
.macro MUL2Z
    lsl     zl    ; Shift all bits to the left
    rol     zh    ; Restore the MSB from the SREG_C (Carry flag)
.endmacro


; === Utility ===

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
