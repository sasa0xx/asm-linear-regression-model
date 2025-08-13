; puts.asm
section .text
global puts

puts:
    pop rsi
    mov rdx, -1

.count:
    inc rdx
    cmp byte [rsi + rdx], 0
    jne .count

    push rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rax

    lea rsi, [rsi + rdx + 1]
    push rsi
    ret