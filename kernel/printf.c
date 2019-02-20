#include "const.h"
#include "type.h"
#include "proto.h"

PUBLIC int printf(const char *fmt, ...) {
    int i;
    char buf[256];

    // var_list其实就是char*，定义在type.h中
    va_list arg = (va_list)((char*)(&fmt) + 4); /* 4是参数fmt所占用堆栈中的大小 */
    i = vsprintf(buf, fmt, arg);
    write(buf, i);

    return i;
}