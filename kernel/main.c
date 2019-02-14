#include "const.h"
#include "proto.h"
#include "proc.h"
#include "string.h"
#include "global.h"

void restart();

PUBLIC int kernel_main()
{
    disp_str("-----\"kernel_main\" begins -----\n");

    /* 初始化进程表 */
    TASK *p_task = task_table;
    PROCESS *p_proc = proc_table;
    char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
    u16 selector_ldt = SELECTOR_LDT_FIRST;
    int i;
    for (i = 0; i < NR_TASKS; i++)
    {
        strcpy(p_proc->p_name, p_task->name); // name of process
        p_proc->pid = i;                      // pid

        /* LDT在GDT中的描述符初始化代码位于：protect.c::init_prot() */
        p_proc->ldt_sel = selector_ldt;

        /* 直接复制内核的代码段和数据段描述符，然后只修改DPL属性 */
        memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5; // change the DPL
        memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5; // change the DPL

        /* 注意：下面的段寄存器存放的是LDT的Selector, LDT没有第一个位置的DUMMY_DESC，所以第0个位置是代码段，第1个位置是数据段 */
        p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;

        p_proc->regs.eip = (u32)p_task->initial_eip;
        p_proc->regs.esp = (u32)p_task_stack;
        p_proc->regs.eflags = 0x1202; // IF=1, IOPL=1, bit 2 is always 1.

        p_task_stack -= p_task->stacksize;
        p_proc++;
        p_task++;
        selector_ldt += 1 << 3;
    }

    p_proc_ready = proc_table;
    k_reenter = -1;
    restart();

    while (1)
    {
    }
}

void TestA()
{
    int i = 0;
    while (1)
    {
        disp_str("A");
        disp_int(i++);
        disp_str(".");
        delay(100);
    }
}

void TestB()
{
    int i = 0x1000;
    while (1)
    {
        disp_str("B");
        disp_int(i++);
        disp_str(".");
        delay(100);
    }
}

void TestC()
{
    int i = 0x2000;
    while (1)
    {
        disp_str("C");
        disp_int(i++);
        disp_str(".");
        delay(100);
    }
}