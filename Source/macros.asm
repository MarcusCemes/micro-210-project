; Load Stack Pointer
; @0: address constant
.macro  LDSP
  ldi   w, low(@0)
  out   spl,r16
  ldi   w,high(@0)
  out   sph,r16
.endmacro