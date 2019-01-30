; 描述符
; usage: Descriptor Base, Limit, Attr
;		 Base: 	dd
;        Limit:	dd (low 20 bits avaiable)
;        Attr:	dw (lower 4 bits of higher byte are always 0)
%macro Descriptor 3
	dw	%2 & 0FFFFh					; 段界限1
	dw	%1 & 0FFFFh					; 段基址1
	db	(%1 >> 16) & 0FFh 			; 段基址2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)		; 属性1 + 段界限2 + 属性2
	db 	(%1 >> 24) & 0FFh 			; 段基址3
%endmacro	; 共8字节

; 门描述符
; usage: Gate Selector, Offset, DCount, Attr
; 		Selector:	dw
; 		Offset:		dd
; 		DCount:		db
;		Attr:		db
%macro Gate 4
	dw (%2 & 0FFFFh)
	dw %1
	dw (%3 & 1Fh) | ((%4 << 8) & 0FF00h)
	dw ((%2 >> 16) & 0FFFFh)
%endmacro


; 描述符类型
DA_32		equ 		4000h 		; 32位段
DA_LIMIT_4K	equ			8000h		; 段界限粒度为4K字节 

DA_DPL0		equ 		00h			; DPL = 0
DA_DPL1		equ 		20h			; DPL = 1
DA_DPL2		equ 		40h			; DPL = 2
DA_DPL3		equ 		60h			; DPL = 3
; 存储段描述符类型
DA_DR		equ 		90h			; 存在的只读数据段属性值
DA_DRW		equ			92h			; 存在的可读写数据段属性值
DA_DRWA		equ 		93h			; 存在的已访问可读写数据段属性值
DA_C		equ 		98h			; 存在的只执行代码段属性值
DA_CR 		equ 		9Ah			; 存在的可执行可读代码段属性值
DA_CCO		equ 		9Ch 		; 存在的只执行一致代码段属性值
DA_CCOR 	equ 		9Eh 		; 存在的可执行可读一致代码段属性值
; 系统段描述符类型
DA_LDT 		equ 		82h 		; 局部描述符表（LDT）段类型值
DA_TaskGate equ 		85h 		; 任务门类型值
DA_386TSS	equ 		89h 		; 可用386任务状态段类型值
DA_386CGate equ 		8Ch 		; 386调用门类型值
DA_386IGate equ 		8Eh			; 386中断门类型值
DA_386TGate equ 		8Fh 		; 386陷阱门类型值

SA_TLG		equ 		0 			; GDT描述符标识
SA_TIL		equ 		4			; LDT描述符标识

SA_RPL0		equ 		0			; RPL = 0
SA_RPL1		equ 		1			; RPL = 1
SA_RPL2		equ 		2			; RPL = 2
SA_RPL3		equ 		3			; RPL = 3

; 分页机制使用的常量说明
PG_P		equ 		1 			; 页存在属性位
PG_RWR 		equ 		0			; R/W属性位，读/执行
PG_RWW 		equ 		2 			; R/W属性位，读/写/执行
PG_USS 		equ 		0 			; U/S属性位，系统级
PG_USU		equ 		4 			; U/S属性位，用户级