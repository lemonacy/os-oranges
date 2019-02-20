#include "const.h"
#include "type.h"
#include "console.h"
#include "tty.h"
#include "proc.h"

PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8 in_byte(u16 port);

PUBLIC void disp_str(char *info);
PUBLIC void disp_color_str(char *info, int color);
PUBLIC void disp_int(int input);

PUBLIC void delay(int time);
PUBLIC void milli_delay(int milli_sec);

PUBLIC char *itoa(char *str, int num);

PUBLIC void init_prot();
PUBLIC void init_8259A();
PUBLIC void put_irq_handler(int irq, irq_handler handler);
PUBLIC void enable_irq(int irq);
PUBLIC void disable_irq(int irq);
PUBLIC void spurious_irq(int irq);
PUBLIC void init_clock();
PUBLIC void init_keyboard();
PUBLIC void keyboard_read(TTY *p_tty);

PUBLIC void enable_int();
PUBLIC void disable_int();

PUBLIC u32 seg2phys(u16 seg);

void TestA();
void TestB();
void TestC();
PUBLIC void task_tty();

/* 以下是系统调用相关 */

/* kernal.asm */
PUBLIC void sys_call(); /* int_handler */

/* syscall.asm */
PUBLIC int get_ticks();
PUBLIC void write(char *buf, int len);
/* proc.c */
PUBLIC int sys_get_ticks();
PUBLIC int sys_write(char *buf, int len, PROCESS *p_proc);

PUBLIC void schedule();

PUBLIC int printf(const char *fmt, ...);
PUBLIC int vsprintf(char *buf, const char *fmt, va_list args);