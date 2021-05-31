; file: menu.asm        target: ATmega128L-4MHz-STK300
; Show a temperature selection menu

; Show a navigable menu, allowing to select temperature unit
; Stores the selection in bit 0 of ACR
show_menu:
    rcall   LCD_CLEAR
    rcall   RE_init_nonblocking
    rcall   _menu_update_screen

    _show_menu_interact:
    rcall   RE_nonblocking

    sbrc    b0, RE_BUTTON
    ret

    sbrs    b0, RE_TURN_RDY
    rjmp    _show_menu_interact
    rcall   RE_nonblocking_acknowledge

    ; Menu only has two options, no need to check turn direcion
    INVB    d3, 0
    rcall   _menu_update_screen
    rjmp    _show_menu_interact


; Update the menu screen based on selection
_menu_update_screen:
    CW      LCD_change_pos, LCD_POS_L1

    PRINTF LCD
        .db "Display unit:", LF, 0, 0

    tst     d3
    breq    _show_menu_print_c
    rjmp    _show_menu_print_f

    _show_menu_print_c:
    PRINTF LCD
    .db "> Celsius   ", 0, 0
    ret

    _show_menu_print_f:
    PRINTF LCD
    .db "> Fahrenheit", 0, 0
    ret
