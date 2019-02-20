#ifndef _ORANGES_CONST_H_
#define _ORANGES_CONST_H_

/* 函数类型 */
#define PUBLIC
#define PRIVATE static

#define TRUE 1
#define FALSE 0

/* Color */
/*
 * e.g. MAKE_COLOR(BLUE, RED)
 *      MAKE_COLOR(BLACK, RED) | BRIGHT
 *      MAKE_COLOR(BLACK, RED) | BRIGHT | FLASH
 */
#define BLACK 0x0                       /* 0000 */
#define WHITE 0x7                       /* 0111 */
#define RED 0x4                         /* 0100 */
#define GREEN 0x2                       /* 0010 */
#define BLUE 0x1                        /* 0001 */
#define FLASH 0x80                      /* 1000 0000 */
#define BRIGHT 0x08                     /* 0000 1000 */
#define MAKE_COLOR(x, y) ((x << 4) | y) /* MAKE_COLOR(Background,Foreground) */

/* GDT和IDT中描述符的个数 */
#define GDT_SIZE 128
#define IDT_SIZE 256

/* 权限 */
#define PRIVILEGE_KRNL 0
#define PRIVILEGE_TASK 1
#define PRIVILEGE_USER 3
/* RPL */
#define RPL_KRNL SA_RPL0
#define RPL_TASK SA_RPL1
#define RPL_USER SA_RPL3

/* 8259A interrupt controller ports. */
#define INT_M_CTL 0x20     /* I/O port for interrupt controller - Master */
#define INT_M_CTLMASK 0x21 /* setting bits in this port disables ints - Master */
#define INT_S_CTL 0xA0     /* I/O port for interrupt controller - Slave */
#define INT_S_CTLMASK 0xA1 /* setting bits in this port disables ints - Slave */

/* VGA */
#define CRTC_ADDR_REG 0x3D4 /* CRT Controller Registers - Addr Register */
#define CRTC_DATA_REG 0x3D5 /* CRT Controller Registers - Data Register */
#define START_ADDR_H 0xC    /* reg index of video mem start addr (MSB) */
#define START_ADDR_L 0xD    /* reg index of video mem start addr (LSB) */
#define CURSOR_H 0xE        /* reg index of cursor position (MSB) */
#define CURSOR_L 0xF        /* reg index of cursor position (LSB) */
#define V_MEM_BASE 0xB8000  /* base of color video memory */
#define V_MEM_SIZE 0x8000   /* 32K: B8000H -> BFFFFH */

/* Hardware interrupts */
#define NR_IRQ 16 /* 对应主从两个8259A */
#define CLOCK_IRQ 0
#define KEYBOARD_IRQ 1

/* system call */
#define NR_SYS_CALL 2

/* 8253/8254 PIT (Programmable Interval Timer) */
#define TIMER0 0x40         /* I/O port for timer channel 0 */
#define TIMER_MODE 0x43     /* I/O port for timer mode control */
#define RATE_GENERATOR 0x34 /* 00-11-010-0 :                                     \
                             * Counter0 - LSB then MSB - rate generator - binary \
                             */
#define TIMER_FREQ 1193182L /* clock frequency for timer in PC and AT */
#define HZ 100              /* clock freq(software settable on IBM-PC) */

/* AT keyboard */
/* 8042 ports */
#define KB_DATA 0x60 /* I/O port for keyboard data \
             Read : Read Output Buffer             \
             Write: Write Input Buffer(8042 Data&8048 Command) */
#define KB_CMD 0x64  /* I/O port for keyboard command \
             Read : Read Status Register              \
             Write: Write Input Buffer(8042 Command) */
#define KB_ACK 0xFA
#define LED_CODE 0xED

/* TTY */
#define NR_CONSOLES 3 /* number of consoles */

#endif /* _ORANGES_CONST_H_ */