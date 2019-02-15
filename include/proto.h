#include "const.h"
#include "type.h"

PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8 in_byte(u16 port);

PUBLIC void disp_str(char *info);
PUBLIC void disp_color_str(char *info, int color);
PUBLIC void disp_int(int input);

PUBLIC void delay(int time);

PUBLIC char *itoa(char *str, int num);

PUBLIC void init_prot();
PUBLIC void init_8259A();
PUBLIC void put_irq_handler(int irq, irq_handler handler);
PUBLIC void spurious_irq(int irq);
PUBLIC void clock_handler(int irq);

PUBLIC u32 seg2phys(u16 seg);

void TestA();
void TestB();
void TestC();

/* 以下是系统调用相关 */

/* kernal.asm */
PUBLIC void sys_call();     /* int_handler */

/* syscall.asm */
PUBLIC int get_ticks();

/* proc.c */
PUBLIC int sys_get_ticks();