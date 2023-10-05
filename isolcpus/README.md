# CPU隔离

一台8核的arm64机器
```
# lscpu
Architecture:        aarch64
Byte Order:          Little Endian
CPU(s):              8
On-line CPU(s) list: 0-7
Thread(s) per core:  1
Core(s) per socket:  7
Socket(s):           1
Model:               0
BogoMIPS:            125.00
Flags:               fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
```

配置isolcpus=2这个启动参数后重启
```
# cat /proc/cmdline
root=/dev/vda isolcpus=2
```

## user space

使用demo创建进程，把CPU占满
```
import multiprocessing

def worker():
    while True:
        pass

if __name__ == '__main__':
    num_processes = multiprocessing.cpu_count()
    print(f"Starting {num_processes} processes...")
    processes = [multiprocessing.Process(target=worker) for _ in range(num_processes)]
    for p in processes:
        p.start()
    for p in processes:
        p.join()
```

可以看到CORE2的CPU占用率为0%，其他CPU占用率为100%
```
    0[||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||97.3%]   4[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    1[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]   5[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    2[                                                                     0.0%]   6[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    3[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]   7[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
  Mem[|||||||||||||                                                  168M/1.67G] Tasks: 27, 1 thr, 92 kthr; 8 running
  Swp[                                                                    0K/0K] Load average: 6.35 2.11 0.76
```

迁移其中一个进程到CORE2
```
# pidof python
249 248 247 246 245 244 243 242 241
# taskset -pc 2 244
pid 244's current affinity list: 0,1,3-7
pid 244's new affinity list: 2
```

可以看到CORE2的CPU占用率也变为100%
```
    0[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]   4[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    1[||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||98.0%]   5[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    2[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]   6[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
    3[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]   7[|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100.0%]
  Mem[|||||||||||||                                                  170M/1.67G] Tasks: 27, 1 thr, 92 kthr; 8 running
  Swp[                                                                    0K/0K] Load average: 8.15 5.33 2.36
```

## kernel space

### interrupt

当前设备上的中断情况
```
# cat /proc/interrupts
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:       1938       1017        144       1455       1408       1131       1524        994 GIC-0  27 Level     arch_timer
 13:         69          0          0          0          0          0          0          0 GIC-0  33 Level     uart-pl011
 14:          0          0          0          0          0          0          0          0 GIC-0  23 Level     arm-pmu
 18:          0          0          0          0          0          0          0          0       MSI 32768 Edge      virtio1-config
 19:       1414          0          0          0          0          0          0          0       MSI 32769 Edge      virtio1-req.0
 20:          0          0          0          0          0          0          0          0       MSI 16384 Edge      virtio0-config
 21:         35          0          0          0          0          0          0          0       MSI 16385 Edge      virtio0-input.0
 22:         65          0          0          0          0          0          0          0       MSI 16386 Edge      virtio0-output.0
IPI0:        40         54         36         66         56         19         53         60       Rescheduling interrupts
IPI1:       985        608         22        601        488        357        477        544       Function call interrupts
IPI2:         0          0          0          0          0          0          0          0       CPU stop interrupts
IPI3:         0          0          0          0          0          0          0          0       CPU stop (for crash dump) interrupts
IPI4:         0          0          0          0          0          0          0          0       Timer broadcast interrupts
IPI5:         0          0          0          0          0          0          0          0       IRQ work interrupts
IPI6:         0          0          0          0          0          0          0          0       CPU wake-up interrupts
Err:          0
```

可以看到类似uart-pl011的affinity也可以配置为跳过CORE2
```
# cat /proc/irq/13/smp_affinity_list
0-1,3-7
```

当把uart-pl011的affinity设置为2后，可以看到CORE2上有对应的中断
```
# cat /proc/interrupts
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:       2017       1051        156       1478       1511       1142       1537       1014 GIC-0  27 Level     arch_timer
 13:         80          0          3          0          0          0          0          0 GIC-0  33 Level     uart-pl011
 14:          0          0          0          0          0          0          0          0 GIC-0  23 Level     arm-pmu
 18:          0          0          0          0          0          0          0          0       MSI 32768 Edge      virtio1-config
 19:       1420          0          0          0          0          0          0          0       MSI 32769 Edge      virtio1-req.0
 20:          0          0          0          0          0          0          0          0       MSI 16384 Edge      virtio0-config
 21:         35          0          0          0          0          0          0          0       MSI 16385 Edge      virtio0-input.0
 22:         65          0          0          0          0          0          0          0       MSI 16386 Edge      virtio0-output.0
IPI0:        40         55         36         66         56         19         53         60       Rescheduling interrupts
IPI1:      1010        613         22        601        509        357        484        547       Function call interrupts
IPI2:         0          0          0          0          0          0          0          0       CPU stop interrupts
IPI3:         0          0          0          0          0          0          0          0       CPU stop (for crash dump) interrupts
IPI4:         0          0          0          0          0          0          0          0       Timer broadcast interrupts
IPI5:         0          0          0          0          0          0          0          0       IRQ work interrupts
IPI6:         0          0          0          0          0          0          0          0       CPU wake-up interrupts
Err:          0
```

