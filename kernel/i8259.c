#include "const.h"
#include "protect.h"
#include "proto.h"

PUBLIC void init_8259A()
{
    /* Master 8259, ICW1 */
    out_byte(INT_M_CTL, 0x11);

    /* Slave 8259, ICW1 */
    out_byte(INT_S_CTL, 0x11);

    /* Master 8259, ICW2. 设置'主8259'的中断入口地址为0x20 */
    out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);

    /* Slave 8259, ICW2. 设置'从8259'的中断入口地址为0x28 */
    out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);

    /* Master 8259, ICW3. IR2对应'从8259' */
    out_byte(INT_M_CTLMASK, 0x4);

    /* Slave 8259, ICW3. 对应'主8259'的IR2 */
    out_byte(INT_S_CTLMASK, 0x2);

    /* Master 8259, ICW4. */
    out_byte(INT_M_CTLMASK, 0x1);   // 指定为80x86模式

    /* Slave 8259, ICW4. */
    out_byte(INT_S_CTLMASK, 0x1);   // 指定为80x86模式

    /* Master 8259, OCW1. */
    out_byte(INT_M_CTLMASK, 0xFF);  // 全屏蔽

    /* Slave 8259, OCW1. */
    out_byte(INT_S_CTLMASK, 0xFF);  // 全屏蔽
}