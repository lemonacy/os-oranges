#include "../include/type.h"
#include "../include/const.h"
#include "../include/protect.h"

PUBLIC void *memcpy(void *pDst, void *pSrc, int iSize);
PUBLIC void disp_str(char *info);

PUBLIC u8 gdt_ptr[6]; /* 0~15 limit; 16~47 base */
PUBLIC DESCRIPTOR gdt[GDT_SIZE];

PUBLIC void cstart()
{
    disp_str("----------\"cstart\" begins ----------");

    /* 将Loader中的GDT复制到新的GDT中 */
    memcpy(&gdt, (void *)(*((u32 *)(&gdt_ptr[2]))), *((u16 *)(&gdt_ptr[0])) + 1);
    /* gdt_ptr[6]共6个字节 */
    u16 *p_gdt_limit = (u16 *)(&gdt_ptr[0]);
    u32 *p_gdt_base = (u32 *)(&gdt_ptr[2]);
    *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
    *p_gdt_base = (u32)&gdt;
}