#include "const.h"
#include "proto.h"
#include "global.h"

PUBLIC int sys_get_ticks()
{
    return ticks;
}

PUBLIC void schedule()
{
    PROCESS *p;
    int greatest_ticks = 0;

    while (!greatest_ticks)
    {
        // 找出最大ticks的进程
        for (p = proc_table; p < proc_table + NR_TASKS + NR_PROCS; p++)
        {
            if (p->ticks > greatest_ticks)
            {
                greatest_ticks = p->ticks;
                p_proc_ready = p;
            }
        }

        // 如果所有进程的ticks都为0，则重新复制再来
        if (!greatest_ticks)
        {
            for (p = proc_table; p < proc_table + NR_TASKS + NR_PROCS; p++)
            {
                p->ticks = p->priority;
            }
        }
    }
}