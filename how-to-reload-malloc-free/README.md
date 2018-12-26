# 1.使用libc的弱定义重载
```
优点：可以直接使用LD_PRELOAD，不需要重新编译
缺点：glibc里面有定义，其他c库未知
```

# 2.使用dlsym重载
```
优点：比较通用
缺点：直接使用LD_PRELOAD会引发段错误，去掉calloc后可以正常
```

# 3.使用wrap重载
```
优点：比较通用
缺点：只能替换静态文件中的符号，无法替换动态库中的符号
```

# 4.使用malloc_hook
```
参考man手册
```