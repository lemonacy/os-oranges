[section .text]

global  memcpy


; --------------------------------------------------------------------------------
; 内存拷贝，仿memcpy
; --------------------------------------------------------------------------------
; void *memcpy(void *es:pDest, void *ds:pSrc, int iSize)
; --------------------------------------------------------------------------------
memcpy:
    push    ebp
    mov     ebp,    esp

    push    esi
    push    edi
    push    ecx

    mov     edi,    [ebp + 8]   ; Destination
    mov     esi,    [ebp + 12]  ; Source
    mov     ecx,    [ebp + 16]  ; Size
.1:
    cmp     ecx,    0
    jz      .2

    mov     al,     [ds:esi]    ;.
    inc     esi                 ; |
    mov     byte[es:edi],   al  ; | 逐字节移动
    inc     edi                 ;/

    dec     ecx                 ; 计数器减1
    jmp     .1

.2:
    mov     eax,    [ebp + 8]   ; 返回值

    pop     ecx
    pop     edi
    pop     esi
    mov     esp,    ebp
    pop     ebp

    ret
; End of memcpy ------------------------------------------------------------------