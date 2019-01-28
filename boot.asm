    org     07c00h      ; 告诉编译器程序加载到7c00处
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
