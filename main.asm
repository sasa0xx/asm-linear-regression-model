; main.asm
extern MSE
extern print_loss
extern model_init
extern model_predict
extern model_fit
extern puts

struc model
    .weight: resq 1
    .bias: resq 1
    .lr: resq 1
endstruc

section .data
    data:           dq -2.0, 0.0, 1.5, 4.0
    labels:         dq -4.0, -0.5, 2.125, 6.5
    num_elements:   equ 4
    model_smartie:  dq 0.0, 0.0, 0.0
    lr:             dq 0.01

section .text
global _start

_start:
    mov rdi, model_smartie
    movsd xmm1, [lr]
    call model_init

    call puts
    db "Initial weight:", 0

    movsd xmm1, [model_smartie + model.weight]
    call print_loss

    call puts
    db "Initial bias:", 0

    movsd xmm1, [model_smartie + model.bias]
    call print_loss

    mov rdi, model_smartie
    mov rsi, data
    mov rdx, labels
    mov r10, 1000
    mov r8, 4
    call model_fit

    call puts
    db "End weight:", 0

    movsd xmm1, [model_smartie + model.weight]
    call print_loss

    call puts
    db "End bias:", 0

    movsd xmm1, [model_smartie + model.bias]
    call print_loss

    mov rax, 60
    xor rdi, rdi
    syscall