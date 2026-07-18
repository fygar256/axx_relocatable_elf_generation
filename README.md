---
title: Creating a relocatable x86_64 ELF with axx, and then linking and executing it
tags: FreeBSD axx x86_64 assembly Terminal
author: fygar256
slide: false
---
https://qiita.com/fygar256/items/1d06fb757ac422796e31

I successfully created a relocatable x86_64 ELF object file using axx on FreeBSD, linked it, and executed it. On March 12, 2026, paxx gained the `-o` option and relocatable ELF output functionality. 

On April 23, 2026, the `.extern` and `.global` directives were added to axx. Testing was performed.

The relocation type can be specified using `.extern label::reloc_type`.

On May 3, 2026, the x86_64 relocatable ELF output of axx became complete.

ELF's default CPU types support x86-64, ARM, AArch64, RISC-V, and PPC.

The remaining step is to extend the relocation type for each CPU.

On May 8, 2026, it became possible to specify the relocation type using `.equ` in axx.

It can be specified using `label: .equ <expression>::reloc_type`.

On June 12, 2026, the -g option was added to ELF object files to include debug information. This should now allow for the creation of complete ELF object files.

As of July 19, 2026, ELF output supports i386, M68K, PowerPC, PowerPC64, s390x, ARM, SuperH, SPARCV9, x86-64, AArch64, and RISC-V; however, 32-bit DWARF output is not supported.

Relocation Type(x86_64)

```
abs64, abs32, abs32s, abs16, abs8
pc32, plt32, pc16, pc8
got32, gotpcrel, got64
```

ELF output is also compatible with Linux.

### Test Environment

FreeBSD, EndeavourOS (Linux)

Assembly
```
axx.py hello.axx hello.s -o hello.o
axx.py hello.axx hel.s -o hel.o
```

Linking

```
ld hello.o hel.o -o hello
```

LLVM linker also passed.

```
ld.lld -o hello hello.o hel.o
```
Execution
```
% hello
hello, world
hello, world
%
```
Minimal pattern file for hello
```text:hello.axx
.setsym::EAX::0
.setsym::EDI::7
.setsym::EDX::2
MOV r,!e :: 0xb8|r,e,e>>8,e>>16,e>>24
MOVABS RSI,!e:: 0x48,0xbe,@@[8,*(e,%%)]
SYSCALL :: 0xf,0x5
MOVABS RAX,!e:: 0x48,0xB8,@@[8,*(e,%%)]
CALL RAX :: 0xff,0xd0
CALL !e :: 0xe8,@@[4,*(e-$.,%%)]
NOP:: 0x90
RET :: 0xC3
```

hello.s body

```assembly:hello.s
; axx test example hello world.
; for x86_64 FreeBSD
;
; assemble:
; axx.py hello.axx hello.s -o hello.o
;
.global _hello
.global _hello2
.section .text
_hello:
_hello2: 
mov eax, 4 ; sys_write (04) 
mov edi, 1; stdout (01) 
mov edx,len ; length (13) 
movabs rsi,msg ; address
syscall
ret
msg: .ascii "hello, world\n"
len: .equ $$ - msg
.endsection
```
hel.s hello call wrapper (for .extern,.global directive test)
```assebly:hel.s
; axx test example hello world.
; for x86_64 FreeBSD
;
.extern _hello::abs64
.extern _hello2
.global _start
.section .text
_start:
nop
call _hello2
movabs rax,_hello
call rax
mov edi,0 ; return 0
mov eax,1
syscall
.endsection
```

Default relocation types by size in x86-64:

```
8 bytes: abs64: R_X86_64_64 (Type 1)
4 bytes: pc32 : R_X86_64_PC32 (Type 2)
2 bytes: pc16 : R_X86_64_PC16 (Type 13)
1 byte: pc8 : R_X86_64_PC8 (Type 15)
```
### How to run on Linux

When running on Linux, pass the option `--osabi Linux` to axx and change the system call number. Normally, the linker doesn't look at OSABI, so you might not need to pass `--osabi`. Pass it if you get an error.

Linux testing was performed on EndeavourOS.

#### Conversion table

