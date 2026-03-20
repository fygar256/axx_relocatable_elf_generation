---
title: Creating a relocatable x86_64 ELF with axx, and then linking and executing it
tags: FreeBSD axx x86_64 assembly Terminal
author: fygar256
slide: false
---

I successfully created a relocatable x86_64 ELF object file using axx on FreeBSD, and linked and executed it. On March 12, 2026, paxx and caxx gained the `-o` option and relocatable ELF output functionality. Relocatable ELF generation in paxx and caxx only supports elf64. Relocatable ELF generation as elf64 is a special case, but since I only have x86_64 machines, I only have one for now. I'll consider general object file output later. I believe the current axx ELF output supports Linux. Strictly speaking, since FreeBSD and Linux are different operating systems, you need to specify 9 for OSABI in the ELF file and 0 for Linux. In that case, you need to specify something like `--osabi Linux` as the first option passed to axx or caxx. I don't think ld checks that far, though. Assemble

```
axx.py hello.axx hello.s -o hello.o
```

Link

```
ld hello.o -o hello
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
```

hello.s main body

```assembly:hello.s
.export _start
section .text
_start:
_hello:
mov eax, 4 ; sys_write (04)
mov edi, 1 ; stdout (01)
mov edx,len ; length (13)
movabs rsi,msg ; address
syscall
mov edi, 0 ; return 0
mov eax, 1
syscall
msg: .ascii "hello, world\n"
len: .equ $$ - msg
endsection
```

Note that when running on Linux, it seems to work fine as long as you change the system call number.

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
````

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
````
