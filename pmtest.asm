; ================================================================================ 
; pmtest.asm
; Compile: nasm pmtest.asm -o pmtest.bin
; ================================================================================ 

%include    "pm.inc"    ; Constants, Macros, or some descriptions

PageDirBase0     equ     200000h ; 页目录开始地址： 2M
PageTblBase0     equ     201000h ; 页表开始地址：   2M + 4K
PageDirBase1     equ     210000h ; 页目录开始地址： 2M + 64K
PageTblBase1     equ     211000h ; 页表开始地址：   2M + 64K + 4K

LinearAddrDemo      equ     00401000h
ProcFoo             equ     00401000h
ProcBar             equ     00501000h
ProcPagingDemo      equ     00301000h

; org        07c00h
org        0100h
jmp        LABEL_BEGIN

[SECTION .gdt]
; GDT
;                                       段基址,                段界限,                属性
LABEL_GDT:            Descriptor            0,                    0,                0                       ; 空描述符
LABEL_DESC_NORMAL:    Descriptor            0,               0ffffh,                DA_DRW
LABEL_DESC_CODE32:    Descriptor            0,     SegCode32Len - 1,                DA_CR + DA_32           ; 非一致代码段，32
LABEL_DESC_CODE16:    Descriptor            0,               0ffffh,                DA_C                    ; 非一致代码段，16
LABEL_DESC_DATA:      Descriptor            0,            DataLen-1,                DA_DRW                  ; Data
LABEL_DESC_STACK:     Descriptor            0,           TopOfStack,                DA_DRWA + DA_32         ; Stack, 32
LABEL_DESC_VIDEO:     Descriptor      0B8000h,               0ffffh,                DA_DRW                  ; 显存首地址
LABEL_DESC_FLAT_C:      Descriptor          0,               0fffffh,               DA_CR | DA_32 | DA_LIMIT_4K     ; 0 ~ 4G
LABEL_DESC_FLAT_RW:     Descriptor          0,               0fffffh,               DA_DRW | DA_LIMIT_4K            ; 0 ~ 4G
; GDT结束

GdtLen      equ     $ - LABEL_GDT       ; GDT长度
GdtPtr      dw      GdtLen - 1          ; GDT界限
            dd      0                   ; GDT基地址

; GDT Selectors
SelectorNormal      equ     LABEL_DESC_NORMAL       - LABEL_GDT
SelectorCode32      equ     LABEL_DESC_CODE32       - LABEL_GDT
SelectorCode16      equ     LABEL_DESC_CODE16       - LABEL_GDT
SelectorData        equ     LABEL_DESC_DATA         - LABEL_GDT
SelectorStack       equ     LABEL_DESC_STACK        - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO        - LABEL_GDT
SelectorFlatC       equ     LABEL_DESC_FLAT_C       - LABEL_GDT
SelectorFlatRW      equ     LABEL_DESC_FLAT_RW      - LABEL_GDT
; End of [SECTION .gdt]

[SECTION .data1]    ; 数据段
ALIGN 32            ; 让接下来的指令或数据对齐到32字节处
[BITS 32]           ; 指定操作数的默认长度，好比: push 0，是push2个字节，还是4个字节
LABEL_DATA:
; 实模式使用这些符号
; 字符串
PMMessage:          db      "In Protected Mode now. ^-^", 0Ah, 0     ; 在保护模式中显示
StrTest:            db      "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
_szMemChkTitle:     db      "BaseAddrL  BaseAddrH   LengthLow   LengthHigh  Type",  0Ah,    0
_szRAMSize:         db      "RAM size:", 0
_szReturn           db      0Ah, 0
; 变量
SPValueInRealMode   dw      0
_dwMCRNumber:       dd      0
_dwDispPos:         dd      (80 * 4 + 0) * 2
_dwMemSize:         dd      0
_ARDStruct:         ; Address Range Descriptor Structure
    _dwBaseAddrLow:     dd  0
    _dwBaseAddrHigh:    dd  0
    _dwLengthLow:       dd  0
    _dwLengthHigh:      dd  0
    _dwType:            dd  0       ; 1 - AddressRangeMemory(OS可用)    2 - AddressRangeReserved(OS不可用)
_MemChkBuf:         times   256     db  0
_PageTableNumber:   dd      0
_Foo                db      "Foo", 0Ah, 0
_Bar                db      "Bar", 0Ah, 0

