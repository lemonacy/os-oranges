[section .text]

global  memcpy
global  memset
global  strcpy


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

; --------------------------------------------------------------------------------
; void memset(void *ptr, char ch, int size);
; --------------------------------------------------------------------------------
memset:
    push    ebp
    mov     ebp,    esp

    push    esi
    push    edi
    push    ecx

    mov     edi,    [ebp + 8]   ; ptr
    mov     edx,    [ebp + 12]  ; ch
    mov     ecx,    [ebp + 16]  ; size
.1:
    cmp     ecx,    0
    jz      .2

    mov     byte[edi],  dl
    inc     edi

    dec     ecx
    jmp     .2
.2:
    pop     ecx
    pop     edi
    pop     esi
    mov     esp,    ebp
    pop     ebp

    ret

; --------------------------------------------------------------------------------
; char *strcpy(char *p_dest, char *p_src);
; --------------------------------------------------------------------------------
strcpy:
    push    ebp
    mov     ebp,    esp

    mov     esi,    [ebp + 12]  ; src
    mov     edi,    [ebp + 8]   ; dst

.1:
    mov     al,     [esi]
    inc     esi
    mov     byte[edi], al
    inc     edi

    cmp     al,     0       ; 是否字符串结尾'\0'
    jnz     .1

    mov     eax,    [ebp + 8]   ; 返回值

    pop     ebp
    ret