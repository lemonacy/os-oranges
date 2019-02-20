#ifndef _ORANGES_PROC_H_
#define _ORANGES_PROC_H_

#include "type.h"
#include "protect.h"

typedef struct s_stackframe /* 作为从task -> 内核态时的临时ring0堆栈(TSS的esp0) */
{
    u32 gs;         /* \                                    */
    u32 fs;         /* |                                    */
    u32 es;         /* |                                    */
    u32 ds;         /* |                                    */
    u32 edi;        /* |                                    */
    u32 esi;        /* | pushed by save()                   */
    u32 ebp;        /* |                                    */
    u32 kernel_esp; /* <- 'popad' will ignore it            */
    u32 ebx;        /* |                                    */
    u32 edx;        /* |                                    */
    u32 ecx;        /* |                                    */
    u32 eax;        /* /                                    */
    u32 retaddr;    /* return addr for kernel.asm::save()   */
    u32 eip;        /* \                                    */
    u32 cs;         /* |                                    */
    u32 eflags;     /* | pushed by CPU during interrupt     */
    u32 esp;        /* |                                    */
    u32 ss;         /* /                                    */
} STACK_FRAME;

typedef struct s_proc
{
    STACK_FRAME regs;          // process regisgers saved in stack frame
    u16 ldt_sel;               // gdt selector giving ldt base and limit
    DESCRIPTOR ldts[LDT_SIZE]; // local descriptors for code and data
    int ticks;                 // remained ticks
    int priority;              // process priority, read only
    u32 pid;                   // process id passed in from MM
    char p_name[16];           // name of the process
} PROCESS;

typedef struct s_task
{
    task_f initial_eip;
    int stacksize;
    char name[32];
} TASK;

/* Number of tasks & procs */
#define NR_TASKS 1
#define NR_PROCS 3

/* stacks of tasks */
#define STACK_SIZE_DEFAULT 0x4000 /* 16KB */
#define STACK_SIZE_TESTA STACK_SIZE_DEFAULT
#define STACK_SIZE_TESTB STACK_SIZE_DEFAULT
#define STACK_SIZE_TESTC STACK_SIZE_DEFAULT
#define STACK_SIZE_TTY STACK_SIZE_DEFAULT

#define STACK_SIZE_TOTAL (STACK_SIZE_TESTA + \
                          STACK_SIZE_TESTB + \
                          STACK_SIZE_TESTC + \
                          STACK_SIZE_TTY)

#endif /* _ORANGES_PROC_H_ */