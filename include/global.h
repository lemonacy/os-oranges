#ifndef _ORANGES_GLOBAL_H_
#define _ORANGES_GLOBAL_H_

#include "const.h"
#include "type.h"
#include "protect.h"
#include "proc.h"
#include "tty.h"
#include "console.h"

/* EXTERN is defined as extern except in global.c */
#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN
#endif

#ifndef GLOBAL_VARIABLES_HERE
#define EXTERN extern
#endif

EXTERN int disp_pos;
EXTERN u8 gdt_ptr[6]; /* 0~15 limit; 16~47 base */
EXTERN DESCRIPTOR gdt[GDT_SIZE];
EXTERN u8 idt_ptr[6]; /* 0~15 limit; 16~47 base */
EXTERN GATE idt[IDT_SIZE];

EXTERN TSS tss;
EXTERN PROCESS *p_proc_ready;

EXTERN int k_reenter;

EXTERN int ticks;

extern PROCESS proc_table[];
extern char task_stack[];
extern TASK task_table[];
extern TASK user_proc_table[];

extern irq_handler irq_table[];

extern system_call sys_call_table[];

extern TTY tty_table[];
extern CONSOLE console_table[];
EXTERN int nr_current_console;
#endif /* _ORANGES_GLOBAL_H_ */