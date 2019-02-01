org     0100h
    
    mov     ax,     0B800h      ; 显存地址
    mov     gs,     ax
    mov     ah,     0Fh         ; 黑底白字
    mov     al,     'L'
    mov     [gs:(80 * 0 + 39) * 2], ax

    jmp     $