```text:FreeBSD
;
; FreeBSD system call numbers
;

SYS_exit 1
SYS_read 3
SYS_write 4
SYS_open 5
SYS_close 6
SYS_mmap 477
SYS_munmap 73
SYS_lseek 478

MAP_FLAGS 0x1002 ; MAP_PRIVATE|MAP_ANON (FreeBSD)
```

```text:Linux
;
; Linux system call numbers
;
SYS_exit 60
SYS_read 0
SYS_write 1
SYS_open 2
SYS_close 3
SYS_mmap 9
SYS_munmap 11
SYS_lseek 8

MAP_FLAGS 0x0022 ; MAP_PRIVATE|MAP_ANONYMOUS (Linux)
```


# C Language Library Call Test

```text:clinktest.axx
LEA RDI,[RIP+!s]::0x48,0x8d,0x3d,@@[4,*(s-$$,%%)]
XOR EAX,EAX::0x31,0xc0
CALL !s::0xe8,@@[4,*(s-$$,%%)]
RET::0xc3
```

```text:clinktest.s
.extern puts::plt32 ;In axx, you specify plt32 (relocation type) like this.

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
```

execution

```
axx clinktest.axx clinktest.s -o clinktest.o
gcc -o testexe clinktest.o -lc
testexe
hello

```

### GOT Test

x86_64 Pattern File (Partial)

got.axx

```
/* ========================================
   x86_64 Pattern File for axx (got.s 用に最適化済み)
   ======================================== */

/* ====================== レジスタ定義 ====================== */
.setsym::RAX::0
.setsym::RCX::1
.setsym::RDX::2
.setsym::RBX::3
.setsym::RSP::4
.setsym::RBP::5
.setsym::RSI::6
.setsym::RDI::7
.setsym::R8::8
.setsym::R9::9
.setsym::R10::10
.setsym::R11::11
.setsym::R12::12
.setsym::R13::13
.setsym::R14::14
.setsym::R15::15

.setsym::EAX::0
.setsym::ECX::1
.setsym::EDX::2
.setsym::EBX::3
.setsym::ESP::4
.setsym::EBP::5
.setsym::ESI::6
.setsym::EDI::7
.setsym::R8D::8
.setsym::R9D::9
.setsym::R10D::10
.setsym::R11D::11
.setsym::R12D::12
.setsym::R13D::13
.setsym::R14D::14
.setsym::R15D::15

/* ====================== 使用中の命令のみ ====================== */

/* MOV RAX,[RIP+foo] */
MOV RAX,[RIP+!d] :: :: 0x48,0x8b,0x05,@@[4,*(d-$.,%%)]

/* 64bit メモリロード */
MOV d,[b]  ::  ::  0x48|((d&8)>>1)|((b&8)>>3),0x8b,((d&7)<<3)|(b&7)

/* 64bit レジスタ間 MOV */
MOV d,s  ::  ::  0x48|((s&8)>>1)|((d&8)>>3),0x89,0xc0|(d&7)|((s&7)<<3)

/* 64bit 即値 MOV */
MOV d,!e  ::  ::  0x48|((d&8)>>3),0xb8|(d&7),@@[8,*(e,%%)]

/* XOR */
XOR d,s  ::  ::  0x48|((s&8)>>1)|((d&8)>>3),0x31,0xc0|(d&7)|((s&7)<<3)

/* LEA RIP相対 */
LEA d,[RIP+!a]  ::  ::  0x48|((d&8)>>1),0x8d,((d&7)<<3)|5,@@[4,*(a-$.,%%)]

/* CALL */
CALL !e      ::   0xe8,@@[4,*(e-$.,%%)]

/* その他 */
PUSH RBP ::  ::  0x55
LEAVE    ::  ::  0xc9
RET      ::  ::  0xc3

/* ====================== データ ====================== */
DB !e  ::  ::  e
DD !e  ::  ::  @@[4,*(e,%%)]
```

got processing assembly source

got.s

```
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

; Get the actual address of foo from GOT

mov rax, [rip + foo]

; Read the value of foo
mov rsi, [rax]

lea rdi, [rip + msg]

xor rax, rax

call printf

mov rax, 0
leave
ret
```

Referenced file foo

```
long foo = 1234;
```

Compile, assemble, and link

```
gcc -fPIC -c foo.c
axx got.axx got.s -o got.o
gcc -pie got.o foo.o -o execfile
```

Execute

```
./execfile
foo = 1234
```
