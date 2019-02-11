BaseOfLoader            equ     09000h                      ; loader.bin被加载到的位置 --- 段地址
OffsetOfLoader          equ     0100h                       ; loader.bin被加载到的位置 --- 偏移地址
BaseOfLoaderPhyAddr     equ     BaseOfLoader * 10h          ; loader.bin被加载到的位置 --- 物理地址

BaseOfKernelFile        equ     08000h                      ; kernel.bin被加载到的位置 --- 段地址
OffsetOfKernelFile      equ     0h                          ; kernel.bin被加载到的位置 --- 偏移地址
BaseOfKernelPhyAddr     equ     BaseOfKernelFile * 10h
KernelEntryPointPhyAddr equ     030400h                     ; 必须跟ld的参数-Ttext指定的值一致