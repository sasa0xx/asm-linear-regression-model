; loss.asm
section .rodata
    newline     db 10
    dot         db '.'
    minus       db '-'
    five_d      dq 100000.0
    minus_one   dq -1.0

section .text
global MSE
global print_loss
global print_int

MSE:
    ;
    ; arguments:
    ;   rdi : a pointer for array y (labels)
    ;   rsi : a pointer for array ŷ (predections)
    ;   rdx : number of elements n
    ; return:
    ;   xmm0 : loss
    ;
    ; tasks:
    ;   calculate the loss with 1/n[nΣ(ŷ - y)²]
    ;
    push rbp
    mov rbp, rsp

    mov rcx, 0      ; initilize counter

    pxor xmm0, xmm0
    .loop:
        neg rcx
        movsd xmm8, [rsi + rcx * 8] ; temp
        neg rcx
        subsd xmm8, [rdi + rcx * 8]
        mulsd xmm8, xmm8
        addsd xmm0, xmm8
        inc rcx
        cmp rcx, rdx
        jne .loop

    cvtsi2sd xmm1, rdx
    divsd xmm0, xmm1

    mov rsp, rbp
    pop rbp
    ret
    
print_int:
    ;
    ;   helper function for print_loss
    ;   arguments:
    ;       rax - int
    ;       rbx - pointer to buffer
    ;   returns:
    ;       rcx - length
    ;
    push rbp
    mov rbp, rsp

    xor rcx, rcx
    .convert_loop:  ; int to ascci (backwards)
        xor rdx, rdx
        mov r8, 10
        div r8
        add dl, '0'
        dec rbx
        mov [rbx], dl
        inc rcx
        test rax, rax
        jnz .convert_loop
    lea rsi, [rbx]
    mov rsp, rbp
    pop rbp
    ret

print_loss:
    ;   
    ;   arguments:
    ;       xmm1 - loss
    ;   
    ;   tasks:
    ;       - print loss
    ;
    push rbx
    push rbp
    mov rbp, rsp

    sub rsp, 64     ; reserve space for 2 buffers
    mov rbx, rsp
    add rbx, 31

    movq rax, xmm1
    bt rax, 63
    jnc .skip

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel minus]
    mov rdx, 1
    syscall

    movsd xmm2, [rel minus_one]
    mulsd xmm1, xmm2

    .skip:
    cvttsd2si rax, xmm1
    call print_int

    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel dot]
    mov rdx, 1
    syscall

    cvttsd2si r8, xmm1
    cvtsi2sd xmm2, r8
    subsd xmm1, xmm2
    movsd xmm2, [rel five_d]
    mulsd xmm1, xmm2
    cvttsd2si rax, xmm1
    mov rbx, rsp
    add rbx, 63
    call print_int

    .pad_loop:
        cmp rcx, 5
        jae .print_frac
        dec rbx
        mov byte [rbx], '0'
        inc rcx
        jmp .pad_loop
    
    .print_frac:
        mov rax, 1
        mov rdi, 1
        lea rsi, [rbx]
        mov rdx, rcx
        syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall

    mov rsp, rbp
    pop rbp
    pop rbx
    ret