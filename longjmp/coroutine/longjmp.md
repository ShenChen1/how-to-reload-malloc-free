man longjmp
NAME
       longjmp, siglongjmp - nonlocal jump to a saved stack context

SYNOPSIS
       #include <setjmp.h>

       void longjmp(jmp_buf env, int val);
       void siglongjmp(sigjmp_buf env, int val);

DESCRIPTION
       longjmp()  and  setjmp(3) are useful for dealing with errors and interrupts encountered in a low-level subroutine of a program.  longjmp() restores the environment saved by the last call of setjmp(3)
       with the corresponding env argument.  After longjmp() is completed, program execution continues as if the corresponding call of setjmp(3) had just returned the value val.  longjmp() cannot cause 0 to
       be returned.  If longjmp() is invoked with a second argument of 0, 1 will be returned instead.

       longjmp和setjmp在处理程序调用子例程过程中遇到错误或中断时非常有用。longjmp将恢复最近一次调用setjmp时通过env参数保存的上下文环境。longjmp完成后，原来调用setjmp的地方将会返回，并且setjmp的返回值是longjmp的val参数。longjmp不会返回0。如果longjmp调用时第二个参数是0，那么它将会返回1.

       siglongjmp()  is  similar  to longjmp() except for the type of its env argument.  If, and only if, the sigsetjmp(3) call that set this env used a nonzero savesigs flag, siglongjmp() also restores the
       signal mask that was saved by sigsetjmp(3).

RETURN VALUE
       These functions never return.