但是从上面可以看出，timer跟IPI的中断依然在CORE2上，而且timer跟IPI的中断是内核空间的中断，无法进行迁移
```
# cat /proc/irq/11/smp_affinity_list
0-7
# echo 2 > /proc/irq/11/smp_affinity_list
-bash: echo: write error: Input/output error
```

这里重点要讨论一下timer tick
一般来说默认情况下已经配置NO_HZ，因此CORE2上面什么都不跑的时候，实际timer中断几乎不发生
```
Wed Dec 28 20:49:26 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      15419      16745       4078       9958      23185      17476      12383      13498 GIC-0  27 Level     arch_timer
Wed Dec 28 20:49:31 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      15450      16756       4080       9966      23188      17502      12439      13517 GIC-0  27 Level     arch_timer
```

但是当我们放一个进程到CORE2上的时候，timer中断就会频繁发生
```
# taskset -pc 2 461
pid 461's current affinity list: 0,1,3-7
pid 461's new affinity list: 2
# date; cat /proc/interrupts | head -n 2; sleep 5; date; cat /proc/interrupts | head -n 2
Wed Dec 28 20:54:19 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      25449      26758      10028      19819      33099      27593      22701      23346 GIC-0  27 Level     arch_timer
Wed Dec 28 20:54:24 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      26009      27316      10586      20375      33657      28152      23258      23904 GIC-0  27 Level     arch_timer
```

但是我们可以通过nohz_full=2来使CPU2支持NO_HZ_FULL
当使能了NO_HZ_FULL后，Linux支持在CPU上仅有1个任务的时候，也是可以NO_HZ的
```
# taskset -pc 2 212
pid 212's current affinity list: 0,1,3-7
pid 212's new affinity list: 2
# date; cat /proc/interrupts | head -n 2; sleep 5; date; cat /proc/interrupts | head -n 2
Wed Dec 28 21:29:16 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      55492      32622         54      32283      32898      31959      32105      32238 GIC-0  27 Level     arch_timer
Wed Dec 28 21:29:21 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      56051      33176         54      32840      33454      32515      32661      32796 GIC-0  27 Level     arch_timer
```

而再放一进程到CORE2上，timer中断就会又会开始频繁发生
```
# taskset -pc 2 214
pid 214's current affinity list: 0,1,3-7
pid 214's new affinity list: 2
# date; cat /proc/interrupts | head -n 2; sleep 5; date; cat /proc/interrupts | head -n 2
Wed Dec 28 21:31:07 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      66656      43385        469      43421      44035      43096      43242      43383 GIC-0  27 Level     arch_timer
Wed Dec 28 21:31:13 UTC 2022
           CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7
 11:      67193      43919       1003      43955      44569      43630      43776      43917 GIC-0  27 Level     arch_timer
```

正如[no_hz.rst](https://www.kernel.org/doc/Documentation/timers/no_hz.rst)描述的一样
```
If a CPU has only one runnable task, there is little point in sending it
a scheduling-clock interrupt because there is no other task to switch to.
Note that omitting scheduling-clock ticks for CPUs with only one runnable
task implies also omitting them for idle CPUs.

如果CPU只有一个可运行的任务，那么向它发送时钟中断就没有什么意义了，因为没有其他任务可供切换。
请注意，对于只有一个可运行任务的CPU，省略时钟节拍意味着对于空闲CPU也省略它们。
```

### kthread

```
# ps
PID   USER     COMMAND
    1 root     {systemd} /sbin/init
    2 root     [kthreadd]

# taskset -pc 2
pid 2's current affinity list: 0,1,3-7
```

## tool

[partrt](https://github.com/OpenEneaLinux/rt-tools/tree/master/partrt)