; 保护模式下使用这些符号
OffsetPMMessage     equ     PMMessage       - $$
OffsetStrTest       equ     StrTest         - $$
szMemChkTitle       equ     _szMemChkTitle  - $$
szRAMSize           equ     _szRAMSize      - $$
szReturn            equ     _szReturn       - $$
dwMCRNumber         equ     _dwMCRNumber    - $$
dwDispPos           equ     _dwDispPos      - $$
dwMemSize           equ     _dwMemSize      - $$
ARDStruct:          equ     _ARDStruct      - $$
    dwBaseAddrLow:      equ     _dwBaseAddrLow  - $$
    dwBaseAddrHigh:     equ     _dwBaseAddrHigh - $$
    dwLengthLow:        equ     _dwLengthLow    - $$
    dwLengthHigh:       equ     _dwLengthHigh   - $$
    dwType:             equ     _dwType         - $$
MemChkBuf:          equ     _MemChkBuf      - $$
PageTableNumber     equ     _PageTableNumber    - $$
Foo                 equ     _Foo            - $$
Bar                 equ     _Bar            - $$

DataLen             equ     $ - LABEL_DATA
; End of [SECTION .data1]

; 全局堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
    times 512 db 0

TopOfStack  equ     $ - LABEL_STACK - 1
; End of [SECTION .gs]

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h   ; 256

    mov [LABEL_GO_BACK_TO_REAL+3],  ax  ; 为回到实模式的跳转指令指定正确的段地址
    mov [SPValueInRealMode], sp

    ; 获取内存大小
    mov ebx,    0           ; 放置着“后续值（continuation value）”，第一次调用时ebx必须为0
    mov di,     _MemChkBuf
.loop:
    mov eax,    0E820h
    mov ecx,    20
    mov edx,    0534D4150h  ; 'SMAP'
    int 15h
    jc  LABEL_MEM_CHK_FAIL  ; CF=0表示成功，否则失败
    add di,     20          ; 20位ARDStruct的大小
    inc dword[_dwMCRNumber] ; 记录内存信息条数
    cmp ebx,    0           ; 如果ebx=0，且CF没有进位，则说明是最后一个地址范围描述符
    jne .loop
    jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
    mov dword[_dwMCRNumber],    0
LABEL_MEM_CHK_OK:

    ; 初始化16位代码段描述符
    xor eax, eax
    mov ax,  cs
    shl eax, 4
    add eax, LABEL_SEG_CODE16
    mov word [LABEL_DESC_CODE16 + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_CODE16 + 4], al
    mov byte [LABEL_DESC_CODE16 + 7], ah

    ; 初始化32位代码段描述符
    xor eax,    eax
    mov ax,     cs
    shl eax,    4
    add eax,    LABEL_SEG_CODE32
    mov word [LABEL_DESC_CODE32 + 2],   ax
    shr eax,    16
    mov byte [LABEL_DESC_CODE32 + 4],   al
    mov byte [LABEL_DESC_CODE32 + 7],   ah

    ; 初始化数据段描述符
    xor eax,    eax
    mov ax,     ds
    shl eax,    4
    add eax,    LABEL_DATA
    mov word [LABEL_DESC_DATA + 2],     ax
    shr eax,    16
    mov byte[LABEL_DESC_DATA + 4],      al
    mov byte[LABEL_DESC_DATA + 7],      ah

    ; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

    ; prepare to load GDTR
    xor eax,    eax
    mov ax,     ds
    shl eax,    4
    add eax,    LABEL_GDT       ; eax <- gdt基地址
    mov dword[GdtPtr + 2], eax  ; [GdtPtr + 2] <- gdt基地址

    ; load GDTR
    lgdt    [GdtPtr]

    ; close interrupt
    cli

    ; 打开地址线A20
    in  al,     92h
    or  al,     00000010b
    out 92h,    al

    ; 准备切换到保护模式
    mov eax,    cr0
    or  eax,    1
    mov cr0,    eax

    ; 真正进入保护模式
    jmp dword SelectorCode32:0  ; 执行这一句会把SelectorCode32装入cs，并跳转到Code32Selector:0处

LABEL_REAL_ENTRY:   ; 从保护模式调回到实模式就到了这里
    mov     ax,     cs
    mov     ds,     ax
    mov     es,     ax
    mov     ss,     ax

    mov     sp,     [SPValueInRealMode]

    in      al,     92h             ; '.
    and     al,     11111101b       ;  | 关闭A20地址线
    out     92h,    al              ; /

    sti ; 开中断

    mov     ax,     4c00h       ; '.
    int     21h                 ; / 回到DOS
; End of [SECTION .s16]



[SECTION .s32]  ; 32位代码段，由实模式跳入
[BITS 32]
LABEL_SEG_CODE32:
    mov     ax,         SelectorData
    mov     ds,         ax
    mov     es,         ax
    mov     ax,         SelectorVideo
    mov     gs,         ax      ; 视频段选择子（目的）

    mov     ax,         SelectorStack
    mov     ss,         ax
    mov     esp,        TopOfStack

    ; 显示保护模式字符串
    push    OffsetPMMessage
    call    DispStr
    add     esp,        4

    ; 打印内存信息
    push    szMemChkTitle
    call    DispStr
    add     esp,        4   ; 销毁参数
    call    DispMemSize

    call    PagingDemo

    ; 到此停止
    jmp     SelectorCode16:0

