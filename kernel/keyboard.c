#include "const.h"
#include "proto.h"
#include "keyboard.h"

void keyboard_handler(int irq);

PRIVATE KB_INPUT kb_in;

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

        disp_int(scan_code);
    }
}