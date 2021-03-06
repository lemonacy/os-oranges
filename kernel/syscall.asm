%include "sconst.inc"

_NR_get_ticks           equ     0       ; 要跟global.c中sys_call_table的定义相对应
_NR_write               equ     1

INT_VECTOR_SYS_CALL     equ     0x90

global get_ticks    ; 导出符号
global write

bits 32
[section .text]

get_ticks:
    mov     eax,    _NR_get_ticks
    int     INT_VECTOR_SYS_CALL
    ret

write:
    mov     eax,    _NR_write
    mov     ebx,    [esp + 4]   ; len
    mov     ecx,    [esp + 8]   ; buf ptr
    int     INT_VECTOR_SYS_CALL
    ret