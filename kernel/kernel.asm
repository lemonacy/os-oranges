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
extern disp_str
extern delay
extern clock_handler

; 导入全局变量
extern gdt_ptr
extern idt_ptr
extern p_proc_ready
extern tss
extern disp_pos
extern k_reenter

[section .bss]
StackSpace  resb    2 * 1024        ; 内核栈
StackTop:                           ; 栈顶

[section .data]
clock_int_msg   db  "^",    0

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
    mov     dword[tss + TSS3_S_SP0],    eax     ; 以便第一次中断发生的时候，发生ring1 -> ring0特权级变换，能切换到正确的ring0堆栈
restart_reenter:
    dec     dword[k_reenter]                    ; 在进程第一次运行之前就-1了，所以main.c中对k_reenter的初始化要从-1改为0，这里减1就变为期望的-1了
    pop     gs
    pop     fs
    pop     es
    pop     ds
    popad

    add     esp,    4   ; 跳过进程表的retaddr，堆栈接下来的内容为：eip, cs, eflags, esp, ss

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
    sub     esp,    4              ; 跳过retaddr（ss,esp,eflags,cs,eip已经由CPU自动压栈了）

    pushad
    push    ds
    push    es
    push    fs
    push    gs
    mov     dx,     ss
    mov     ds,     dx
    mov     es,     dx

    ; inc     byte[gs:0]

    mov     al,         EOI         ; reenable master 8259
    out     INT_M_CTL,  al          ; 为了让时钟中断可以不停地发生而不是只发生一次，需要设置EOI

    inc     dword[k_reenter]
    cmp     dword[k_reenter],   0
    ; jne     .re_enter               ; 如果是中断重入，则不再开启中断嵌套
    jne     .1                      ; 重入时跳转到.1，通常情况下顺序执行

    mov     esp,    StackTop        ; 非重入时才切刀内核栈

    push    restart                 ; 指定非重入时，下面ret的返回地址是restart_v2，需要执行mov,lldt,lea,mov指令
    jmp     .2
.1:                                 ; 中断重入
    push    restart_reenter         ; 指定重入时，下面ret的返回地址是restart_reenter_v2，不需要执行下面的mov,lldt,lea,mov指令，因为最外层的中断（第一次进入的中断）会负责做这部分工作
.2:                                 ; 没有中断重入
    sti                             ; 开启中断嵌套

    push    0
    call    clock_handler           ; 不管重入还是非重入，clock_handler都会被执行，所以需要在clock_handler里边处理是否重入的问题
    add     esp,    4

    cli                             ; 关闭嵌套中断

    ret                             ; 重入时返回到.restart_reenter_v2，通常情况下(非重入)返回到.restart_v2。注：ret - 短返回，只从堆栈中pop出EIP

;; 对比下面的代码和_start中的restart+restart_reenter，除了标号的名字不同外，其余都是相同的，我们完全可以删掉其中的一段，同时修改用到的标号
; .restart_v2:
;     mov     esp,    [p_proc_ready]  ; 离开内核栈
;     lldt    [esp + P_LDT_SEL]
;     lea     eax,                        [esp + P_STACKTOP]
;     mov     dword[tss + TSS3_S_SP0],    eax ; tss.esp0存放本次中断要返回的任务在下次被中断时的ring0堆栈，以便在中断发生时，正确地保留任务的状态
;
; .restart_reenter_v2:                ; 如果k_reenter != 0，会跳转到这里
; ; .re_enter:  ; 如果k_reenter != 0(好比等于1)，则会调到这里
;     dec     dword[k_reenter]
;
;     pop     gs
;     pop     fs
;     pop     es
;     pop     ds
;     popad
;     add     esp,    4              ; 让栈顶指向eip处，以便下面指向iretd
;
;     iretd
;
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
