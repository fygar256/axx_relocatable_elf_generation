.extern puts::plt32

.section .text
.global main

main:
    lea rdi, [rip+msg]
    xor eax, eax
    call puts
    ret
.section .data
msg:
    .asciz "hello\n"
