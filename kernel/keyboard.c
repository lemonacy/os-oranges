#include "const.h"
#include "proto.h"
#include "keyboard.h"
#include "string.h"
#include "keymap.h"
#include "tty.h"
#include "global.h"

void keyboard_handler(int irq);

PRIVATE KB_INPUT kb_in;

PRIVATE int code_with_E0;
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

PRIVATE u8 get_byte_from_kbuf();
PRIVATE void kb_wait();
PRIVATE void kb_ack();
PRIVATE void set_leds();

PUBLIC void init_keyboard()
{
    kb_in.count = 0;
    kb_in.p_head = kb_in.p_tail = kb_in.buf;

    shift_l = shift_r = 0;
    ctrl_l = ctrl_r = 0;
    alt_l = alt_r = 0;

    caps_lock = 0;
    num_lock = 1;
    scroll_lock = 0;

    set_leds();

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

PUBLIC void keyboard_read(TTY *p_tty)
{
    u8 scan_code;
    int make; /* TRUE: make, FALSE: break */

    u32 key = 0; /* 用一个整形来表示一个键。比如，如果Home键被按下，则key值将为定义在keyboard.h中的HOME。 */
    u32 *keyrow; /* 指向keymap[]的某一行 */

    if (kb_in.count > 0)
    {
        code_with_E0 = 0;
        scan_code = get_byte_from_kbuf();

        /* 下面开始解析扫描码 */
        if (scan_code == 0xE1)
        {
            int i;
            u8 pausebrk_scode[] = {0xE1, 0x1D, 0x45, 0xE1, 0x9D, 0xC5};
            int is_pausebreak = 1;
            for (i = 1; i < 6; i++)
            {
                if (get_byte_from_kbuf() != pausebrk_scode[i])
                {
                    is_pausebreak = FALSE;
                    break;
                }
            }
            if (is_pausebreak)
            {
                key = PAUSEBREAK;
            }
        }
        else if (scan_code == 0xE0)
        {
            scan_code = get_byte_from_kbuf();

            /* PrintScreen被按下: 0xE0,0x2A,0xE0,0x37 */
            if (scan_code == 0x2A)
            {
                if (get_byte_from_kbuf() == 0xE0)
                {
                    if (get_byte_from_kbuf() == 0x37)
                    {
                        key = PRINTSCREEN;
                        make = TRUE;
                    }
                }
            }
            /* PrintScreen被释放: 0xE0,0xB7,0xE0,0xAA */
            if (scan_code == 0xB7)
            {
                if (get_byte_from_kbuf() == 0xE0)
                {
                    if (get_byte_from_kbuf() == 0xAA)
                    {
                        key = PRINTSCREEN;
                        make = FALSE;
                    }
                }
            }
            /* 不是PrintScreen，此时scan_code为0xE0紧跟的那个值 */
            if (key == 0)
            {
                code_with_E0 = TRUE;
            }
        }

        if (key != PAUSEBREAK && key != PRINTSCREEN)
        {
            /* 首先判断是make还是break */
            make = (scan_code & FLAG_BREAK ? FALSE : TRUE);
            /* 先定位到keymap[]中的行 */
            keyrow = &keymap[(scan_code & 0x7F) * MAP_COLS];

            column = 0;
            int caps = shift_l || shift_r;
            if (caps_lock)
            {
                if ((keyrow[0] >= 'a') && (keyrow[0] <= 'z'))
                {
                    caps = !caps; /* shift按键与否有打开大小写键有关系 */
                }
            }
            if (caps)
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
                break;
            case SHIFT_R:
                shift_r = make;
                break;
            case CTRL_L:
                ctrl_l = make;
                break;
            case CTRL_R:
                ctrl_r = make;
                break;
            case ALT_L:
                alt_l = make;
                break;
            case ALT_R:
                alt_r = make;
                break;
            case CAPS_LOCK:
                if (make)
                {
                    caps_lock = !caps_lock;
                    set_leds();
                }
                break;
            case NUM_LOCK:
                if (make)
                {
                    num_lock = !num_lock;
                    set_leds();
                }
                break;
            case SCROLL_LOCK:
                if (make)
                {
                    scroll_lock = !scroll_lock;
                    set_leds();
                }
                break;
            default:
                break;
            }

            if (make) /* 忽略break code */
            {
                int pad = 0;

                /* 首先处理小写键盘 */
                if ((key >= PAD_SLASH) && (key <= PAD_9))
                {
                    pad = 1;
                    switch (key)
                    {
                    case PAD_SLASH:
                        key = '/';
                        break;
                    case PAD_STAR:
                        key = '*';
                        break;
                    case PAD_MINUS:
                        key = '-';
                        break;
                    case PAD_PLUS:
                        key = '+';
                        break;
                    case PAD_ENTER:
                        key = ENTER;
                        break;
                    default:
                        if (num_lock && (key >= PAD_0) && (key <= PAD_9))
                        {
                            key = key - PAD_0 + '0';
                        }
                        else if (num_lock && (key == PAD_DOT))
                        {
                            key = '.';
                        }
                        else
                        {
                            switch (key)
                            {
                            case PAD_HOME:
                                key = HOME;
                                break;
                            case PAD_END:
                                key = END;
                                break;
                            case PAD_PAGEUP:
                                key = PAGEUP;
                                break;
                            case PAD_PAGEDOWN:
                                key = PAGEDOWN;
                                break;
                            case PAD_INS:
                                key = INSERT;
                                break;
                            case PAD_UP:
                                key = UP;
                                break;
                            case PAD_DOWN:
                                key = DOWN;
                                break;
                            case PAD_LEFT:
                                key = LEFT;
                                break;
                            case PAD_RIGHT:
                                key = RIGHT;
                                break;
                            case PAD_DOT:
                                key = DELETE;
                                break;
                            default:
                                break;
                            }
                        }
                        break;
                    }
                }

                key |= shift_l ? FLAG_SHIFT_L : 0; /* 不管是单键还是组合键，都使用一个32位整形数key来表示。因为 */
                key |= shift_r ? FLAG_SHIFT_R : 0; /* 可打印字符的ASCII码是8位，而我们将特殊的按键定义成了FLAG_EXT和一个 */
                key |= ctrl_l ? FLAG_CTRL_L : 0;   /* 单字节数的和，也不超过9位（可参考keyboard.h），这样，我们还剩余很多位 */
                key |= ctrl_r ? FLAG_CTRL_R : 0;   /* 来表示Shift、Alt、Ctrl等键的状态，一个整形记载的信息足够我们了解当前的按键情况。*/
                key |= alt_l ? FLAG_ALT_L : 0;
                key |= alt_r ? FLAG_ALT_R : 0;
                key |= pad ? FLAG_PAD : 0;

                in_process(p_tty, key);
            }
        }
    }
}

