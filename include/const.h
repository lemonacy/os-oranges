#ifndef _ORANGES_CONST_H_
#define _ORANGES_CONST_H_

/* 函数类型 */
#define PUBLIC
#define PRIVATE static

/* GDT和IDT中描述符的个数 */
#define GDT_SIZE 128
#define IDT_SIZE 256

/* 权限 */
#define PRIVILEGE_KRNL 0
#define PRIVILEGE_TASK 1
#define PRIVILEGE_USER 3

/* 8259A interrupt controller ports. */
#define INT_M_CTL 0x20     /* I/O port for interrupt controller - Master */
#define INT_M_CTLMASK 0x21 /* setting bits in this port disables ints - Master */
#define INT_S_CTL 0xA0     /* I/O port for interrupt controller - Slave */
#define INT_S_CTLMASK 0xA1 /* setting bits in this port disables ints - Slave */

#endif /* _ORANGES_CONST_H_ */