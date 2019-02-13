#ifndef _ORANGES_PROTECT_H_
#define _ORANGES_PROTECT_H_

#include "type.h"

/* 存储段描述符 / 系统段描述符 */
typedef struct s_descriptor /* 共8个字节 */
{
    u16 limit_low;
    u16 base_low;
    u8 base_mid;
    u8 attr1;
    u8 limit_high_attr2;
    u8 base_high;
} DESCRIPTOR;

/* 门描述符 */
typedef struct s_gate /* 共8个字节 */
{
    u16 offset_low;
    u16 selector;
    u8 dcount; /* 改字段只在调用门描述符中有效。如果在利用调用门调用子程序时引起特权级的转换和堆栈的改变，需要将外层堆栈中的参数复制到内层堆栈。该双字计数字段（dcount means double-count）就是用于说明这种情况发生时，要复制的双字参数的数量。 */
    u8 attr;   /* P(1) DPL(2) DT(1) TYPE(4) */
    u16 offset_high;
} GATE;

/* 选择子(LOADER中已经确定了的) */
#define SELECTOR_DUMMY 0x0
#define SELECTOR_FLAT_C 0x08
#define SELECTOR_FLAT_RW 0x10
#define SELECTOR_VIDEO (0x18 + 3) // RPL=3

#define SELECTOR_KERNEL_CS SELECTOR_FLAT_C
#define SELECTOR_KERNEL_DS SELECTOR_FLAT_RW

/* 描述符类型 */
#define DA_32 0x4000       // 32位段
#define DA_LIMIT_4K 0x8000 // 段界限粒度为4K字节
#define DA_DPL0 0x00       // DPL = 0
#define DA_DPL1 0x20       // DPL = 1
#define DA_DPL2 0x40       // DPL = 2
#define DA_DPL3 0x60       // DPL = 3

/* 存储段描述符类型 */
#define DA_DR 0x90   // 存在的只读数据段属性值
#define DA_DRW 0x92  // 存在的可读写数据段属性值
#define DA_DRWA 0x93 // 存在的已访问可读写数据段属性值
#define DA_C 0x98    // 存在的只执行代码段属性值
#define DA_CR 0x9A   // 存在的可执行可读代码段属性值
#define DA_CCO 0x9C  // 存在的只执行一致代码段属性值
#define DA_CCOR 0x9E // 存在的可执行可读一致代码段属性值

/* 系统段描述符类型 */
#define DA_LDT 0x82      // 局部描述符表（LDT）段类型值
#define DA_TaskGate 0x85 // 任务门类型值
#define DA_386TSS 0x89   // 可用386任务状态段类型值
#define DA_386CGate 0x8C // 386调用门类型值
#define DA_386IGate 0x8E // 386中断门类型值
#define DA_386TGate 0x8F // 386陷阱门类型值

#define SA_TLG 0x0 // GDT描述符标识
#define SA_TIL 0x4 // LDT描述符标识

#define SA_RPL0 0x0 // RPL = 0
#define SA_RPL1 0x1 // RPL = 1
#define SA_RPL2 0x2 // RPL = 2
#define SA_RPL3 0x3 // RPL = 3

/* 分页机制使用的常量说明 */
#define PG_P 0x1   // 页存在属性位
#define PG_RWR 0x0 // R/W属性位，读/执行
#define PG_RWW 0x2 // R/W属性位，读/写/执行
#define PG_USS 0x0 // U/S属性位，系统级
#define PG_USU 0x4 // U/S属性位，用户级

/* 中断向量 */
#define INT_VECTOR_DIVIDE 0x0
#define INT_VECTOR_DEBUG 0x1
#define INT_VECTOR_NMI 0x2
#define INT_VECTOR_BREAKPOINT 0x3
#define INT_VECTOR_OVERFLOW 0x4
#define INT_VECTOR_BOUNDS 0x5
#define INT_VECTOR_INVAL_OP 0x6
#define INT_VECTOR_COPROC_NOT 0x7
#define INT_VECTOR_DOUBLE_FAULT 0x8
#define INT_VECTOR_COPROC_SEG 0x9
#define INT_VECTOR_INVAL_TSS 0xA
#define INT_VECTOR_SEG_NOT 0xB
#define INT_VECTOR_STACK_FAULT 0xC
#define INT_VECTOR_PROTECTION 0xD
#define INT_VECTOR_PAGE_FAULT 0xE
#define INT_VECTOR_COPROC_ERR 0x10

/* 中断向量 */
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

#endif /* _ORANGES_PROTECT_H_ */