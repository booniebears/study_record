# nontrivalCPU

 1. Uncache的 lb 指令的Arsize未修改      -> 已修复
 2. 旁路 HILO移到EXE级 CP0移到MEM级      -> 已修复
 3. 重构CP0 & 中断的bug修复              -> 已修复
 4. 乘法的bug                            -> 已修复
  5. CP0中TLB例外                         -> 已完成  



## TODO:

+  1. 重写cache   （需要TB的测试）

+  2. 阅读相关PMON资料，准备添加指令，并启动操作系统    （已经实现 但未经过测试）

+  3. 现在时钟中断未经过测试，可能存在bug    （中断标记的bug需要修复）
+  4. **MEM级扇出较大**，需要优化，可以去除instr & 旁路数据的信号
+ 5. 减少一些**没用到的线**，可以优化时序 



## OS相关
+  PMON: 协处理器异常，自陷异常，非对齐访存，ebase+offset，去除branchlikely，CACHE指令

+  ucore: 协处理器异常，自陷异常，非对齐访存，去除branchlikely，tlbwr

+  linux（context寄存器？清华16spring的markdown）重大有wired和context，MADD，MOV指令

+  Cause寄存器太弱了，Wired，Random？   （已经实现 但未经过测试）

+  TLBWR去除（ucore请看清华15年报告，linux请看16spring的markdown）

+  Branchlikely去除（请看）

+  LL/SC去除，watchlo/watchhi去除 （清华17pdf）
## Caution

+ 系统测试中，为了跑监控程序**必须将cache打开**，否则串口中断的接受存在一定的时序问题（初步估计是线程切换的时间大于两次串口中断的时间）
+ 系统测试中，为了正确运行G指令，由A指令输入的数据 **必须存放在A0000000 - C0000000 段下** ，否则A命令写入的数据会 **优先存在Dcache中**Icache取指令的时候就存在一定的问题。（这与清华监控程序的文档存在偏差，暂时不清楚应该如何处理）
