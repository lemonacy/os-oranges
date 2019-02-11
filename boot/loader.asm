; nasm loader.asm -o loader.bin

org     0100h

BaseOfStack         equ     0100h

BaseOfKernelFile    equ     08000h
OffsetOfKernelFile  equ     0h

    jmp     short LABEL_START

; 下面是FAT12磁盘的头，之所以包含它是因为下面用到了磁盘的一些信息
%include    "include/fat12hdr.inc"

LABEL_START:
    mov     ax,     cs
    mov     ds,     ax
    mov     es,     ax
    mov     es,     ax
    mov     ss,     ax
    mov     sp,     BaseOfStack

    mov     dh,     0           ; 0号字符串 - Loading
    call    DispStr

    xor     ah,     ah  ; '.
    xor     dl,     dl  ;  | 软驱复位
    int     13h         ; /

    ; 下面在A盘的根目录寻找KERNEL.BIN
    mov     word[wSectorNo],    SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp     word[wRootDirSizeForLoop],  0   ; '. wRootDirSizeForLoop=14根目录占用扇区数
    jz      LABEL_NO_KERNELBIN              ;  | 判断根目录所有扇区是否已经读完，如果读完表示没有找到kernel.bin
    dec     word[wRootDirSizeForLoop]       ; /

    mov     ax,     BaseOfKernelFile
    mov     es,     ax
    mov     bx,     OffsetOfKernelFile          ; BaseOfKernelFile:OffsetOfKernelFile(es:bx)是kernel.bin将被加载到的内存地址
    mov     ax,     [wSectorNo]             ; Root Directory中的某Sector号
    mov     cl,     1                       ; 要读取的扇区数，这里一次读一个扇区
    call    ReadSector

    mov     si,     KernelFileName          ; ds:si -> "LOADER  BIN"
    mov     di,     OffsetOfKernelFile          ; es:di -> BaseOfKernelFile:0100
    cld
    mov     dx,     10h                         ; 512/32=16个条目，每个扇区16个条目
LABEL_SEARCH_FOR_KERNELBIN:
    cmp     dx,     0                           ; '. 循环次数控制,
    jz      LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR  ;  | 如果已经读完了一个Sector，
    dec     dx                                  ; /  就跳到下一个sector
    mov     cx,     11
LABEL_CMP_FILENAME:
    cmp     cx,     0
    jz      LABEL_FILENAME_FOUND            ; 如果比较了11个字符都相等，表示找到
    dec     cx
    lodsb                                   ; [ds:si] -> al
    cmp     al,     byte[es:di]
    jz      LABEL_GO_ON
    jmp     LABEL_DIFFERENT                 ; 只要发现不一样的字符就表明本DirectoryEntry不是我们要找的kernel.bin

LABEL_GO_ON:
    inc     di
    jmp     LABEL_CMP_FILENAME              ; 继续循环比较FILENAME

LABEL_DIFFERENT:
    and     di,     0FFE0h                  ; '. di &= E0 为了让它指向本条目开始
    add     di,     20h                     ;  | di += 20h 指向下一个目录条目
    mov     si,     KernelFileName          ;  |
    jmp     LABEL_SEARCH_FOR_KERNELBIN      ; /

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    add     word[wSectorNo],    1
    jmp     LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_KERNELBIN:
    mov     dh,     2                       ; 字符串序号2，"No KERNEL"
    call    DispStr
%ifdef  _BOOT_DEBUG_
    mov     ax,     4c00h
    int     21h                             ; 没有找到kernel.bin，回到DOS
%else
    jmp     $                               ; 没有找到kernel.bin，suspending
%endif

