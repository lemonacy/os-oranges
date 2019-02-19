#ifndef _ORANGES_CONSOLE_H_
#define _ORANGES_CONSOLE_H_

#include "const.h"
#include "tty.h"

typedef struct s_console
{
    unsigned int current_start_addr; /* 当前显示到了什么位置 */
    unsigned int original_addr;      /* 当前控制台对应显存位置 */
    unsigned int v_mem_limit;        /* 当前控制点占的显存大小 */
    unsigned int cursor;             /* 当前光标位置 */
} CONSOLE;

#define SCR_UP 1  /* scroll upward */
#define SCR_DN -1 /* scroll downward */

#define SCR_SIZE (80 * 25)
#define SCR_WIDTH 80

#define DEFAULT_CHAR_COLOR (MAKE_COLOR(BLACK, WHITE))
#define GRAY_CHAR (MAKE_COLOR(BLACK, BLACK) | BRIGHT)
#define RED_CHAR (MAKE_COLOR(BLUE, RED) | BRIGHT)

PUBLIC int is_current_console(CONSOLE *p_con);
PUBLIC void out_char(CONSOLE *p_con, char ch);
PUBLIC void init_screen(TTY *p_tty);
PUBLIC void select_console(int nr_console);

#endif /* _ORANGES_CONSOLE_H_ */