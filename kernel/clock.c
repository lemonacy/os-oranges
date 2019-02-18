#include "const.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

void clock_handler(int irq);

PUBLIC void init_clock()
{
    /* 初始化8253 PIT */
    out_byte(TIMER_MODE, RATE_GENERATOR);
    out_byte(TIMER0, (u8)(TIMER_FREQ / HZ));
    out_byte(TIMER0, (u8)((TIMER_FREQ / HZ) >> 8));

    put_irq_handler(CLOCK_IRQ, clock_handler); /* 设定时钟中断处理程序 */
    enable_irq(CLOCK_IRQ);                     /* 然8259A可以接受时钟中断 */
}

void clock_handler(int irq)
{
    ticks++;
    p_proc_ready->ticks--;

    if (k_reenter != 0)
    {
        return;
    }

    if (p_proc_ready->ticks > 0)
    {
        return;
    }

    schedule();
}

PUBLIC void milli_delay(int milli_sec)
{
    int t = get_ticks();
    while (((get_ticks() - t) * 1000 / HZ) < milli_sec)
    {
    }
}