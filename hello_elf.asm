; 编译链接方法
; (ld的’-s‘选项意为“strip all”)
;
; $ nasm -f elf hello_elf.asm -o hello_elf.o
; $ brew install i386-elf-binutils
; $ i386-elf-ld -s hello_elf.o -o hello_elf
; $ ./hello_elf (copy to linux host)
; Hello, world!
; $

[section .data]
strHello    db      "Hello, world!", 0Ah
STRLEN      equ     $ - strHello

[section .text]

global _start       ; 我们必须导出_start这个入口，以便让连接器识别

_start:
    mov     edx,    STRLEN
    mov     ecx,    strHello
    mov     ebx,    1
    mov     eax,    4       ; sys_write
    int     0x80
    mov     ebx,    0
    mov     eax,    1       ; sys_exit
    int     0x80
