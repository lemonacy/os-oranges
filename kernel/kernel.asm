; $ nasm -f elf kernel.asm -o kernel.o
; $ i386-elf-ld -s -Ttext 0x30400 kernel.o -o kernel.bin
; 为什么是0x30400? 因为ELF header等信息占了0x400的空间，而这些空间又属于第一个Program Header的范畴（可通过readelf -l 看到第一个Program Header的p_vaddr是0x30000）,
; 为了保证程序的入口地址是0x30400，所以我们要将内核复制到0x30400 - 0x400 = 0x30000处，保证和Program header里边的p_vaddr吻合

%include "sconst.inc"

; 导入函数
extern cstart
extern exception_handler
extern spurious_irq
extern kernel_main

; 导入全局变量
extern gdt_ptr
extern idt_ptr
extern p_proc_ready
extern tss
extern disp_pos

[section .bss]
StackSpace  resb    2 * 1024
StackTop:                           ; 栈顶

[section .text]

global _start                       ; i386-elf-ld链接的时候必须要有_start导出符号
global restart

global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global inval_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global inval_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error

global hwint00
global hwint01
global hwint02
global hwint03
global hwint04
global hwint05
global hwint06
global hwint07
global hwint08
global hwint09
global hwint10
global hwint11
global hwint12
global hwint13
global hwint14
global hwint15

_start:
    ; mov     ah,     0Fh
    ; mov     al,     'K'
    ; mov     [gs:((80 * 1 + 39) * 2)], ax

    ; 把esp从LOADER挪到KERNEL
    mov     esp,    StackTop        ; 堆栈在bss段中

    sgdt    [gdt_ptr]               ; cstart()中将会用到gdt_ptr
    call    cstart                  ; 在此函数中改变了gdt_ptr，让它指向新的GDT

    lgdt    [gdt_ptr]               ; 使用新的GDT
    lidt    [idt_ptr]               ; 加载IDT

    jmp     SELECTOR_KERNEL_CS:csinit   ; 这个跳转指令强制使用刚刚初始化的结构

csinit:
    push    0
    popfd                           ; Pop top of stack into EFLAGS

    ; ud2
    ; jmp     0x40:0

    ; 此处注释掉sti,在通过iretd进入第一个进程的时候会自动开启，因为在第一个进程的进程表中eflags的IF被置位为1（详见main.c::kernel_main()）
    ; sti                             ; 置IF位，开启8259A可屏蔽中断

    ; 加载第一个任务的TSS
    xor     eax,    eax
    mov     ax,     SELECTOR_TSS
    ltr     ax

    jmp     kernel_main

restart:
    mov     esp,    [p_proc_ready]
    lldt    [esp + P_LDT_SEL]
    lea     eax,    [esp + P_STACKTOP]
    mov     dword[tss + TSS3_S_SP0],    eax

    pop     gs
    pop     fs
    pop     es
    pop     ds
    popad

    add     esp,    4

    iretd   ; 进入第一个进程

; 中断和异常 - 异常
divide_error:
    push    0xFFFFFFFF              ; no err code
    push    0                       ; vector_no = 0
    jmp     exception
single_step_exception:
    push    0xFFFFFFFF              ; no err code
    push    1                       ; vector_no = 1
    jmp     exception
nmi:
    push    0xFFFFFFFF              ; no err code
    push    2                       ; vector_no = 2
    jmp     exception
breakpoint_exception:
    push    0xFFFFFFFF              ; no err code
    push    3                       ; vector_no = 3
    jmp     exception
overflow:
    push    0xFFFFFFFF              ; no err code
    push    4                       ; vector_no = 4
    jmp     exception
bounds_check:
    push    0xFFFFFFFF              ; no err code
    push    5                       ; vector_no = 5
    jmp     exception
inval_opcode:
    push    0xFFFFFFFF              ; no err code
    push    6                       ; vector_no = 6
    jmp     exception
copr_not_available:
    push    0xFFFFFFFF              ; no err code
    push    7                       ; vector_no = 7
    jmp     exception
double_fault:
    push    8                       ; vector_no = 8
    jmp     exception
copr_seg_overrun:
    push    0xFFFFFFFF              ; no err code
    push    9                       ; vector_no = 9
    jmp     exception
inval_tss:
    push    10                      ; vector_no = A
    jmp     exception
segment_not_present:
    push    11                      ; vector_no = B
    jmp     exception
stack_exception:
    push    12                      ; vector_no = C
    jmp     exception
general_protection:
    push    13                      ; vector_no = D
    jmp     exception
page_fault:
    push    14                      ; vector_no = E
    jmp     exception
copr_error:
    push    0xFFFFFFFF              ; no err code
    push    16                      ; vector_no = 10h
    jmp     exception

exception:
    call    exception_handler
    add     esp,    4 * 2             ; 让栈顶指向EIP，堆栈中从顶向底依次是：EIP,CS,EFLAGS
    hlt

; 中断和异常 - 硬件中断
; ------------------------------
%macro hwint_master 1
    push    %1
    call    spurious_irq
    add     esp,    4
    hlt
%endmacro
; ------------------------------

ALIGN   16
hwint00:                           ; Interrupt routine for irq 0 (the click)
    iretd

ALIGN   16
hwint01:                           ; Interrupt routine for irq 1 (keyboard)
    hwint_master    1

ALIGN   16
hwint02:                           ; Interrupt routine for irq 2 (cascade!)
    hwint_master    2

ALIGN   16
hwint03:                           ; Interrupt routine for irq 3 (second serial)
    hwint_master    3

ALIGN   16
hwint04:                           ; Interrupt routine for irq 4 (first serial)
    hwint_master    4

ALIGN   16
hwint05:                           ; Interrupt routine for irq 5 (XT winchester)
    hwint_master    5

ALIGN   16
hwint06:                           ; Interrupt routine for irq 6 (floppy)
    hwint_master    6

ALIGN   16
hwint07:                           ; Interrupt routine for irq 7 (printer)
    hwint_master    7

; ------------------------------
%macro hwint_slave 1
    push    %1
    call    spurious_irq
    add     esp,    4
    hlt
%endmacro
; ------------------------------

ALIGN   16
hwint08:                           ; Interrupt routine for irq 8 (realtime clock)
    hwint_slave    8

ALIGN   16
hwint09:                           ; Interrupt routine for irq 9 (irq 2 redirected)
    hwint_slave    9

ALIGN   16
hwint10:                           ; Interrupt routine for irq 10
    hwint_slave    10

ALIGN   16
hwint11:                           ; Interrupt routine for irq 11
    hwint_slave    11

ALIGN   16
hwint12:                           ; Interrupt routine for irq 12
    hwint_slave    12

ALIGN   16
hwint13:                           ; Interrupt routine for irq 13 (FPU exception)
    hwint_slave    13

ALIGN   16
hwint14:                           ; Interrupt routine for irq 14 (AT winchester)
    hwint_slave    14

ALIGN   16
hwint15:                           ; Interrupt routine for irq 15
    hwint_slave    15
