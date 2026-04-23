---
title: Creating a relocatable x86_64 ELF with axx, and then linking and executing it
tags: FreeBSD axx x86_64 assembly Terminal
author: fygar256
slide: false
---
https://qiita.com/fygar256/items/1d06fb757ac422796e31

I successfully created a relocatable x86_64 ELF object file using axx on FreeBSD, linked it, and executed it. On March 12, 2026, paxx gained the `-o` option and relocatable ELF output functionality. paxx's relocatable ELF generation only supports elf64. Generating elf64 for relocatable ELF as object output is a special case, but since I only have x86_64 machines, I only have one for now. I'll consider general object file output later.

On April 23, 2026, the `.extern` and `.global` directives were added to `axx`. I've tested them.

I believe the current `axx` ELF output supports Linux. Strictly speaking, since FreeBSD and Linux are different operating systems, you need to specify `OSABI` in the ELF file: 9 for FreeBSD and 0 for Linux. In that case, you need to specify something like `--osabi Linux` in the first option passed to `paxx`. I don't think `ld` checks that far, though.

Assemble
```
axx.py hello.axx hello.s -o hello.o
axx.py hello.axx hel.s -o hel.o
```
Link
```
ld hello.o hel.o -o hello
```
Execute
```
% hello
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
DB e :: e
````

hello.s body

```assembly:hello.s
; axx test example hello world.
; for x86_64 FreeBSD
;
.global _hello 
.org 0
section.text
_hello: 
mov eax, 4 ; sys_write (04) 
mov edi, 1; stdout (01) 
mov edx,len ; length (13) 
movabs rsi,msg ; address 
syscall 
mov edi, 0; return 0 
mov eax, 1 
syscall
msg: .ascii "hello, world\n"
len: .equ $$ - msg
end section
````

hel.s hello call wrapper (for .extern,.global directive test)

````
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
```
Note that when running on Linux, it seems to work simply by changing the system call number.

#### Conversion Table
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

The LLVM linker also passed.

````
% ld.lld -o hello hello.o hel.o
% ./hello
hello, world
%
````
