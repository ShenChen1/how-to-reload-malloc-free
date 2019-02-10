# x86替换got表

## 执行test.out:
```
 hello 1
 hello 2
 hello 3
 hello ./test.out
```

## 找到my_printf:
objdump -d -s -j .text test.out
```
0000000000400560 <my_printf>:
  400560:   48 83 ec 08             sub    $0x8,%rsp
  400564:   e8 97 fe ff ff          callq  400400 <puts@plt>
  400569:   48 83 c4 08             add    $0x8,%rsp
  40056d:   c3                      retq   
  40056e:   90                      nop
  40056f:   90                      nop
```

## 找到printf@plt:
objdump -d -s -j .plt test.out
```
00000000004003f0 <printf@plt>:
  4003f0:   ff 25 22 05 20 00       jmpq   *0x200522(%rip)        # 600918 <_GLOBAL_OFFSET_TABLE_+0x18>
  4003f6:   68 00 00 00 00          pushq  $0x0
  4003fb:   e9 e0 ff ff ff          jmpq   4003e0 <_init+0x18>
```

## 找到printf的got位置:
objdump -d -s -j .got.plt test.out
```
Contents of section .got.plt:
 600900 68076000 00000000 00000000 00000000  h.`.............
 600910 00000000 00000000 f6034000 00000000  ..........@.....
 600920 06044000 00000000 16044000 00000000  ..@.......@.....
```

`600918`地址上的`004003f6`就是`printf@plt`中的`pushq  $0x0`.<br>
`4003e0`为动态链接器处理入口，运行完成以后,<br>
`600918`地址上的`004003f6`就会被替换成printf在动态链接库的内存映像中的地址,<br>
因此直接将`f6034000`替换为`60054000`，完成函数替换.<br>

## 执行a.out:
```
hello 1
hello 2
hello 3
hello %s

hello %s %s

```
