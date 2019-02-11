; $ nasm -f elf kernel.asm -o kernel.o
; $ i386-elf-ld -s -Ttext 0x30400 kernel.o -o kernel.bin

[section .text]

global _start

_start:
    mov     ah,     0Fh
    mov     al,     'K'
    mov     [gs:((80 * 1 + 39) * 2)], ax
    jmp     $