; 启动分页机制 --------------------------------------------------------------------------------
SetupPaging:
    ; 根据实际内存大小计算应初始化多少PDE以及多少页表
    xor     edx,    edx
    mov     eax,    [dwMemSize]
    mov     ebx,    400000h     ; 400000h = 4M = 4096 * 1024，一个页表对应的内存大小
    div     ebx                 ; eax - 商, edx - 余数
    mov     ecx,    eax         ; 此时ecx为页表的个数，即PDE的个数
    test    edx,    edx         ; edx - 余数
    jz      .no_remainder
    inc     ecx                 ; 如果余数不为0，则需要多加一个页表
.no_remainder:
    mov     [PageTableNumber],  ecx     ; 暂存页表个数

    ; 为了简化处理，所有线性地址对应相等的物理地址，并不考虑内存空洞

    ; 首先初始化页目录
    mov ax,     SelectorFlatRW
    mov es,     ax
    mov edi,    PageDirBase0    ; 此段首地址为PageDirBase0
    xor eax,    eax
    mov eax,    PageTblBase0 | PG_P | PG_USU | PG_RWW
.1:
    stosd   ; eax -> es:edi
    add eax,    4096    ; 为了简化，所有页表在内存中是连续的
    loop    .1

    ; 再初始化所有页表
    mov ax,     SelectorFlatRW
    mov es,     ax
    mov eax,    [PageTableNumber]             ; 页表个数
    mov ebx,    1024    ; 每个页表1024个PTE
    mul ebx
    mov ecx,    eax     ; PTE = PDE * 1024
    mov edi,    PageTblBase0
    xor eax,    eax
    mov eax,    0 | PG_P | PG_USU | PG_RWW  ; 从内存地址0开始计算
.2:
    stosd   ; eax -> es:edi
    add eax,    4096        ; 每一项指向4K的空间
    loop .2

    mov eax,    PageDirBase0
    mov cr3,    eax         ; CR3 - Page-Directory Base Register，高20位起作用(4K对齐)
    mov eax,    cr0
    or  eax,    80000000h   ; 设置CR0的PG位
    mov cr0,    eax
    jmp short .3
.3:
    nop

    ret
; 分页机制启动完毕 --------------------------------------------------------------------------------

;; 显示内存信息
DispMemSize:
    push    esi
    push    edi
    push    ecx

    mov     esi,    MemChkBuf
    mov     ecx,    [dwMCRNumber]
.loop:
    mov     edx,    5                   ; for(int i = 0; i < 5; i++)    // 每次得到一个ARDS中的成员
    mov     edi,    ARDStruct           ; 依次显示BaseAddrLow, BaseAddrHigh, LengthLow, LengthHigh, Type
.1:
    push    dword[esi]
    call    DispInt

    pop     eax
    stosd       ; 保持MemChkBuf数组中的一项到ARDStruct结构体，下面会用来计算MemSize
    
    add     esi,    4
    dec     edx
    cmp     edx,    0
    jnz     .1
    call    DispReturn                  ; 显示完一条地址信息，换行
    
    cmp     dword[dwType],  1           ; if(Type == AddressRangeMemory)
    jne     .2
    mov     eax,    [dwBaseAddrLow]
    add     eax,    [dwLengthLow]
    cmp     eax,    [dwMemSize]         ;       if(BaseAddrLow + LengthLow > MemSize)
    jb      .2
    mov     [dwMemSize],    eax         ;           MemSize = BaseAddrLow + LengthLow
.2:
    loop    .loop

    call    DispReturn
    push    szRAMSize
    call    DispStr                     ; printf("RAM size:")
    add     esp,    4

    push    dword[dwMemSize]
    call    DispInt
    add     esp,    4

    pop     ecx
    pop     edi
    pop     esi
    ret

;; 演示分页效果
PagingDemo:
    ; 下面的MemCpy函数假设元数据为ds段，目标数据为es段
    mov     ax,     cs
    mov     ds,     ax
    mov     ax,     SelectorFlatRW
    mov     es,     ax

    push    LenFoo
    push    OffsetFoo
    push    ProcFoo
    call    MemCpy
    add     esp,    12

    push    LenBar
    push    OffsetBar
    push    ProcBar
    call    MemCpy
    add     esp,    12

    push    LenPagingDemoAll
    push    OffsetPagingDemoProc
    push    ProcPagingDemo
    call    MemCpy
    add     esp,    12

    mov     ax,     SelectorData
    mov     ds,     ax
    mov     es,     ax

    call    SetupPaging     ; 启动分页

    call    SelectorFlatC:ProcPagingDemo
    call    PSwitch         ; 切换页目录，改变地址映射关系
    call    SelectorFlatC:ProcPagingDemo

    ret

