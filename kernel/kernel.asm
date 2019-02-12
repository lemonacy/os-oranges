; $ nasm -f elf kernel.asm -o kernel.o
; $ i386-elf-ld -s -Ttext 0x30400 kernel.o -o kernel.bin
; 为什么是0x30400? 因为ELF header等信息占了0x400的空间，而这些空间又属于第一个Program Header的范畴（可通过readelf -l 看到第一个Program Header的p_vaddr是0x30000）,
; 为了保证程序的入口地址是0x30400，所以我们要将内核复制到0x30400 - 0x400 = 0x30000处，保证和Program header里边的p_vaddr吻合

SELECTOR_KERNEL_CS      equ     8

; 导入函数
extern  cstart

; 导入全局变量
extern  gdt_ptr

[section .bss]
StackSpace  resb    2 * 1024
StackTop:                           ; 栈顶

[section .text]

global _start                       ; i386-elf-ld链接的时候必须要有_start导出符号

_start:
    ; mov     ah,     0Fh
    ; mov     al,     'K'
    ; mov     [gs:((80 * 1 + 39) * 2)], ax

    ; 把esp从LOADER挪到KERNEL
    mov     esp,    StackTop        ; 堆栈在bss段中

    sgdt    [gdt_ptr]               ; cstart()中将会用到gdt_ptr
    call    cstart                  ; 在此函数中改变了gdt_ptr，让它指向新的GDT
    lgdt    [gdt_ptr]               ; 使用新的GDT

    jmp     SELECTOR_KERNEL_CS:csinit   ; 这个跳转指令强制使用刚刚初始化的结构

csinit:
    push    0
    popfd                           ; Pop top of stack into EFLAGS

    hlt
