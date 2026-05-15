.global main
.extern printf::plt32
.extern foo::gotpcrel

.section .rodata
msg:
    .asciz "foo = %ld\n"

.section .text

main:
    push rbp
    mov rbp, rsp

    ; foo の実アドレスを GOT から取得
    mov rax, [rip + foo]

    ; foo の値を読む
    mov rsi, [rax]

    lea rdi, [rip + msg]
    xor rax, rax

    call printf

    mov rax, 0
    leave
    ret
