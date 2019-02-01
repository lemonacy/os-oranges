    org     07c00h      ; 告诉编译器程序加载到7c00处
    jmp     short LABEL_START
    nop                 ; 这个nop不可少

    ; 下面是FAT12磁盘的头
    BS_OEMName      db  'ForrestY'  ; OEM String，必须是8个字符
    BPB_BytsPerSec  dw  512         ; 每个扇区字节数
    BPB_SecPerClus  db  1           ; 每簇多少个扇区
    BPB_RsvdSecCnt  dw  1           ; Boot记录占用多少个扇区
    BPB_NumFATs     db  2           ; 共有多少个FAT表
    BPB_RootENtCnt  dw  224         ; 根目录文件数最大值
    BPB_TotSec16    dw  2880        ; 逻辑扇区总数
    BPB_Media       db  0xF0        ; 媒体描述符
    BPB_FATSz16     dw  9           ; 每FAT占扇区数
    BPB_SecPerTrk   dw  18          ; 每磁道扇区数
    BPB_NumHeads    dw  2           ; 磁头数
    BPB_HiddSec     dd  0           ; 隐藏扇区数
    BPB_TotSec32    dd  0           ; wTotalSectorCount为0时这个值记录扇区数
    BS_DrvNum       db  0           ; 中断13的驱动器号
    BS_Reserved1    db  0           ; 保留
    BS_BootSig      db  29h         ; 扩展引用标记(29h)
    BS_VolID        dd  0           ; 卷序列号
    BS_VolLab       db  'OrangeS0.02'   ; 卷标，必须是11个字符
    BS_FileSysType  db  'FAT12'     ; 文件系统类型，必须是8个字节

BaseOfStack     equ     07c00h      ; 堆栈基地址（栈底，从这个位置向低地址生长）
BaseOfLoader    equ     09000h      ; loader.bin被加载到的位置 --- 段地址
OffsetOfLoader  equ     0100h       ; loader.bin被加载到的位置 --- 偏移地址
RootDirSectors  equ     14          ; 根目录占用空间
SectorNoOfRootDirectory equ     19  ; Root Directory的第一个扇区

LABEL_START:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, BaseOfStack

    ; 寻找loader.bin
    xor     ah,     ah  ; '.
    xor     dl,     dl  ;  | 软驱复位
    int     13h         ; /

    ; 下面在A盘的根目录寻找loader.bin
    mov     word[wSectorNo],    SectorNoOfRootDirectory     ; 19 - Root Directory的第一个扇区
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp     word[wRootDirSizeForLoop],  0   ; '. wRootDirSizeForLoop=14根目录占用扇区数
    jz      LABEL_NO_LOADERBIN              ;  | 判断根目录所有扇区是否已经读完，如果读完表示没有找到loader.bin
    dec     word[wRootDirSizeForLoop]       ; /

    mov     ax,     BaseOfLoader
    mov     es,     ax
    mov     bx,     OffsetOfLoader          ; BaseOfLoader:OffsetOfLoader(es:bx)是loader.bin将被加载到的内存地址
    mov     ax,     [wSectorNo]             ; Root Directory中的某Sector号
    mov     cl,     1                       ; 要读取的扇区数，这里一次读一个扇区
    call    ReadSector

    mov     si,     LoaderFileName          ; ds:si -> "LOADER  BIN"
    mov     di,     OffsetOfLoader          ; es:di -> BaseOfLoader:0100
    cld
    mov     dx,     10h                         ; 512/32=16个条目，每个扇区16个条目
LABEL_SEARCH_FOR_LOADERBIN:
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
    jmp     LABEL_DIFFERENT                 ; 只要发现不一样的字符就表明本DirectoryEntry不是我们要找的loader.bin

LABEL_GO_ON:
    inc     di 
    jmp     LABEL_CMP_FILENAME              ; 继续循环比较FILENAME

LABEL_DIFFERENT:
    and     di,     0FFE0h                  ; '. di &= E0 为了让它指向本条目开始
    add     di,     20h                     ;  | di += 20h 指向下一个目录条目
    mov     si,     LoaderFileName          ;  |
    jmp     LABEL_SEARCH_FOR_LOADERBIN      ; /

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    add     word[wSectorNo],    1
    jmp     LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
    mov     dh,     2                       ; 字符串序号2，"No LOADER"
    call    DispStr
%ifdef  _BOOT_DEBUG_
    mov     ax,     4c00h
    int     21h                             ; 没有找到loader.bin，回到DOS
%else
    jmp     $
%endif

LABEL_FILENAME_FOUND:                       ; 找到loader.bin后便来到这里继续

    jmp     $

DispStr:
    mov     ax, MessageLenght
    mul     dh          ; 字符串序号
    add     ax, BootMessage 
    mov     bp, ax      ; '.
    mov     ax, ds      ;  | ES:BP = string address
    mov     es, ax      ; /
    mov     cx, MessageLenght
    mov     ax, 01301h  ; AH=13, AL=01
    mov     bx, 0007h   ; 页号为0(BH=0) 黑底白字(BL=07h)
    mov     dl, 0
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

; 变量
wRootDirSizeForLoop dw  RootDirSectors  ; Root Directory占用的扇区数，在循环中会递减至0
wSectorNo           dw  0               ; 要读取的扇区号
bOdd                db  0               ; 奇数还是偶数
; 字符串
LoaderFileName      db  "LOADER  BIN", 0    ; loader.bin之文件名
; 为了简化代码，下面每个字符串的长度均为MessageLength
MessageLenght       equ     9
BootMessage         db      "Booting  "     ; 9字节，不够用空格补齐，序号0
Message1            db      "Ready.   "     ; 9字节，不够用空格补齐，序号1
Message2            db      "No LOADER"     ; 9字节，不够用空格补齐，序号2

times   510-($-$$)  db  0
dw  0xaa55
