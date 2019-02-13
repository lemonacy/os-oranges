#ifndef _ORANGES_GLOBAL_H_
#define _ORANGES_GLOBAL_H_

#include "const.h"
#include "type.h"
#include "protect.h"

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

#endif /* _ORANGES_GLOBAL_H_ */