PRIVATE u8 get_byte_from_kbuf()
{
    u8 scan_code;
    while (kb_in.count <= 0)
    {
    } // wait

    disable_int();
    scan_code = *(kb_in.p_tail);
    kb_in.p_tail++;
    if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES)
    {
        kb_in.p_tail = kb_in.buf;
    }
    kb_in.count--;
    enable_int();

    return scan_code;
}

PRIVATE void kb_wait() /* 等待8042的输入缓冲区空 */
{
    u8 kb_stat;
    do
    {
        kb_stat = in_byte(KB_CMD);
    } while (kb_stat & 0x02);
}

PRIVATE void kb_ack()
{
    u8 kb_read;
    do
    {
        kb_read = in_byte(KB_DATA);
    } while (kb_read = !KB_ACK);
}

PRIVATE void set_leds()
{
    u8 leds = (caps_lock << 2) | (num_lock << 1) | scroll_lock;
    /* 我们的目的是往8048（键盘编码器Keyboard Encoder，位于键盘上，224页）发送命令，但我们不会直接操作8048，而是通过操作8042的相关寄存器，然后由8042去自动操作8048（使用8042的端口0x60） */
    kb_wait();                   /* 当向8042（监控控制器Keyboard Controller，位于主板上，224页）输入缓冲区写数据时，要先判断一下输入缓冲区是否为空，方法是通过端口0x64读取状态寄存器。状态寄存器的第1位如果为0，表示输入缓冲区是空的，可以向其写入数据。 */
    out_byte(KB_DATA, LED_CODE); /* 设置LED的命令是0xED */
    kb_ack();                    /* 当键盘接收到这个命令后，会回复一个ACK(0xFA)，然后等待从端口0x60写入的LED参数字节 */
    kb_wait();                   /* 同上 */
    out_byte(KB_DATA, leds);     /* 格式：00000|caps lock|num lock|scroll lock| */
    kb_ack();                    /* 当键盘收到参数字节后，会再回复一个ACK，并根据参数字节的值来设置LED */
}