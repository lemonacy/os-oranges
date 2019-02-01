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

LABEL_START:
    mov     ax, cs
    mov     ds, ax
    mov     es, ax
    call    DispStr
    jmp     $
DispStr:
    mov     ax, BootMessage
    mov     bp, ax      ; ES:BP = string address
    mov     cx, 16      ; CX = string len
    mov     ax, 01301h  ; AH=13, AL=01
    mov     bx, 000ch   ; 页号为0(BH=0) 黑底红字(BL=0Ch,高亮)
    mov     dl, 0
    int     10h         ; 10h 号中断
    ret
BootMessage:        db  "Hello, OS world!"
times   510-($-$$)  db  0
dw  0xaa55
