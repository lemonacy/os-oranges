#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "global.h"

PUBLIC void cstart()
{
    disp_pos = (80 * 16 + 0) * 2;
    disp_str("----------\"cstart\" begins ----------\n");

    /* 将Loader中的GDT复制到新的GDT中 */
    memcpy(&gdt, (void *)(*((u32 *)(&gdt_ptr[2]))), *((u16 *)(&gdt_ptr[0])) + 1);
    /* gdt_ptr[6]共6个字节：0~15:Limit 16~47:Base。用作sgdt/lgdt的参数 */
    u16 *p_gdt_limit = (u16 *)(&gdt_ptr[0]);
    u32 *p_gdt_base = (u32 *)(&gdt_ptr[2]);
    *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
    *p_gdt_base = (u32)&gdt;

    /* idt_ptr[6]共6个字节：0~15:Limit 16~47:Base。用作sidt/lidt的参数  */
    u16 *p_idt_limit = (u16 *)(&idt_ptr[0]);
    u32 *p_idt_base = (u32 *)(&idt_ptr[2]);
    *p_idt_limit = IDT_SIZE * sizeof(GATE) - 1;
    *p_idt_base = (u32)&idt;

    init_prot();

    disp_str("----------\"cstart\" ends ----------\n");
}