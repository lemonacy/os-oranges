#include "const.h"
#include "proto.h"
#include "keyboard.h"
#include "string.h"
#include "keymap.h"

void keyboard_handler(int irq);

PRIVATE KB_INPUT kb_in;

PRIVATE int code_with_E0 = 0;
PRIVATE int shift_l;
PRIVATE int shift_r;
PRIVATE int ctrl_l;
PRIVATE int ctrl_r;
PRIVATE int alt_l;
PRIVATE int alt_r;
PRIVATE int caps_lock;
PRIVATE int num_lock;
PRIVATE int scroll_lock;
PRIVATE int column;

PUBLIC void init_keyboard()
{
    kb_in.count = 0;
    kb_in.p_head = kb_in.p_tail = kb_in.buf;

    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
    enable_irq(KEYBOARD_IRQ);
}

void keyboard_handler(int irq)
{
    // disp_str("*");
    // disp_int(scan_code);
    u8 scan_code = in_byte(KB_DATA);
    if (kb_in.count < KB_IN_BYTES)
    {
        *(kb_in.p_head) = scan_code;
        kb_in.p_head++;
        if (kb_in.p_head == kb_in.buf + KB_IN_BYTES)
        {
            kb_in.p_head = kb_in.buf; // 循环队列
        }
        kb_in.count++;
    }
}

PUBLIC void keyboard_read()
{
    u8 scan_code;
    char output[2];
    int make; /* TRUE: make, FALSE: break */

    u32 key = 0; /* 用一个整形来表示一个键。比如，如果Home键被按下，则key值将为定义在keyboard.h中的HOME。 */
    u32 *keyrow; /* 指向keymap[]的某一行 */

    memset(output, 0, 2);

    if (kb_in.count > 0)
    {
        disable_int();
        scan_code = *kb_in.p_tail;
        kb_in.p_tail++;
        if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES)
        {
            kb_in.p_tail = kb_in.buf;
        }
        kb_in.count--;
        enable_int();

        /* 下面开始解析扫描码 */
        if (scan_code == 0xE1)
        {
            /* 暂时不做任何操作 */
        }
        else if (scan_code == 0xE0)
        {
            code_with_E0 = TRUE;
        }
        else /* 下面处理可打印字符 */
        {
            /* 首先判断是make还是break */
            make = (scan_code & FLAG_BREAK ? FALSE : TRUE);
            /* 先定位到keymap[]中的行 */
            keyrow = &keymap[(scan_code & 0x7F) * MAP_COLS];
            column = 0;
            if (shift_l || shift_r)
            {
                column = 1;
            }
            if (code_with_E0)
            {
                column = 2;
                code_with_E0 = FALSE;
            }
            key = keyrow[column];
            switch (key)
            {
            case SHIFT_L:
                shift_l = make;
                key = 0;
                break;
            case SHIFT_R:
                shift_r = make;
                key = 0;
                break;
            case CTRL_L:
                ctrl_l = make;
                key = 0;
                break;
            case CTRL_R:
                ctrl_r = make;
                key = 0;
                break;
            case ALT_L:
                alt_l = make;
                key = 0;
                break;
            case ALT_R:
                alt_r = make;
                key = 0;
                break;
            default:
                if (!make)
                {            /* 如果是break code */
                    key = 0; /* 忽略之 */
                }
                break;
            }
            /* 如果key不为0则可打印，否则不做处理 */
            if (key)
            {
                output[0] = key;
                disp_str(output);
            }
        }
    }
}