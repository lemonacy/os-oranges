; ================================================================================ 
; pmtest1.asm
; Compile: nasm pmtest.asm -o pmtest.bin
; ================================================================================ 

%include    "pm.inc"    ; Constants, Macros, or some descriptions

; org        07c00h
org        0100h
jmp        LABEL_BEGIN

[SECTION .gdt]
; GDT
;                                       段基址,                段界限,                属性
LABEL_GDT:            Descriptor            0,                    0,                0                       ; 空描述符
LABEL_DESC_NORMAL:    Descriptor            0,               0ffffh,                DA_DRW
LABEL_DESC_CODE32:    Descriptor            0,     SegCode32Len - 1,                DA_C + DA_32            ; 非一致代码段，32
LABEL_DESC_CODE16:    Descriptor            0,               0ffffh,                DA_C                    ; 非一致代码段，16
LABEL_DESC_DATA:      Descriptor            0,            DataLen-1,                DA_DRW + DA_DPL1        ; Data
LABEL_DESC_STACK:     Descriptor            0,           TopOfStack,                DA_DRWA + DA_32         ; Stack, 32
LABEL_DESC_TEST:      Descriptor     0500000h,               0ffffh,                DA_DRW
LABEL_DESC_VIDEO:     Descriptor      0B8000h,               0ffffh,                DA_DRW                  ; 显存首地址
LABEL_DESC_LDT:       Descriptor            0,           LDTLen - 1,                DA_LDT                  ; LDT
LABEL_DESC_CODE_DEST: Descriptor            0,   SegCodeDestLen - 1,                DA_C + DA_32            ; 非一致，32位
; 门                                 目标选择子,                  偏移,    DCount,     属性
LABEL_CALL_GATE_TEST: Gate   SelectorCodeDest,                    0,         0,     DA_386CGate + DA_DPL0
; GDT结束

GdtLen      equ     $ - LABEL_GDT       ; GDT长度
GdtPtr      dw      GdtLen - 1          ; GDT界限
            dd      0                   ; GDT基地址

; GDT Selectors
SelectorNormal      equ     LABEL_DESC_NORMAL       - LABEL_GDT
SelectorCode32      equ     LABEL_DESC_CODE32       - LABEL_GDT
SelectorCode16      equ     LABEL_DESC_CODE16       - LABEL_GDT
SelectorData        equ     LABEL_DESC_DATA         - LABEL_GDT + SA_RPL0
SelectorStack       equ     LABEL_DESC_STACK        - LABEL_GDT
SelectorTest        equ     LABEL_DESC_TEST         - LABEL_GDT
SelectorVideo       equ     LABEL_DESC_VIDEO        - LABEL_GDT
SelectorLDT         equ     LABEL_DESC_LDT          - LABEL_GDT
SelectorCodeDest    equ     LABEL_DESC_CODE_DEST    - LABEL_GDT
SelectorCallGateTest    equ     LABEL_CALL_GATE_TEST    - LABEL_GDT

; End of [SECTION .gdt]

[SECTION .data1]    ; 数据段
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode   dw      0
; 字符串
PMMessage:          db      "In Protected Mode now. ^-^", 0     ; 在保护模式中显示
OffsetPMMessage     equ     PMMessage - $$
StrTest:            db      "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest       equ     StrTest - $$
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
    mov sp, 0100h

    mov [LABEL_GO_BACK_TO_REAL+3],  ax  ; 为回到实模式的跳转指令指定正确的段地址
    mov [SPValueInRealMode], sp

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

    ; 初始化LDT在GDT中的描述符
    xor eax,    eax
    mov ax,     ds
    shl eax,    4
    add eax,    LABEL_LDT
    mov word [LABEL_DESC_LDT + 2],  ax
    shr eax,    16
    mov byte [LABEL_DESC_LDT + 4],  al
    mov byte [LABEL_DESC_LDT + 7],  ah

    ; 初始化LDT中的描述符
    xor eax,    eax
    mov ax,     ds
    shl eax,    4
    add eax,    LABEL_CODE_A
    mov word[LABEL_LDT_DESC_CODEA + 2], ax
    shr eax,    16
    mov byte[LABEL_LDT_DESC_CODEA + 4], al
    mov byte[LABEL_LDT_DESC_CODEA + 7], ah

    ; 初始化调用门的代码段描述符
    xor eax,    eax
    mov ax,     cs
    shl eax,    4
    add eax,    LABEL_SEG_CODE_DEST
    mov word[LABEL_DESC_CODE_DEST + 2], ax
    shr eax,    16
    mov byte[LABEL_DESC_CODE_DEST + 4], al
    mov byte[LABEL_DESC_CODE_DEST + 7], ah

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
    mov     ax,         SelectorTest
    mov     es,         ax
    mov     ax,         SelectorVideo
    mov     gs,         ax      ; 视频段选择子（目的）

    mov     ax,         SelectorStack
    mov     ss,         ax
    mov     esp,        TopOfStack

    mov     ah,         0ch                 ; 0000: 黑底  1100: 红字
    xor     esi,        esi
    xor     edi,        edi
    mov     esi,        OffsetPMMessage
    mov     edi,        (80 * 10 + 0) * 2  ; 屏幕第10行，第0列
    cld
