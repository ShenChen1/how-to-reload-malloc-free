<br/>select核心函数</br>
```
static int do_select(int n, fd_set_bits *fds, struct timespec64 *end_time)
```

<br/>获取最大文件描述符编号</br>
```
rcu_read_lock();
retval = max_select_fd(n, fds);
rcu_read_unlock();
```

<br/>使用`init_poll_funcptr`注册回调函数`__pollwait`</br>
<br/>`__pollwait`后面轮询时，设备字符驱动会调用，把进程添加到对应的监听文件等待队列</br>
```
poll_initwait(&table);
wait = &table.pt;

void poll_initwait(struct poll_wqueues *pwq)
{
	init_poll_funcptr(&pwq->pt, __pollwait);
	pwq->polling_task = current;
	pwq->triggered = 0;
	pwq->error = 0;
	pwq->table = NULL;
	pwq->inline_index = 0;
}

static inline void init_poll_funcptr(poll_table *pt, poll_queue_proc qproc)
{
	pt->_qproc = qproc;
	pt->_key   = ~(__poll_t)0; /* all events enabled */
}
```

<br/>这里会调用`struct file*`实现的poll函数进行轮询</br>
```
mask = vfs_poll(f.file, wait);

static inline __poll_t vfs_poll(struct file *file, struct poll_table_struct *pt)
{
	if (unlikely(!file->f_op->poll))
		return DEFAULT_POLLMASK;
	return file->f_op->poll(file, pt);
}
```

<br/>以`scull_p_poll`为例，把调用select的进程添加到文件描述符对应的监听列表</br>
<br/>通过`poll_wait`把当前进程挂到`dev->inq`和`dev->outq`队列里面来，</br>
<br/>当有读写事件到来时，就会唤醒队列里面的进程，让他们重新运行，来轮询读写数据</br>
```
static unsigned int scull_p_poll(struct file *filp, poll_table *wait)
{
    struct scull_pipe *dev = filp->private_data;
    unsigned int mask = 0;

    /*
     * The buffer is circular; it is considered full
     * if "wp" is right behind "rp" and empty if the
     * two are equal.
     */
    down(&dev->sem);
    poll_wait(filp, &dev->inq,  wait);
    poll_wait(filp, &dev->outq, wait);
    if (dev->rp != dev->wp)
        mask |= POLLIN | POLLRDNORM;    /* readable */
    if (spacefree(dev))
        mask |= POLLOUT | POLLWRNORM;   /* writable */
    up(&dev->sem);
    return mask;
}

static inline void poll_wait(struct file * filp, wait_queue_head_t * wait_address, poll_table *p)
{
	if (p && p->_qproc && wait_address)
		p->_qproc(filp, wait_address, p);
}

//p->_qproc就是一开始注册的__pollwait
/* Add a new entry */
static void __pollwait(struct file *filp, wait_queue_head_t *wait_address,
				poll_table *p)
{
	struct poll_table_entry *entry = poll_get_entry(p);
	if (!entry)
		return;
	get_file(filp);
	entry->filp = filp;
	entry->wait_address = wait_address;
	init_waitqueue_entry(&entry->wait, current);
	add_wait_queue(wait_address,&entry->wait);
}
```

<br/>`retval`保存了检测到的可操作的文件描述符的个数
<br/>如果有文件可操作，则跳出`for(;;)`循环，直接返回
<br/>若没有文件可操作且timeout时间未到同时没有收到signal，则执行schedule_timeout睡眠
<br/>睡眠时间长短由timeout决定，一直等到该进程被唤醒。
```
if (retval || timed_out || signal_pending(current))
	break;
```
