; axx test example hello world.
; for x86_64 FreeBSD
;
.extern _hello
.global _start
    .org 0
section .text
_start:
        jmp _hello
endsection

