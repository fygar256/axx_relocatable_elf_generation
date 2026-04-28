; axx test example hello world.
; for x86_64 FreeBSD
;
.extern _hello
.global _start
.section .text
_start:
        nop
        jmp _hello
.endsection

