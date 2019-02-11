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

; --------------------------------------------------------------------------------
; 基于FAT12头的一些常量定义，如果头信息改变，下面的常量可能也要做响应调整
; --------------------------------------------------------------------------------
; BPB_FATSz16
FATSz                       equ     9

; 根目录占用空间：
; RootDirSectors = (BPB_RootEntCnt*32)+(BPB_BytsPerSec-1)/BPB_bytsPerSec
; 但如果在代码里边实时计算的话，会导致代码过长，所以定义为宏
RootDirSectors             equ     14

; Root Directory的第一个扇区号 = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz)
SectorNoOfRootDirectory     equ     19

; FAT1的第一个扇区号 = BPB_RsvdSecCnt
SectorNoOfFAT1              equ     1

; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
; 文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
DeltaSectorNo               equ     17