.1:
    lodsb
    test    al,         al
    jz      .2
    mov     [gs:edi],   ax
    add     edi,        2
    jmp     .1
.2: ; 显示完毕

    call    DispReturn

    call    TestRead
    call    TestWrite
    call    TestRead

    ; 测试调用门（无特权级变换），将打印字母C，由于没有涉及到特权级变换，其实等同于 call    SelectorCodeDest:0
    call    SelectorCallGateTest:0
    ; call    SelectorCodeDest:0

    ; Load LDT
    mov     ax,     SelectorLDT
    lldt    ax
    jmp     SelectorLDTCodeA:0  ; 跳入局部任务

    ; 到此停止
    ; jmp     SelectorCode16:0

; -------------------------------------------------------------------------------
TestRead:
    xor     esi,    esi
    mov     ecx,    8
.loop:
    mov     al,     [es:esi]
    call    DispAL
    inc     esi
    loop    .loop

    call    DispReturn

    ret
; End of TestRead

; --------------------------------------------------------------------------------
TestWrite:
    push    esi
    push    edi
    xor     esi,    esi
    xor     edi,    edi
    mov     esi,    OffsetStrTest
    cld     ; 请方向, DF=0, esi, edi自增，配合lodsb和stosb指令使用
.1:
    lodsb   ; 从ds:esi指定的地质处读取一个字节到al，如果DF=0，esi+1，如果DF=1，esi-1
    test    al,     al  ; 测试al是否为0（test等价于AND操作），如果为0，则ZF=1，则JZ跳转。在此处即为是否读取到了字符串结束的\null标记
    jz      .2
    mov     [es:edi],   al
    inc     edi
    jmp     .1
.2:
    pop     edi
    pop     esi

    ret
; End of TestWrite

; --------------------------------------------------------------------------------
; 显示AL中的数字
; 默认地：
;       数字已经存在AL中
;       edi始终指向要显示的下一个字符的位置
; 被改变的寄存器：
;       ax, edi
; -------------------------------------------------------------------------------- 
DispAL:
    push    ecx
    push    edx

    mov     ah,     0ch     ; 0000:黑底     1100:红字
    mov     dl,     al
    shr     al,     4       ; 先显示高4bits
    mov     ecx,    2
.begin:
    and     al,     01111b
    cmp     al,     9
    ja      .1
    add     al,     '0'
    jmp     .2
.1:
    sub     al,     0Ah
    add     al,     'A'
.2:
    mov     [gs:edi],   ax
    add     edi,    2

    mov     al,     dl      ; 再显示低4bits
    loop    .begin
    add     edi,    2

    pop     edx
    pop     ecx

    ret
; End of DispAL

; --------------------------------------------------------------------------------
DispReturn:
    push    eax
    push    ebx
    mov     eax,    edi
    mov     bl,     160
    div     bl      ; eax为被除数，ax存商，eax的高16位存余数
    and     eax,    0FFh    ; al为商（行数）
    inc     eax             ; 行数加1
    mov     bl,     160
    mul     bl      ; al为乘数，积存ax
    mov     edi,    eax
    pop     ebx
    pop     eax

    ret
; End of DispReturn

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
    and al,     11111110b
    mov cr0,    eax         ; 切换为实模式

LABEL_GO_BACK_TO_REAL:
    jmp 0:LABEL_REAL_ENTRY  ; 段地址会在程序开始处被设置成正确的值

Code16Len       equ     $ - LABEL_SEG_CODE16
; End of [SECTION .s16code]

[SECTION .ldt]
ALIGN 32
LABEL_LDT:
LABEL_LDT_DESC_CODEA:   Descriptor  0,  CodeALen - 1,   DA_C + DA_32 ; code, 32bits

LDTLen  equ     $ - LABEL_LDT
; LDT选择子
SelectorLDTCodeA    equ     LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL
; End of [SECTION .ldt]

; CodeA(LDT, 32位代码段)
[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
    mov     ax,     SelectorVideo
    mov     gs,     ax

    mov     edi,    (80 * 13 + 0) * 2
    mov     ah,     0ch
    mov     al,     'L'
    mov     [gs:edi],   ax

    ; 准备经由16位代码段跳回实模式
    jmp     SelectorCode16:0
CodeALen    equ     $ - LABEL_CODE_A
; End of [SECTION .la]

[SECTION .sdest];   调用门目标段
[BITS 32]
LABEL_SEG_CODE_DEST:
    mov ax,     SelectorVideo
    mov gs,     ax

    mov edi,    (80 * 14 + 0) * 2
    mov ah,     0ch
    mov al,     'C'
    mov [gs:edi],   ax

    retf

SegCodeDestLen  equ     $ - LABEL_SEG_CODE_DEST
; End of [SECTION .sdest]