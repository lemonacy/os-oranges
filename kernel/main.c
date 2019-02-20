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
    TASK *p_task;
    PROCESS *p_proc = proc_table;
    char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
    u16 selector_ldt = SELECTOR_LDT_FIRST;

    u8 privilege;
    u8 rpl;
    int eflags;
    int i;
    for (i = 0; i < NR_TASKS + NR_PROCS; i++)
    {
        if (i < NR_TASKS) /* 任务 */
        {
            p_task = task_table + i;
            privilege = PRIVILEGE_TASK;
            rpl = RPL_TASK;
            eflags = 0x1202; /* IF=1, IOPL=1, bit 2 is always 1 */
        }
        else /* 用户进程 */
        {
            p_task = user_proc_table + (i - NR_TASKS);
            privilege = PRIVILEGE_USER;
            rpl = RPL_USER;
            eflags = 0x202; /* IF=1, bit 2 is always 1, 剥夺了用户进程所有的I/O权限 */
        }
        strcpy(p_proc->p_name, p_task->name);  // name of process
        p_proc->pid = i;                       // pid
        p_proc->ticks = p_proc->priority = 10; // default priority 10
        p_proc->nr_tty = 0;                    // defualt tty

        /* LDT在GDT中的描述符初始化代码位于：protect.c::init_prot() */
        p_proc->ldt_sel = selector_ldt;

        /* 直接复制内核的代码段和数据段描述符，然后只修改DPL属性 */
        memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[0].attr1 = DA_C | privilege << 5; // change the DPL
        memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | privilege << 5; // change the DPL

        /* 注意：下面的段寄存器存放的是LDT的Selector, LDT没有第一个位置的DUMMY_DESC，所以第0个位置是代码段，第1个位置是数据段 */
        p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | rpl;

        p_proc->regs.eip = (u32)p_task->initial_eip;
        p_proc->regs.esp = (u32)p_task_stack;
        p_proc->regs.eflags = eflags;

        p_task_stack -= p_task->stacksize;
        p_proc++;
        p_task++;
        selector_ldt += 1 << 3;
    }
    proc_table[0].ticks = proc_table[0].priority = 10; // TASK
    proc_table[1].ticks = proc_table[1].priority = 1;  // TestA
    proc_table[2].ticks = proc_table[2].priority = 1;  // TestB
    proc_table[3].ticks = proc_table[3].priority = 1;  // TestC

    proc_table[1].nr_tty = 0;
    proc_table[2].nr_tty = 1;
    proc_table[3].nr_tty = 1;

    p_proc_ready = proc_table;
    k_reenter = 0; // 由于在第一次中断发生之前（kernal.asm::_start::restart_reenter）就执行了一次减一操作，所以这个地方的初始化要修改为0
    ticks = 0;

    init_clock();
    // init_keyboard();

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
        // disp_str("A");
        // disp_int(get_ticks());
        // disp_str(".");
        printf("<Ticks:%x", get_ticks());
        milli_delay(200);
    }
}

void TestB()
{
    int i = 0x1000;
    while (1)
    {
        // disp_str("B");
        // disp_int(i++);
        // disp_str(".");
        printf("B");
        milli_delay(10);
    }
}

void TestC()
{
    int i = 0x2000;
    while (1)
    {
        // disp_str("C");
        // disp_int(i++);
        // disp_str(".");
        printf("C");
        milli_delay(10);
    }
}