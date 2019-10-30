# popen捕获的输出与sh直接输出不一致
最近在做RPC，想用下popen执行远程命令再返回执行结果

## 直接在console执行:
```
[root@sc WinShare]# ls 
a.out  dup.c  popen.c
```

## 执行popen.out:
```
[root@sc WinShare]# ./a.out 
a.out
dup.c
popen.c
```

## 使用strace跟踪ls:
```
[root@sc WinShare]# strace ls
......
execve("/usr/bin/sh", ["sh", "-c", "ls"], [/* 29 vars */]) = 0
......
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TIOCGWINSZ, {ws_row=32, ws_col=77, ws_xpixel=0, ws_ypixel=0}) = 0
......
write(1, "a.out  dup.c  popen.c\n", 22a.out  dup.c  popen.c
) = 22
......
```

## 使用strace跟踪popen.out:
```
[root@sc WinShare]# strace -f ./a.out
......
[pid  8204] execve("/bin/sh", ["sh", "-c", "ls"], [/* 29 vars */]) = 0
......
[pid  8204] ioctl(1, TCGETS, 0x7ffced4b8900) = -1 ENOTTY (Inappropriate ioctl for device)
[pid  8204] ioctl(1, TIOCGWINSZ, 0x7ffced4b89d0) = -1 ENOTTY (Inappropriate ioctl for device)
......
[pid  8204] write(1, "a.out\ndup.c\npopen.c\n", 20) = 20
[pid  8203] <... read resumed> "a.out\ndup.c\npopen.c\n", 4096) = 20
......
```

因此可以看出是由于没有获取到terminal属性导致输出的不一致
