---
title: Creating a relocatable x86_64 ELF with axx, and then linking and executing it
tags: FreeBSD axx x86_64 assembly Terminal
author: fygar256
slide: false
---
https://qiita.com/fygar256/items/1d06fb757ac422796e31

I successfully created a relocatable x86_64 ELF object file using axx on FreeBSD, linked it, and executed it. On March 12, 2026, paxx gained the `-o` option and relocatable ELF output functionality. paxx's relocatable ELF generation only supports elf64. Generating elf64 for relocatable ELF as object output is a special case, but since I only have x86_64 machines, I only have one for now. I'll consider general object file output later. On April 23, 2026, the `.extern` and `.global` directives were added to axx. Testing was performed.

The relocation type can be specified using `.extern label::reloc_type`.

On May 3, 2026, the x86_64 relocatable ELF output of axx became complete.

The default relocation type supports x86-64, ARM, AArch64, RISC-V, and PPC.

The remaining step is to extend the relocation type for each CPU.

On May 8, 2026, it became possible to specify the relocation type using `.equ` in axx.

It can be specified using `label: .equ <expression>::reloc_type`.

Relocation Type

```
abs64, abs32, abs32s, abs16, abs8
pc32, plt32, pc16, pc8
got32, gotpcrel, got64
```

ELF output is also compatible with Linux.

The current axx.py ELF output is a special solution for FreeBSD and Linux for x86_64, but automatic detection of the relocation type for ELF64 is not implemented because it would compromise the generality of the instructions.

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

x86_64.axx