LABEL_FILENAME_FOUND:                       ; 找到kernel.bin后便来到这里继续
    mov     ax,     RootDirSectors          ; 14
    and     di,     0FFE0h                  ; di -> 当前条目的开始

    push    eax                             ; '.
    mov     eax,    [es: di + 01Ch]         ;  |
    mov     dword[dwKernelSize],    eax     ;  | 保持kernel.bin文件的大小
    pop     eax                             ; /

    add     di,     01Ah                    ; di -> 首Sector，01Ah偏移处为2个字节的DIR_FstClus(开始簇号)
    mov     cx,     word[es:di]             ; DIR_FstClus占2个字节，所以读word
    push    cx                              ; 保存此Sector在FAT中的序号
    ; 下面计算DIR_FstClus对应的真实扇区号：X + RootDirSectors + 19 - 2
    add     cx,     ax                      ; cx + 14
    add     cx,     DeltaSectorNo           ; cx + 19 - 2, cl <- kernel.bin数据所在的真实扇区号(0-based).

    mov     ax,     BaseOfKernelFile
    mov     es,     ax
    mov     bx,     OffsetOfKernelFile          ; es:bx kernel.bin将被加载到的目标内存区
    mov     ax,     cx                      ; ax: Sector号
LABEL_GOON_LOADING_FILE:
    push    ax                              ; '.
    push    bx                              ;  |
    mov     ah,     0Eh                     ;  | 每读一个扇区就在“Booting  ”后面
    mov     al,     '.'                     ;  | 打一个点，形成这样的效果：
    mov     bl,     0Fh                     ;  | Booting  ........
    int     10h                             ;  |
    pop     bx                              ;  |
    pop     ax                              ; /

    mov     cl,     1                       ; 读取一个扇区
    call    ReadSector
    pop     ax
    call    GetFATEntry                     ; 取出此Sector在FAT中的序号，在文件占用多个扇区的情况下，判断是否读完
    cmp     ax,     0FFFh
    jz      LABEL_FILE_LOADED
    push    ax                              ; 保存Sector在FAT中的序号
    mov     dx,     RootDirSectors          ; '.
    add     ax,     dx                      ;  | X + 14 + 19 - 2
    add     ax,     DeltaSectorNo           ; / ax:下一个数据扇区Sector号
    add     bx,     [BPB_BytsPerSec]        ; 目标缓冲区es:bx后移512个字符，准备接收下一次ReadSector
    jmp     LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
    call    KillMotor                       ; 关闭软驱马达

    mov     dh,     1                       ; 序号1的字符串“Ready.  ”
    call    DispStr

    jmp     $

KillMotor:
    push    dx
    mov     dx,     03F2h
    mov     al,     0
    out     dx,     al
    pop     dx
    ret

DispStr:
    mov     ax, MessageLength
    mul     dh          ; 字符串序号
    add     ax, LoadingMessage
    mov     bp, ax      ; '.
    mov     ax, ds      ;  | ES:BP = string address
    mov     es, ax      ; /
    mov     cx, MessageLength
    mov     ax, 01301h  ; AH=13, AL=01
    mov     bx, 0007h   ; 页号为0(BH=0) 黑底白字(BL=07h)
    mov     dl, 0
    add     dh, 3       ; 从第3行往下显示
    int     10h         ; 10h 号中断
    ret

ReadSector:
    push    bp
    mov     bp,     sp
    sub     esp,    2   ; 辟出两个字节的堆栈区保持要读的扇区数：byte[bp-2]

    mov     byte[bp - 2],   cl
    push    bx          ; 保存bx
    mov     bl,     [BPB_SecPerTrk] ; bl:除数
    div     bl          ; al - 商, ah - 余数
    inc     ah
    mov     cl,     ah  ; cl <- 起始扇区号
    mov     dh,     al
    shr     al,     1   ; y/BPB_NumHeads（软盘有正反两面，所以柱面号要除以2）
    mov     ch,     al  ; ch <- 柱面号
    and     dh,     1   ; 磁头号（0，1两个磁头号）
    pop     bx          ; 恢复bx
    ; 至此“柱面号、起始扇区、磁头号”全部获取
    mov     dl,     [BS_DrvNum] ; 驱动器号，0表示A盘
