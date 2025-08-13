; model.asm
extern MSE
extern print_loss
extern puts
extern print_int

struc model
    .weight: resq 1
    .bias: resq 1
    .lr: resq 1
endstruc

section .rodata ; constants, will use later don't worry :D
    one:    dq 1.0
    two:    dq 2.0

section .text
global model_init
global model_predict
global model_fit

generate_random_number:
    ; 
    ;   return:
    ;       xmm0 : random number between 0 and 1
    ;   
    ;   tasks:
    ;       helper function for model_init
    ;       libraries ? never head of `em.
    ;
    push rbp
    push rdi
    mov rbp, rsp
    sub rsp, 8

    mov rdi, rsp    ; there is actually no need to sub/add 8 to rsp;
                    ; call frame should take care :D
    mov rsi, 8
    mov rdx, 0
    mov rax, 318    ; syscall for getrandom
    syscall

    mov rax, [rsp]
    shr rax, 12
    mov rcx, 0x3FF0000000000000
    or rax, rcx                 ; yes, I love bit hacks :D.
    movq xmm0, rax              ; right now, scale is [1, 2)
    subsd xmm0, [rel two]       ; [1, 2)  -> [-1, 0)
    mulsd xmm0, [rel two]       ; [-1, 0) -> [-2, 0)
    addsd xmm0, [rel one]       ; [-2, 0) -> [-1, 1]

    mov rsp, rbp
    pop rdi
    pop rbp
    ret

model_init:
    ;
    ;   arguments:
    ;       rdi  : model
    ;       xmm1 : learning rate
    ;   return:
    ;       rax  : return model again.
    ;
    ;   tasks:
    ;       put a random number in the range of [-1, 1) in model.weight
    ;       put a random number in the range of [-1, 1) in model.bias
    ;       put the learning rate in model.lr
    ;

    push rbp
    mov rbp, rsp

    movsd [rdi + model.lr], xmm1

    call generate_random_number     
    movsd [rdi + model.weight], xmm0

    call generate_random_number
    movsd [rdi + model.bias], xmm0    
    mov rax, rdi

    mov rsp, rbp
    pop rbp
    ret

model_predict:
    ;
    ;   arguments:
    ;       rdi : model
    ;       xmm1 : X (input)
    ;   return:
    ;       xmm0 : Y (output)
    ;   
    ;   tasks:
    ;       just z = x ⋅ w + b. can't be simpler.
    ;
    movsd xmm0, [rdi + model.weight]
    movsd xmm2, [rdi + model.bias]
    vfmadd132sd xmm0, xmm2 , xmm1
    ret

model_fit:
    ;
    ;   arguments:
    ;       rdi : model
    ;       rsi : data (pointer)
    ;       rdx : labels (pointer)
    ;       r10 : epoches
    ;       r8 : number of elements in data
    ;   
    ;   tasks:
    ;       train the model on the data.
    ;
    push rbp
    mov rbp, rsp

    ; calculate the amount of bytes we will need to allocate
    mov r9, r8
    shl r9, 3
    ; allocate space for ŷ
    sub rsp, r9
    sub rsp, 16     ; allocate space for 3 local variables;
                    ; [rsp] is wg
                    ; [rsp + 8] is bg

    xor rcx, rcx    ; counter -> 0
    .epoch_loop:
        mov qword [rsp], 0
        mov qword [rsp+8], 0
        
        mov r9, 0 ; counter -> 0
        .forward_loop:
            inc r9
            lea r11, [r9 - 1]   ; this lets us have two pointers, one for main loop (r11)
                                ; and one to use for rbp indexing (r9)

            ;   calculate ŷ:
            ;   predict
            ;   calculate gradients while we're at it
            movsd xmm9, [rdx + r11 * 8]  ; temp
            movsd xmm1, [rsi + r11 * 8]
            call model_predict

            ;   save result
            mov rax, r9
            neg rax
            movsd [rbp + rax * 8], xmm0
            subsd xmm0, xmm9
            mov eax, 2
            cvtsi2sd xmm9, eax
            mulsd xmm0, xmm9            ; err = 2(Y_hat - Y)

            movsd xmm1, [rsp + 8]
            addsd xmm1, xmm0
            movsd [rsp + 8], xmm1       ; add to bg

            mulsd xmm0, [rsi + r11 * 8]  ; err = err*x
            movsd xmm1, [rsp + 0]
            addsd xmm1, xmm0
            movsd [rsp + 0], xmm1       ; add to wg
                                        ; note : IK that +0 was just usless, js for clearness

            cmp r9, r8
            jb .forward_loop         

        ; adjusting gradients
        cvtsi2sd xmm0, r8

        movsd xmm1, [rsp + 0]
        divsd xmm1, xmm0
        movsd [rsp + 0], xmm1

        movsd xmm1, [rsp + 8]
        divsd xmm1, xmm0
        movsd [rsp + 8], xmm1

        ; calculate loss :
        push rdi
        push rsi
        push rdx
        push rcx
        push r8
        mov rax, rcx

        mov rdi, rdx 
        lea rsi, [rbp - 8] 
        mov rdx, r8
        call MSE

        xor rdx, rdx
        cmp rax, 0
        je .print

        mov rcx, 100
        div rcx
        test rdx, rdx
        jnz .do_not_print
    mul rcx

    .print:
        call puts
        db "epoch ", 0

        sub rsp, 32
        mov rbx, rsp
        add rbx, 31
        call print_int

        mov rax, 1
        mov rdi, 1
        mov rdx, rcx
        syscall
        add rsp, 32

        call puts
        db " loss: ", 0

        movsd xmm1, xmm0
        call print_loss
       
        .do_not_print:
        pop r8
        pop rcx
        pop rdx
        pop rsi
        pop rdi
        ;   now we apply the gradients
        movsd xmm0, [rdi + model.lr]        ; load learning rate to xmm0

        movsd xmm1, [rsp + 0]
        mulsd xmm1, xmm0                    ; xmm1 = lr ⋅ 2(ŷ - y) ⋅ X

        movsd xmm2, [rsp + 8]
        mulsd xmm2, xmm0                    ; xmm2 = lr ⋅ 2(ŷ - y)

        movsd xmm0, [rdi + model.weight]
        subsd xmm0, xmm1
        movsd [rdi + model.weight], xmm0    ; w = w - lr ⋅ 2(ŷ - y) ⋅ X

        movsd xmm0, [rdi + model.bias]
        subsd xmm0, xmm2
        movsd [rdi + model.bias], xmm0      ; b = b - lr ⋅ 2(ŷ - y)

        inc rcx
        cmp rcx, r10
        jbe .epoch_loop

    mov rsp, rbp
    pop rbp
    ret