```
/* ========================================
x86_64 Pattern File for axx
======================================= */

/* ====================== Register Definitions ====================== */
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
.s etsym::EDX::2
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

.setsym::AL::0
.setsym::CL::1
.setsym::DL::2
.setsym::BL::3

/* ====================== MOV RAX,[rip+foo] ====================== */
MOV RAX,[RIP+!d] :: :: 0x48,0x8b,0x05,@@[4,*(d-$.,%%)]

/* ====================== 64bit Memory Load ====================== */
/* MOV r64, [r/m64] (opcode 0x8B)
REX: W=1, R=(d>=8 → extends reg field), B=(b>=8 → extends r/m field)
ModRM: mod=00, reg=d (dest), r/m=b (source) */
MOV d,[b] :: :: 0x48|((d&8)>>1)|((b&8)>>3),0x8b,((d&7)<<3)|(b&7)

/* ======================= 32-bit memory load ====================== */
/* MOV r32, [r/m32] (opcode 0x8B, REX.W omitted)
';(cond?val:0)' → If val is 0, byte is omitted */
MOV DWORD d,[b] :: :: ;(((d|b)&8)?(0x40|((d&8)>>1)|((b&8)>>3)):0),0x8b,((d&7)<<3)|(b&7)

/* ====================== 64bit register-to-register MOV ====================== */
/* MOV r/m64, r64 (opcode 0x89) 
reg=s(source), r/m=d(dest) 
REX: W=1, R=(s>=8), B=(d>=8) */
MOV d,s :: :: 0x48|((s&8)>>1)|((d&8)>>3),0x89,0xc0|(d&7)|((s&7)<<3)

/* ====================== 64bit immediate value MOV ====================== */
/* MOV r64, imm64 (opcode 0xB8+rd) 
REX: W=1, B=(d>=8 → extends opcode register field) 
opcode = 0xB8 | (d&7) */
MOV d,!e :: :: 0x48|((d&8)>>3),0xb8|(d&7),@@[8,*(e,%%)]

/* ====================== 32-bit register-to-register MOV ====================== */
MOV DWORD d,s :: :: ;(((d|s)&8)?(0x40|((s&8)>>1)|((d&8)>>3)):0),0x89,0xc0|(d&7)|((s&7)<<3)

/* ====================== 32-bit immediate value MOV ====================== */
MOV DWORD d,!e :: :: ;((d&8)?(0x41):0),0xb8|(d&7),@@[4,*(e,%%)]

/* ====================== 8bit MOV ====================== */
MOV BYTE d,s :: :: ;(((d|s)&8)?(0x40|((s&8)>>1)|((d&8)>>3)):0),0x88,0xc0|(d&7)|((s&7)<<3)
MOV BYTE d,!e :: :: 0xb0|(d&7),e

/* ====================== ADD ====================== */
/* ADD r/m64, r64 (opcode 0x01) 
REX: W=1, R=(s>=8), B=(d>=8) */
ADD d,s :: :: 0x48|((s&8)>>1)|((d&8)>>3),0x01,0xc0|(d&7)|((s&7)<<3)

/* ADD r/m64, imm32 (opcode 0x81 /0) 
ModRM: mod=11, /0 → reg=0, r/m=d → 0xC0|(d&7) */
ADD d,!i :: :: 0x48|((d&8)>>3),0x81,0xc0|(d&7),@@[4,*(i,%%)]

/* ====================== XOR ====================== */
XOR d,s :: :: 0x48|((s&8)>>1)|((d&8)>>3),0x31,0xc0|(d&7)|((s&7)<<3)

/* ====================== CMP (64bit) ====================== */
/* CMP r/m64, r64 (opcode 0x39) */
CMP d,s :: :: 0x48|((s&8)>>1)|((d&8)>>3),0x39,0xc0|(d&7)|((s&7)<<3)

/* CMP r/m64, imm32 (opcode 0x81 /7) 
ModRM: mod=11, /7 → reg=7, r/m=d → 0xF8|(d&7) */
CMP d,!i :: :: 0x48|((d&8)>>3),0x81,0xf8|(d&7),@@[4,*(i,%%)]

/* ====================== CMP (32bit) ====================== */
CMP DWORD d,s :: :: ;(((d|s)&8)?(0x40|((s&8)>>1)|((d&8)>>3)):0),0x39,0xc0|(d&7)|((s&7)<<3)
CMP DWORD d,!i :: :: ;((d&8)?(0x41):0),0x81,0xf8|(d&7),@@[4,*(i,%%)]

/* ====================== CMP (8bit) ====================== */
/* CMP BYTE PTR [b], imm8 — Register indirect
ModRM: mod=00, /7 → reg=7(CMP), r/m=b → 0x38|(b&7) */
CMP BYTE [b],!i :: :: ;((b&8)?0x41:0),0x80,0x38|(b&7),i

/* CMP r/m8, imm8 — register direct */
CMP BYTE d,!i :: :: ;((d&8)?0x41:0),0x80,0xf8|(d&7),i

/* ====================== INC/DEC (64bit) ====================== */
/* INC r/m64 (opcode 0xFF /0) 
REX: W=1, B=(d>=8) 
ModRM: mod=11, /0 → reg=0, r/m=d → 0xC0|(d&7) */
INC d :: :: 0x48|((d&8)>>3),0xff,0xc0|(d&7)

/* DEC r/m64 (opcode 0xFF /1) 
ModRM: mod=11, /1 → reg=1, r/m=d → 0xC8|(d&7) */
DEC d :: :: 0x48|((d&8)>>3),0xff,0xc8|(d&7)

/* ====================== LEA ====================== */
/* LEA r64, [RIP+disp32] — RIP relative (instruction length = (7 bytes)
REX: W=1, R=(d>=8)
ModRM: mod=00, reg=d, r/m=5(RIP+disp32) → ((d&7)<<3)|5 */
LEA d,[RIP+!a] :: :: 0x48|((d&8)>>1),0x8d,((d&7)<<3)|5,@@[4,*(a-$.,%%)]

/* ====================== Unconditional branch (32-bit relative, 5 bytes) ====================== */
CALL !e :: 0xe8,@@[4,*(e-$.,%%)]

/* ====================== Other ====================== */
SYSCALL :: :: 0x0f,0x05
RET :: :: 0xc3
NOP :: :: 0x90
LEAVE :: :: 0xc9
PUSH RBP :: :: 0x55
/* ====================== Data ====================== */
DB !e :: :: e
DD !e :: :: @@[4,*(e,%%)]
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
axx x86_64.axx got.s -o got.o
gcc -pie got.o foo.o -o execfile
```

Execute

```
./execfile
foo = 1234
```
