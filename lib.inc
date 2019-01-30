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
    push    edi

    mov     edi,    [dwDispPos]

    mov     ah,     0Fh     ; 0000:黑底     1111:白字
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
    ; add     edi,    2

    mov     [dwDispPos],    edi

    pop     edi
    pop     edx
    pop     ecx

    ret
; End of DispAL

;; 显示一个整数
DispInt:
    mov     eax,    [esp + 4]
    shr     eax,    24
    call    DispAL

    mov     eax,    [esp + 4]
    shr     eax,    16
    call    DispAL

    mov     eax,    [esp + 4]
    shr     eax,    8
    call    DispAL

    mov     eax,    [esp + 4]
    call    DispAL

    mov     ah,     07h     ; 0000b:黑底 0111b:灰字
    mov     al,     'h'
    push    edi
    mov     edi,    [dwDispPos]
    mov     [gs:edi],   ax
    add     edi,    4       ; 包含了一个跳格
    mov     [dwDispPos],    edi
    pop     edi

    ret
;; DispInt结束

;; 显示一个字符串
DispStr:
    push    ebp
    mov     ebp,    esp
    push    ebx
    push    esi
    push    edi

    mov     esi,    [ebp + 8]   ; pszInfo
    mov     edi,    [dwDispPos]
    mov     ah,     0Fh         ; 0000:黑底     1111:白字
.1:
    lodsb
    test    al,     al
    jz      .2
    cmp     al,     0Ah     ; 是回车吗？
    jnz     .3
    push    eax
    mov     eax,    edi
    mov     bl,     160
    div     bl
    and     eax,    0FFh
    inc     eax
    mov     bl,     160
    mul     bl
    mov     edi,    eax
    pop     eax
    jmp     .1
.3:
    mov     [gs:edi],   ax
    add     edi,        2
    jmp     .1
.2:
    mov     [dwDispPos],    edi

    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret
;; DispStr结束

;; 换行
DispReturn:
    push    szReturn
    call    DispStr     ; printf("\n")
    add     esp,    4   ; 销毁堆栈中的参数，相对于pop ...

    ret

; --------------------------------------------------------------------------------
Obsolete_DispReturn:
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
; End of Obsolete_DispReturn