.GoOnReading:
    mov     ah,     2   ; 读
    mov     al,     byte[bp - 2]    ; 读al个扇区
    int     13h         ; es:bx - 数据缓冲区
    jc      .GoOnReading    ; 如果读取错误CF会被置为1，这时就不停地读，知道正确位置

    add     esp,    2
    pop     bp

    ret

GetFATEntry:
    push    es
    push    bx
    push    ax                          ; 文件数据所在的真实扇区号
    mov     ax,     BaseOfKernelFile    ; '.
    sub     ax,     0100h               ;  | 在BaseOfKernelFile后面留出4K空间用于存放FAT（这里减的是段地址，真实地址还要shl 4, 即1000=4k，高地址在前，低地址在后，所以这里说“后”）
    mov     es,     ax                  ; /  es:bx = 08F00:0000

    ; Sector# * 3 / 2 即得到改扇区在FAT表中的开始字节，可能是整数，也有可能是x.5的小数
    pop     ax                      ; 真实Sector号
    mov     byte[bOdd],     0
    mov     bx,     3
    mul     bx                      ; dx:ax = ax * 3
    mov     bx,     2
    div     bx                      ; dx:ax / 2  ===> ax:商，dx:余数

    cmp     dx,     0               ; 如果没有余数(.5小数)，则说明该扇区在FAT里边刚好是在一个字节的开始处（如果有余数的话，则说明开始处在半个字节处）
    jz      LABEL_EVEN
    mov     byte[bOdd],     1
LABEL_EVEN: ; 偶数
    ; 现在ax中是FATEntry在FAT中的偏移量，下面来计算FATEntry在哪个扇区中（FAT占用不止一个扇区）
    xor     dx,     dx
    mov     bx,     [BPB_BytsPerSec]    ; 512
    div     bx                          ; dx:ax / BPB_BytsPerSec, ax:商（FATEntry所在扇区相对于FAT的扇区号）dx:余数（FATEntry在扇区内的偏移）
    push    dx
    mov     bx,     0                   ; bx <- 0 于是，es:bx = (BaseOfKernelFile - 100):0000，缓冲区首地址
    add     ax,     SectorNoOfFAT1      ; ax = ax + 1 此句之后的ax就是FATEntry所在的扇区号
    mov     cl,     2                   ; 一次读取2个扇区
    call    ReadSector                  ; 读取FATEntry所在的扇区，一个读2个，避免在边界发生错误，因为一个FATEntry可能跨越2个扇区
    pop     dx                          ; dx余数（偏移）
    add     bx,     dx                  ; 加偏移
    mov     ax,     [es:bx]             ; 读2个字节
    cmp     byte[bOdd],     1           ; 如果是半字节开始，要去掉高4位
    jnz     LABEL_ODD
    shr     ax,     4                   ; 如果是字节开始，则去掉低4位
LABEL_ODD:
    and     ax,     0FFFh               ; 如果是半字节开始，则去掉高4位

LABEL_GET_FAT_ENTRY_OK:
    pop     bx
    pop     es
    ret                                 ; 结果在ax中返回

; 变量
wRootDirSizeForLoop dw  RootDirSectors  ; Root Directory占用的扇区数，在循环中会递减至0
wSectorNo           dw  0               ; 要读取的扇区号
bOdd                db  0               ; 奇数还是偶数
dwKernelSize        dd  0               ; 保存kernel.bin文件大小
; 字符串
KernelFileName      db  "KERNEL  BIN", 0    ; kernel.bin之文件名
; 为了简化代码，下面每个字符串的长度均为MessageLength
MessageLength       equ     9
LoadingMessage      db      "Loading  "     ; 9字节，不够用空格补齐，序号0
Message1            db      "Ready.   "     ; 9字节，不够用空格补齐，序号1
Message2            db      "No KERNEL"     ; 9字节，不够用空格补齐，序号2