;; --------------------------------------------------------------------------------
PagingDemoProc:
OffsetPagingDemoProc    equ     PagingDemoProc - $$
    mov     eax,    LinearAddrDemo
    call    eax
    retf
LenPagingDemoAll        equ     $ - PagingDemoProc

foo:
OffsetFoo               equ     foo - $$
    ; 注！！！：此处不能直接调用DispStr函数了，因为现在已经开启了分页机制，寻址方式发生了变化，直接调用会出现崩溃！！！！
    ; 2019-01-31的中午在这里纠结了好久！！！！！
    ; push    Foo
    ; call    SelectorCode32:DispStr
    ; add     esp,    4

    mov     ah,     0Ch
    mov     al,     'F'
    mov     [gs:((80*15+0)*2)], ax
    mov     al,     'o'
    mov     [gs:((80*15+1)*2)], ax
    mov     al,     'o'
    mov     [gs:((80*15+2)*2)], ax
    ret
LenFoo                  equ     $ - foo

bar:
OffsetBar               equ     bar - $$
    ; push    Bar
    ; ; call    DispStr
    ; add     esp,    4

    mov     ah,     0Ch
    mov     al,     'B'
    mov     [gs:((80*16+0)*2)], ax
    mov     al,     'a'
    mov     [gs:((80*16+1)*2)], ax
    mov     al,     'r'
    mov     [gs:((80*16+2)*2)], ax
    ret
    ret
LenBar                  equ     $ - bar
;; --------------------------------------------------------------------------------

;; --------------------------------------------------------------------------------
PSwitch:
    ; 初始化页目录
    mov     ax,     SelectorFlatRW
    mov     es,     ax
    mov     edi,    PageDirBase1        ; 此段首地址为PageDirBase1
    xor     eax,    eax
    mov     eax,    PageTblBase1 | PG_P | PG_USU | PG_RWW
    mov     ecx,    [PageTableNumber]
.1:
    stosd
    add     eax,    4096                ; 为了简化，所有页表在内存中是连续的
    loop    .1

    ; 再初始化所有页表
    mov     eax,    [PageTableNumber]   ; 页表个数
    mov     ebx,    1024                ; 每个页表1024个PTE
    mul     ebx
    mov     ecx,    eax                 ; PTE个数 = 页表个数 * 1024
    mov     edi,    PageTblBase1        ; 此段首地址为PageTblBase1
    xor     eax,    eax
    mov     eax,    0 | PG_P | PG_USU | PG_RWW
.2:
    stosd
    add     eax,    4096                ; 每一项指向4K空间
    loop    .2

    ; 在此假设内存是大于8M的
    mov     eax,    LinearAddrDemo
    shr     eax,    22                  ; 取高10位线性地址
    mov     ebx,    4096                ; 计算页目录对应的地址偏移（4k对齐）
    mul     ebx
    mov     ecx,    eax                 ; 将结果保存在本地标量ecx中，后面做加法用

    mov     eax,    LinearAddrDemo
    shr     eax,    12                  ; 获取中10位线性地址
    and     eax,    03FFh               ; 1111111111b(10bits)
    mov     ebx,    4                   ; 计算对应的页表项地址偏移
    mul     ebx

    add     eax,    ecx                 ; 页目录地址偏移 + 页表项地址偏移
    add     eax,    PageTblBase1        ; 再加上基址，得到最终的页表项的线性地址（线性地址对应物理地址）
    mov     dword[es:eax],  ProcBar | PG_P | PG_USU | PG_RWW    ; ProcBar的第12位全为0，所以这个地方恰好OK

    mov     eax,    PageDirBase1
    mov     cr3,    eax                 ; 切换Page-Directory Base Register
    jmp     short   .3
.3:
    nop

    ret
;; --------------------------------------------------------------------------------

%include    "lib.inc"

SegCode32Len    equ     $ - LABEL_SEG_CODE32
; End of [SECTION .s32]

[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16: ; 此处还是保护模式下的16位代码
    ; 跳回实模式
    mov ax,     SelectorNormal
    mov ds,     ax
    mov es,     ax
    mov fs,     ax
    mov gs,     ax
    mov ss,     ax

    mov eax,    cr0
    and eax,    7FFFFFFEh   ; PE=0,PG=0
    mov cr0,    eax         ; 切换为实模式

LABEL_GO_BACK_TO_REAL:
    jmp 0:LABEL_REAL_ENTRY  ; 段地址会在程序开始处被设置成正确的值

Code16Len       equ     $ - LABEL_SEG_CODE16
; End of [SECTION .s16code]
