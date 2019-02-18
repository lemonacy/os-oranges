#include "const.h"
#include "proto.h"
#include "keyboard.h"
#include "global.h"

PUBLIC void task_tty()
{
    while (1)
    {
        keyboard_read();
    }
}

PUBLIC void in_process(u32 key)
{
    char output[2] = {'\0', '\0'};
    if (!(key & FLAG_EXT)) // 可打印字符
    {
        output[0] = key & 0xFF;
        disp_str(output);
    }
    else
    {
        int raw_code = key & MASK_RAW;
        switch (raw_code)
        {
        case UP:
            if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R))
            {
                disable_int();
                out_byte(CRTC_ADDR_REG, START_ADDR_H);
                out_byte(CRTC_DATA_REG, ((80 * 15) >> 8) & 0xFF);
                out_byte(CRTC_ADDR_REG, START_ADDR_L);
                out_byte(CRTC_DATA_REG, (80 * 15) & 0xFF);
                enable_int();
            }
            break;
        case DOWN:
            if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R))
            {
                /* Shift + Down, do nothing */
            }
            break;
        default:
            break;
        }
    }

    /* 实现光标跟随 */
    disable_int();
    out_byte(CRTC_ADDR_REG, CURSOR_H);
    out_byte(CRTC_DATA_REG, ((disp_pos / 2) >> 8) & 0xFF);
    out_byte(CRTC_ADDR_REG, CURSOR_L);
    out_byte(CRTC_DATA_REG, (disp_pos / 2) & 0xFF);
    enable_int();
}