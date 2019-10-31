# soname的使用
有时会升级共享库，因此要有办法辨识共享库的版本，还有可能需要并存同一套但不同版本的共享库

## Linux的命名规则
```
为了解决共享库的兼容问题，使用共享库版本：
libname.so.x.y.z其中lib是前缀，中间是库名称和后缀.so,
最后是三个数字组成的版本号。x表示主版本号，y表示次版本号，z表示发布版本号。
主版本号，表示重大升级，不同主版本号库之间不兼容
次版本号，表示库的增量升级，增加了一些新接口符号，并保持原来符号不变。在主版本号相同下，新的次版本号向后兼容低次版本号的接口。
发布版本号，表示库的一些错误的修正，性能的改进，并不添加任何新的dao接口，也不对接口进行更正。相同主版本号，次版本号的共享库，不同的发布版本号之间完全兼容。
```
### realname：libname.so.x.y.z
realname表示包含实际库代码的文件名

### soname：libname.so.x
soname为runtime-linker提供了创建适当链接的提示

### linkname：libname.so
linkname是compiler在请求库时使用的名称

## test
```
[root@sc tmp]# make v1 test
gcc -shared -fPIC -Wl,-soname,libfoo.so.1 -o libfoo.so.1.1 foo_1.c
ln -sf libfoo.so.1.1 libfoo.so
gcc main.c -I. -L. -lfoo -o a.out
# Same as `ldconfig -n .`, creates a symbolic link
# ln -sf libfoo.so.1.1 libfoo.so.1
ldconfig -n .
#./a.out: error while loading shared libraries: libfoo.so.1: cannot open 
# shared object file: No such file or directory
LD_LIBRARY_PATH=. ./a.out
call foo 1
[root@sc tmp]# make v2 test
gcc -shared -fPIC -Wl,-soname,libfoo.so.1 -o libfoo.so.1.2 foo_2.c
# Same as `ldconfig -n .`, creates a symbolic link
# ln -sf libfoo.so.1.2 libfoo.so.1
ldconfig -n .
#./a.out: error while loading shared libraries: libfoo.so.1: cannot open 
# shared object file: No such file or directory
LD_LIBRARY_PATH=. ./a.out
call foo 2
```
此时执行可以看到库已经被升级了，因为linker使用的是soname

```
[root@sc tmp]# ll
total 48
-rwxr-xr-x 1 root root 8424 Oct 31 20:06 a.out
-rw-r--r-- 1 root root   78 Oct 31 19:59 foo_1.c
-rw-r--r-- 1 root root   78 Oct 31 20:00 foo_2.c
-rw-r--r-- 1 root root   47 Oct 31 18:15 foo.h
lrwxrwxrwx 1 root root   13 Oct 31 20:06 libfoo.so -> libfoo.so.1.1
lrwxrwxrwx 1 root root   13 Oct 31 20:06 libfoo.so.1 -> libfoo.so.1.2
-rwxr-xr-x 1 root root 8104 Oct 31 20:06 libfoo.so.1.1
-rwxr-xr-x 1 root root 8104 Oct 31 20:06 libfoo.so.1.2
-rw-r--r-- 1 root root   55 Oct 31 18:16 main.c
-rw-r--r-- 1 root root  888 Oct 31 20:06 Makefile
```
